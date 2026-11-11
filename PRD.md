# PRD: `play_permission_setup`

**Version:** 0.1.0 · **Status:** Pre-release (pub.dev) · **License:** MIT · **Stack:** Flutter ≥3.32, Dart ≥3.8, `flutter_bloc`, `permission_handler`

## 1. Summary
`play_permission_setup` is a Flutter package with two parts:
1. **A ready-made permission setup screen.** It is responsive, themeable and driven by a BLoC.
2. **A build-time CLI.** It audits the files where permissions are declared (`AndroidManifest.xml`, `Info.plist`, macOS entitlements, iOS `Podfile`) and generates the list of permissions the app really supports.

A companion app, `permission_playground`, demonstrates the package. `play_permission_setup/example` is the package's own example app.

## 2. Problem
`permission_handler` provides the calls but leaves three gaps:
- **No UI.** Every app rebuilds the same permissions list and hand-codes the denied, open-settings and return-from-settings flows.
- **No guard on platform config.**
  - A missing `NSCameraUsageDescription` crashes the iOS app when it asks for the camera.
  - A missing Podfile macro makes iOS silently report "denied".
  - A blank usage string gets the app rejected by Apple.
- **Edge-case logic is left to each app.**
  - Background location must be requested after foreground location.
  - Storage is meaningless on Android 13+.
  - Bluetooth is two permissions on Android 12+.

## 3. Goals
| # | Goal |
|---|---|
| G1 | An app can show a correct permission screen in under 10 lines of integration code. |
| G2 | Misconfigured platform files are caught at build or CI time, not at runtime or in App Store review. |
| G3 | The UI works at any size (phone, tablet, desktop, dialog, side panel) and in light/dark, RTL and large text. |
| G4 | Developers can customise from "change the text" up to "replace everything" without forking. |
| G5 | The package never crashes on an unsupported platform or a failed request. |

## 4. Non-goals
- Replacing `permission_handler` for the single-permission, just-in-time request case.
- Permissions outside the supported catalogue (extensible via a custom service).
- Runtime parsing of native files, which Dart cannot do. This is deliberately build-time only.
- Server-side or consent-management (GDPR/CMP) flows.

## 5. Target users
| Persona | Need |
|---|---|
| **Flutter app developer** | Drop-in onboarding or settings permission page. |
| **Multi-platform team** (mobile + desktop) | One consistent flow with per-platform correctness. |
| **CI / release engineer** | `scan --strict` gate against permission config drift before store review. |
| **Design-system owner** | Full control of look, copy and localisation. |

## 6. User stories
- As a developer, I run `generate` and get a list containing only permissions declared on each platform, so the page never asks for something that would crash.
- As a user who permanently denied a permission, I see a **Settings** button. When I come back, the status refreshes automatically.
- As a user on a managed device (MDM), I see why a permission is restricted instead of a dead button.
- As a CI engineer, I fail the build when an iOS usage string is blank or a Podfile macro is missing.
- As a developer with my own design, I use `PermissionSetupBuilder` and get state and actions without any UI.

## 7. Functional requirements

### 7.1 Setup page (UI)
- **FR-1** `PermissionSetupPage` accepts `items`, `onComplete`, `onSkip` and `autoCompleteWhenSatisfied`.
- **FR-2** Three layouts are chosen from the widget's available width, not the device type:
  - below 600: compact, with a pinned bottom action bar
  - 600–1000: medium, a single centred column of at most 640px
  - 1000 and above: expanded, two columns when they fit
- **FR-3** Customisation is available at four levels:
  1. `PermissionItem` content
  2. `PermissionSetupStyle` and `PermissionSetupStrings` (all text localisable)
  3. Builders for header, item, footer, empty and loading
  4. `PermissionSetupBuilder` with state and actions
- **FR-4** Actions are `request`, `requestAll`, `openSettings`, `refresh`, `skip` and `finish`.
- **FR-5** **Continue** is blocked until all required permissions are satisfied.

### 7.2 BLoC
- **FR-6** `PermissionSetupBloc` exposes six events: started/refreshed, requested, all-requested, settings-opened, continued and skipped.
- **FR-7** State includes `status`, `entries`, `canContinue`, progress helpers, `blockedRequired` and `isLocked`.
- **FR-8** The BLoC re-checks permissions automatically when the app resumes.
- **FR-9** Grant states are `granted`, `limited`, `provisional`, `denied`, `permanentlyDenied`, `restricted`, `notApplicable` and `unknown`.

### 7.3 Edge-case handling
- **FR-10** Permanently denied → show **Settings**.
- **FR-11** Android "never asks again" quirk → after 2 refusals, offer **Settings**.
- **FR-12** Restricted → show an explanation and a lock icon, with no action button.
- **FR-13** Limited photos and provisional notifications → counted as satisfied, with a **Manage** shortcut.
- **FR-14** Location granted but GPS off → flag the row and offer a Settings shortcut.
- **FR-15** Background location → locked until foreground location is granted.
- **FR-16** Android version gating:
  - legacy `storage` is hidden on Android 13+
  - Bluetooth permissions are hidden below Android 12
  - nearby-wifi is hidden below Android 13
