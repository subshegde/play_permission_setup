import 'package:flutter_test/flutter_test.dart';
import 'package:play_permission_setup/play_permission_setup.dart';

import 'helpers/fake_service.dart';

PermissionSetupBloc make(
  FakeService s,
  List<PermissionItem> items, {
  PermissionPlatform platform = PermissionPlatform.android,
  bool autoComplete = false,
}) => PermissionSetupBloc(
  items: items,
  service: s,
  platform: platform,
  autoRefreshOnResume: false,
  autoCompleteWhenSatisfied: autoComplete,
);

Future<PermissionSetupBloc> ready(PermissionSetupBloc b) async {
  await b.stream.firstWhere((s) => s.status == PermissionSetupStatus.ready);
  return b;
}

const cam = PermissionItem(kind: PermissionKind.camera);
const mic = PermissionItem(kind: PermissionKind.microphone, isRequired: false);
const loc = PermissionItem(kind: PermissionKind.location);
const bg = PermissionItem(
  kind: PermissionKind.locationAlways,
  isRequired: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads current statuses', () async {
    final s = FakeService(
      initial: {
        PermissionKind.camera: PermissionGrant.granted,
        PermissionKind.microphone: PermissionGrant.permanentlyDenied,
      },
    );
    final b = await ready(make(s, [cam, mic]));
    expect(
      b.state.entryOf(PermissionKind.camera)!.grant,
      PermissionGrant.granted,
    );
    expect(
      b.state.entryOf(PermissionKind.microphone)!.grant,
      PermissionGrant.permanentlyDenied,
    );
    expect(b.state.grantedCount, 1);
    await b.close();
  });

  test(
    'items not applicable on this platform are removed; duplicates dropped',
    () async {
      final s = FakeService();
      final b = await ready(
        make(s, [
          cam,
          cam,
          const PermissionItem(kind: PermissionKind.videos), // android only
          const PermissionItem(
            kind: PermissionKind.microphone,
            platforms: {PermissionPlatform.android},
          ),
        ], platform: PermissionPlatform.ios),
      );
      expect(
        [for (final e in b.state.entries) e.item.kind],
        [PermissionKind.camera],
      );
      await b.close();
    },
  );

  test('every item filtered out => empty state that can continue', () async {
    final b = await ready(
      make(FakeService(), [
        const PermissionItem(kind: PermissionKind.sms),
      ], platform: PermissionPlatform.windows),
    );
    expect(b.state.isEmpty, isTrue);
    expect(b.state.canContinue, isTrue);
    await b.close();
  });

  test('granting a permission updates state and counts attempts', () async {
    final s = FakeService();
    s.outcomes[PermissionKind.camera] = [PermissionGrant.granted];
    final b = await ready(make(s, [cam]));
    b.add(const PermissionRequested(PermissionKind.camera));
    await b.stream.firstWhere(
      (x) =>
          x.status == PermissionSetupStatus.ready &&
          x.entryOf(PermissionKind.camera)!.attempts == 1,
    );
    final e = b.state.entryOf(PermissionKind.camera)!;
    expect(e.grant, PermissionGrant.granted);
    expect(e.isRequesting, isFalse);
    expect(b.state.canContinue, isTrue);
    await b.close();
  });

  test('denied twice on Android => offers Settings', () async {
    final s = FakeService();
    s.outcomes[PermissionKind.camera] = [
      PermissionGrant.denied,
      PermissionGrant.denied,
    ];
    final b = await ready(make(s, [cam]));
    for (var i = 1; i <= 2; i++) {
      b.add(const PermissionRequested(PermissionKind.camera));
      await b.stream.firstWhere(
        (x) =>
            x.status == PermissionSetupStatus.ready &&
            x.entryOf(PermissionKind.camera)!.attempts == i,
      );
      if (i == 1) {
        expect(
          b.state.entryOf(PermissionKind.camera)!.shouldOpenSettings,
          isFalse,
        );
      }
    }
    expect(b.state.entryOf(PermissionKind.camera)!.shouldOpenSettings, isTrue);
    await b.close();
  });

  test(
    'dependent permission is locked and ordered after its dependency',
    () async {
      final s = FakeService();
      final b = await ready(make(s, [bg, loc])); // given in the wrong order
      expect(
        [for (final e in b.state.entries) e.item.kind],
        [PermissionKind.location, PermissionKind.locationAlways],
      );
      final always = b.state.entryOf(PermissionKind.locationAlways)!;
      expect(b.state.isLocked(always), isTrue);

      b.add(const PermissionRequested(PermissionKind.locationAlways));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(s.requested, isEmpty, reason: 'must not prompt while locked');
      await b.close();
    },
  );

  test('requestAll skips permanently denied / restricted / locked', () async {
    final s = FakeService(
      initial: {
        PermissionKind.camera: PermissionGrant.permanentlyDenied,
        PermissionKind.microphone: PermissionGrant.denied,
        PermissionKind.location: PermissionGrant.restricted,
      },
    );
    s.outcomes[PermissionKind.microphone] = [PermissionGrant.granted];
    final b = await ready(make(s, [cam, mic, loc, bg]));
    b.add(const PermissionAllRequested());
    await b.stream.firstWhere(
      (x) =>
          x.status == PermissionSetupStatus.ready &&
          x.entryOf(PermissionKind.microphone)!.grant ==
              PermissionGrant.granted,
    );
    expect(s.requested, [PermissionKind.microphone]);
    expect(b.state.blockedRequired.map((e) => e.item.kind), [
      PermissionKind.location,
    ]);
    expect(b.state.canContinue, isFalse);
    await b.close();
  });

  test('rapid duplicate taps open only one dialog', () async {
    final s = FakeService()..requestDelay = const Duration(milliseconds: 50);
    s.outcomes[PermissionKind.camera] = [PermissionGrant.granted];
    final b = await ready(make(s, [cam]));
    b
      ..add(const PermissionRequested(PermissionKind.camera))
      ..add(const PermissionRequested(PermissionKind.camera));
    await b.stream.firstWhere(
      (x) => x.entryOf(PermissionKind.camera)!.attempts >= 1,
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(s.requested.length, 1);
    await b.close();
  });

  test(
    'optional permissions do not block Continue; continue completes',
    () async {
      final s = FakeService(
        initial: {PermissionKind.camera: PermissionGrant.granted},
      );
      final b = await ready(make(s, [cam, mic]));
      expect(b.state.canContinue, isTrue);
      b.add(const PermissionSetupContinued());
      await b.stream.firstWhere(
        (x) => x.status == PermissionSetupStatus.completed,
      );

      // returning from Settings / resume must not undo "completed"
      b.add(const PermissionSetupRefreshed());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(b.state.status, PermissionSetupStatus.completed);
      await b.close();
    },
  );

  test('Continue is ignored while a required permission is missing', () async {
    final b = await ready(make(FakeService(), [cam]));
    b.add(const PermissionSetupContinued());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(b.state.status, PermissionSetupStatus.ready);
    await b.close();
  });

  test('autoCompleteWhenSatisfied completes straight away', () async {
    final s = FakeService(
      initial: {PermissionKind.camera: PermissionGrant.granted},
    );
    final b = make(s, [cam], autoComplete: true);
    await b.stream.firstWhere(
      (x) => x.status == PermissionSetupStatus.completed,
    );
    await b.close();
  });

  test('limited / provisional / notApplicable count as satisfied', () async {
    final s = FakeService(
      initial: {
        PermissionKind.camera: PermissionGrant.limited,
        PermissionKind.microphone: PermissionGrant.provisional,
        PermissionKind.location: PermissionGrant.notApplicable,
      },
    );
    final b = await ready(make(s, [cam, mic, loc]));
    expect(b.state.allGranted, isTrue);
    expect(
      b.state.entryOf(PermissionKind.camera)!.shouldOpenSettings,
      isTrue,
      reason: 'limited offers Manage',
    );
    await b.close();
  });

  test('GPS off while granted is surfaced', () async {
    final s = FakeService(
      initial: {PermissionKind.location: PermissionGrant.granted},
    )..serviceOff.add(PermissionKind.location);
    final b = await ready(make(s, [loc]));
    final e = b.state.entryOf(PermissionKind.location)!;
    expect(e.isSatisfied, isTrue);
    expect(e.serviceDisabled, isTrue);
    expect(e.shouldOpenSettings, isTrue);
    await b.close();
  });

  test('check failure becomes a per-item error, retry recovers', () async {
    final s = FakeService()..throwOnCheck = StateError('boom');
    final b = await ready(make(s, [cam]));
    expect(b.state.entryOf(PermissionKind.camera)!.error, isNotNull);
    expect(
      b.state.entryOf(PermissionKind.camera)!.grant,
      PermissionGrant.unknown,
    );

    s.throwOnCheck = null;
    b.add(const PermissionSetupRefreshed());
    await b.stream.firstWhere(
      (x) => x.entryOf(PermissionKind.camera)!.error == null,
    );
    expect(
      b.state.entryOf(PermissionKind.camera)!.grant,
      PermissionGrant.denied,
    );
    await b.close();
  });

  test('request failure does not leave the page stuck "requesting"', () async {
    final s = FakeService()..throwOnRequest = StateError('boom');
    final b = await ready(make(s, [cam]));
    b.add(const PermissionRequested(PermissionKind.camera));
    await b.stream.firstWhere(
      (x) =>
          x.status == PermissionSetupStatus.ready &&
          x.entryOf(PermissionKind.camera)!.error != null,
    );
    expect(b.state.entryOf(PermissionKind.camera)!.isRequesting, isFalse);
    await b.close();
  });

  test('skip emits skipped', () async {
    final b = await ready(make(FakeService(), [cam]));
    b.add(const PermissionSetupSkipped());
    await b.stream.firstWhere((x) => x.status == PermissionSetupStatus.skipped);
    await b.close();
  });

  test('closing the bloc mid-request does not throw', () async {
    final s = FakeService()..requestDelay = const Duration(milliseconds: 30);
    final b = await ready(make(s, [cam]));
    b.add(const PermissionRequested(PermissionKind.camera));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await b.close();
    await Future<void>.delayed(const Duration(milliseconds: 60));
  });

  test('combine() aggregates multi-permission kinds (bluetooth)', () {
    G(Iterable<PermissionGrant> g) => PermissionHandlerService.combine(g);
    expect(
      G([PermissionGrant.granted, PermissionGrant.granted]),
      PermissionGrant.granted,
    );
    expect(
      G([PermissionGrant.granted, PermissionGrant.denied]),
      PermissionGrant.denied,
    );
    expect(
      G([PermissionGrant.denied, PermissionGrant.permanentlyDenied]),
      PermissionGrant.permanentlyDenied,
    );
    expect(
      G([PermissionGrant.granted, PermissionGrant.restricted]),
      PermissionGrant.restricted,
    );
    expect(G(const []), PermissionGrant.notApplicable);
  });
}
