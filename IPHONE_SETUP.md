# Test Secure By Design on your iPhone

This project contains the app source and native runner projects. An iPhone build must run on macOS, but you can use either a physical Mac or Codemagic's hosted Mac build environment. From a Windows laptop, follow **CODEMAGIC_SETUP.md**. The instructions below are for a physical Mac and a free Apple Account's Personal Team.

## 1. Prepare the Mac

1. Install Xcode and open it once to finish its setup and review Apple's license terms.
2. Install Flutter using the [official setup guide](https://docs.flutter.dev/install/manual). This project was checked with Flutter 3.47.6 stable.
3. Follow [Flutter's iOS setup guide](https://docs.flutter.dev/platform-integration/ios/setup) for the Xcode tools, iOS platform support, and native plugin prerequisites.
4. Download and unzip `Secure_By_Design_Native_App.zip` on the Mac.

The easiest starting point is to double-click `START_HERE_MAC.command` inside the extracted project. If macOS blocks it the first time, Control-click the file, choose **Open**, and confirm. The starter checks for Flutter and Xcode, restores the app packages, runs `flutter doctor`, and opens the correct iOS workspace. It does not request or store your Apple credentials.

You can also perform the same steps manually:

Open Terminal in the extracted `secure_by_design_app` folder and run:

```bash
flutter pub get
flutter doctor
```

Resolve the iOS/Xcode items shown by `flutter doctor`. You do not need to resolve Android or Windows tooling to test on your iPhone.

## 2. Try an iPhone simulator first

Open an iPhone simulator from Xcode's device tools. With Xcode 26 or earlier, the application is named Simulator; with Xcode 27, it is Device Hub.

Then run:

```bash
flutter devices
flutter run -d <simulator-device-id>
```

Replace `<simulator-device-id>` with the simulator identifier displayed by `flutter devices`. No Apple account signing is needed for a simulator.

## 3. Connect your real iPhone

1. Connect your iPhone to the Mac by USB, unlock it, and trust the computer when prompted.
2. Open Xcode and sign in to your Apple Account under **Xcode → Settings → Accounts**.
3. Enable **Settings → Privacy & Security → Developer Mode** on the iPhone, then follow the restart prompts. If the setting is missing, let Xcode configure the connected device first.
4. From the project folder, open the workspace:

```bash
open ios/Runner.xcworkspace
```

5. In Xcode, select the **Runner** project, then its **Runner** target, and open **Signing & Capabilities**.
6. Enable **Automatically manage signing** and choose your **Personal Team**.
7. Keep the generated bundle identifier if Xcode accepts it. If it is unavailable, choose a unique identifier such as `com.securebydesigninc.jon.learningpreview` in the Runner target. This is a test-app identifier.
8. Select your connected iPhone as the run destination and press Xcode's Run button. Alternatively, after signing is configured, use:

```bash
flutter devices
flutter run -d <iphone-device-id>
```

9. If iOS asks you to trust the developer app, follow the on-device prompt under **Settings → General → VPN & Device Management**.

Keep Apple credentials and macOS signing prompts on your own Mac. No account credentials are included in the project.

Apple's free Personal Team provisioning expires after seven days, so you may need to rebuild and reinstall the app periodically. Paid membership is needed later for TestFlight/App Store distribution; it is not required for this personal-device test.

## 4. Walk through the prototype

1. On **Home**, tap **Start learning**.
2. Open the first Active Directory lesson.
3. Try a wrong answer, then choose the correct answer and tap **Complete lesson**.
4. Return to **Progress** and confirm that one lesson is recorded.
5. Open **Resources**, bookmark a guide, and switch to **Saved**.
6. Close and reopen the app. Check that your progress and saved resource are still present.
7. Try larger text and rotate the device. Check an iPad if one is available.

Lessons are bundled for offline reading. External references need internet access. Accounts and synchronization between devices are future work.

## Official references

- [Flutter iOS development setup](https://docs.flutter.dev/platform-integration/ios/setup)
- [Apple Developer account overview and Personal Team limitations](https://developer.apple.com/help/account/basics/about-your-developer-account)
- [Apple membership comparison](https://developer.apple.com/support/compare-memberships/)