- **FR-17** Multi-part permissions such as Bluetooth scan and connect → combined into one status.
- **FR-18** Only one system dialog is shown at a time. Duplicate items are ignored, with the first winning.
- **FR-19** Request failures show a per-row error with **Retry**.
- **FR-20** Platforms without an implementation report `notApplicable`. If nothing applies, an empty state is shown.
- **FR-21** Closing the page mid-request must not throw.

### 7.4 CLI (`dart run play_permission_setup …`)
- **FR-22** `scan [--path] [--strict]` prints a permission-by-platform matrix and a list of errors and warnings. It exits with code 1 on errors, or on warnings when `--strict` is set.
- **FR-23** `generate [--path] [--output] [--required] [--exclude]` writes `play_permission_setup.g.dart` with `kDetectedPermissions`. Each item carries its actually-declared platforms.
- **FR-24** Scan checks:

| Area | Checks |
|---|---|
| Android | `uses-permission` and `uses-permission-sdk-23`; `tools:node="remove"`; flavour manifests; partial Bluetooth; legacy storage on 13+; background location without foreground |
| iOS | Missing or blank usage keys; Podfile macro missing, commented out or `=0`; key without macro, and the reverse; Always-location without When-in-use; binary plists |
| macOS | Usage keys; sandbox entitlements present in both Debug and Release |
| Cross-platform | Permission declared on some platforms but not others |

### 7.5 Permission catalogue
25 `PermissionKind`s:
- **Hardware and media:** camera, microphone, location, locationAlways, photos, videos, audio, bluetooth, nearbyWifi, sensors, activityRecognition
- **Personal data:** storage, manageStorage, contacts, calendar, reminders, mediaLibrary
- **Telephony and notifications:** phone, sms, notification
- **iOS-specific:** speech, appTracking
- **System-level (mostly Android):** exactAlarm, overlay, batteryOptimization, installPackages

Each kind maps to its Android permission(s), plist key(s), Podfile macro, macOS entitlement and supported platforms. A custom service allows extension and test fakes.

## 8. Non-functional requirements
| Area | Requirement |
|---|---|
| **Accessibility** | Status is never conveyed by colour alone. Rows carry semantic labels. Text scales to 2×. RTL and dark mode work. |
| **Resilience** | No crashes on missing plugins, unsupported platforms or thrown checks. |
| **Testability** | Injectable service and platform. Unit tests for the BLoC, the scanner and the UI. A fake service helper. |
| **Performance** | The scanner is pure Dart with no Flutter imports. It runs in CI without a device. |
| **Compatibility** | Android, iOS, macOS, Windows and Web, with per-permission platform support. |
| **Docs** | README covers quick start, a cheat-sheet, recipes, FAQ and limitations. Screenshots are auto-generated. |

## 9. Success metrics
*(Suggested; none are instrumented today.)*
- Integration time from install to working page: under 15 minutes.
- Percentage of apps whose CI catches at least one config issue via `scan --strict`.
- pub.dev likes, downloads and pub points.
- Issues filed about permission-related crashes or App Store rejections: trending to 0.
- Test coverage of scanner rules: 100% of documented checks.

## 10. Risks and open questions
| Risk | Mitigation |
|---|---|
| Depends on `permission_handler`'s behaviour. Its quirks and version bumps can break the flow. | Pin the version range. Keep the service abstraction. |
| iOS and Android policy changes add or rename permission keys. | Keep the catalogue data-driven. Add a release checklist. |
| The generated file goes stale. | Document it and enforce it with `scan --strict` in CI. |
| The scanner may miss exotic project layouts (monorepos, custom flavours). | Expose `--path`. Add fixtures for layouts as they are reported. |
| **Open:** should a Web/Windows scanner be added? | Currently only Android, iOS and macOS files are audited. |
| **Open:** should it ship a localisation set beyond English? | Strings are overridable today, but no bundled translations. |
| **Open:** should `scan` offer `--fix`, or a `--format json` output? | Both would help CI. |

## 11. Roadmap
- **Now (v0.1.x):** stabilise the API, publish, and add more scanner fixtures.
- **Next:**
  - built-in translations
  - JSON/SARIF output for CI
  - an auto-fix suggestion mode in `scan`
  - Windows and Web declaration scanning
- **Later:**
  - just-in-time rationale dialogs
  - analytics hooks
  - a Cupertino-styled default theme

## 12. Release criteria
- All tests pass (BLoC, scanner, UI).
- `scan` and `generate` are verified on a sample Flutter project (`permission_playground`).
- README, CHANGELOG and screenshots are current.
- `dart pub publish --dry-run` is clean.
