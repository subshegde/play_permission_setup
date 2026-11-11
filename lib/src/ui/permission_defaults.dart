import 'package:flutter/material.dart';

import '../core/permission_kind.dart';

/// Default title / description / icon of each permission.
class PermissionDefaults {
  const PermissionDefaults._();

  static String title(PermissionKind k) => _t[k]![0];
  static String description(PermissionKind k) => _t[k]![1];
  static IconData icon(PermissionKind k) => _icons[k]!;

  static const _t = <PermissionKind, List<String>>{
    PermissionKind.camera: ['Camera', 'Take photos and record video.'],
    PermissionKind.microphone: ['Microphone', 'Record audio and voice.'],
    PermissionKind.location: [
      'Location',
      'Show what’s near you and personalise results.',
    ],
    PermissionKind.locationAlways: [
      'Background location',
      'Keep location features working when the app is closed.',
    ],
    PermissionKind.photos: [
      'Photos & gallery',
      'Pick and save pictures from your gallery.',
    ],
    PermissionKind.videos: ['Videos', 'Choose videos from your device.'],
    PermissionKind.audio: [
      'Music & audio',
      'Access audio files on your device.',
    ],
    PermissionKind.storage: ['Storage', 'Read and save files on your device.'],
    PermissionKind.manageStorage: [
      'All files access',
      'Manage files across your device.',
    ],
    PermissionKind.contacts: ['Contacts', 'Find and invite people you know.'],
    PermissionKind.calendar: ['Calendar', 'Add and show your events.'],
    PermissionKind.reminders: ['Reminders', 'Create and read reminders.'],
    PermissionKind.phone: ['Phone', 'Read call state and place calls.'],
    PermissionKind.sms: ['SMS', 'Send and read text messages.'],
    PermissionKind.sensors: [
      'Body & motion sensors',
      'Read health and motion data.',
    ],
    PermissionKind.activityRecognition: [
      'Physical activity',
      'Count steps and detect activity.',
    ],
    PermissionKind.notification: [
      'Notifications',
      'Get alerts, reminders and updates.',
    ],
    PermissionKind.bluetooth: [
      'Bluetooth & nearby devices',
      'Find and connect to nearby devices.',
    ],
    PermissionKind.speech: ['Speech recognition', 'Turn your voice into text.'],
    PermissionKind.appTracking: [
      'App tracking',
      'Allow personalised content across apps and websites.',
    ],
    PermissionKind.mediaLibrary: [
      'Media library',
      'Access your music library.',
    ],
    PermissionKind.nearbyWifi: [
      'Nearby Wi‑Fi devices',
      'Discover and connect to nearby Wi‑Fi devices.',
    ],
    PermissionKind.exactAlarm: [
      'Alarms & reminders',
      'Fire alarms at the exact time.',
    ],
    PermissionKind.overlay: [
      'Display over other apps',
      'Show floating windows.',
    ],
    PermissionKind.batteryOptimization: [
      'Run in background',
      'Ignore battery optimisation so tasks aren’t stopped.',
    ],
    PermissionKind.installPackages: ['Install apps', 'Install app updates.'],
  };

  static const _icons = <PermissionKind, IconData>{
    PermissionKind.camera: Icons.photo_camera_outlined,
    PermissionKind.microphone: Icons.mic_none_rounded,
    PermissionKind.location: Icons.location_on_outlined,
    PermissionKind.locationAlways: Icons.near_me_outlined,
    PermissionKind.photos: Icons.photo_library_outlined,
    PermissionKind.videos: Icons.video_library_outlined,
    PermissionKind.audio: Icons.music_note_outlined,
    PermissionKind.storage: Icons.folder_outlined,
    PermissionKind.manageStorage: Icons.folder_special_outlined,
    PermissionKind.contacts: Icons.contacts_outlined,
    PermissionKind.calendar: Icons.calendar_month_outlined,
    PermissionKind.reminders: Icons.checklist_rounded,
    PermissionKind.phone: Icons.call_outlined,
    PermissionKind.sms: Icons.sms_outlined,
    PermissionKind.sensors: Icons.monitor_heart_outlined,
    PermissionKind.activityRecognition: Icons.directions_run_rounded,
    PermissionKind.notification: Icons.notifications_none_rounded,
    PermissionKind.bluetooth: Icons.bluetooth_rounded,
    PermissionKind.speech: Icons.record_voice_over_outlined,
    PermissionKind.appTracking: Icons.ads_click_outlined,
    PermissionKind.mediaLibrary: Icons.library_music_outlined,
    PermissionKind.nearbyWifi: Icons.wifi_tethering_rounded,
    PermissionKind.exactAlarm: Icons.alarm_rounded,
    PermissionKind.overlay: Icons.layers_outlined,
    PermissionKind.batteryOptimization: Icons.battery_saver_outlined,
    PermissionKind.installPackages: Icons.system_update_outlined,
  };
}
