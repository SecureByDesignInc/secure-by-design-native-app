# Secure By Design — native app proof of concept

Version 0.2.0 · October 5, 2026

A shared Flutter application for iOS/iPadOS, Android, Windows, macOS, and Linux. Native apps come first. The web app is deferred.

## What works

- Home, Training, Explore, and My Progress with the website's navy/cyan design.
- Both published courses, in website order: DC01/DC02 (five chapters) and RMF/Body of Evidence/ATO (12 modules, 36 topics).
- Overview, Lessons, and Materials views; recordings are honestly labeled Video coming soon.
- Bundled course text and knowledge checks, plus the nine original foundation lessons.
- Inside the Network: six offline traffic walkthroughs and 23 system references; the complete website 3D explorer opens in-app on iOS, Android, and macOS.
- Saved materials and native homepage sharing: Learn it. Share it. Pay it forward.
- Optional website-account sign-in and shared progress/bookmarks. Choose Connect progress; Add my device-only progress is a separate, confirmed import.
- Account-specific offline caches, durable pending changes, retry on resume, and untouched guest history on sign-out.
- Getting-started prompts, optional anonymous analytics, and existing feedback flow.

Course text and the network reference work offline. 3D, downloads, external resources, and account synchronization require a connection. Account sessions stay in memory and expire within 12 hours. Lab access remains request-based. This release does not add public store listings or recordings.

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

## Course content updates

Import from the current Site checkout, then format and validate:

```bash
node tool/import_site_training.mjs /path/to/site
dart format lib/data/published_catalog.dart
flutter analyze
flutter test
```

The importer also writes the Site's course progress and material catalogs so both clients keep identical IDs. Preserve those IDs on content edits.

## Release workflow

Codemagic checks pull requests targeting main and builds the signed TestFlight IPA when main changes, provided the existing repository webhook is enabled. The Apple integration and bundle identifier remain unchanged. No public App Store review or external tester invitation is configured. Platform compilation and physical-device checks are separate from the Flutter widget tests.

## Official setup references

- [Flutter installation](https://docs.flutter.dev/install/manual)
- [Flutter iOS setup](https://docs.flutter.dev/platform-integration/ios/setup)
- [Apple Developer account and Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account)
- [Flutter Android setup](https://docs.flutter.dev/platform-integration/android/setup)
- [Flutter desktop setup](https://docs.flutter.dev/platform-integration/desktop)

Original sample explanations link to [Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview), [NIST](https://csrc.nist.gov/projects/risk-management/about-rmf), and [Splunk](https://help.splunk.com/en/splunk-enterprise/get-started/overview/9.1/about-splunk-enterprise/about-splunk-enterprise) within the app.
