# Pitfalls And Fixes

Purpose: record known problems and proven fixes so future agent windows can resolve repeat issues quickly.

## How To Update

- Add the symptom, root cause, fix, and verification command.
- Keep newest entries at the top.
- Include exact error text when useful.
- Do not add speculation; only record confirmed issues.

## Emergency Email Sent Without Matching Morning Push

Symptom:

- After a user checked in again, a later missed-check-in cycle could produce an emergency email without the expected morning push.

Root cause:

- Morning push used this condition:

```text
today not checked, yesterday not checked, two days ago checked
```

- Emergency email used a different condition:

```text
today not checked, yesterday not checked, two days ago not checked, lastNotifiedAt is null
```

- Because check-in resets `lastNotifiedAt`, a stale long-missed state could become email-eligible without being on the same day as the morning push.

Fix:

- Use the same missed-day policy for morning push and emergency email.
- Emergency email adds only one extra guard: `alreadyNotified == false`.
- Shared policy file: `functions/src/checkin_policy.ts`.

Verification:

```bash
cd functions && npm test
flutter test
flutter analyze
```

## GitHub Push Fails Over HTTPS

Symptom:

```text
fatal: could not read Username for 'https://github.com': Device not configured
```

Root cause:

- The repo remote used HTTPS, but this machine did not have usable HTTPS GitHub credentials for non-interactive push.

Fix:

```bash
ssh -T git@github.com
git remote set-url origin git@github.com:chenyl25123-blip/kyogen-app.git
git push -u origin <branch-name>
```

Verification:

```bash
git ls-remote --heads origin <branch-name>
```

Confirmed result:

```text
Hi chenyl25123-blip! You've successfully authenticated, but GitHub does not provide shell access.
```

## Emergency Contact Email Rejected

Symptom:

- Binding an emergency contact email failed with an invalid email format error, even for common emails such as `user@gmail.com`.

Root cause:

- The old email regex in the contact screen required an extra dot segment after the domain and rejected normal addresses.

Fix:

- Use `isValidEmailAddress()` from `lib/utils/email_validator.dart`.
- Validator pattern:

```dart
r'^[^\s@]+@[^\s@]+\.[^\s@]+$'
```

Verification:

```bash
flutter test test/email_validator_test.dart
```

## Firebase Phone Login Error Visibility

Symptom:

- Phone login or linking failures are hard to diagnose if UI only shows a generic failure message.

Fix:

- Phone number parsing throws `PhoneNumberFormatException` with stable codes:
  - `phone/empty`
  - `phone/invalid-characters`
  - `phone/invalid-length`
  - `phone/invalid-prefix`
- Auth flow wraps errors in `AuthFlowException` with codes:
  - `auth/no-current-user`
  - `phone/empty-sms-code`
  - `firebase/<FirebaseAuthException.code>`

Verification:

```bash
flutter test test/phone_number_test.dart
flutter analyze
```

## Functions Build Uses Node 22

Symptom:

- Running `npm install` or builds with a different Node version may show engine warnings.

Known warning seen locally:

```text
current Node v26.0.0, package engines wants node: 22
```

Fix:

- Use Node 22 for Firebase Functions work when possible.
- Do not run `npm audit fix` casually; it can create unrelated dependency churn.

Verification:

```bash
cd functions && npm run build
```
