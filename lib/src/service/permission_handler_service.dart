import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/permission_kind.dart';
import '../models/permission_grant.dart';
import '../models/platform.dart';
import 'permission_service.dart';

/// Default [PermissionService] built on `permission_handler`.
class PermissionHandlerService implements PermissionService {
  PermissionHandlerService({Future<int?> Function()? androidSdkInt})
    : _androidSdkInt = androidSdkInt ?? _defaultSdkInt;

  final Future<int?> Function() _androidSdkInt;
  int? _sdk;
  bool _sdkLoaded = false;

  static Future<int?> _defaultSdkInt() async {
    try {
      return (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    } catch (_) {
      return null;
    }
  }

  Future<int?> _sdkVersion() async {
    if (currentPermissionPlatform() != PermissionPlatform.android) return null;
    if (!_sdkLoaded) {
      _sdk = await _androidSdkInt();
      _sdkLoaded = true;
    }
    return _sdk;
  }

  /// Permissions that do not exist on older/newer Android versions.
  Future<bool> _notNeeded(PermissionKind kind) async {
    final sdk = await _sdkVersion();
    if (sdk == null) return false;
    switch (kind) {
      case PermissionKind.storage:
        return sdk >= 33; // replaced by READ_MEDIA_*; always "denied" otherwise
      case PermissionKind.bluetooth:
        return sdk < 31; // legacy BLUETOOTH is install-time
      case PermissionKind.nearbyWifi:
        return sdk < 33;
      case PermissionKind.manageStorage:
        return sdk < 30;
      case PermissionKind.activityRecognition:
        return sdk < 29;
      default:
        return false;
    }
  }

  List<Permission> _permissions(PermissionKind kind) {
    final p = currentPermissionPlatform();
    switch (kind) {
      case PermissionKind.camera:
        return [Permission.camera];
      case PermissionKind.microphone:
        return [Permission.microphone];
      case PermissionKind.location:
        return [
          p == PermissionPlatform.ios
              ? Permission.locationWhenInUse
              : Permission.location,
        ];
      case PermissionKind.locationAlways:
        return [Permission.locationAlways];
      case PermissionKind.photos:
        return [Permission.photos];
      case PermissionKind.videos:
        return [Permission.videos];
      case PermissionKind.audio:
        return [Permission.audio];
      case PermissionKind.storage:
        return [Permission.storage];
      case PermissionKind.manageStorage:
        return [Permission.manageExternalStorage];
      case PermissionKind.contacts:
        return [Permission.contacts];
      case PermissionKind.calendar:
        return [Permission.calendarFullAccess];
      case PermissionKind.reminders:
        return [Permission.reminders];
      case PermissionKind.phone:
        return [Permission.phone];
      case PermissionKind.sms:
        return [Permission.sms];
      case PermissionKind.sensors:
        return [Permission.sensors];
      case PermissionKind.activityRecognition:
        return [Permission.activityRecognition];
      case PermissionKind.notification:
        return [Permission.notification];
      case PermissionKind.bluetooth:
        return p == PermissionPlatform.android
            ? [Permission.bluetoothScan, Permission.bluetoothConnect]
            : [Permission.bluetooth];
      case PermissionKind.speech:
        return [Permission.speech];
      case PermissionKind.appTracking:
        return [Permission.appTrackingTransparency];
      case PermissionKind.mediaLibrary:
        return [Permission.mediaLibrary];
      case PermissionKind.nearbyWifi:
        return [Permission.nearbyWifiDevices];
      case PermissionKind.exactAlarm:
        return [Permission.scheduleExactAlarm];
      case PermissionKind.overlay:
        return [Permission.systemAlertWindow];
      case PermissionKind.batteryOptimization:
        return [Permission.ignoreBatteryOptimizations];
      case PermissionKind.installPackages:
        return [Permission.requestInstallPackages];
    }
  }

  static PermissionGrant _map(PermissionStatus s) {
    switch (s) {
      case PermissionStatus.granted:
        return PermissionGrant.granted;
      case PermissionStatus.limited:
        return PermissionGrant.limited;
      case PermissionStatus.provisional:
        return PermissionGrant.provisional;
      case PermissionStatus.denied:
        return PermissionGrant.denied;
      case PermissionStatus.permanentlyDenied:
        return PermissionGrant.permanentlyDenied;
      case PermissionStatus.restricted:
        return PermissionGrant.restricted;
    }
  }

  /// Combines several statuses (e.g. bluetooth scan + connect) into one.
  @visibleForTesting
  static PermissionGrant combine(Iterable<PermissionGrant> all) {
    final list = all.toList();
    if (list.isEmpty) return PermissionGrant.notApplicable;
    bool has(PermissionGrant g) => list.contains(g);
    if (list.every((g) => g == PermissionGrant.granted)) {
      return PermissionGrant.granted;
    }
    if (has(PermissionGrant.permanentlyDenied)) {
      return PermissionGrant.permanentlyDenied;
    }
    if (has(PermissionGrant.restricted)) return PermissionGrant.restricted;
    if (has(PermissionGrant.denied)) return PermissionGrant.denied;
    if (has(PermissionGrant.limited)) return PermissionGrant.limited;
    if (has(PermissionGrant.provisional)) return PermissionGrant.provisional;
    return PermissionGrant.notApplicable;
  }

  Future<bool> _serviceEnabled(PermissionKind kind) async {
    if (kind != PermissionKind.location &&
        kind != PermissionKind.locationAlways) {
      return true;
    }
    try {
      return await Permission.location.serviceStatus.isEnabled;
    } catch (_) {
      return true; // can't tell – don't nag
    }
  }

  PermissionCheck _unsupported() =>
      const PermissionCheck(PermissionGrant.notApplicable);

  /// Platform without a plugin implementation => not applicable, not a crash.
  bool _isUnsupportedError(Object e) =>
      e is MissingPluginException ||
      e is UnimplementedError ||
      e is UnsupportedError;

  @override
  Future<PermissionCheck> check(PermissionKind kind) async {
    if (await _notNeeded(kind)) return _unsupported();
    try {
      final grants = <PermissionGrant>[];
      for (final p in _permissions(kind)) {
        grants.add(_map(await p.status));
      }
      final grant = combine(grants);
      final service = grant.isSatisfied ? await _serviceEnabled(kind) : true;
      return PermissionCheck(grant, serviceEnabled: service);
    } catch (e) {
      if (_isUnsupportedError(e)) return _unsupported();
      rethrow;
    }
  }

  @override
  Future<PermissionCheck> request(PermissionKind kind) async {
    if (await _notNeeded(kind)) return _unsupported();
    try {
      // Android 11+/iOS: background location can only be asked AFTER
      // foreground location is granted.
      if (kind == PermissionKind.locationAlways) {
        final fg = await request(PermissionKind.location);
        if (!fg.grant.isSatisfied) return fg;
      }
      final grants = <PermissionGrant>[];
      for (final p in _permissions(kind)) {
        grants.add(_map(await p.request()));
      }
      final grant = combine(grants);
      final service = grant.isSatisfied ? await _serviceEnabled(kind) : true;
      return PermissionCheck(grant, serviceEnabled: service);
    } catch (e) {
      if (_isUnsupportedError(e)) return _unsupported();
      rethrow;
    }
  }

  @override
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
