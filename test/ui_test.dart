import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_permission_setup/play_permission_setup.dart';

import 'helpers/fake_service.dart';

const items = [
  PermissionItem(kind: PermissionKind.camera),
  PermissionItem(kind: PermissionKind.microphone, isRequired: false),
  PermissionItem(kind: PermissionKind.location),
  PermissionItem(kind: PermissionKind.locationAlways, isRequired: false),
  PermissionItem(kind: PermissionKind.photos, isRequired: false),
  PermissionItem(kind: PermissionKind.bluetooth, isRequired: false),
  PermissionItem(kind: PermissionKind.notification, isRequired: false),
  PermissionItem(kind: PermissionKind.contacts, isRequired: false),
];

PermissionSetupBloc bloc(FakeService s, {List<PermissionItem> list = items}) =>
    PermissionSetupBloc(
      items: list,
      service: s,
      platform: PermissionPlatform.android,
      autoRefreshOnResume: false,
    );

Future<void> pump(
  WidgetTester t,
  PermissionSetupBloc b, {
  Size size = const Size(390, 844),
  double textScale = 1,
  TextDirection dir = TextDirection.ltr,
  ThemeData? theme,
  PermissionSetupPage Function(PermissionSetupBloc)? page,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: theme ?? ThemeData(useMaterial3: true),
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(
          c,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Directionality(textDirection: dir, child: child!),
      ),
      home: page != null
          ? page(b)
          : PermissionSetupPage(items: items, bloc: b, onSkip: (_) {}),
    ),
  );
  await t.pumpAndSettle();
}

/// Blocs live in the fake-async zone: start closing, then pump to flush.
Future<void> closeBloc(WidgetTester t, PermissionSetupBloc b) async {
  b.close();
  await t.pump();
}

