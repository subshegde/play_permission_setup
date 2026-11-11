import 'package:flutter/foundation.dart';

import '../core/permission_kind.dart';

/// The platform the app is running on right now.
PermissionPlatform currentPermissionPlatform() {
  if (kIsWeb) return PermissionPlatform.web;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return PermissionPlatform.android;
    case TargetPlatform.iOS:
      return PermissionPlatform.ios;
    case TargetPlatform.macOS:
      return PermissionPlatform.macos;
    case TargetPlatform.windows:
      return PermissionPlatform.windows;
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return PermissionPlatform.linux;
  }
}
