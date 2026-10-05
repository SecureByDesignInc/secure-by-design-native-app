# Secure By Design — native app proof of concept

Version 0.7.0 · October 5, 2026

A shared Flutter application for iOS/iPadOS, Android, Windows, macOS, and Linux. Native apps come first. The web app is deferred.

## What works

- Home, Training, Explore, and My Account with the website's navy/cyan design.
- Both published courses, in website order: DC01/DC02 (five chapters) and RMF/Body of Evidence/ATO (12 modules, 36 topics).
- Overview, Lessons, and Materials views; recordings are honestly labeled Video coming soon.
- Bundled course text and knowledge checks, plus the nine original foundation lessons.
- Inside the Network: six offline traffic walkthroughs and 23 system references; the complete website 3D explorer opens in-app on iOS, Android, and macOS.
- Saved materials and native homepage sharing: Learn it. Share it. Pay it forward.
- Optional website-account sign-in and shared progress/bookmarks. Choose Connect progress; Add my device-only progress is a separate, confirmed import.
- Account-specific offline caches, durable pending changes, retry on resume, and untouched guest history on sign-out.
- A skippable first-run welcome: goals, starting level, real lesson recommendations, and a personal note from Jon. The Home checklist follows actual lesson and bookmark progress.
- Returning learners keep their place. Reopen the welcome through the info button → Personalize my learning; the creator note is also available there.
- Device-only onboarding choices, getting-started prompts, optional anonymous analytics, and existing feedback flow.
- Optional haptic feedback on supported iOS and Android devices: selection taps, saved bookmark confirmations, and successful lesson completion. Use the info button → Haptic feedback to turn it off; the preference stays on this device across account changes and app restarts. Background synchronization and unsupported platforms remain silent.

Course text and the network reference work offline. 3D, downloads, external resources, and account synchronization require a connection. Account sessions stay in memory and expire within 12 hours. Lab access remains request-based. This release does not add public store listings or recordings.

## Onboarding design

The welcome adapts the outcome-first presentation, useful personalization, founder note, and continuing checklist described in [Mobbin’s onboarding video](https://www.youtube.com/watch?v=Qsq-Sj_rojU), with [Tiimo’s flow](https://mobbin.com/explore/flows/817f5bfd-1701-4756-bcbc-dcdfc3597723) as a reference. Goals and starting level select existing lessons, with their real durations. Recommendations never claim a guaranteed result or completion date. The note is original Secure By Design copy. Sharing is voluntary; lesson access and optional sign-in keep their existing behavior.

The new profile is stored under `sbd.onboarding.v1`, separate from account progress and analytics. Existing install markers prevent an intrusive first-run replay after upgrading. Finishing or skipping suppresses the old welcome card while retaining the existing learning-tip schedule. Disabling getting-started prompts hides the Home checklist.

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

## Daily learning (0.4.0)

Home and My Account include a local-calendar streak, seven-day calendar, daily XP goal (10/20/40), XP levels, three daily quests, a 30-quest monthly challenge, six achievements, and lesson/review celebrations. Haptics retain the existing default-on preference. Completed lessons can be reviewed through Practice; the correct answer is required before rewards are saved.

- New lessons earn 20 XP; reviews earn 10; correct first attempts add 5. Each lesson earns rewards once per calendar day. Each completed daily quest adds 10 XP once. There are no timers, purchases, or penalties that lock lessons.
- One lesson or review maintains a streak independently of the daily goal. One automatic freeze is earned on the first active day; another every seven active days, capped at two. Freezes preserve a run but add neither streak days nor XP. Historical best streak remains after a reset.
- Immutable local date/lesson keys make rewards idempotent across retries and device imports. Existing undated completions do not become fictional streak history. Dates keep their original local-calendar meaning across time-zone changes. The daily goal is device-local and account-scoped.
- `/api/native-activity` syncs account activity with bounded uploads and paginated history. Guest data only joins an account through the existing explicit import. Delayed responses are discarded after account changes, and failed writes remain pending. Activity is private; there are no fabricated competitors, public leaderboards, or friend invitations. Website reading completions do not retroactively earn app activity rewards.
- Deploy the additive Site migration 0008 and native-activity endpoint before distributing this app. The previous app remains compatible with its unchanged native-progress endpoint.

## Membership plans (0.4.1)

Memberships are available from Info, My Account, and after learning. The first lesson celebration offers an optional link; Continue remains the primary action. Community keeps all current lessons, rewards, downloads, and optional progress sync. Builder ($20/month or $180/year) and Guided ($99/month) are coming-soon previews. Detail selection and the billing-period toggle are local display state only: no checkout, subscription, paid entitlement, or marketing signup exists. The bundled `assets/membership-plans.json` matches the website’s `content/membership-plans.json`; update both together. Haptics keep the saved default-on preference.

## My Account consolidation (0.5.0)

My Account combines account access, learning progress, rewards, and the full membership comparison. Home and first-lesson membership invitations open this tab at the membership section. Continue with Community returns to Training; comparing plans never creates a subscription or changes learning records. Builder and Guided remain coming soon.


## App design refresh (0.7.0)

The native app adapts the reviewed Mobbin references: Brilliant's goal and level
choices, Uxcel Go's grouped cards, MasterClass's expandable curriculum, and the
Speak / Gentler Streak account patterns. No website files, imported course
content, progress IDs, backend endpoints, membership pricing, or entitlements
change in this release.

- Onboarding is three steps: goals, starting level, and a real recommended lesson.
  It stays skippable, retains existing profiles, and keeps the creator note optional.
- Training uses app-only Network Foundations, Certificates & Trust, and Network
  Authorization categories. Tiles expand to reveal course outcomes, durations,
  and directly accessible lessons. Completion and materials stay visible;
  unavailable recordings remain labeled Video coming soon.
- My Account is a compact hub for Community access, genuine learning statistics,
  continuation, saved materials, rewards, learning preferences, account security,
  privacy, feedback, and membership comparison. Detailed controls open from this
  hub. Device-progress import still requires its existing explicit confirmation.
- Existing navy/cyan colors, Geist typeface, offline learning, and platform
  accessibility preferences are preserved. No mandatory signup or new tracking.

References:
- https://mobbin.com/flows/20ad012b-2683-4c0c-beb8-8ff62c6f509e
- https://mobbin.com/screens/dba87d9e-9955-49be-be73-686477e601ee
- https://mobbin.com/screens/72dcf33e-58e8-486f-a178-583a2d411f67
- https://mobbin.com/screens/b1802d44-e332-4130-bbf4-f195931c7bd1
- https://mobbin.com/screens/83aeb4be-08be-4066-8f85-510daf0ecf8a