void main() {
  final sizes = <String, Size>{
    'small phone': const Size(320, 568),
    'phone': const Size(390, 844),
    'phone landscape': const Size(844, 390),
    'tablet portrait': const Size(768, 1024),
    'tablet landscape': const Size(1180, 820),
    'desktop': const Size(1440, 900),
    'ultrawide': const Size(3440, 1440),
    'tiny window': const Size(300, 300),
  };

  for (final e in sizes.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('no overflow: ${e.key} @ text x$scale', (t) async {
        final b = bloc(FakeService());
        await pump(t, b, size: e.value, textScale: scale);
        expect(t.takeException(), isNull);
        expect(find.text('Camera'), findsOneWidget);
        await closeBloc(t, b);
      });
    }
  }

  testWidgets('picks layout from available width', (t) async {
    const style = PermissionSetupStyle();
    expect(style.layoutFor(390), PermissionSetupLayout.compact);
    expect(style.layoutFor(768), PermissionSetupLayout.medium);
    expect(style.layoutFor(1440), PermissionSetupLayout.expanded);
  });

  testWidgets('desktop shows two columns, centred and capped', (t) async {
    final b = bloc(FakeService());
    await pump(t, b, size: const Size(1440, 900));
    final first = t.getTopLeft(find.text('Camera')).dx;
    final last = t.getTopLeft(find.text('Contacts')).dx;
    expect(last, greaterThan(first + 300), reason: 'second column');
    // content is centred, not glued to the left edge
    expect(first, greaterThan(150));
    await closeBloc(t, b);
  });

  testWidgets('tablet keeps one readable column', (t) async {
    final b = bloc(FakeService());
    await pump(t, b, size: const Size(800, 1000));
    expect(
      t.getTopLeft(find.text('Camera')).dx,
      t.getTopLeft(find.text('Microphone')).dx,
    );
    final width = t.getSize(find.byType(PermissionTile).first).width;
    expect(width, lessThanOrEqualTo(640));
    await closeBloc(t, b);
  });

  testWidgets('phone: tap Allow requests and shows Allowed', (t) async {
    final s = FakeService();
    s.outcomes[PermissionKind.camera] = [PermissionGrant.granted];
    final b = bloc(s);
    await pump(t, b);
    await t.tap(find.widgetWithText(FilledButton, 'Allow').first);
    await t.pumpAndSettle();
    expect(s.requested, [PermissionKind.camera]);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    await closeBloc(t, b);
  });

  testWidgets('permanently denied shows Open settings and calls the service', (
    t,
  ) async {
    final s = FakeService(
      initial: {PermissionKind.camera: PermissionGrant.permanentlyDenied},
    );
    final b = bloc(s, list: [items.first]);
    await pump(t, b);
    expect(find.textContaining('Turned off'), findsOneWidget);
    await t.tap(find.widgetWithText(OutlinedButton, 'Settings'));
    await t.pumpAndSettle();
    expect(s.settingsOpened, 1);
    await closeBloc(t, b);
  });

  testWidgets('restricted explains itself and offers no Allow button', (
    t,
  ) async {
    final s = FakeService(
      initial: {PermissionKind.camera: PermissionGrant.restricted},
    );
    final b = bloc(s, list: [items.first]);
    await pump(t, b);
    expect(find.textContaining('Restricted by device policy'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Allow'), findsNothing);
    expect(find.textContaining('restricted on this device'), findsOneWidget);
    await closeBloc(t, b);
  });

  testWidgets('locked background location explains what to do first', (
    t,
  ) async {
    final b = bloc(FakeService());
    await pump(t, b);
    expect(find.textContaining('Allow “Location” first'), findsOneWidget);
    await closeBloc(t, b);
  });

  testWidgets(
    'Continue disabled until required items are granted; then fires onComplete',
    (t) async {
      final s = FakeService(
        initial: {
          PermissionKind.camera: PermissionGrant.granted,
          PermissionKind.location: PermissionGrant.granted,
        },
      );
      PermissionSetupState? done;
      final b = bloc(s);
      await pump(
        t,
        b,
        page: (b) => PermissionSetupPage(
          items: items,
          bloc: b,
          onComplete: (st) => done = st,
        ),
      );
      await t.tap(find.widgetWithText(FilledButton, 'Continue'));
      await t.pumpAndSettle();
      expect(done, isNotNull);
      await closeBloc(t, b);
    },
  );

  testWidgets('Skip button only when onSkip given', (t) async {
    final b = bloc(FakeService());
    await pump(
      t,
      b,
      page: (b) => PermissionSetupPage(items: items, bloc: b),
    );
    expect(find.text('Skip'), findsNothing);
    await closeBloc(t, b);
  });

  testWidgets('Skip is in the header and fires onSkip', (t) async {
    PermissionSetupState? skipped;
    final b = bloc(FakeService());
    await pump(
      t,
      b,
      page: (b) => PermissionSetupPage(
        items: items,
        bloc: b,
        onSkip: (st) => skipped = st,
      ),
    );
    await t.tap(find.widgetWithText(TextButton, 'Skip'));
    await t.pumpAndSettle();
    expect(skipped, isNotNull);
    await closeBloc(t, b);
  });

  testWidgets(
    'rows stay compact (10 permissions fit a phone screen height ×2)',
    (t) async {
      final b = bloc(FakeService());
      await pump(t, b, size: const Size(390, 844));
      final h = t.getSize(find.byType(PermissionTile).first).height;
      expect(h, lessThan(96));
      await closeBloc(t, b);
    },
  );

  testWidgets('empty (nothing applicable) shows the empty state', (t) async {
    final b = PermissionSetupBloc(
      items: items,
      service: FakeService(),
      platform: PermissionPlatform.linux,
      autoRefreshOnResume: false,
    );
    await pump(t, b);
    expect(find.text('Nothing to set up'), findsOneWidget);
    await closeBloc(t, b);
  });

  testWidgets('custom strings, itemBuilder and headerBuilder are honoured', (
    t,
  ) async {
    final b = bloc(FakeService(), list: [items.first]);
    await pump(
      t,
      b,
      page: (b) => PermissionSetupPage(
        items: const [PermissionItem(kind: PermissionKind.camera)],
        bloc: b,
        strings: const PermissionSetupStrings(allowAll: 'Erlauben'),
        headerBuilder: (c, s, l) => Text('MY HEADER ${l.name}'),
        itemBuilder: (c, e, s, a) => ElevatedButton(
          onPressed: () => a.request(e.item.kind),
          child: Text('custom ${e.item.kind.name}'),
        ),
      ),
    );
    expect(find.text('MY HEADER compact'), findsOneWidget);
    expect(find.text('custom camera'), findsOneWidget);
    expect(find.text('Erlauben'), findsOneWidget);
    await closeBloc(t, b);
  });

  testWidgets('PermissionSetupBuilder gives full control', (t) async {
    final s = FakeService();
    await t.pumpWidget(
      MaterialApp(
        home: PermissionSetupBuilder(
          items: const [PermissionItem(kind: PermissionKind.camera)],
          service: s,
          builder: (c, state, actions) => Column(
            children: [
              Text('n=${state.total}'),
              TextButton(
                onPressed: actions.requestAll,
                child: const Text('go'),
              ),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('n=1'), findsOneWidget);
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(s.requested, isNotEmpty);
  });

  testWidgets('works unbounded inside a scroll view', (t) async {
    final b = bloc(FakeService());
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PermissionSetupBuilder(
              bloc: b,
              builder: (c, state, actions) =>
                  PermissionSetupView(state: state, actions: actions),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Camera'), findsOneWidget);
    await closeBloc(t, b);
  });

  testWidgets('RTL and dark theme render without errors', (t) async {
    final b = bloc(FakeService());
    await pump(
      t,
      b,
      size: const Size(1280, 800),
      dir: TextDirection.rtl,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
    );
    expect(t.takeException(), isNull);
    await closeBloc(t, b);
  });

  group('explainBeforeAsk', () {
    Future<void> open(WidgetTester t, FakeService svc, bool explain) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          home: PermissionSetupPage(
            items: const [
              PermissionItem(
                kind: PermissionKind.camera,
                description: 'Scan your receipts.',
              ),
            ],
            service: svc,
            explainBeforeAsk: explain,
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('shows the reason first; Continue then asks', (t) async {
      final s = FakeService();
      await open(t, s, true);
      await t.tap(find.widgetWithText(FilledButton, 'Allow').first);
      // The row's spinner keeps animating while the dialog is open.
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Scan your receipts.'), findsWidgets);
      expect(s.requested, isEmpty);
      await t.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Continue'),
        ),
      );
      await t.pumpAndSettle();
      expect(s.requested, [PermissionKind.camera]);
    });

    testWidgets('Not now asks nothing', (t) async {
      final s = FakeService();
      await open(t, s, true);
      await t.tap(find.widgetWithText(FilledButton, 'Allow').first);
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.widgetWithText(TextButton, 'Not now'));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(s.requested, isEmpty);
    });

    testWidgets('off by default: no explanation dialog', (t) async {
      final s = FakeService();
      await open(t, s, false);
      await t.tap(find.widgetWithText(FilledButton, 'Allow').first);
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(s.requested, [PermissionKind.camera]);
    });
  });

  group('wizard', () {
    const wItems = [
      PermissionItem(kind: PermissionKind.camera),
      PermissionItem(kind: PermissionKind.microphone, isRequired: false),
    ];

    Future<List<String>> open(
      WidgetTester t,
      FakeService svc, {
      bool wizard = true,
      bool skipAll = false,
    }) async {
      final events = <String>[];
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          home: PermissionSetupPage(
            items: wItems,
            service: svc,
            wizard: wizard,
            onComplete: (_) => events.add('complete'),
            onSkip: skipAll ? (_) => events.add('skip') : null,
          ),
        ),
      );
      await t.pumpAndSettle();
      return events;
    }

    testWidgets('shows one permission per screen with the step count', (
      t,
    ) async {
      await open(t, FakeService());
      expect(find.text('Step 1 of 2'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Microphone'), findsNothing);
    });

    testWidgets('Allow asks, and a grant moves on by itself', (t) async {
      final s = FakeService();
      s.outcomes[PermissionKind.camera] = [PermissionGrant.granted];
      await open(t, s);
      await t.tap(find.widgetWithText(FilledButton, 'Allow'));
      await t.pumpAndSettle();
      expect(s.requested, [PermissionKind.camera]);
      expect(find.text('Step 2 of 2'), findsOneWidget);
      expect(find.text('Microphone'), findsOneWidget);
    });

    testWidgets('Skip goes on, Back returns', (t) async {
      final s = FakeService();
      await open(t, s);
      await t.tap(find.widgetWithText(TextButton, 'Skip'));
      await t.pumpAndSettle();
      expect(find.text('Step 2 of 2'), findsOneWidget);
      expect(s.requested, isEmpty);
      await t.tap(find.widgetWithText(TextButton, 'Back'));
      await t.pumpAndSettle();
      expect(find.text('Step 1 of 2'), findsOneWidget);
    });

    testWidgets('last step: missing required blocks Continue, Review jumps', (
      t,
    ) async {
      await open(t, FakeService());
      await t.tap(find.widgetWithText(TextButton, 'Skip')); // camera skipped
      await t.pumpAndSettle();
      expect(
        find.text('Some required permissions are still missing.'),
        findsOneWidget,
      );
      // Skipping can't finish the flow while a required one is missing.
      expect(find.widgetWithText(TextButton, 'Skip'), findsNothing);
      await t.tap(find.widgetWithText(TextButton, 'Review missing'));
      await t.pumpAndSettle();
      expect(find.text('Step 1 of 2'), findsOneWidget);
    });

    testWidgets('finishes with Continue once required are granted', (t) async {
      final s = FakeService();
      s.outcomes[PermissionKind.camera] = [PermissionGrant.granted];
      final events = await open(t, s);
      await t.tap(find.widgetWithText(FilledButton, 'Allow'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(TextButton, 'Skip')); // optional mic
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(TextButton, 'Skip'));
      await t.pumpAndSettle();
      expect(events, ['complete']);
    });

    testWidgets('Skip setup ends the whole flow', (t) async {
      final events = await open(t, FakeService(), skipAll: true);
      await t.tap(find.text('Skip setup'));
      await t.pumpAndSettle();
      expect(events, ['skip']);
    });

    testWidgets('permanently denied shows Settings', (t) async {
      final s = FakeService(
        initial: {PermissionKind.camera: PermissionGrant.permanentlyDenied},
      );
      await open(t, s);
      await t.tap(find.widgetWithText(FilledButton, 'Settings'));
      await t.pumpAndSettle();
      expect(s.settingsOpened, 1);
      expect(s.requested, isEmpty);
    });

    testWidgets('off by default: the list is shown', (t) async {
      await open(t, FakeService(), wizard: false);
      expect(find.textContaining('Step 1 of'), findsNothing);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Microphone'), findsOneWidget);
    });
  });
}
