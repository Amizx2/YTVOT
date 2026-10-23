# YTVOT — Автономный мод голосового перевода для YouTube на iOS

[🇬🇧 **Read in English (README.md)**](README.md) | [📦 **Скачать готовый IPA (v1.0.0)**](https://github.com/Amizx2/YTVOT/releases/download/v1.0.0/YouTube_VOT_1.0.0.ipa) | [🧩 **Скачать YTVOT.dylib**](https://github.com/Amizx2/YTVOT/releases/download/v1.0.0/YTVOT.dylib)

**YTVOT** — это независимый, автономный iOS-твик, добавляющий синхронный нейросетевой голосовой перевод видео в официальное приложение YouTube на iPhone и iPad.

Проект основан на наработках [voice-over-translation](https://github.com/ilyhalight/voice-over-translation) и [vot.js](https://github.com/FOSWLY/vot.js), но полностью переписан на чистый Objective-C++ / UIKit и отделен от любых сторонних твиков.

Мод собирается в виде отдельной динамической библиотеки `YTVOT.dylib` и rootless `.deb` пакета. Его можно внедрить в **любой** YouTube: чистый оригинальный клиент, YTKACE, YTLite, uYouEnhanced и др.

---

## Возможности

- **Универсальная совместимость**: работает со стоковым YouTube и любыми сборками (YTKACE, YTLite, uYouEnhanced).
- **Синхронизация звука через Phase-Locked Loop (PLL)**: устраняет рассинхрон аудиодорожки. Микро-коррекции скорости ($\pm 12\%$) плавно удерживают речь синхронно с видеорядом:

$$
\Delta t = t_{\text{video}} - t_{\text{audio}}, \quad \text{rate} = \text{rate}_{\text{video}} \times (1.0 + \text{clamp}(\Delta t \times 0.2, -0.12, +0.12))
$$

- **Умное адаптивное приглушение (Smart Adaptive Ducking)**: фоновый сканер аудиофайла (`AVAssetReader`) определяет точные границы речи. Звук оригинального видео приглушается **только когда говорит переводчик**, и плавно нарастает в паузах.
- **Выбор голоса**: мужской, женский или автоматический.
- **Языки перевода**: русский (RU), английский (EN), казахский (KK).
- **Кнопка на плеере**:
  - **Одиночный тап**: включение и отключение перевода.
  - **Долгое нажатие (long-press)**: открытие окна настроек YTVOT.
- **Интеграция в меню видео**: пункт быстрого перевода прямо в стандартном меню действий плеера.
- **Интеграция в настройки YouTube**: раздел YTVOT в главном меню настроек приложения.
- **Авторизация в Яндекс**: встроенный вход через OAuth (WKWebView) для длинных видео.

---

## 🛠️ Сборка и упаковка IPA на macOS

В репозитории есть готовый скрипт [`build_macos.sh`](build_macos.sh) для автоматической сборки `YouTube_VOT.ipa` в 1 команду на Mac.

### Требования на Mac
- macOS 12+ (Intel или Apple Silicon M1/M2/M3/M4)
- Установленные утилиты командной строки Xcode (`xcode-select --install`)
- Python 3

### Пошаговая инструкция

1. **Клонируйте репозиторий:**
```bash
git clone https://github.com/Amizx2/YTVOT.git
cd YTVOT
```

2. **Поместите чистый файл `YouTube.ipa`** в папку `YTVOT` (либо укажите путь к нему аргументом).

3. **Сделайте скрипт исполняемым и запустите:**
```bash
chmod +x build_macos.sh
./build_macos.sh YouTube.ipa
```

Скрипт выполнит всю работу автоматически:
- Возьмет готовый `YTVOT.dylib` (или скомпилирует его из исходников, если его нет).
- Распакует `YouTube.ipa`.
- Скопирует `YTVOT.dylib` в папку `Payload/YouTube.app/Frameworks/`.
- Пропишет команду загрузки `@rpath/YTVOT.dylib` в заголовок Mach-O бинарника через автономный скрипт [`Tools/macho_inject.py`](Tools/macho_inject.py).
- Подпишет компоненты ad-hoc сертификатом macOS (`codesign -f -s -`).
- Упакует всё в готовый файл `YouTube_VOT.ipa`.

### Режимы работы скрипта

| Команда | Описание |
| :--- | :--- |
| `./build_macos.sh YouTube.ipa` | **Быстрая перепаковка**: внедряет уже скомпилированный `YTVOT.dylib` в IPA (~3 секунды). |
| `./build_macos.sh --compile YouTube.ipa` | **Полная сборка**: перекомпилирует `YTVOT.dylib` из исходников через Theos, затем собирает `YouTube_VOT.ipa`. |
| `./build_macos.sh --compile` | Компилирует только `YTVOT.dylib` и `.deb` пакет без перепаковки IPA. |

---

## 💻 Сборка из исходников

### 1. На macOS (Theos)
```bash
# Установка Theos (если еще не установлен)
export THEOS=~/theos
[ -d "$THEOS" ] || git clone --recursive https://github.com/roothide/theos.git "$THEOS"

# Компиляция пакета
make clean
make -j$(sysctl -n hw.ncpu) package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```
Скомпилированная библиотека появится в `.theos/obj/YTVOT.dylib`, а deb-пакет — в `packages/com.amizx2.ytvot_1.0.0_iphoneos-arm64.deb`.

### 2. На Linux / Kali (в 1 клик)
```bash
chmod +x build_kali.sh
./build_kali.sh
```
Скрипт автоматически установит зависимости, настроит RootHide Theos, загрузит iOS SDK, скомпилирует `.deb` и извлечет `YTVOT.dylib`.

---

## 📱 Способы установки

### Вариант 1: Готовый IPA (без Mac и ПК)
Скачайте готовый IPA из [Релизов проекта](https://github.com/Amizx2/YTVOT/releases/tag/v1.0.0):
- **[YouTube_VOT_1.0.0.ipa](https://github.com/Amizx2/YTVOT/releases/download/v1.0.0/YouTube_VOT_1.0.0.ipa)**
- Установите через **TrollStore**, **Sideloadly**, **AltStore** или **ESign**.

### Вариант 2: Через Sideloadly / ESign (инжекция dylib)
1. Скачайте чистый `YouTube.ipa` и [YTVOT.dylib](https://github.com/Amizx2/YTVOT/releases/download/v1.0.0/YTVOT.dylib).
2. В Sideloadly откройте **Advanced Options** ➔ **Inject Dylibs/Frameworks** ➔ выберите `YTVOT.dylib`.
3. Подпишите и установите приложение на устройство.

### Вариант 3: TrollStore / Джейлбрейк (.deb)
1. Скачайте [com.amizx2.ytvot_1.0.0_iphoneos-arm64.deb](https://github.com/Amizx2/YTVOT/releases/download/v1.0.0/com.amizx2.ytvot_1.0.0_iphoneos-arm64.deb).
2. Установите через TrollStore, Sileo или Zebra.

### Вариант 4: Через утилиту Azule CLI (macOS / Linux)
```bash
azule -i YouTube.ipa -o YouTube_VOT.ipa -f YTVOT.dylib
```

---

## Лицензия

Распространяется под лицензией GNU General Public License v3.0 (GPLv3).
