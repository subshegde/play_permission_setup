import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/permission_kind.dart';
import '../models/permission_item.dart';
import '../models/platform.dart';

/// What the installed app really declares, as reported by the platform.
///
/// * Android: the merged manifest's `uses-permission` names
///   (`android.permission.CAMERA` or just `CAMERA`).
/// * iOS: the `Info.plist` usage-description keys that have a non-blank text,
///   and the `UIBackgroundModes` entries.
class DeclaredPermissions {
  const DeclaredPermissions({
    required this.platform,
    this.androidPermissions = const {},
    this.iosKeys = const {},
    this.backgroundModes = const {},
  });

  final PermissionPlatform platform;
  final Set<String> androidPermissions;
  final Set<String> iosKeys;
  final Set<String> backgroundModes;

  /// Android names without the `android.permission.` prefix.
  Set<String> get androidShortNames => {
    for (final n in androidPermissions)
      n.startsWith('android.permission.')
          ? n.substring('android.permission.'.length)
          : n,
  };
}

/// Reads what the app declares. Replace it to fake the platform in tests or to
/// support another platform.
abstract class PermissionDetector {
  /// `null` when the platform cannot tell (web, desktop, plugin missing).
  Future<DeclaredPermissions?> detect();
}

/// Default detector: asks the small native part of this package.
class PlatformPermissionDetector implements PermissionDetector {
  const PlatformPermissionDetector();

  static const _channel = MethodChannel('play_permission_setup/detector');

  @override
  Future<DeclaredPermissions?> detect() async {
    if (kIsWeb) return null;
    final platform = currentPermissionPlatform();
    if (platform != PermissionPlatform.android &&
        platform != PermissionPlatform.ios) {
      return null;
    }
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('declared');
      if (raw == null) return null;
      Set<String> strings(Object? v) =>
          v is Iterable ? {...v.whereType<String>()} : <String>{};
      return DeclaredPermissions(
        platform: platform,
        androidPermissions: strings(raw['permissions']),
        iosKeys: strings(raw['keys']),
        backgroundModes: strings(raw['backgroundModes']),
      );
    } on MissingPluginException {
      return null; // plugin not registered (e.g. an unsupported embedding)
    } on PlatformException {
      return null;
    }
  }
}

/// How the list is built from what the app declares.
class PermissionDetection {
  const PermissionDetection({
    this.requiredKinds = const {},
    this.excludeKinds = const {},
    this.includeKinds = const {},
    this.overrides = const {},
    this.fallbackItems = const [],
    this.detector = const PlatformPermissionDetector(),
    this.timeout = const Duration(seconds: 5),
    this.onResult,
    this.logWarnings = true,
  });

  /// Detected kinds that block *Continue* until granted. Everything else is
  /// optional. A kind that is not declared is never required (it cannot be
  /// requested); you get a warning instead.
  final Set<PermissionKind> requiredKinds;

  /// Kinds to hide even though they are declared.
  final Set<PermissionKind> excludeKinds;

  /// Kinds to show even when the platform cannot reveal them as declared (for
  /// example iOS notifications, which have no `Info.plist` key).
  final Set<PermissionKind> includeKinds;

  /// Your own title / description / icon / rationale for a kind. Its
  /// `isRequired` is kept unless the kind is in [requiredKinds].
  final Map<PermissionKind, PermissionItem> overrides;

  /// Used when the platform cannot be scanned (web, desktop). Empty by default,
  /// which shows the "nothing to set up" state.
  final List<PermissionItem> fallbackItems;

  /// Reads the declared permissions.
  final PermissionDetector detector;

  /// Gives up scanning after this long and uses [fallbackItems].
  final Duration timeout;

  /// Called once with the outcome (for logging or analytics).
  final void Function(DetectionResult result)? onResult;

  /// Print [DetectionResult.warnings] in debug mode.
  final bool logWarnings;

  /// Whether scanning with [other] would give the same list. Callbacks
  /// ([onResult]) and [logWarnings] are ignored on purpose, so a parent that
  /// builds a new `PermissionDetection(...)` on every rebuild does not rescan.
  bool sameScanAs(PermissionDetection other) =>
      identical(this, other) ||
      (setEquals(requiredKinds, other.requiredKinds) &&
          setEquals(excludeKinds, other.excludeKinds) &&
          setEquals(includeKinds, other.includeKinds) &&
          mapEquals(overrides, other.overrides) &&
          listEquals(fallbackItems, other.fallbackItems) &&
          identical(detector, other.detector) &&
          timeout == other.timeout);

