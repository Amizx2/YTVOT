# YTVOT — Standalone Voice-Over Translation for YouTube iOS

**YTVOT** is an independent, standalone iOS tweak that adds real-time AI Voice-Over Translation to the official YouTube app on iOS.

Ported and enhanced from [voice-over-translation](https://github.com/ilyhalight/voice-over-translation) and [vot.js](https://github.com/FOSWLY/vot.js), **YTVOT** is completely decoupled from any other tweak. It compiles as a standalone `.dylib` and rootless `.deb`, allowing it to be injected into **any** YouTube IPA (stock YouTube, YTKACE, YTLite, uYouEnhanced, etc.).

---

## Features

- **Universal Compatibility**: Works with stock YouTube and modded YouTube clients alike (YTKACE, YTLite, uYouEnhanced).
- **Phase-Locked Loop (PLL) Audio Sync**: Eliminates audio drift. Micro-rate adjustments keep translated speech tightly locked to video playback.
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

## Installation

### Method 1: Sideloading via Sideloadly or ESign (Non-Jailbroken)
1. Download a YouTube `.ipa` file.
2. In Sideloadly or ESign, choose **Inject Dylib** / **Add Framework**.
3. Select `YTVOT.dylib`.
4. Sign and install the IPA to your iPhone or iPad.

### Method 2: Jailbroken / TrollStore (.deb)
1. Install `com.amizx2.ytvot_1.0.0_iphoneos-arm64.deb` using TrollStore, Sileo, or Zebra.
2. Respring or restart YouTube.

### Method 3: Azule CLI
```bash
azule -i YouTube.ipa -o YouTube_VOT.ipa -f YTVOT.dylib
```

---

## Building from Source

### Requirements
- RootHide Theos (or standard Theos with rootless support)
- iOS 15.0+ SDK (e.g. `iPhoneOS16.5.sdk`)
- Clang / Make / ldid

### One-Click Build on Linux / Kali
```bash
chmod +x build_kali.sh
./build_kali.sh
```

The script automatically sets up Theos, installs dependencies, compiles `packages/com.amizx2.ytvot_1.0.0_iphoneos-arm64.deb`, and extracts `YTVOT.dylib`.

---

## Architecture Overview

```
Source/
├── YTVOTDefines.h                 # Constants, enums, bundle IDs
├── YTVOTLog.h / .m                # Unified logging system
├── YTVOTHooking.h / .m            # Silent runtime swizzling engine
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
