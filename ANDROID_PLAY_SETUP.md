# Publish Secure By Design on Google Play

The Android app is built from the same Flutter code as the iPhone app.

| Setting | Value |
| --- | --- |
| App name | Secure By Design |
| Application ID | `com.securebydesigninc.secure_by_design_app` (permanent after the first upload) |
| Target API | Android 16 (API 36), required for new apps from 31 August 2026 |
| Privacy policy | https://securebydesigninc.com/privacy |
| Account deletion | https://securebydesigninc.com/privacy#delete-account (also linked in the app under My Account) |

`codemagic.yaml` has two manual Android workflows:

| Workflow | What it does |
| --- | --- |
| `android-release-bundle` | Analyzes, tests, builds a release `.aab` signed with the upload key, and refuses a debug-signed bundle |
| `android-play-internal` | The same build, then uploads it to the **internal testing** track as a draft |

Never commit keystores, `android/key.properties`, passwords, or the Google service account JSON.

## 1. Create the Google Play developer account (owner)

1. Sign up at https://play.google.com/console/signup with the Google account that will own the app.
2. Choose an **organization** account for Secure By Design. Google asks for the organization's D-U-N-S number
   and verifies the organization and your identity. There is a one-time registration fee.
   (Personal accounts created after 13 November 2023 must also run a closed test with at least 12 testers
   for 14 days before production; that requirement is stated for personal accounts.)
3. In Play Console choose **Create app**: name *Secure By Design*, type *App*, *Free*.

## 2. Create the upload key (owner, once)

Google Play App Signing keeps the key that signs the app for users. You upload builds signed with your
own **upload key**. If the upload key is ever lost or exposed, Play Console can reset it.

On Windows, Android Studio includes `keytool` (for example
`"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"`); any JDK 17 also works.

```
keytool -genkey -v -keystore sbd-upload.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias sbd-upload
```

Use a strong keystore password and store it, with the `.jks` file, in your password manager.
Codemagic cannot give the file back to you.

## 3. Add the upload key to Codemagic (owner)

Team settings → codemagic.yaml settings → **Code signing identities** → **Android keystores**:
upload `sbd-upload.jks`, enter the keystore password, alias `sbd-upload`, the key password, and use the
reference name **`sbd_upload_key`** (the workflows refer to that name).

## 4. Build and upload the first version

1. Start **Secure By Design - Android app bundle** in Codemagic on branch `main`.
2. Download `app-release.aab` from the build's artifacts.
3. In Play Console: **Test and release → Testing → Internal testing → Create new release**, accept
   Play App Signing, upload the `.aab`, and add yourself (and any testers) to the tester list.

## 5. Let Codemagic upload later versions

1. In Google Cloud Console (IAM & Admin → Service accounts) create a service account and a JSON key.
2. In Play Console → **Users and permissions**, invite the service account's email with access to this app
   and the **Releases** permissions.
3. In Codemagic, add an environment variable group named **`google_play`** with a secure variable
   **`GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`** containing the whole JSON key.
4. From then on, start **Secure By Design - Google Play internal testing**; it uploads a draft release to the
   internal track.

## 6. Store listing and policy forms

- **Privacy policy URL:** https://securebydesigninc.com/privacy
- **App access:** provide a test account (email and password) so reviewers can sign in; learning works
  without an account.
- **Ads:** the app contains no ads.
- **Data safety** (reflects the current app and website):
  - Personal info: *email address* — collected when you sign in; used for account management and app
    functionality; not shared; encrypted in transit; deletion can be requested.
  - App activity: *app interactions* (lesson progress, bookmarks, learning activity) — synced to your account
    for app functionality.
  - Optional analytics: *app interactions* and a random *device or other ID* sent to PostHog only if the
    learner turns on Share learning analytics (off by default); used for analytics.
  - Data is encrypted in transit; users can request deletion at the account deletion URL above.
- **Content rating:** complete the questionnaire (educational content; no violence, user-to-user chat,
  or purchases).
- **Target audience:** adults and older teens learning cybersecurity; the app is not directed at children.
- **Graphics:** 512 × 512 app icon, a 1024 × 500 feature graphic, and at least two phone screenshots
  (`previews/` has screens to start from).

## 7. Release

Promote the internal release to production when you are ready and submit it for review. After the listing
is live, set the Google Play `listingUrl` in the website's `content/app-stores.json` and enable the badge.
