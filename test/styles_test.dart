import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_permission_setup/play_permission_setup.dart';

import 'helpers/fake_service.dart';
import 'ui_test.dart' as base show bloc, closeBloc, items, pump;

void main() {
  workstationTests();
  final presets = {
    'crimson': PermissionSetupStyle.crimson,
    'clinical': PermissionSetupStyle.clinical,
  };
  final sizes = {
    'small phone': const Size(320, 568),
    'phone': const Size(390, 844),
    'tablet': const Size(768, 1024),
    'desktop': const Size(1440, 900),
    'tiny window': const Size(300, 300),
  };

  PermissionSetupPage Function(PermissionSetupBloc) page(
    PermissionSetupStyle style, {
    VoidCallback? toggle,
  }) =>
      (b) => PermissionSetupPage(
        items: base.items,
        bloc: b,
        style: style,
        onSkip: (_) {},
        onToggleTheme: toggle,
        brand: const PermissionSetupBrand(appName: 'Demo', badge: 'Setup'),
        strings: const PermissionSetupStrings(
          progressBadge: 'Secured',
          footerNote: 'Change this anytime in Settings.',
        ),
      );

  for (final p in presets.entries) {
    for (final s in sizes.entries) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('${p.key}: no overflow ${s.key} @ x$scale', (t) async {
          final b = base.bloc(
            FakeService(
              initial: {
                PermissionKind.photos: PermissionGrant.permanentlyDenied,
                PermissionKind.bluetooth: PermissionGrant.restricted,
                PermissionKind.contacts: PermissionGrant.limited,
              },
            ),
          );
          await base.pump(
            t,
            b,
            size: s.value,
            textScale: scale,
            page: page(p.value),
          );
          expect(t.takeException(), isNull);
          expect(find.text('Camera'), findsOneWidget);
          await base.closeBloc(t, b);
        });
      }
    }
  }

  testWidgets('crimson: dark theme uses the dark variant', (t) async {
    final b = base.bloc(FakeService());
    await base.pump(
      t,
      b,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      page: page(PermissionSetupStyle.crimson),
    );
    final scaffold = t.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFF121212));
    await base.closeBloc(t, b);
  });

  testWidgets('cards variant: Allow all lives in the section header', (
    t,
  ) async {
    final s = FakeService();
    final b = base.bloc(s);
    await base.pump(t, b, page: page(PermissionSetupStyle.crimson));
    expect(find.text('Allow all'), findsOneWidget);
    await t.tap(find.text('Allow all'));
    await t.pumpAndSettle();
    expect(s.requested, isNotEmpty);
    await base.closeBloc(t, b);
  });

  testWidgets('hero shows brand, progress card, toggle and footer note', (
    t,
  ) async {
    var toggled = 0;
    final b = base.bloc(FakeService());
    await base.pump(
      t,
      b,
      page: page(PermissionSetupStyle.clinical, toggle: () => toggled++),
    );
    expect(find.text('Demo'), findsOneWidget);
    expect(find.text('SETUP'), findsOneWidget);
    expect(find.text('SETUP PROGRESS'), findsOneWidget);
    expect(find.text('Secured'), findsOneWidget);
    expect(find.text('Change this anytime in Settings.'), findsOneWidget);
    await t.tap(
      find.byIcon(Icons.dark_mode_outlined).evaluate().isNotEmpty
          ? find.byIcon(Icons.dark_mode_outlined)
          : find.byIcon(Icons.wb_sunny_outlined),
    );
    expect(toggled, 1);
    await base.closeBloc(t, b);
  });

  testWidgets('desktop splits hero (left) and list (right)', (t) async {
    final b = base.bloc(FakeService());
    await base.pump(
      t,
      b,
      size: const Size(1440, 900),
      page: page(PermissionSetupStyle.crimson),
    );
    final hero = t.getTopLeft(find.text('Set up permissions')).dx;
    final list = t.getTopLeft(find.text('Camera')).dx;
    expect(list, greaterThan(hero + 300));
    await base.closeBloc(t, b);
  });

  testWidgets('everything is configurable via copyWith, flags and builders', (
    t,
  ) async {
    final b = base.bloc(FakeService());
    final style = PermissionSetupStyle.crimson.copyWith(
      accentColor: Colors.indigo,
      showIllustration: false,
      showSectionHeader: false,
      removeDark: true,
    );
    await base.pump(
      t,
      b,
      page: (b) => PermissionSetupPage(
        items: base.items,
        bloc: b,
        style: style,
        illustration: const SizedBox(key: ValueKey('mine')),
      ),
    );
    expect(find.byType(PermissionSetupIllustration), findsNothing);
    expect(find.byType(PermissionSectionHeader), findsNothing);
    expect(t.takeException(), isNull);
    await base.closeBloc(t, b);
  });
}