  /// A value that changes exactly when a different scan would be needed (same
  /// fields as [sameScanAs]). Used as a widget key so a changed configuration
  /// rescans while an equal one does not.
  int get scanHash => Object.hash(
    Object.hashAllUnordered(requiredKinds),
    Object.hashAllUnordered(excludeKinds),
    Object.hashAllUnordered(includeKinds),
    Object.hashAllUnordered(
      overrides.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAll(fallbackItems),
    identityHashCode(detector),
    timeout,
  );

  /// Scans and builds the items. Never throws.
  Future<DetectionResult> resolve({PermissionPlatform? platform}) async {
    DeclaredPermissions? declared;
    final warnings = <String>[];
    try {
      declared = await detector.detect().timeout(timeout);
    } on TimeoutException {
      warnings.add('Scanning timed out after $timeout.');
    } catch (e) {
      warnings.add('Scanning failed: $e');
    }
    final result = buildDetectionResult(
      declared,
      this,
      platform: platform ?? declared?.platform ?? currentPermissionPlatform(),
      warnings: warnings,
    );
    if (logWarnings && kDebugMode) {
      for (final w in result.warnings) {
        debugPrint('play_permission_setup: $w');
      }
    }
    onResult?.call(result);
    return result;
  }
}

/// Outcome of a scan.
class DetectionResult {
  const DetectionResult({
    required this.items,
    required this.warnings,
    required this.scanned,
    required this.platform,
    this.declaredKinds = const {},
  });

  /// What the page will show.
  final List<PermissionItem> items;

  /// Things worth fixing (partial Bluetooth, required but undeclared, ...).
  final List<String> warnings;

  /// `false` when the platform could not be scanned and [items] are the
  /// fallback.
  final bool scanned;

  final PermissionPlatform platform;

  /// Every kind found in the platform files (before include / exclude).
  final Set<PermissionKind> declaredKinds;
}

/// Pure function behind [PermissionDetection.resolve]; exposed for testing.
@visibleForTesting
DetectionResult buildDetectionResult(
  DeclaredPermissions? declared,
  PermissionDetection config, {
  required PermissionPlatform platform,
  List<String> warnings = const [],
}) {
  final warn = [...warnings];

  if (declared == null) {
    return DetectionResult(
      items: [...config.fallbackItems],
      warnings: [
        ...warn,
        'The platform could not be scanned; using the fallback items '
            '(${config.fallbackItems.length}).',
      ],
      scanned: false,
      platform: platform,
    );
  }

  final found = <PermissionKind>{};
  final android = declared.androidShortNames;

  for (final kind in PermissionKind.values) {
    final d = kind.descriptor;
    switch (declared.platform) {
      case PermissionPlatform.android:
        if (d.android.isEmpty) continue;
        final present = d.android.where(android.contains).toList();
        if (present.isEmpty) continue;
        if (d.androidAllRequired && present.length != d.android.length) {
          final missing = d.android.where((n) => !present.contains(n));
          warn.add(
            '${kind.name}: AndroidManifest declares ${present.join(', ')} '
            'but not ${missing.join(', ')}; hidden because it would not work.',
          );
          continue;
        }
        found.add(kind);
      case PermissionPlatform.ios:
        final hasKey = d.iosKeys.any(declared.iosKeys.contains);
        final isPush =
            kind == PermissionKind.notification &&
            declared.backgroundModes.contains('remote-notification');
        if (hasKey || isPush) found.add(kind);
      default:
        break;
    }
  }

  // Background location is useless (and unrequestable) without foreground.
  if (found.contains(PermissionKind.locationAlways) &&
      !found.contains(PermissionKind.location)) {
    found.add(PermissionKind.location);
    warn.add(
      'locationAlways is declared without location; location was added '
      'because it has to be granted first.',
    );
  }

  final shown = <PermissionKind>{
    ...found,
    for (final k in config.includeKinds)
      if (k.platforms.contains(platform)) k,
  }..removeAll(config.excludeKinds);

  for (final k in config.requiredKinds) {
    if (!shown.contains(k)) {
      warn.add(
        '${k.name} is marked required but is not declared on '
        '${platform.name}; it will not be shown.',
      );
    }
  }

  final items = <PermissionItem>[];
  for (final kind in PermissionKind.values) {
    if (!shown.contains(kind)) continue;
    final base = config.overrides[kind] ?? PermissionItem(kind: kind);
    final isRequired = config.requiredKinds.contains(kind)
        ? true
        : (config.overrides.containsKey(kind) ? base.isRequired : false);
    items.add(
      PermissionItem(
        kind: kind,
        title: base.title,
        description: base.description,
        rationale: base.rationale,
        icon: base.icon,
        isRequired: isRequired,
        platforms: base.platforms ?? {platform},
      ),
    );
  }

  return DetectionResult(
    items: items,
    warnings: warn,
    scanned: true,
    platform: platform,
    declaredKinds: found,
  );
}

/// Scans the running app and returns what the page would show. Use it to build
/// a custom UI around `PermissionSetupBuilder`:
///
/// ```dart
/// final result = await detectPermissions();
/// PermissionSetupBuilder(items: result.items, builder: ...)
/// ```
Future<DetectionResult> detectPermissions([
  PermissionDetection config = const PermissionDetection(),
]) => config.resolve();
