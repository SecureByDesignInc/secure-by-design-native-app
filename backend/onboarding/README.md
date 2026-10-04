# App getting-started email sequence

Status: implemented server module and branded templates, locally tested, **not deployed or active**. The current Flutter app has no account sign-in. No recipients have been enrolled and no messages sent. Resend dashboard access is awaiting sign-in. This directory is an integration package, not a running email service.

## Behavior

- After a verified account signs in, offer the separate, unchecked consent in `sequence.mjs`. Account creation, app use, and optional PostHog analytics must work without subscribing.
- A confirmed opt-in starts one sequence: welcome immediately, a resources tip after 3 days, feedback request after 7 days. The second delay is 4 days.
- Each email has a Resend-hosted unsubscribe link. Every send step checks the contact's current `unsubscribed` value; an unsubscribed or unknown value takes a terminal branch. Do not reset provider subscription preferences when a reader signs in again.
- The primary key prevents a repeated login, reinstall, or another device from restarting the sequence. Only the server-authenticated account can determine the recipient. No existing newsletter audience is imported.
- Resend owns the delayed execution, so the app can be closed. PostHog is not an identity source and receives no emails or enrollment records.
- Ambiguous network responses are retained as `review_required` (or `dispatching` after a process crash). Reconcile the provider event/run logs before any manual retry. The event endpoint has no documented idempotency guarantee, so automatically retrying could duplicate the entire sequence. An accepted event means queued, not inbox delivery.

## Integration with the existing account backend

The website's `server/reader-auth.js` already verifies email and password and exposes `getReader(request, env)`. It stores a cookie session, not a native bearer token. Preserve its Origin checks and HttpOnly cookie handling. Do not let a native caller simply supply an account ID or an email as authentication.

1. Add the table from `schema.sql` through a new generated Drizzle migration in that backend, preserving existing migrations.
2. Mount the enrollment handler at `/api/app-onboarding-email`, passing D1 as `db`, `resendEventSender(env.RESEND_API_KEY)` as `sendEvent`, and a trusted account-session adapter as `authenticate`. For the existing web account service, the adapter calls `getReader`, rejects `needsPassword`, and only then returns `{id, email, emailVerified:true}`. Verified account creation in that service is what establishes this flag. Never read it from request JSON.
3. Leave `enabled` false until the Resend automation is published and its actual account limits and permissions are confirmed. Existing API credentials may be send-only and may not authorize `/events/send`.
4. Finish native sign-in/session integration using the same reader accounts. The current module is a **same-origin browser-cookie adapter**. It must not be used as a native bearer-token route without a separately verified native session design. Add the consent control after sign-in; submit only `{consent:true,consentVersion:'app-onboarding-v1'}`. Persist server responses, show pending/review errors honestly, and keep offline learning available. Do not expose a nonfunctional sign-in button in TestFlight.
5. Import/publish the three templates and create the disabled automation generated below. Use the verified notification sender already configured for the website and `support@securebydesigninc.com` for replies. Add the approved business mailing address to each footer before production activation. Do not copy a private billing address from chat receipts.
6. Verify Resend entitlement, template aliases, event definition `sbd.app.onboarding.v1`, live contact condition behavior, unsubscribe behavior, hard-bounce/complaint suppression, and sender status in the actual account. No new paid subscription is approved. The contact email is automatically created by Resend when an event starts a run; existing subscription preferences must be preserved.
7. Activate only after a recipient-authorized end-to-end test: opt in once; sign in again; verify one run; unsubscribe before the next send; confirm the remaining sends are skipped. Use an isolated shorter-delay test automation, not edits to a running production sequence. Test account/session ownership, sign-out, revoked sessions, and email verification in the native integration as well.

For a later in-app opt-out UI, update the provider subscription first and verify it; do not merely flip a device-local setting while the provider still holds an active run. Provider unsubscribe is global to its marketing contact; explain that scope in the email preference UI.

## Local verification and review

Requires Node 22.13+ (tested on Node 24). No npm packages or API key needed:

```sh
node --test backend/onboarding/onboarding.test.mjs
node backend/onboarding/export.mjs
```

`generated/` contains the three HTML emails and a disabled automation request. These can be reviewed without sending mail. Templates use the native app's navy/cyan palette and a soft header gradient with solid-color fallback.

## Provider references (checked October 4, 2026)

- https://resend.com/docs/api-reference/events/send-event
- https://resend.com/docs/dashboard/automations/trigger
- https://resend.com/docs/dashboard/automations/condition
- https://resend.com/docs/dashboard/automations/send-email
- https://resend.com/docs/api-reference/automations/create-automation

Do not merge or report this as released until the account integration, provider activation, and end-to-end verification above are complete.
