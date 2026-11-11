import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/permission_kind.dart';
import 'android_scanner.dart';
import 'plist_parser.dart';
import 'scan_result.dart';

/// Install-time permissions that need no runtime prompt; never reported.
const _normalAndroid = {
  'INTERNET',
  'ACCESS_NETWORK_STATE',
  'ACCESS_WIFI_STATE',
  'CHANGE_WIFI_STATE',
  'VIBRATE',
  'WAKE_LOCK',
  'RECEIVE_BOOT_COMPLETED',
  'BLUETOOTH',
  'BLUETOOTH_ADMIN',
  'FOREGROUND_SERVICE',
  'NFC',
  'SET_ALARM',
  'USE_BIOMETRIC',
  'USE_FINGERPRINT',
  'CHANGE_NETWORK_STATE',
  'MODIFY_AUDIO_SETTINGS',
  'REORDER_TASKS',
  'EXPAND_STATUS_BAR',
  'USE_FULL_SCREEN_INTENT',
  'QUERY_ALL_PACKAGES',
  'FLASHLIGHT',
};

/// Reads AndroidManifest.xml, Info.plist, *.entitlements and the iOS Podfile
/// of a Flutter project and cross-checks them.
class ProjectScanner {
  ProjectScanner(this.root);
  final String root;

  ScanResult scan() {
    final declared = <PermissionKind, Set<PermissionPlatform>>{};
    final issues = <ScanIssue>[];
    final scanned = <PermissionPlatform>{};
    final files = <String>[];

    void mark(PermissionKind k, PermissionPlatform pl) =>
        declared.putIfAbsent(k, () => {}).add(pl);

    final android = _scanAndroid(declared, issues, scanned, files, mark);
    final iosKeys = _scanIos(declared, issues, scanned, files, mark);
    final macKeys = _scanMacos(declared, issues, scanned, files, mark);
    _crossCheck(declared, issues, scanned, android, iosKeys, macKeys);

    if (scanned.isEmpty) {
      final example = Directory('$root/example');
      final isPlugin = File('$root/pubspec.yaml').existsSync() &&
          File('$root/pubspec.yaml').readAsStringSync().contains('pluginClass');
      final hint = isPlugin && example.existsSync()
          ? ' This folder is a plugin/package, not an app: its android/ and ios/ '
              'folders hold native plugin code, not a manifest or Info.plist. '
              'Scan an app instead, e.g. --path example.'
          : ' Run from your Flutter app folder or pass --path.';
      issues.add(
        ScanIssue(
          IssueSeverity.error,
          'No android/, ios/ or macos/ project files found in $root.$hint',
        ),
      );
    }
    return ScanResult(
      declared: declared,
      issues: issues,
      scanned: scanned,
      files: files,
    );
  }

  String _abs(String rel) => p.join(root, rel);

  // ---------------------------------------------------------------- Android
  Set<String>? _scanAndroid(
    Map<PermissionKind, Set<PermissionPlatform>> declared,
    List<ScanIssue> issues,
    Set<PermissionPlatform> scanned,
    List<String> files,
    void Function(PermissionKind, PermissionPlatform) mark,
  ) {
    final srcDir = Directory(_abs('android/app/src'));
    if (!srcDir.existsSync()) return null;

    final all = <String>{};
    final maxSdk = <String, int>{};
    for (final dir in srcDir.listSync().whereType<Directory>()) {
      final f = File(p.join(dir.path, 'AndroidManifest.xml'));
      if (!f.existsSync()) continue;
      final rel = p.relative(f.path, from: root);
      try {
        final m = parseManifest(f.readAsStringSync());
        all.addAll(m.declared);
        maxSdk.addAll(m.maxSdk);
        files.add(rel);
      } catch (e) {
        issues.add(
          ScanIssue(
            IssueSeverity.error,
            'Cannot parse manifest: $e',
            platform: PermissionPlatform.android,
            file: rel,
          ),
        );
      }
    }
    if (files.where((f) => f.startsWith('android')).isEmpty) return null;
    scanned.add(PermissionPlatform.android);

    final known = <String>{};
    for (final kind in PermissionKind.values) {
      final d = kind.descriptor;
      final hits = d.android.where(all.contains).toList();
      known.addAll(d.android);
      if (hits.isEmpty) continue;
      mark(kind, PermissionPlatform.android);
      if (d.androidAllRequired) {
        final missing = d.android.where((n) => !all.contains(n)).toList();
        if (missing.isNotEmpty) {
          issues.add(
            ScanIssue(
              IssueSeverity.warning,
              '${kind.name}: also declare ${missing.join(', ')} – Android 12+ requests all of them together.',
              platform: PermissionPlatform.android,
              kind: kind,
            ),
          );
        }
      }
    }

    if (all.contains('READ_EXTERNAL_STORAGE') ||
        all.contains('WRITE_EXTERNAL_STORAGE')) {
      issues.add(
        const ScanIssue(
          IssueSeverity.info,
          'Storage permission is ignored on Android 13+ (API 33). Use READ_MEDIA_IMAGES / READ_MEDIA_VIDEO / READ_MEDIA_AUDIO for gallery access (add android:maxSdkVersion="32" to the legacy one). The setup page hides "storage" automatically on 13+.',
          platform: PermissionPlatform.android,
          kind: PermissionKind.storage,
        ),
      );
    }
    final unmapped =
        all
            .where((n) => !known.contains(n) && !_normalAndroid.contains(n))
            .where((n) => !n.startsWith('FOREGROUND_SERVICE'))
            .where((n) => !n.contains('.'))
            .toList()
          ..sort();
    if (unmapped.isNotEmpty) {
      issues.add(
        ScanIssue(
          IssueSeverity.info,
          'Declared but not handled by this package: ${unmapped.join(', ')}',
          platform: PermissionPlatform.android,
        ),
      );
    }
    return all;
  }

