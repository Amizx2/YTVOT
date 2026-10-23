#!/usr/bin/env bash
set -e

# ==============================================================================
# YTVOT: Standalone Voice-Over Translation Builder for Linux / Kali / Ubuntu
# ==============================================================================

BOLD="\033[1m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${BOLD}${CYAN}=== YTVOT Standalone Builder for Linux / Kali ===${RESET}\n"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

INPUT_IPA="${1:-}"

# 1. System packages
echo -e "${YELLOW}[1/5] Проверка системных зависимостей...${RESET}"
MISSING_PKGS=()
for pkg in build-essential make clang git curl wget xz-utils zip unzip python3 ccache; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo -e "Установка недостающих пакетов: ${MISSING_PKGS[*]}..."
    sudo apt-get update -y
    sudo apt-get install -y "${MISSING_PKGS[@]}"
else
    echo -e "${GREEN}Все системные пакеты установлены.${RESET}"
fi

# ldid
if ! command -v ldid >/dev/null 2>&1; then
    echo -e "${YELLOW}Загрузка ldid...${RESET}"
    sudo curl -fsSL -o /usr/local/bin/ldid https://github.com/ProcursusTeam/ldid/releases/latest/download/ldid_linux_x86_64
    sudo chmod +x /usr/local/bin/ldid 2>/dev/null || true
fi

# libtinfo compatibility
if [ ! -f /usr/lib/x86_64-linux-gnu/libtinfo.so.5 ] && [ -f /usr/lib/x86_64-linux-gnu/libtinfo.so.6 ]; then
    sudo ln -sf /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5 2>/dev/null || true
    sudo ln -sf /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5 2>/dev/null || true
    sudo ldconfig 2>/dev/null || true
fi

# 2. Setup Theos
echo -e "\n${YELLOW}[2/5] Проверка Theos...${RESET}"
export THEOS="${THEOS:-$HOME/theos}"
if [ ! -d "$THEOS" ]; then
    echo "Установка RootHide Theos в $THEOS..."
    CI=true bash -c "$(curl -fsSL https://raw.githubusercontent.com/roothide/theos/master/bin/install-theos)" <<< "n"
fi

# SDK
mkdir -p "$THEOS/sdks"
SDK_TARGET="iPhoneOS16.5.sdk"
if [ ! -d "$THEOS/sdks/$SDK_TARGET" ]; then
    echo "Загрузка iOS 16.5 SDK..."
    curl -fsSL "https://github.com/theos/sdks/releases/latest/download/${SDK_TARGET}.tar.xz" -o "/tmp/${SDK_TARGET}.tar.xz"
    tar -xJf "/tmp/${SDK_TARGET}.tar.xz" -C "$THEOS/sdks"
    rm -f "/tmp/${SDK_TARGET}.tar.xz"
fi

# 3. Compile
echo -e "\n${YELLOW}[3/5] Компиляция YTVOT.dylib и .deb...${RESET}"
NCPU=$(nproc 2>/dev/null || echo 4)
export CCACHE_DIR="$HOME/.ccache"
ccache -M 5G >/dev/null 2>&1 || true

make clean
make -j"$NCPU" package \
    FINALPACKAGE=1 \
    THEOS_PACKAGE_SCHEME=rootless \
    DISABLE_ROOTLESS_COMPAT_WARNING=1

DEB_FILE=$(ls -t packages/*.deb 2>/dev/null | head -n1)
if [ -z "$DEB_FILE" ] || [ ! -f "$DEB_FILE" ]; then
    echo -e "${RED}Ошибка: .deb пакет не был собран!${RESET}"
    exit 1
fi

echo -e "${GREEN}Пакет успешно скомпилирован: $DEB_FILE${RESET}"

# 4. Extract dylib
echo -e "\n${YELLOW}[4/5] Извлечение YTVOT.dylib...${RESET}"
mkdir -p extracted_deb
dpkg-deb -x "$DEB_FILE" extracted_deb/
DYLIB_PATH=$(find extracted_deb -name "YTVOT.dylib" | head -n1)

if [ -n "$DYLIB_PATH" ] && [ -f "$DYLIB_PATH" ]; then
    cp "$DYLIB_PATH" ./YTVOT.dylib
    echo -e "${GREEN}Готовый dylib сохранён: ./YTVOT.dylib${RESET}"
fi
rm -rf extracted_deb

# 5. Pack into IPA (if IPA is provided or found)
echo -e "\n${YELLOW}[5/5] Упаковка готового IPA...${RESET}"
if [ -z "$INPUT_IPA" ]; then
    INPUT_IPA=$(find . -maxdepth 1 -type f -iname "*.ipa" ! -iname "*_VOT.ipa" | sed 's|^\./||' | head -n1 || true)
fi

if [ -n "$INPUT_IPA" ] && [ -f "$INPUT_IPA" ]; then
    echo "Обнаружен базовый IPA: $INPUT_IPA"
    INPUT_BASE=$(basename "$INPUT_IPA" .ipa)
    OUTPUT_IPA="${INPUT_BASE}_VOT.ipa"

    WORK_DIR=$(mktemp -d /tmp/ytvot_kali.XXXXXX)
    unzip -q "$INPUT_IPA" -d "$WORK_DIR"
    APP_DIR=$(find "$WORK_DIR/Payload" -mindepth 1 -maxdepth 1 -type d -name "*.app" | head -n1)

    EXECUTABLE=$(python3 - "$APP_DIR/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], 'rb') as f:
    pl = plistlib.load(f)
    print(pl.get('CFBundleExecutable', 'YouTube'))
PY
)
    MAIN_BIN="$APP_DIR/$EXECUTABLE"

    mkdir -p "$APP_DIR/Frameworks"
    cp "./YTVOT.dylib" "$APP_DIR/Frameworks/YTVOT.dylib"

    echo "Инжекция LC_LOAD_DYLIB (@rpath/YTVOT.dylib)..."
    python3 "Tools/macho_inject.py" "$MAIN_BIN" --add-load '@rpath/YTVOT.dylib'

    rm -rf "$APP_DIR/_CodeSignature"
    ldid -S "$APP_DIR/Frameworks/YTVOT.dylib" 2>/dev/null || true
    ldid -S "$MAIN_BIN" 2>/dev/null || true

    (
        cd "$WORK_DIR"
        zip -qry "$SCRIPT_DIR/$OUTPUT_IPA" Payload
    )
    rm -rf "$WORK_DIR"

    echo -e "\n${BOLD}${GREEN}================================================================${RESET}"
    echo -e "${BOLD}${GREEN}✔ Финальный IPA успешно собран:${RESET}"
    echo -e "${BOLD}${CYAN}$SCRIPT_DIR/$OUTPUT_IPA${RESET}"
    echo -e "${BOLD}${GREEN}================================================================${RESET}"
else
    echo -e "${YELLOW}Базовый YouTube.ipa не найден в текущей папке.${RESET}"
    echo -e "Чтобы собрать готовый IPA, поместите YouTube.ipa в эту папку и запустите:"
    echo -e "  ${CYAN}./build_kali.sh YouTube.ipa${RESET}"
    echo -e "\nЛибо используйте готовый DEB-пакет: ${CYAN}$DEB_FILE${RESET}"
    echo -e "Или библиотеку: ${CYAN}./YTVOT.dylib${RESET}"
fi
