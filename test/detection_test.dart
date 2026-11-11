import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_permission_setup/play_permission_setup.dart';
import 'package:play_permission_setup/src/service/permission_detector.dart'
    show buildDetectionResult;

import 'helpers/fake_service.dart';

/// Scriptable detector.
class FakeDetector implements PermissionDetector {
  FakeDetector(this.declared, {this.error, this.completer});
  final DeclaredPermissions? declared;
  final Object? error;
  final Completer<DeclaredPermissions?>? completer;
  int calls = 0;

  @override
  Future<DeclaredPermissions?> detect() {
    calls++;
    if (error != null) return Future.error(error!);
    if (completer != null) return completer!.future;
    return Future.value(declared);
  }
}

/// Holds a value the test can change (stands in for app state).
class ValueCubit<T> extends Cubit<T> {
  ValueCubit(super.initial);
  void set(T v) => emit(v);
}

DeclaredPermissions android(Iterable<String> names) => DeclaredPermissions(
  platform: PermissionPlatform.android,
  androidPermissions: names.toSet(),
);

DeclaredPermissions ios(
  Iterable<String> keys, {
  Iterable<String> modes = const [],
}) => DeclaredPermissions(
  platform: PermissionPlatform.ios,
  iosKeys: keys.toSet(),
  backgroundModes: modes.toSet(),
);

List<PermissionKind> kinds(DetectionResult r) => [
  for (final i in r.items) i.kind,
];