  // -------------------------------------------------------------------- iOS
  Map<String, String>? _scanIos(
    Map<PermissionKind, Set<PermissionPlatform>> declared,
    List<ScanIssue> issues,
    Set<PermissionPlatform> scanned,
    List<String> files,
    void Function(PermissionKind, PermissionPlatform) mark,
  ) {
    final plistFile = File(_abs('ios/Runner/Info.plist'));
    if (!plistFile.existsSync()) return null;
    const rel = 'ios/Runner/Info.plist';
    final Map<String, String> plist;
    try {
      plist = parsePlist(plistFile.readAsStringSync());
    } on PlistParseException catch (e) {
      issues.add(
        ScanIssue(
          IssueSeverity.error,
          'Cannot parse: $e',
          platform: PermissionPlatform.ios,
          file: rel,
        ),
      );
      return null;
    }
    files.add(rel);
    scanned.add(PermissionPlatform.ios);

    final macros = _podMacros();
    final iosKinds = PermissionKind.values.where(
      (k) => k.platforms.contains(PermissionPlatform.ios),
    );

    for (final kind in iosKinds) {
      final d = kind.descriptor;
      final presentKeys = d.iosKeys.where(plist.containsKey).toList();
      final macroOn =
          d.podMacro != null && (macros?.contains(d.podMacro) ?? false);

      if (d.iosKeys.isNotEmpty) {
        if (presentKeys.isEmpty) {
          if (macroOn) {
            issues.add(
              ScanIssue(
                IssueSeverity.warning,
                '${kind.name}: Podfile enables ${d.podMacro} but Info.plist has none of ${d.iosKeys.join(' / ')}. iOS terminates the app when it is requested.',
                platform: PermissionPlatform.ios,
                kind: kind,
                file: rel,
              ),
            );
          }
          continue;
        }
        mark(kind, PermissionPlatform.ios);
        for (final k in presentKeys) {
          if ((plist[k] ?? '').isEmpty) {
            issues.add(
              ScanIssue(
                IssueSeverity.warning,
                '$k is empty. Apple rejects apps with blank usage descriptions; explain why you need it.',
                platform: PermissionPlatform.ios,
                kind: kind,
                file: rel,
              ),
            );
          }
        }
        if (macros != null && d.podMacro != null && !macroOn) {
          issues.add(
            ScanIssue(
              IssueSeverity.warning,
              '${kind.name}: add \'${d.podMacro}=1\' to GCC_PREPROCESSOR_DEFINITIONS in ios/Podfile, otherwise permission_handler always reports "denied".',
              platform: PermissionPlatform.ios,
              kind: kind,
              file: 'ios/Podfile',
            ),
          );
        }
      } else if (macroOn) {
        // e.g. notifications: no plist key, declared by the macro alone.
        mark(kind, PermissionPlatform.ios);
      }
    }

    if (plist.containsKey('NSLocationAlwaysAndWhenInUseUsageDescription') &&
        !plist.containsKey('NSLocationWhenInUseUsageDescription')) {
      issues.add(
        const ScanIssue(
          IssueSeverity.error,
          'NSLocationAlwaysAndWhenInUseUsageDescription requires NSLocationWhenInUseUsageDescription too.',
          platform: PermissionPlatform.ios,
          kind: PermissionKind.locationAlways,
          file: rel,
        ),
      );
    }
    return plist;
  }

  /// Enabled `PERMISSION_*=1` macros from ios/Podfile, or null if no Podfile.
  Set<String>? _podMacros() {
    final f = File(_abs('ios/Podfile'));
    if (!f.existsSync()) return null;
    final out = <String>{};
    final re = RegExp(r'''['"](PERMISSION_[A-Z_]+)\s*=\s*(\d)['"]''');
    for (final line in f.readAsLinesSync()) {
      if (line.trimLeft().startsWith('#')) continue; // commented out
      for (final m in re.allMatches(line)) {
        if (m.group(2) == '1') out.add(m.group(1)!);
      }
    }
    return out;
  }

