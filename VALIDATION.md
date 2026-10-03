# Prototype validation

Checked October 3, 2026 with Flutter 3.47.6 stable / Dart 3.13.5 in a Linux environment.

## Completed shared-app checks

- Dependency resolution with the included `pubspec.lock`.
- Dart static analysis of the application and tests.
- `codemagic.yaml` parsing with separate unsigned cloud-check and signed TestFlight workflows.
- Apple signing files excluded from Git by default; no credentials are included in the project.
- 15 passing automated tests, covering:
  - Opening a learning path and lesson.
  - Incorrect-answer gating, correct-answer completion, and the resulting progress display.
  - Progress and bookmark persistence across loaded sessions.
  - Duplicate completion and serialized concurrent local writes.
  - Completed-path behavior and invalid stored identifiers.
  - Saving a resource, filtering saved resources, removing it, and the empty collection state.
  - All four main tabs at 320, 390, 768, and 1280 logical pixels, with normal and 200% text size.
  - Rendering four screen previews with the bundled brand and fonts.

The reference-link launcher is implemented with Flutter's `url_launcher` package. Opening links through the actual host operating system still needs a device check.

## Platform checks still required

| Check | Status |
| --- | --- |
| iOS compilation | Ready for the included Codemagic cloud-check workflow |
| iOS Simulator build and run | Needs an interactive macOS/Xcode environment |
| iPhone signing and installation | Needs Codemagic or a Mac, Apple Developer credentials, and an iPhone |
| Android APK / emulator / device | Needs Android SDK/toolchain |
| macOS native build | Needs macOS/Xcode |
| Windows native build | Needs Windows/Visual Studio tooling |
| Linux native desktop build | Needs native compiler/development packages |
| Actual device persistence and external-browser launch | Needs device testing |

Native runner projects and launcher assets are included for all five targets. This deliverable is a source prototype with tested shared behavior; it does not contain an IPA, APK, or signed desktop installer.

The Codemagic cloud-check workflow can validate iOS compilation without signing. The TestFlight workflow additionally requires an active Apple Developer Program membership, a matching App Store Connect record, and signing identities configured in Codemagic.

No web application was built or published. No cloud backend, user account service, payment service, or live cybersecurity tool connection is configured.
