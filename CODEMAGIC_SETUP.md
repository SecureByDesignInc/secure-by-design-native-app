# Build Secure By Design for iPhone with Codemagic

This project is ready for a cloud macOS build through Codemagic. The repository
contains two workflows in `codemagic.yaml`:

| Workflow | Purpose | Apple membership needed |
| --- | --- | --- |
| `ios-cloud-check` | Runs analysis and tests, then compiles an unsigned iOS app on a hosted Mac | No |
| `ios-testflight` | Builds a signed IPA and uploads it to App Store Connect for TestFlight | Yes |

The unsigned result verifies that the project compiles on macOS, but it cannot
be installed on an iPhone. Use the TestFlight workflow for installation.

## Information already configured

- App name: **Secure By Design**
- Bundle identifier: `com.securebydesigninc.secureByDesignApp`
- Minimum iOS version: iOS 15
- Codemagic integration name: `secure_by_design_apple`
- Flutter version: 3.47.6

Do not commit Apple API keys, certificates, provisioning profiles, passwords,
or recovery codes to GitHub. The project does not contain any credentials.

## Phase 1 — Put the project in a private GitHub repository

### GitHub website and GitHub Desktop

1. Sign in to GitHub and create a new **private** repository named
   `secure-by-design-native-app`.
2. Do not add a README, `.gitignore`, or license when creating it; those files
   are already in this project.
3. Install and open GitHub Desktop on the Windows laptop.
4. Choose **File → Add local repository**, then select the extracted
   `secure_by_design_app` folder.
5. If GitHub Desktop says the folder is not a repository, choose
   **create a repository here**. Keep the existing files and use `main` as the
   branch.
6. Commit all files with the message `Initial Secure By Design native app`.
7. Choose **Publish repository**, keep **Keep this code private** selected, and
   publish to the repository created above.

The repository root must contain both `pubspec.yaml` and `codemagic.yaml`.

### PowerShell alternative

From the extracted project folder:

```powershell
git init
git add .
git commit -m "Initial Secure By Design native app"
git branch -M main
git remote add origin https://github.com/YOUR-GITHUB-NAME/secure-by-design-native-app.git
git push -u origin main
```

Replace `YOUR-GITHUB-NAME` before running the remote command. GitHub may ask
you to authenticate in a browser.

## Phase 2 — Connect the repository to Codemagic

1. Sign in to [Codemagic](https://codemagic.io/) with GitHub.
2. Authorize access to the private `secure-by-design-native-app` repository.
3. Choose **Add application**, select GitHub, and select the repository.
4. Codemagic should detect `codemagic.yaml` at the repository root.
5. Select the **Secure By Design - iOS Cloud Check** workflow and start it.
6. Confirm that package restore, analysis, tests, and unsigned iOS compilation
   all complete successfully.

This first workflow does not need an Apple account and does not publish an app.

## Phase 3 — Enroll and create the Apple app record

TestFlight requires Apple Developer Program membership.

1. Enroll at [Apple Developer](https://developer.apple.com/programs/enroll/)
   using the Apple Account that will own the app.
2. After Apple activates the membership, open
   [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list).
3. Register a new explicit App ID using
   `com.securebydesigninc.secureByDesignApp`.
4. Open [App Store Connect](https://appstoreconnect.apple.com/), choose
   **My Apps → + → New App**, and use:

   - Platform: iOS
   - Name: Secure By Design
   - Bundle ID: `com.securebydesigninc.secureByDesignApp`
   - SKU: `SBD-NATIVE-001`

If Apple reports that the bundle identifier is unavailable, stop and select a
new identifier before changing the project. The Apple record and project must
use exactly the same identifier.

## Phase 4 — Connect Apple securely to Codemagic

1. In App Store Connect, open **Users and Access → Integrations → App Store
   Connect API**.
2. Generate a key named `Codemagic Secure By Design` with **App Manager**
   access.
3. Record its **Issuer ID** and **Key ID**, then download the `.p8` key. Apple
   allows the private key to be downloaded only once.
4. In Codemagic, open **Team settings → Team integrations → Developer Portal**.
5. Add the key using the exact integration name `secure_by_design_apple`, enter
   the Issuer ID and Key ID, and upload the `.p8` file.
6. In **Team settings → codemagic.yaml settings → Code signing identities →
   iOS certificates**, generate an **Apple Distribution** certificate using
   that integration. Save the generated certificate and password securely,
   then add the certificate to Code signing identities.
7. Create an App Store provisioning profile for
   `com.securebydesigninc.secureByDesignApp` in the Apple Developer portal.
8. In Codemagic's **iOS provisioning profiles** section, fetch or upload that
   App Store profile.

Codemagic matches the distribution certificate and profile by distribution
type and bundle identifier. Their names do not need to be placed in the YAML.

## Phase 5 — Build and install with TestFlight

1. In Codemagic, select **Secure By Design - TestFlight** and start a new build.
2. The workflow runs analysis and tests before producing the signed IPA.
3. After the upload completes, wait for Apple to process the build in
   **App Store Connect → My Apps → Secure By Design → TestFlight**.
4. Complete any export-compliance question Apple displays.
5. Add your Apple Account as an internal tester.
6. Install Apple's TestFlight app on the iPhone, accept the invitation, and
   install Secure By Design.

The workflow uploads the build but does not submit it for public App Store
review or automatically invite external testers.

## What to share when asking for help

Safe to share:

- A screenshot of the Codemagic workflow screen
- The failed step name and ordinary build log around the error
- The Apple or Codemagic status message

Do not share:

- The `.p8` key file or its contents
- Certificate files or passwords
- Apple Account passwords or verification codes
- GitHub personal access tokens

## TestFlight builds start from GitHub (27 October 2026)

Codemagic was not receiving GitHub's push events, so `ios-testflight` stopped building on its own after merges. `.github/workflows/testflight.yml` now starts it through Codemagic's API whenever something merges into `main` (skipping changes to Markdown, workflows and preview images), using the `CM_API_TOKEN` secret. It waits a minute and skips the request if Codemagic already has a build for that commit, so a repaired webhook won't cause double builds. To build by hand, run the "TestFlight build" workflow from the Actions tab.