DetectionResult build(
  DeclaredPermissions? d, {
  PermissionDetection config = const PermissionDetection(),
  PermissionPlatform platform = PermissionPlatform.android,
}) => buildDetectionResult(d, config, platform: platform);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('mapping declared permissions to items', () {
    test(
      'Android: full and short names both work, order follows the catalogue',
      () {
        final r = build(android(['android.permission.RECORD_AUDIO', 'CAMERA']));
        expect(kinds(r), [PermissionKind.camera, PermissionKind.microphone]);
        expect(r.scanned, isTrue);
      },
    );

    test('unknown, foreign and duplicate names are ignored', () {
      final r = build(
        android([
          'android.permission.INTERNET',
          'com.google.android.c2dm.permission.RECEIVE',
          'CAMERA',
          'android.permission.CAMERA',
          '',
        ]),
      );
      expect(kinds(r), [PermissionKind.camera]);
    });

    test('nothing declared -> empty list, still "scanned"', () {
      final r = build(android([]));
      expect(r.items, isEmpty);
      expect(r.scanned, isTrue);
    });

    test('partial Bluetooth is hidden with a warning, complete is shown', () {
      final partial = build(android(['BLUETOOTH_SCAN']));
      expect(partial.items, isEmpty);
      expect(partial.warnings.single, contains('BLUETOOTH_CONNECT'));
      final both = build(android(['BLUETOOTH_SCAN', 'BLUETOOTH_CONNECT']));
      expect(kinds(both), [PermissionKind.bluetooth]);
    });

    test('either location permission is enough', () {
      expect(kinds(build(android(['ACCESS_COARSE_LOCATION']))), [
        PermissionKind.location,
      ]);
    });

    test('background location without foreground adds location + warns', () {
      final r = build(android(['ACCESS_BACKGROUND_LOCATION']));
      expect(kinds(r), [
        PermissionKind.location,
        PermissionKind.locationAlways,
      ]);
      expect(r.warnings.single, contains('locationAlways'));
    });

    test('iOS uses Info.plist keys, ignores Android names', () {
      final r = build(
        DeclaredPermissions(
          platform: PermissionPlatform.ios,
          iosKeys: {'NSCameraUsageDescription'},
          androidPermissions: {'RECORD_AUDIO'},
        ),
        platform: PermissionPlatform.ios,
      );
      expect(kinds(r), [PermissionKind.camera]);
    });

    test('iOS: any one of several keys is enough', () {
      final r = build(
        ios(['NSCalendarsUsageDescription']),
        platform: PermissionPlatform.ios,
      );
      expect(kinds(r), [PermissionKind.calendar]);
    });

    test(
      'iOS notifications: detected via remote-notification, else include',
      () {
        expect(
          kinds(
            build(
              ios([], modes: ['remote-notification']),
              platform: PermissionPlatform.ios,
            ),
          ),
          [PermissionKind.notification],
        );
        expect(build(ios([]), platform: PermissionPlatform.ios).items, isEmpty);
        expect(
          kinds(
            build(
              ios([]),
              platform: PermissionPlatform.ios,
              config: const PermissionDetection(
                includeKinds: {PermissionKind.notification},
              ),
            ),
          ),
          [PermissionKind.notification],
        );
      },
    );

    test('desktop / web declarations produce nothing (cannot be scanned)', () {
      final r = build(
        const DeclaredPermissions(platform: PermissionPlatform.macos),
        platform: PermissionPlatform.macos,
      );
      expect(r.items, isEmpty);
    });
  });

  group('configuration', () {
    test('everything is optional by default', () {
      final r = build(android(['CAMERA', 'RECORD_AUDIO']));
      expect(r.items.every((i) => !i.isRequired), isTrue);
    });

    test('requiredKinds marks declared kinds required', () {
      final r = build(
        android(['CAMERA', 'RECORD_AUDIO']),
        config: const PermissionDetection(
          requiredKinds: {PermissionKind.camera},
        ),
      );
      expect(r.items[0].isRequired, isTrue);
      expect(r.items[1].isRequired, isFalse);
    });

    test('a required kind that is not declared is dropped with a warning', () {
      final r = build(
        android(['CAMERA']),
        config: const PermissionDetection(
          requiredKinds: {PermissionKind.microphone},
        ),
      );
      expect(kinds(r), [PermissionKind.camera]);
      expect(r.warnings.single, contains('microphone'));
    });

    test('excludeKinds beats declared and included', () {
      final r = build(
        android(['CAMERA', 'RECORD_AUDIO']),
        config: const PermissionDetection(
          excludeKinds: {PermissionKind.camera},
          includeKinds: {PermissionKind.camera},
        ),
      );
      expect(kinds(r), [PermissionKind.microphone]);
    });

    test('includeKinds ignores kinds the platform does not support', () {
      final r = build(
        ios([]),
        platform: PermissionPlatform.ios,
        config: const PermissionDetection(includeKinds: {PermissionKind.sms}),
      );
      expect(r.items, isEmpty);
    });

    test(
      'overrides keep your texts and own isRequired; requiredKinds wins',
      () {
        final r = build(
          android(['CAMERA', 'RECORD_AUDIO']),
          config: const PermissionDetection(
            overrides: {
              PermissionKind.camera: PermissionItem(
                kind: PermissionKind.camera,
                title: 'Scan receipts',
                description: 'Only for receipts.',
                isRequired: true,
              ),
              PermissionKind.microphone: PermissionItem(
                kind: PermissionKind.microphone,
                title: 'Voice notes',
                isRequired: true,
              ),
            },
            requiredKinds: {PermissionKind.microphone},
          ),
        );
        expect(r.items[0].title, 'Scan receipts');
        expect(r.items[0].description, 'Only for receipts.');
        expect(r.items[0].isRequired, isTrue);
        expect(r.items[1].title, 'Voice notes');
        expect(r.items[1].isRequired, isTrue);
      },
    );

    test('items only apply on the scanned platform', () {
      final r = build(android(['CAMERA']));
      expect(r.items.single.platforms, {PermissionPlatform.android});
    });

    test('an override with explicit platforms keeps them', () {
      final r = build(
        android(['CAMERA']),
        config: const PermissionDetection(
          overrides: {
            PermissionKind.camera: PermissionItem(
              kind: PermissionKind.camera,
              platforms: {PermissionPlatform.android, PermissionPlatform.ios},
            ),
          },
        ),
      );
      expect(r.items.single.platforms!.length, 2);
    });

    test('sameScanAs ignores callbacks, notices real changes', () {
      const a = PermissionDetection(requiredKinds: {PermissionKind.camera});
      final b = PermissionDetection(
        requiredKinds: {PermissionKind.camera},
        onResult: (_) {},
        logWarnings: false,
      );
      expect(a.sameScanAs(b), isTrue);
      expect(
        a.sameScanAs(
          const PermissionDetection(
            requiredKinds: {PermissionKind.camera, PermissionKind.microphone},
          ),
        ),
        isFalse,
      );
      expect(
        a.sameScanAs(PermissionDetection(detector: FakeDetector(null))),
        isFalse,
      );
    });
  });

  group('when scanning is not possible', () {
    test('null -> fallback items, scanned=false, with a warning', () {
      final r = build(
        null,
        config: const PermissionDetection(
          fallbackItems: [PermissionItem(kind: PermissionKind.camera)],
        ),
      );
      expect(r.scanned, isFalse);
      expect(kinds(r), [PermissionKind.camera]);
      expect(r.warnings, isNotEmpty);
    });

    test('null without fallback -> empty', () {
      expect(build(null).items, isEmpty);
    });

    test('a throwing detector never throws out of resolve()', () async {
      final r = await PermissionDetection(
        detector: FakeDetector(null, error: StateError('boom')),
      ).resolve(platform: PermissionPlatform.android);
      expect(r.scanned, isFalse);
      expect(r.warnings.join(), contains('boom'));
    });

    test('a hanging detector times out', () async {
      final r = await PermissionDetection(
        detector: FakeDetector(null, completer: Completer()),
        timeout: const Duration(milliseconds: 20),
        fallbackItems: const [PermissionItem(kind: PermissionKind.camera)],
      ).resolve(platform: PermissionPlatform.android);
      expect(r.scanned, isFalse);
      expect(kinds(r), [PermissionKind.camera]);
      expect(r.warnings.join(), contains('timed out'));
    });

    test('onResult is called exactly once', () async {
      var n = 0;
      await PermissionDetection(
        detector: FakeDetector(android(['CAMERA'])),
        onResult: (_) => n++,
        logWarnings: false,
      ).resolve();
      expect(n, 1);
    });

    test('detectPermissions() works as a one-liner', () async {
      final r = await detectPermissions(
        PermissionDetection(detector: FakeDetector(android(['CAMERA']))),
      );
      expect(kinds(r), [PermissionKind.camera]);
    });
  });

  group('native channel', () {
    const channel = MethodChannel('play_permission_setup/detector');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    test('parses what the native side returns', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      messenger.setMockMethodCallHandler(
        channel,
        (c) async => {
          'platform': 'android',
          'permissions': ['android.permission.CAMERA', 3, null, 'RECORD_AUDIO'],
        },
      );
      final d = await const PlatformPermissionDetector().detect();
      expect(d!.platform, PermissionPlatform.android);
      expect(d.androidShortNames, {'CAMERA', 'RECORD_AUDIO'});
      debugDefaultTargetPlatformOverride = null;
    });

    test('iOS payload', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      messenger.setMockMethodCallHandler(
        channel,
        (c) async => {
          'platform': 'ios',
          'keys': ['NSCameraUsageDescription'],
          'backgroundModes': ['remote-notification'],
        },
      );
      final d = await const PlatformPermissionDetector().detect();
      expect(d!.iosKeys, {'NSCameraUsageDescription'});
      expect(d.backgroundModes, {'remote-notification'});
      debugDefaultTargetPlatformOverride = null;
    });

    test(
      'missing plugin, platform error and null all mean "unknown"',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        // no handler -> MissingPluginException
        expect(await const PlatformPermissionDetector().detect(), isNull);
        messenger.setMockMethodCallHandler(
          channel,
          (c) async => throw PlatformException(code: 'scan_failed'),
        );
        expect(await const PlatformPermissionDetector().detect(), isNull);
        messenger.setMockMethodCallHandler(channel, (c) async => null);
        expect(await const PlatformPermissionDetector().detect(), isNull);
        debugDefaultTargetPlatformOverride = null;
      },
    );

    test('garbage payload does not crash', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      messenger.setMockMethodCallHandler(
        channel,
        (c) async => {'permissions': 'not a list', 'keys': 5},
      );
      final d = await const PlatformPermissionDetector().detect();
      expect(d!.androidPermissions, isEmpty);
      debugDefaultTargetPlatformOverride = null;
    });

    test('desktop never calls the channel', () async {
      var called = false;
      messenger.setMockMethodCallHandler(channel, (c) async {
        called = true;
        return {};
      });
      for (final p in [
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
      ]) {
        debugDefaultTargetPlatformOverride = p;
        expect(await const PlatformPermissionDetector().detect(), isNull);
      }
      expect(called, isFalse);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('the page scans by itself', () {
    Future<void> pumpPage(
      WidgetTester t, {
      required FakeDetector detector,
      FakeService? service,
      Set<PermissionKind> required = const {},
      List<PermissionItem> fallback = const [],
      void Function(PermissionSetupState)? onComplete,
      bool autoComplete = false,
      Key? key,
    }) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          home: PermissionSetupPage(
            key: key,
            service: service ?? FakeService(),
            onComplete: onComplete,
            autoCompleteWhenSatisfied: autoComplete,
            detection: PermissionDetection(
              detector: detector,
              requiredKinds: required,
              fallbackItems: fallback,
              logWarnings: false,
            ),
          ),
        ),
      );
    }

    testWidgets('shows exactly what the app declares, nothing static', (
      t,
    ) async {
      final d = FakeDetector(android(['CAMERA', 'ACCESS_FINE_LOCATION']));
      await pumpPage(t, detector: d);
      await t.pumpAndSettle();
      expect(find.byType(PermissionTile), findsNWidgets(2));
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Microphone'), findsNothing);
      expect(find.text('Contacts'), findsNothing);
    });

    testWidgets('shows a spinner while scanning, then the list', (t) async {
      final c = Completer<DeclaredPermissions?>();
      await pumpPage(t, detector: FakeDetector(null, completer: c));
      await t.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(PermissionTile), findsNothing);
      c.complete(android(['CAMERA']));
      await t.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Camera'), findsOneWidget);
    });

    testWidgets('platform cannot be scanned -> empty state', (t) async {
      await pumpPage(t, detector: FakeDetector(null));
      await t.pumpAndSettle();
      expect(find.text('Nothing to set up'), findsOneWidget);
    });

    testWidgets('platform cannot be scanned -> your fallback is shown', (
      t,
    ) async {
      await pumpPage(
        t,
        detector: FakeDetector(null),
        fallback: const [PermissionItem(kind: PermissionKind.camera)],
      );
      await t.pumpAndSettle();
      expect(find.text('Camera'), findsOneWidget);
    });

    testWidgets('a crashing detector shows the empty state, not an error', (
      t,
    ) async {
      await pumpPage(
        t,
        detector: FakeDetector(null, error: StateError('boom')),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('Nothing to set up'), findsOneWidget);
    });

    testWidgets('nothing declared -> empty state', (t) async {
      await pumpPage(t, detector: FakeDetector(android([])));
      await t.pumpAndSettle();
      expect(find.text('Nothing to set up'), findsOneWidget);
    });

    testWidgets('requiredKinds gates Continue until granted', (t) async {
      final s = FakeService();
      s.outcomes[PermissionKind.camera] = [PermissionGrant.granted];
      PermissionSetupState? done;
      await pumpPage(
        t,
        detector: FakeDetector(android(['CAMERA', 'RECORD_AUDIO'])),
        service: s,
        required: {PermissionKind.camera},
        onComplete: (st) => done = st,
      );
      await t.pumpAndSettle();
      expect(
        find.text('Continue'),
        findsNothing,
        reason: 'camera (required) is still missing',
      );
      expect(done, isNull);
      await t.tap(find.widgetWithText(FilledButton, 'Allow').first);
      await t.pumpAndSettle();
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(done, isNotNull);
    });

    testWidgets('autoCompleteWhenSatisfied works with scanned items', (
      t,
    ) async {
      PermissionSetupState? done;
      await pumpPage(
        t,
        detector: FakeDetector(android(['CAMERA'])),
        service: FakeService(
          initial: {PermissionKind.camera: PermissionGrant.granted},
        ),
        required: {PermissionKind.camera},
        autoComplete: true,
        onComplete: (st) => done = st,
      );
      await t.pumpAndSettle();
      expect(done, isNotNull);
    });

    testWidgets('a parent rebuild with an equal config does not rescan', (
      t,
    ) async {
      final d = FakeDetector(android(['CAMERA']));
      final host = ValueCubit<int>(0);
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          home: BlocBuilder<ValueCubit<int>, int>(
            bloc: host,
            builder: (_, n) => PermissionSetupPage(
              service: FakeService(),
              // a NEW (but equal) configuration object on every rebuild
              detection: PermissionDetection(
                detector: d,
                requiredKinds: const {PermissionKind.camera},
                logWarnings: false,
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      host.set(1);
      await t.pumpAndSettle();
      host.set(2);
      await t.pumpAndSettle();
      expect(d.calls, 1);
    });

    testWidgets('a changed configuration rescans', (t) async {
      final d = FakeDetector(android(['CAMERA']));
      final host = ValueCubit<Set<PermissionKind>>({});
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          home:
              BlocBuilder<ValueCubit<Set<PermissionKind>>, Set<PermissionKind>>(
                bloc: host,
                builder: (_, req) => PermissionSetupPage(
                  service: FakeService(),
                  detection: PermissionDetection(
                    detector: d,
                    requiredKinds: req,
                    logWarnings: false,
                  ),
                ),
              ),
        ),
      );
      await t.pumpAndSettle();
      host.set({PermissionKind.camera});
      await t.pumpAndSettle();
      expect(d.calls, 2);
    });

    testWidgets('leaving the page while it scans is safe', (t) async {
      final c = Completer<DeclaredPermissions?>();
      await pumpPage(t, detector: FakeDetector(null, completer: c));
      await t.pump();
      await t.pumpWidget(const MaterialApp(home: SizedBox()));
      c.complete(android(['CAMERA']));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('passing items still hard-codes the screen (no scan)', (
      t,
    ) async {
      final d = FakeDetector(android(['CAMERA']));
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          home: PermissionSetupPage(
            items: const [PermissionItem(kind: PermissionKind.contacts)],
            service: FakeService(),
            detection: PermissionDetection(detector: d),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(d.calls, 0);
      expect(find.text('Contacts'), findsOneWidget);
    });

    testWidgets('your own title and description are used', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          home: PermissionSetupPage(
            service: FakeService(),
            detection: PermissionDetection(
              detector: FakeDetector(android(['CAMERA'])),
              logWarnings: false,
              overrides: const {
                PermissionKind.camera: PermissionItem(
                  kind: PermissionKind.camera,
                  title: 'Scan receipts',
                  description: 'We only scan receipts.',
                ),
              },
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Scan receipts'), findsOneWidget);
      expect(find.text('We only scan receipts.'), findsOneWidget);
    });
  });
}
