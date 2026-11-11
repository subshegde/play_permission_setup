# play_permission_setup example

A complete app using `play_permission_setup`.

```bash
cd example
flutter pub get
flutter run                     # any platform

# After changing AndroidManifest.xml / Info.plist / entitlements:
dart run play_permission_setup scan
dart run play_permission_setup generate --required camera,location
```

* `lib/main.dart` – shows the page, then a home screen.
* No permission list: the page scans the app's manifest / `Info.plist` by itself.
* The platform files declare many permissions on purpose, including a few
  **deliberate mistakes** (a blank iOS usage string, a macOS entitlement present in
  only one build type) so `dart run play_permission_setup scan` has something to report.
