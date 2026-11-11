/// Pure-Dart (no Flutter imports) so the CLI scanner can use it too.
library;

/// Platforms a permission can be declared for / requested on.
enum PermissionPlatform { android, ios, macos, windows, linux, web }

/// Every permission this package knows how to scan, request and display.
enum PermissionKind {
  camera,
  microphone,
  location,
  locationAlways,
  photos, // gallery images
  videos, // gallery videos (Android 13+)
  audio, // audio files (Android 13+)
  storage, // legacy external storage (Android <= 12)
  manageStorage,
  contacts,
  calendar,
  reminders,
  phone,
  sms,
  sensors,
  activityRecognition,
  notification,
  bluetooth,
  speech,
  appTracking,
  mediaLibrary,
  nearbyWifi,
  exactAlarm,
  overlay,
  batteryOptimization,
  installPackages,
}

/// Static knowledge about where a permission must be declared.
class PermissionDescriptor {
  const PermissionDescriptor({
    required this.platforms,
    this.android = const [],
    this.androidAllRequired = false,
    this.iosKeys = const [],
    this.macosEntitlements = const [],
    this.podMacro,
    this.dependsOn = const [],
  });

  /// Platforms where the underlying plugin can request this permission.
  final Set<PermissionPlatform> platforms;

  /// Manifest names (without the `android.permission.` prefix).
  final List<String> android;

  /// If true every [android] entry must be declared (e.g. bluetooth).
  final bool androidAllRequired;

  /// Info.plist usage-description keys (any one means "declared").
  final List<String> iosKeys;

  /// macOS sandbox entitlements.
  final List<String> macosEntitlements;

  /// `permission_handler` Podfile macro, e.g. `PERMISSION_CAMERA`.
  final String? podMacro;

  /// Kinds that must be granted first (e.g. background location).
  final List<PermissionKind> dependsOn;
}

const _all3 = {
  PermissionPlatform.android,
  PermissionPlatform.ios,
  PermissionPlatform.macos,
};
const _web3 = {..._all3, PermissionPlatform.web};
const _mobile = {PermissionPlatform.android, PermissionPlatform.ios};
const _android = {PermissionPlatform.android};
const _ios = {PermissionPlatform.ios};
const _ent = 'com.apple.security.';

extension PermissionKindInfo on PermissionKind {
  PermissionDescriptor get descriptor => _descriptors[this]!;
  Set<PermissionPlatform> get platforms => descriptor.platforms;
  List<PermissionKind> get dependsOn => descriptor.dependsOn;
}