void workstationTests() {
  PermissionSetupPage Function(PermissionSetupBloc) wsPage({
    PermissionSetupStyle? style,
    PermissionSetupStyle? desktop,
  }) =>
      (b) => PermissionSetupPage(
        items: base.items,
        bloc: b,
        style: style ?? PermissionSetupStyle.workstation,
        desktopStyle: desktop,
        onSkip: (_) {},
        onToggleTheme: () {},
        brand: const PermissionSetupBrand(
          appName: 'Demo',
          chip: 'pkg v1',
          navItems: ['Overview', 'Permissions'],
        ),
        topBanner: PermissionSetupMetaBar(
          style: PermissionSetupStyle.workstation,
          leading: 'engine',
          trailing: 'session',
          trailingChip: 'bus',
        ),
        bottomBanner: PermissionSetupMetaBar(
          style: PermissionSetupStyle.workstation,
          leading: 'running',
        ),
        strings: const PermissionSetupStrings(
          title: "Let's get ready",
          titleHighlight: 'ready',
          heroBadge: 'Demo SETUP',
          stepLabel: 'STEP 1 / 2',
          progressTag: 'REQ',
          progressStatus: 'state: in progress',
          noteTitle: 'Private',
          noteBody: 'Nothing leaves your device.',
          allowAll: 'Grant All Missing',
          requiredChip: 'REQUIRED',
          continueLabel: 'Continue now',
          footerNote: 'Change anytime.',
        ),
      );

  final sizes = {
    'tablet': const Size(768, 1024),
    'laptop': const Size(1024, 768),
    'desktop': const Size(1440, 900),
    'ultrawide': const Size(3440, 1440),
    'phone': const Size(390, 844),
    'tiny window': const Size(300, 300),
  };
  for (final s in sizes.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('workstation: no overflow ${s.key} @ x$scale', (t) async {
        final b = base.bloc(
          FakeService(
            initial: {
              PermissionKind.photos: PermissionGrant.permanentlyDenied,
              PermissionKind.bluetooth: PermissionGrant.restricted,
              PermissionKind.contacts: PermissionGrant.limited,
            },
          ),
        );
        await base.pump(t, b, size: s.value, textScale: scale, page: wsPage());
        expect(t.takeException(), isNull);
        expect(find.text('Camera'), findsOneWidget);
        await base.closeBloc(t, b);
      });
    }
  }

  testWidgets('workstation shows counters, pill and inline status', (t) async {
    final b = base.bloc(FakeService());
    await base.pump(t, b, size: const Size(1440, 900), page: wsPage());
    expect(find.text('Grant All Missing'), findsOneWidget);
    expect(find.textContaining('REQUIRED'), findsWidgets);
    expect(find.text('Not allowed'), findsWidgets);
    expect(find.text('Tab'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    await base.closeBloc(t, b);
  });

  testWidgets('Enter continues when nothing else is focused', (t) async {
    final s = FakeService(
      initial: {for (final i in base.items) i.kind: PermissionGrant.granted},
    );
    PermissionSetupState? done;
    final b = base.bloc(s);
    await base.pump(
      t,
      b,
      size: const Size(1440, 900),
      page: (b) => PermissionSetupPage(
        items: base.items,
        bloc: b,
        style: PermissionSetupStyle.workstation,
        onComplete: (st) => done = st,
      ),
    );
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(done, isNotNull);
    await base.closeBloc(t, b);
  });

  for (final os in [
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  ]) {
    testWidgets('desktopStyle is used on $os, phone style on Android', (
      t,
    ) async {
      debugDefaultTargetPlatformOverride = os;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final b = base.bloc(FakeService());
      await base.pump(
        t,
        b,
        size: const Size(1440, 900),
        page: wsPage(
          style: PermissionSetupStyle.crimson,
          desktop: PermissionSetupStyle.workstation,
        ),
      );
      expect(find.byType(PermissionSetupWorkstationPanel), findsOneWidget);
      await base.closeBloc(t, b);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final b2 = base.bloc(FakeService());
      await base.pump(
        t,
        b2,
        size: const Size(1440, 900),
        page: wsPage(
          style: PermissionSetupStyle.crimson,
          desktop: PermissionSetupStyle.workstation,
        ),
      );
      expect(find.byType(PermissionSetupWorkstationPanel), findsNothing);
      await base.closeBloc(t, b2);
      debugDefaultTargetPlatformOverride =
          null; // must be reset before the test ends
    });
  }
}
