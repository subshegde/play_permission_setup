import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:play_permission_setup/scanner.dart';

String plist(Map<String, String> m) =>
    '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
${m.entries.map((e) => e.value == 'true' ? '<key>${e.key}</key><true/>' : '<key>${e.key}</key><string>${e.value}</string>').join('\n')}
</dict></plist>''';

String manifest(List<String> perms, {String extra = ''}) =>
    '''<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
  ${perms.map((p) => '<uses-permission android:name="$p"/>').join('\n')}
  $extra
  <application android:label="x"/>
</manifest>''';

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('perm_scan'));
  tearDown(() => root.deleteSync(recursive: true));

  void write(String rel, String content) {
    final f = File(p.join(root.path, rel));
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(content);
  }

  ScanResult scan() => ProjectScanner(root.path).scan();
  bool has(ScanResult r, String text) =>
      r.issues.any((i) => i.message.contains(text));

  test('no platform folders => error', () {
    expect(scan().hasErrors, isTrue);
  });

  test(
    'reads Android permissions with or without prefix; ignores normal ones',
    () {
      write(
        'android/app/src/main/AndroidManifest.xml',
        manifest([
          'android.permission.CAMERA',
          'android.permission.INTERNET',
          'RECORD_AUDIO',
          'android.permission.SOMETHING_NEW',
        ]),
      );
      final r = scan();
      expect(
        r.declared.keys,
        containsAll([PermissionKind.camera, PermissionKind.microphone]),
      );
      expect(r.declared.containsKey(PermissionKind.location), isFalse);
      expect(
        has(r, 'SOMETHING_NEW'),
        isTrue,
        reason: 'unknown dangerous perms are reported',
      );
      expect(has(r, 'INTERNET'), isFalse);
    },
  );

  test('tools:node="remove" cancels a permission (library merge override)', () {
    write('android/app/src/main/AndroidManifest.xml', '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android" xmlns:tools="http://schemas.android.com/tools">
 <uses-permission android:name="android.permission.CAMERA"/>
 <uses-permission android:name="android.permission.CAMERA" tools:node="remove"/>
</manifest>''');
    expect(scan().declared.containsKey(PermissionKind.camera), isFalse);
  });

  test('flavour manifests are merged', () {
    write('android/app/src/main/AndroidManifest.xml', manifest(['CAMERA']));
    write(
      'android/app/src/paid/AndroidManifest.xml',
      manifest(['READ_CONTACTS']),
    );
    final r = scan();
    expect(
      r.declared.keys,
      containsAll([PermissionKind.camera, PermissionKind.contacts]),
    );
  });

  test('bluetooth needs both SCAN and CONNECT', () {
    write(
      'android/app/src/main/AndroidManifest.xml',
      manifest(['BLUETOOTH_SCAN']),
    );
    final r = scan();
    expect(r.declared.containsKey(PermissionKind.bluetooth), isTrue);
    expect(has(r, 'BLUETOOTH_CONNECT'), isTrue);
  });

  test('legacy storage permission gets an Android 13 note', () {
    write(
      'android/app/src/main/AndroidManifest.xml',
      manifest(['READ_EXTERNAL_STORAGE']),
    );
    expect(has(scan(), 'Android 13'), isTrue);
  });

  test('background location without foreground location is an error', () {
    write(
      'android/app/src/main/AndroidManifest.xml',
      manifest(['ACCESS_BACKGROUND_LOCATION']),
    );
    expect(scan().hasErrors, isTrue);
  });

  test('iOS: usage keys, blank strings, missing keys, Podfile macros', () {
    write(
      'ios/Runner/Info.plist',
      plist({
        'NSCameraUsageDescription': 'Take photos',
        'NSMicrophoneUsageDescription': '',
        'NSPhotoLibraryUsageDescription': 'Pick pictures',
      }),
    );
    write('ios/Podfile', '''
post_install do |installer|
  config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
    '\$(inherited)',
    'PERMISSION_CAMERA=1',
    ## 'PERMISSION_PHOTOS=1',
    'PERMISSION_MICROPHONE=0',
    'PERMISSION_CONTACTS=1',
  ]
end''');
    final r = scan();
    expect(r.declared[PermissionKind.camera], contains(PermissionPlatform.ios));
    expect(has(r, 'NSMicrophoneUsageDescription is empty'), isTrue);
    // commented-out macro and =0 macro are NOT enabled
    expect(has(r, "PERMISSION_PHOTOS=1"), isTrue);
    expect(has(r, "PERMISSION_MICROPHONE=1"), isTrue);
    // macro on, key missing
    expect(has(r, 'Podfile enables PERMISSION_CONTACTS'), isTrue);
    expect(r.declared.containsKey(PermissionKind.contacts), isFalse);
  });

  test('iOS notifications are declared by the Podfile macro alone', () {
    write('ios/Runner/Info.plist', plist({}));
    write('ios/Podfile', "'PERMISSION_NOTIFICATIONS=1'");
    expect(
      scan().declared[PermissionKind.notification],
      contains(PermissionPlatform.ios),
    );
  });

  test('iOS Always without WhenInUse is an error', () {
    write(
      'ios/Runner/Info.plist',
      plist({'NSLocationAlwaysAndWhenInUseUsageDescription': 'x'}),
    );
    expect(scan().hasErrors, isTrue);
  });

  test('binary / broken plist reports an error instead of crashing', () {
    write('ios/Runner/Info.plist', 'bplist00garbage');
    expect(scan().hasErrors, isTrue);
    write('ios/Runner/Info.plist', '<plist><dict>');
    expect(scan().hasErrors, isTrue);
  });

  test('macOS entitlements must be in Debug and Release', () {
    write(
      'macos/Runner/Info.plist',
      plist({'NSCameraUsageDescription': 'Camera'}),
    );
    write(
      'macos/Runner/DebugProfile.entitlements',
      plist({'com.apple.security.device.camera': 'true'}),
    );
    write(
      'macos/Runner/Release.entitlements',
      plist({'com.apple.security.app-sandbox': 'true'}),
    );
    final r = scan();
    expect(
      r.declared[PermissionKind.camera],
      contains(PermissionPlatform.macos),
    );
    expect(has(r, 'only in DebugProfile'), isTrue);
  });

  test('cross-platform gap: declared on Android only', () {
    write('android/app/src/main/AndroidManifest.xml', manifest(['CAMERA']));
    write('ios/Runner/Info.plist', plist({}));
    final r = scan();
    expect(has(r, 'not on ios'), isTrue);
    expect(r.declared[PermissionKind.camera], {PermissionPlatform.android});
  });

  test('generator output only lists detected kinds with their platforms', () {
    write(
      'android/app/src/main/AndroidManifest.xml',
      manifest(['CAMERA', 'READ_CONTACTS']),
    );
    write('ios/Runner/Info.plist', plist({'NSCameraUsageDescription': 'x'}));
    final src = generateDartSource(
      scan(),
      required: {PermissionKind.camera},
      exclude: {PermissionKind.contacts},
    );
    expect(src, contains('PermissionKind.camera'));
    expect(src, contains('isRequired: true'));
    expect(src, contains('PermissionPlatform.android, PermissionPlatform.ios'));
    expect(src, isNot(contains('contacts')));
  });

  test('descriptor table is complete', () {
    for (final k in PermissionKind.values) {
      expect(k.descriptor.platforms, isNotEmpty, reason: k.name);
    }
  });

  group('project locator', () {
    void app(String rel) {
      write('$rel/pubspec.yaml', 'name: x');
      Directory(p.join(root.path, rel, 'android')).createSync(recursive: true);
    }

    test('finds the app when started in a sub-folder', () {
      app('myapp');
      Directory(p.join(root.path, 'myapp/lib/src')).createSync(recursive: true);
      expect(
        findProjectRoot(p.join(root.path, 'myapp/lib/src')),
        p.join(root.path, 'myapp'),
      );
    });

    test('a plain package (no android/ios/macos) is not an app', () {
      write('pkg/pubspec.yaml', 'name: pkg');
      expect(findProjectRoot(p.join(root.path, 'pkg')), isNull);
    });

    test('suggests apps one and two levels below', () {
      app('apps/first');
      app('second');
      write('plain/pubspec.yaml', 'name: plain');
      final near = findNearbyProjects(root.path).map(p.basename).toList();
      expect(near, containsAll(['first', 'second']));
      expect(near, isNot(contains('plain')));
    });

    test('error message names the folder that was scanned', () {
      final r = scan();
      expect(r.hasErrors, isTrue);
      expect(has(r, root.path), isTrue);
    });
  });
}
