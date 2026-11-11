## 0.2.1

* `autoRequest: true` (on `PermissionSetupPage`, `PermissionSetupBuilder` and `PermissionSetupBloc`): the system
  permission dialogs open one after another as soon as the page appears, with no tap. Permissions that need Settings
  are skipped. Off by default.

## 0.2.0

* **Automatic scanning.** `PermissionSetupPage()` without `items:` reads the permissions the installed app declares
  (merged Android manifest, iOS `Info.plist`) and shows exactly those. Configure with `PermissionDetection`
  (`requiredKinds`, `excludeKinds`, `includeKinds`, `overrides`, `fallbackItems`, `timeout`). New `detectPermissions()`.
  This adds a small native part for Android and iOS.
* Desktop workstation layout: `PermissionSetupStyle.workstation`, `desktopStyle:` (picked on Windows, macOS, Linux and
  wide web), top bar with navigation, meta bars, panel rows, keyboard hints and Enter-to-continue.

* New hero layout: brand bar, illustration, progress card, section heading, card-style rows with status pills and a pinned Continue button (two columns on desktop).
* `PermissionSetupStyle.crimson` and `PermissionSetupStyle.clinical` presets, each tweakable with `copyWith`; a `dark:` style is used under a dark theme.
* Many new style tokens (colours, gradient, radii, shadows, fonts) and strings; new `brand`, `onToggleTheme` and `illustration` options.
* The default look is unchanged.
* Scanner CLI: run from a plugin folder, it now scans the bundled `example/` app instead of failing, and the error
  explains why a plugin has nothing to scan. Permissions enabled only through the Podfile (e.g. notifications on
  iOS/macOS) show `podfile` instead of `MISSING`.

## 0.1.0

First release.

* **Scanner CLI** – `dart run play_permission_setup scan|generate` reads
  `AndroidManifest.xml` (incl. flavours), `Info.plist`, macOS entitlements and the
  iOS `Podfile`, reports mistakes (missing/blank usage strings, missing Podfile
  macros, entitlements, cross-platform gaps) and generates `kDetectedPermissions`.
* **`PermissionSetupBloc`** – state management for the whole flow (requests,
  refresh on resume, dependency ordering, one dialog at a time).
* **`PermissionSetupPage`** – compact, responsive default UI (phone, tablet,
  desktop; light/dark; RTL; large text) with four levels of customisation:
  items, style/strings, builders, and `PermissionSetupBuilder`.
* 26 permissions: camera, microphone, location (+ background), photos/gallery,
  videos, audio, storage, bluetooth, contacts, calendar, reminders, notifications,
  phone, sms, sensors, activity recognition, speech, app tracking, media library,
  nearby Wi-Fi, exact alarms, overlay, battery optimisation, install packages.
* Depends on `permission_handler ^12.0.1` (works with Android Gradle Plugin 8).