const Map<PermissionKind, PermissionDescriptor> _descriptors = {
  PermissionKind.camera: PermissionDescriptor(
    platforms: _web3,
    android: ['CAMERA'],
    iosKeys: ['NSCameraUsageDescription'],
    macosEntitlements: ['${_ent}device.camera'],
    podMacro: 'PERMISSION_CAMERA',
  ),
  PermissionKind.microphone: PermissionDescriptor(
    platforms: _web3,
    android: ['RECORD_AUDIO'],
    iosKeys: ['NSMicrophoneUsageDescription'],
    macosEntitlements: ['${_ent}device.audio-input'],
    podMacro: 'PERMISSION_MICROPHONE',
  ),
  PermissionKind.location: PermissionDescriptor(
    platforms: {..._web3, PermissionPlatform.windows},
    android: ['ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION'],
    iosKeys: ['NSLocationWhenInUseUsageDescription'],
    macosEntitlements: ['${_ent}personal-information.location'],
    podMacro: 'PERMISSION_LOCATION',
  ),
  PermissionKind.locationAlways: PermissionDescriptor(
    platforms: _mobile,
    android: ['ACCESS_BACKGROUND_LOCATION'],
    iosKeys: [
      'NSLocationAlwaysAndWhenInUseUsageDescription',
      'NSLocationAlwaysUsageDescription',
    ],
    podMacro: 'PERMISSION_LOCATION',
    dependsOn: [PermissionKind.location],
  ),
  PermissionKind.photos: PermissionDescriptor(
    platforms: _all3,
    android: ['READ_MEDIA_IMAGES'],
    iosKeys: ['NSPhotoLibraryUsageDescription'],
    macosEntitlements: ['${_ent}personal-information.photos-library'],
    podMacro: 'PERMISSION_PHOTOS',
  ),
  PermissionKind.videos: PermissionDescriptor(
    platforms: _android,
    android: ['READ_MEDIA_VIDEO'],
  ),
  PermissionKind.audio: PermissionDescriptor(
    platforms: _android,
    android: ['READ_MEDIA_AUDIO'],
  ),
  PermissionKind.storage: PermissionDescriptor(
    platforms: _android,
    android: ['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE'],
  ),
  PermissionKind.manageStorage: PermissionDescriptor(
    platforms: _android,
    android: ['MANAGE_EXTERNAL_STORAGE'],
  ),
  PermissionKind.contacts: PermissionDescriptor(
    platforms: _all3,
    android: ['READ_CONTACTS', 'WRITE_CONTACTS'],
    iosKeys: ['NSContactsUsageDescription'],
    macosEntitlements: ['${_ent}personal-information.addressbook'],
    podMacro: 'PERMISSION_CONTACTS',
  ),
  PermissionKind.calendar: PermissionDescriptor(
    platforms: _all3,
    android: ['READ_CALENDAR', 'WRITE_CALENDAR'],
    iosKeys: [
      'NSCalendarsFullAccessUsageDescription',
      'NSCalendarsUsageDescription',
    ],
    macosEntitlements: ['${_ent}personal-information.calendars'],
    podMacro: 'PERMISSION_EVENTS',
  ),
  PermissionKind.reminders: PermissionDescriptor(
    platforms: _ios,
    iosKeys: [
      'NSRemindersFullAccessUsageDescription',
      'NSRemindersUsageDescription',
    ],
    podMacro: 'PERMISSION_REMINDERS',
  ),
  PermissionKind.phone: PermissionDescriptor(
    platforms: _android,
    android: ['READ_PHONE_STATE', 'CALL_PHONE'],
  ),
  PermissionKind.sms: PermissionDescriptor(
    platforms: _android,
    android: ['SEND_SMS', 'READ_SMS', 'RECEIVE_SMS'],
  ),
  PermissionKind.sensors: PermissionDescriptor(
    platforms: _mobile,
    android: ['BODY_SENSORS'],
    iosKeys: ['NSMotionUsageDescription'],
    podMacro: 'PERMISSION_SENSORS',
  ),
  PermissionKind.activityRecognition: PermissionDescriptor(
    platforms: _android,
    android: ['ACTIVITY_RECOGNITION'],
  ),
  PermissionKind.notification: PermissionDescriptor(
    // iOS/macOS have no plist key; they are declared by the Podfile macro.
    platforms: _web3,
    android: ['POST_NOTIFICATIONS'],
    podMacro: 'PERMISSION_NOTIFICATIONS',
  ),
  PermissionKind.bluetooth: PermissionDescriptor(
    platforms: _all3,
    android: ['BLUETOOTH_SCAN', 'BLUETOOTH_CONNECT'],
    androidAllRequired: true,
    iosKeys: [
      'NSBluetoothAlwaysUsageDescription',
      'NSBluetoothPeripheralUsageDescription',
    ],
    macosEntitlements: ['${_ent}device.bluetooth'],
    podMacro: 'PERMISSION_BLUETOOTH',
  ),
  PermissionKind.speech: PermissionDescriptor(
    platforms: _mobile,
    iosKeys: ['NSSpeechRecognitionUsageDescription'],
    podMacro: 'PERMISSION_SPEECH_RECOGNIZER',
  ),
  PermissionKind.appTracking: PermissionDescriptor(
    platforms: _ios,
    iosKeys: ['NSUserTrackingUsageDescription'],
    podMacro: 'PERMISSION_APP_TRACKING_TRANSPARENCY',
  ),
  PermissionKind.mediaLibrary: PermissionDescriptor(
    platforms: _ios,
    iosKeys: ['NSAppleMusicUsageDescription'],
    podMacro: 'PERMISSION_MEDIA_LIBRARY',
  ),
  PermissionKind.nearbyWifi: PermissionDescriptor(
    platforms: _android,
    android: ['NEARBY_WIFI_DEVICES'],
  ),
  PermissionKind.exactAlarm: PermissionDescriptor(
    platforms: _android,
    android: ['SCHEDULE_EXACT_ALARM', 'USE_EXACT_ALARM'],
  ),
  PermissionKind.overlay: PermissionDescriptor(
    platforms: _android,
    android: ['SYSTEM_ALERT_WINDOW'],
  ),
  PermissionKind.batteryOptimization: PermissionDescriptor(
    platforms: _android,
    android: ['REQUEST_IGNORE_BATTERY_OPTIMIZATIONS'],
  ),
  PermissionKind.installPackages: PermissionDescriptor(
    platforms: _android,
    android: ['REQUEST_INSTALL_PACKAGES'],
  ),
};
