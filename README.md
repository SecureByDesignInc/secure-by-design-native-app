# Secure By Design — native app proof of concept

Version 0.1.0 · October 3, 2026

A shared Flutter application for iOS/iPadOS, Android, Windows, macOS, and Linux. Native apps come first. The web app is deferred.

## What works

- Home screen with a starting or continuing learning path.
- Three sample paths: Active Directory, security monitoring, and RMF.
- Nine short lessons with a knowledge check before completion.
- Resource collection with external links and saved-resource filtering.
- Progress and bookmarks stored on the device, including after the app restarts.
- Bottom navigation on phones/tablets and side navigation on larger windows.
- Website-derived colors, Geist typography, the supplied logo, and native launcher icons.

The lessons are bundled with the app and work offline. External links require internet access. This version has no account creation, cloud sync, payments, live lab connection, or embedded video playback.

## Start here

For an iPhone, use **CODEMAGIC_SETUP.md** to build through a hosted Mac from a Windows laptop, or **IPHONE_SETUP.md** to build on a physical Mac. The project archive is source code rather than an installable IPA or App Store release.

Install Flutter **3.47.6 stable** (the version used to validate this project), or a compatible later stable release. The bundled dependency lockfile preserves the tested package versions.

From this project folder:

```bash
flutter pub get
flutter doctor
flutter devices
flutter run -d <device-id>
```

Replace `<device-id>` with a real identifier from `flutter devices`.

## Native targets

| Target | Development machine | Next check |
| --- | --- | --- |
| iOS / iPadOS | macOS with Xcode | Simulator, Personal Team signing, real iPhone/iPad |
| Android | macOS, Windows, or Linux with Android tooling | Emulator, then real device |
| macOS | macOS with Xcode | `flutter run -d macos` |
| Windows | Windows with Visual Studio's Desktop development with C++ tools | `flutter run -d windows` |
| Linux | Linux with Flutter's documented native build dependencies | `flutter run -d linux` |

The generated iOS project uses iOS 15 as its minimum deployment target; the macOS project uses macOS 12. The desktop and mobile runner projects are included. Each native build still needs validation on its corresponding toolchain/device. No web runner or web deployment is included.

## Validation

See **VALIDATION.md** for the checked behavior and the remaining platform checks. To repeat the shared-code checks:

```bash
flutter analyze
flutter test
```

The preview images in `previews/` are rendered by Flutter's test engine at phone dimensions. They show actual app widgets; they are not captures from an iOS Simulator or physical phone.

## Design reference

Read from [securebydesigninc.com](https://securebydesigninc.com) on October 3, 2026:

| Token | Value |
| --- | --- |
| Background | `#050B14` |
| Card surface | `#102237` |
| Main text | `#F3F7FF` |
| Secondary text | `#AEBDD0` |
| Cyan accent | `#83DCFA` |
| Blue accent | `#378EFA` |
| Border | `#2B3D53` |
| Typeface | Geist |

The logo mark is the existing website asset's displayed viewport. It is reused for the header and launcher icons. Geist is distributed under the included SIL Open Font License in `assets/fonts/OFL.txt`.

## Project map

| File or folder | Purpose |
| --- | --- |
| `lib/main.dart` / `lib/bootstrap.dart` | Startup, local-state loading, retry state |
| `lib/app.dart` | Application shell and adaptive navigation |
| `lib/theme.dart` | Shared design tokens and component styles |
| `lib/data/catalog.dart` | Sample lessons, questions, and reference links |
| `lib/data/learning_store.dart` | Serialized local progress and bookmark writes |
| `lib/screens/` | Home, learning paths, lessons, resources, and progress |
| `lib/widgets/` | Shared interface components |
| `test/` | Learning flow, persistence, and layout validation |
| `tool/generate_brand_icons.py` | Reproduce the native launcher assets with Python/Pillow |
| `codemagic.yaml` | Hosted macOS validation and signed TestFlight workflows |
| `CODEMAGIC_SETUP.md` | Windows-to-Codemagic setup and signing walkthrough |

## Where to go next

1. Run the app on Jon's iPhone and an Android test device.
2. Review the screen layout and agree on the next learning flow.
3. Add account and shared-backend requirements once the fundamentals are settled.
4. Expand real lessons and lab connections; add the web application in a later phase.

## Official setup references

- [Flutter installation](https://docs.flutter.dev/install/manual)
- [Flutter iOS setup](https://docs.flutter.dev/platform-integration/ios/setup)
- [Apple Developer account and Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account)
- [Flutter Android setup](https://docs.flutter.dev/platform-integration/android/setup)
- [Flutter desktop setup](https://docs.flutter.dev/platform-integration/desktop)

Original sample explanations link to [Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview), [NIST](https://csrc.nist.gov/projects/risk-management/about-rmf), and [Splunk](https://help.splunk.com/en/splunk-enterprise/get-started/overview/9.1/about-splunk-enterprise/about-splunk-enterprise) within the app.
