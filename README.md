# YTVOT — Standalone Voice-Over Translation for YouTube iOS

[🇷🇺 **Читать на русском (README_RU.md)**](README_RU.md) | [📦 **Download Ready IPA (v1.0.0)**](https://github.com/Amizx2/YTVOT/releases/download/v1.0.0/YouTube_VOT_1.0.0.ipa) | [🧩 **Download YTVOT.dylib**](https://github.com/Amizx2/YTVOT/releases/download/v1.0.0/YTVOT.dylib)

**YTVOT** is an independent, standalone iOS tweak that adds real-time AI Voice-Over Translation to the official YouTube app on iOS.

Ported and enhanced from [voice-over-translation](https://github.com/ilyhalight/voice-over-translation) and [vot.js](https://github.com/FOSWLY/vot.js), **YTVOT** is completely decoupled from any other tweak. It compiles as a standalone `.dylib` and rootless `.deb`, allowing it to be injected into **any** YouTube IPA (stock YouTube, YTKACE, YTLite, uYouEnhanced, etc.).

---

## 📸 Screenshots

<p align="center">
  <img src="screenshots/player.png" width="31%" alt="Player Overlay Button" />
  &nbsp;
  <img src="screenshots/menu.png" width="31%" alt="Action Sheet Menu Item" />
  &nbsp;
  <img src="screenshots/settings.png" width="31%" alt="YTVOT Settings" />
</p>

---

## Features

- **Universal Compatibility**: Works with stock YouTube and modded YouTube clients alike (YTKACE, YTLite, uYouEnhanced).
- **Phase-Locked Loop (PLL) Audio Sync**: Eliminates audio drift. Micro-rate adjustments keep translated speech tightly locked to video playback:

$$
\Delta t = t_{\text{video}} - t_{\text{audio}}, \quad \text{rate} = \text{rate}_{\text{video}} \times (1.0 + \text{clamp}(\Delta t \times 0.2, -0.12, +0.12))
$$

- **Smart Adaptive Ducking**: Uses offline audio speech scanning (`AVAssetReader`) to detect speech boundaries. The original video volume ducks **only** while translation is speaking, smoothly returning to normal during pauses.
- **Voice Selection**: Choose between Automatic, Female, or Male voice.
- **Multi-Language Support**: Translate videos into Russian (RU), English (EN), or Kazakh (KK).
- **Native Floating Player Controls**: Compact translation button overlaid directly on player controls.
  - **Single tap**: Toggle translation on/off.
  - **Long press**: Open the YTVOT Settings panel.
- **Action Sheet Menu Item**: Adds a direct translation toggle to YouTube's native action sheet menu.
- **YouTube Settings Integration**: Access YTVOT settings directly from YouTube's main settings page.
- **Yandex Account Authorization**: Built-in OAuth login (via WKWebView) for authenticated translation sessions.

---

## 🛠️ Building & Packaging IPA (macOS & Linux)

Automated scripts are provided for both **macOS** and **Linux / Kali** to package a ready-to-install `YouTube_VOT.ipa` in one click.

### 🍎 Option A: On macOS (`build_macos.sh`)

1. **Clone the repository:**
```bash
git clone https://github.com/Amizx2/YTVOT.git
cd YTVOT
```

2. **Place a clean `YouTube.ipa`** into the project directory (or provide the full path as an argument).

3. **Run the build script:**
```bash
chmod +x build_macos.sh
./build_macos.sh YouTube.ipa
```

- **Fast Repack (default)**: Injects prebuilt `YTVOT.dylib` into IPA in ~3 seconds.
- **Full Recompile + Repack**: `./build_macos.sh --compile YouTube.ipa` (recompiles `YTVOT.dylib` from source code via Theos before packaging).

---

### 🐧 Option B: On Linux / Kali / Ubuntu (`build_kali.sh`)

1. **Clone the repository:**
```bash
git clone https://github.com/Amizx2/YTVOT.git
cd YTVOT
```

2. **Place a clean `YouTube.ipa`** into the project directory (or provide the full path as an argument).

3. **Run the build script:**
```bash
chmod +x build_kali.sh
./build_kali.sh YouTube.ipa
```

The script automatically sets up dependencies, compiles the tweak via Theos, unpacks `YouTube.ipa`, injects `YTVOT.dylib` via [`Tools/macho_inject.py`](Tools/macho_inject.py), signs with `ldid`, and outputs `YouTube_VOT.ipa`.

---

## 💻 Building from Source (Compiling Tweak Only)

If you only want to compile the `.dylib` and `.deb` packages without packaging an IPA:

### 1. On macOS (Theos)
```bash
export THEOS=~/theos
[ -d "$THEOS" ] || git clone --recursive https://github.com/roothide/theos.git "$THEOS"

make clean
make -j$(sysctl -n hw.ncpu) package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```
Artifacts: `.theos/obj/YTVOT.dylib` and `packages/com.amizx2.ytvot_1.0.0_iphoneos-arm64.deb`.

### 2. On Linux / Kali / Ubuntu
```bash
chmod +x build_kali.sh
./build_kali.sh
```
*(Running without specifying an IPA compiles the `.deb` package and extracts `YTVOT.dylib` to the current folder).*

---

## 📱 Installation Methods

### Method 1: Sideloadly / ESign (Dylib Injection)
1. Download `YouTube.ipa` and [YTVOT.dylib](https://github.com/Amizx2/YTVOT/releases/download/v1.0.0/YTVOT.dylib).
2. Open Sideloadly ➔ Advanced Options ➔ **Inject Dylibs/Frameworks** ➔ Add `YTVOT.dylib`.
3. Sign and install to your device.

### Method 2: Jailbroken / TrollStore (.deb)
1. Download [com.amizx2.ytvot_1.0.0_iphoneos-arm64.deb](https://github.com/Amizx2/YTVOT/releases/download/v1.0.0/com.amizx2.ytvot_1.0.0_iphoneos-arm64.deb).
2. Install via TrollStore, Sileo, or Zebra.

### Method 3: Azule CLI (macOS / Linux)
```bash
azule -i YouTube.ipa -o YouTube_VOT.ipa -f YTVOT.dylib
```

---

## Architecture Overview

```
Source/
├── YTVOTDefines.h                 # Constants, enums, bundle IDs
├── YTVOTLog.h / .m                # Unified logging system
├── YTVOTHooking.h / .m            # Silent runtime swizzling engine (zero dependencies)
├── YTVOTPreferences.h / .m        # Persistent user settings
├── YTVOTLocalization.h / .m       # English / Russian localization
├── YTVOTNotice.h / .m             # Native floating HUD toast banners
├── YTVOTClient.h / .mm            # Protobuf & HMAC-SHA256 Yandex client
├── YTVOTAudioPlayer.h / .mm       # AVPlayer with PLL sync & speech scanner
├── YTVOTCoordinator.h / .mm       # State machine and lifecycle manager
├── YTVOTOverlayButton.h / .m      # Player controls overlay button
├── YTVOTSettingsViewController.h  # Standalone settings modal UI
├── YTVOTYandexAuthViewController  # WKWebView OAuth authorization
├── YTVOTHooks.h / .mm             # Safe YouTube hooks
└── Tweak.x                        # Constructor entrypoint
```

---

## Credits & Acknowledgements

- **Amizx2** — iOS port, PLL sync engine, speech scanner, UI integration, standalone architecture.
- [ilyhalight/voice-over-translation](https://github.com/ilyhalight/voice-over-translation) & [vot.js](https://github.com/FOSWLY/vot.js) — Protocol reverse engineering and API specifications.
- [itzzace/ytkace](https://github.com/itzzace/ytkace) — Inspiration for YouTube hook patterns.

---

## License

This project is licensed under the GNU General Public License v3.0 (GPLv3).
