#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# YTVOT: macOS Build & IPA Injection Script
# ==============================================================================

BOLD="\033[1m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${BOLD}${CYAN}=== YTVOT: macOS IPA Builder ===${RESET}\n"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

INPUT_IPA="${1:-}"
FORCE_COMPILE="${2:-}"

# 1. Check or compile YTVOT.dylib
if [[ ! -f "YTVOT.dylib" || "$INPUT_IPA" == "--compile" || "$FORCE_COMPILE" == "--compile" ]]; then
    if [[ "$INPUT_IPA" == "--compile" ]]; then
        INPUT_IPA="${2:-}"
    fi

    echo -e "${YELLOW}[1/4] Компиляция YTVOT.dylib из исходников...${RESET}"
    
    # Check Theos
    export THEOS="${THEOS:-$HOME/theos}"
    if [[ ! -d "$THEOS" ]]; then
        echo -e "Theos не найден в $THEOS. Установка RootHide Theos..."
        git clone --recursive https://github.com/roothide/theos.git "$THEOS"
    fi

    # Check SDK
    mkdir -p "$THEOS/sdks"
    if [[ ! -d "$THEOS/sdks/iPhoneOS16.5.sdk" && ! -d "$THEOS/sdks/iPhoneOS15.0.sdk" ]]; then
        echo -e "Загрузка iOS SDK..."
        git clone --depth=1 https://github.com/theos/sdks.git /tmp/theos_sdks
        cp -R /tmp/theos_sdks/*.sdk "$THEOS/sdks/" 2>/dev/null || true
        rm -rf /tmp/theos_sdks
    fi

    NCPU=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
    make clean
    make -j"$NCPU" package \
        FINALPACKAGE=1 \
        THEOS_PACKAGE_SCHEME=rootless \
        DISABLE_ROOTLESS_COMPAT_WARNING=1

    DEB_FILE=$(ls -t packages/*.deb 2>/dev/null | head -n1 || true)
    if [[ -z "$DEB_FILE" || ! -f "$DEB_FILE" ]]; then
        echo -e "${RED}Ошибка компиляции: .deb пакет не был создан!${RESET}"
        exit 1
    fi

    # Extract dylib
    mkdir -p /tmp/ytvot_extract
    dpkg-deb -x "$DEB_FILE" /tmp/ytvot_extract 2>/dev/null || tar -xf "$DEB_FILE" -C /tmp/ytvot_extract
    EXTRACTED_DYLIB=$(find /tmp/ytvot_extract -name "YTVOT.dylib" | head -n1)
    if [[ -n "$EXTRACTED_DYLIB" && -f "$EXTRACTED_DYLIB" ]]; then
        cp "$EXTRACTED_DYLIB" ./YTVOT.dylib
    fi
    rm -rf /tmp/ytvot_extract
    echo -e "${GREEN}YTVOT.dylib успешно скомпилирован!${RESET}"
else
    echo -e "${GREEN}[1/4] Использование готового YTVOT.dylib${RESET}"
fi

if [[ ! -f "YTVOT.dylib" ]]; then
    echo -e "${RED}Ошибка: YTVOT.dylib не найден в текущей папке!${RESET}"
    echo -e "Запустите с флагом --compile или скачайте готовый dylib из Releases."
    exit 1
fi

# 2. Locate input IPA
echo -e "\n${YELLOW}[2/4] Поиск базового YouTube IPA...${RESET}"
if [[ -z "$INPUT_IPA" ]]; then
    # Scan current folder
    FOUND_IPAS=($(find . -maxdepth 1 -type f -iname "*.ipa" ! -iname "*_VOT.ipa" | sed 's|^\./||'))
    if [[ ${#FOUND_IPAS[@]} -eq 1 ]]; then
        INPUT_IPA="${FOUND_IPAS[0]}"
        echo -e "Автоматически выбран IPA: ${CYAN}$INPUT_IPA${RESET}"
    elif [[ ${#FOUND_IPAS[@]} -gt 1 ]]; then
        echo -e "Найдено несколько IPA файлов. Выберите нужный:"
        select chosen in "${FOUND_IPAS[@]}"; do
            INPUT_IPA="$chosen"
            break
        done
    else
        echo -e "${RED}Ошибка: исходный YouTube IPA файл не найден!${RESET}"
        echo -e "Поместите YouTube IPA в папку проекта или передайте путь аргументом:"
        echo -e "  ${CYAN}./build_macos.sh YouTube.ipa${RESET}"
        exit 1
    fi
fi

if [[ ! -f "$INPUT_IPA" ]]; then
    echo -e "${RED}Файл не существует: $INPUT_IPA${RESET}"
    exit 1
fi

INPUT_BASE=$(basename "$INPUT_IPA" .ipa)
OUTPUT_IPA="${INPUT_BASE}_VOT.ipa"

# 3. Unpack and inject
echo -e "\n${YELLOW}[3/4] Внедрение YTVOT.dylib в $INPUT_IPA...${RESET}"
WORK_DIR=$(mktemp -d /tmp/ytvot_build.XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT

unzip -q "$INPUT_IPA" -d "$WORK_DIR"
APP_DIR=$(find "$WORK_DIR/Payload" -mindepth 1 -maxdepth 1 -type d -name "*.app" | head -n1)

if [[ -z "$APP_DIR" || ! -d "$APP_DIR" ]]; then
    echo -e "${RED}Ошибка: Payload/*.app не найден внутри IPA!${RESET}"
    exit 1
fi

# Get main executable
EXECUTABLE=$(python3 - "$APP_DIR/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], 'rb') as f:
    pl = plistlib.load(f)
    print(pl.get('CFBundleExecutable', 'YouTube'))
PY
)
MAIN_BIN="$APP_DIR/$EXECUTABLE"

if [[ ! -f "$MAIN_BIN" ]]; then
    echo -e "${RED}Бинарный файл не найден: $MAIN_BIN${RESET}"
    exit 1
fi

echo -e "Главный исполняемый файл: ${BOLD}$EXECUTABLE${RESET}"

# Copy dylib into Frameworks
mkdir -p "$APP_DIR/Frameworks"
cp "YTVOT.dylib" "$APP_DIR/Frameworks/YTVOT.dylib"

# Inject LC_LOAD_DYLIB command
echo -e "Инжекция LC_LOAD_DYLIB (@rpath/YTVOT.dylib)..."
python3 "Tools/macho_inject.py" "$MAIN_BIN" --add-load '@rpath/YTVOT.dylib'

# Remove old code signature
rm -rf "$APP_DIR/_CodeSignature"

# Sign with macOS codesign or ldid
echo -e "Подписание компонентов ad-hoc сертификатом..."
if command -v codesign >/dev/null 2>&1; then
    codesign -f -s - "$APP_DIR/Frameworks/YTVOT.dylib" 2>/dev/null || true
    codesign -f -s - "$APP_DIR" 2>/dev/null || true
elif command -v ldid >/dev/null 2>&1; then
    ldid -S "$APP_DIR/Frameworks/YTVOT.dylib" 2>/dev/null || true
    ldid -S "$MAIN_BIN" 2>/dev/null || true
fi

# 4. Repack IPA
echo -e "\n${YELLOW}[4/4] Упаковка финального IPA...${RESET}"
(
    cd "$WORK_DIR"
    zip -qry "$SCRIPT_DIR/$OUTPUT_IPA" Payload
)

IPA_SIZE=$(du -h "$SCRIPT_DIR/$OUTPUT_IPA" | awk '{print $1}')

echo -e "\n${BOLD}${GREEN}================================================================${RESET}"
echo -e "${BOLD}${GREEN}✔ Финальный IPA успешно собран!${RESET}"
echo -e "Файл:    ${BOLD}${CYAN}$SCRIPT_DIR/$OUTPUT_IPA${RESET} ($IPA_SIZE)"
echo -e "${BOLD}${GREEN}================================================================${RESET}"
echo -e "\n${BOLD}Как установить на iPhone / iPad:${RESET}"
echo -e "  1. ${CYAN}TrollStore${RESET}: отправьте IPA через AirDrop и откройте в TrollStore."
echo -e "  2. ${CYAN}Sideloadly / AltStore / ESign${RESET}: перетащите собранный IPA и подпишите своим Apple ID."
echo -e "  3. ${CYAN}Scarlet / MapleSign${RESET}: установите напрямую через профиль подписи.\n"