  // ------------------------------------------------------------------ macOS
  Map<String, String>? _scanMacos(
    Map<PermissionKind, Set<PermissionPlatform>> declared,
    List<ScanIssue> issues,
    Set<PermissionPlatform> scanned,
    List<String> files,
    void Function(PermissionKind, PermissionPlatform) mark,
  ) {
    final plistFile = File(_abs('macos/Runner/Info.plist'));
    if (!plistFile.existsSync()) return null;
    const rel = 'macos/Runner/Info.plist';
    Map<String, String> plist;
    try {
      plist = parsePlist(plistFile.readAsStringSync());
    } on PlistParseException catch (e) {
      issues.add(
        ScanIssue(
          IssueSeverity.error,
          'Cannot parse: $e',
          platform: PermissionPlatform.macos,
          file: rel,
        ),
      );
      return null;
    }
    files.add(rel);
    scanned.add(PermissionPlatform.macos);

    // Sandbox entitlements – must be in both Debug and Release.
    final ents = <String, Set<String>>{};
    for (final name in ['DebugProfile', 'Release']) {
      final f = File(_abs('macos/Runner/$name.entitlements'));
      if (!f.existsSync()) continue;
      files.add('macos/Runner/$name.entitlements');
      try {
        final m = parsePlist(f.readAsStringSync());
        ents[name] = {
          for (final e in m.entries)
            if (e.value == 'true') e.key,
        };
      } on PlistParseException catch (e) {
        issues.add(
          ScanIssue(
            IssueSeverity.error,
            'Cannot parse: $e',
            platform: PermissionPlatform.macos,
            file: 'macos/Runner/$name.entitlements',
          ),
        );
      }
    }

    for (final kind in PermissionKind.values.where(
      (k) => k.platforms.contains(PermissionPlatform.macos),
    )) {
      final d = kind.descriptor;
      final hasKey = d.iosKeys.any(plist.containsKey);
      final entNames = [
        for (final e in ents.entries)
          if (d.macosEntitlements.any(e.value.contains)) e.key,
      ];
      final hasEnt = entNames.isNotEmpty;

      if (hasKey || hasEnt) mark(kind, PermissionPlatform.macos);

      if (d.macosEntitlements.isNotEmpty && ents.isNotEmpty) {
        if (hasKey && !hasEnt) {
          issues.add(
            ScanIssue(
              IssueSeverity.warning,
              '${kind.name}: add ${d.macosEntitlements.first} to the macOS entitlements, the sandbox blocks it otherwise.',
              platform: PermissionPlatform.macos,
              kind: kind,
            ),
          );
        } else if (hasEnt && entNames.length < ents.length) {
          issues.add(
            ScanIssue(
              IssueSeverity.warning,
              '${kind.name}: entitlement is only in ${entNames.join(', ')} – add it to both DebugProfile and Release.',
              platform: PermissionPlatform.macos,
              kind: kind,
            ),
          );
        }
      }
      if (hasEnt && !hasKey && d.iosKeys.isNotEmpty) {
        issues.add(
          ScanIssue(
            IssueSeverity.warning,
            '${kind.name}: entitlement present but Info.plist lacks ${d.iosKeys.first}.',
            platform: PermissionPlatform.macos,
            kind: kind,
            file: rel,
          ),
        );
      }
    }
    return plist;
  }

  // ----------------------------------------------------------- cross checks
  void _crossCheck(
    Map<PermissionKind, Set<PermissionPlatform>> declared,
    List<ScanIssue> issues,
    Set<PermissionPlatform> scanned,
    Set<String>? android,
    Map<String, String>? ios,
    Map<String, String>? macos,
  ) {
    if (declared.containsKey(PermissionKind.locationAlways) &&
        !declared.containsKey(PermissionKind.location)) {
      issues.add(
        const ScanIssue(
          IssueSeverity.error,
          'Background location is declared but foreground location is not. Android 11+ and iOS require foreground access first.',
          kind: PermissionKind.locationAlways,
        ),
      );
    }

    for (final entry in declared.entries) {
      final kind = entry.key;
      for (final platform in scanned) {
        if (!kind.platforms.contains(platform)) continue;
        if (entry.value.contains(platform)) continue;
        // Macro-only permissions (notifications) can only be judged from the
        // iOS Podfile; without one we can't say they're missing.
        if (kind.descriptor.iosKeys.isEmpty &&
            kind.descriptor.podMacro != null &&
            (platform == PermissionPlatform.macos ||
                (platform == PermissionPlatform.ios &&
                    !File(_abs('ios/Podfile')).existsSync()))) {
          continue;
        }
        final hint = switch (platform) {
          PermissionPlatform.android =>
            'add ${kind.descriptor.android.isEmpty ? '(n/a)' : kind.descriptor.android.first} to AndroidManifest.xml',
          PermissionPlatform.ios || PermissionPlatform.macos =>
            kind.descriptor.iosKeys.isEmpty
                ? 'enable the Podfile macro ${kind.descriptor.podMacro}'
                : 'add ${kind.descriptor.iosKeys.first} to Info.plist',
          _ => 'declare it',
        };
        issues.add(
          ScanIssue(
            IssueSeverity.warning,
            '${kind.name} is declared on ${entry.value.map((e) => e.name).join(', ')} but not on ${platform.name}; the item will be hidden there. To enable it: $hint.',
            platform: platform,
            kind: kind,
          ),
        );
      }
    }
  }
}
