// Regenerates screenshots/*.png (used by pub.dev and the README).
//
//   flutter test tool/generate_screenshots_test.dart
//
// Uses the fonts shipped with your Flutter SDK so text and icons render.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_permission_setup/play_permission_setup.dart';

import '../test/helpers/fake_service.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(
      Future.value(
        ByteData.sublistView(
          File('$root/bin/cache/artifacts/material_fonts/$f').readAsBytesSync(),
        ),
      ),
    );
  }
  await loader.load();
}

void main() {
  const items = [
    PermissionItem(kind: PermissionKind.camera),
    PermissionItem(kind: PermissionKind.location),
    PermissionItem(kind: PermissionKind.locationAlways, isRequired: false),
    PermissionItem(kind: PermissionKind.photos, isRequired: false),
    PermissionItem(kind: PermissionKind.microphone, isRequired: false),
    PermissionItem(kind: PermissionKind.bluetooth, isRequired: false),
    PermissionItem(kind: PermissionKind.notification, isRequired: false),
    PermissionItem(kind: PermissionKind.contacts, isRequired: false),
  ];
  final shots = {
    'phone': (const Size(390, 844), Brightness.light),
    'tablet': (const Size(820, 1100), Brightness.light),
    'desktop': (const Size(1440, 700), Brightness.light),
    'desktop_dark': (const Size(1440, 700), Brightness.dark),
  };
  for (final e in shots.entries) {
    testWidgets('screenshot ${e.key}', (t) async {
      await _loadFont('Roboto', ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']);
      await _loadFont('MaterialIcons', ['MaterialIcons-Regular.otf']);
      t.view.physicalSize = e.value.$1;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final bloc = PermissionSetupBloc(
        items: items,
        service: FakeService(
          initial: {
            PermissionKind.camera: PermissionGrant.granted,
            PermissionKind.microphone: PermissionGrant.permanentlyDenied,
            PermissionKind.photos: PermissionGrant.limited,
          },
        ),
        platform: PermissionPlatform.android,
        autoRefreshOnResume: false,
      );
      final key = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorSchemeSeed: Colors.indigo,
              brightness: e.value.$2,
              useMaterial3: true,
              fontFamily: 'Roboto',
            ),
            home: PermissionSetupPage(items: items, bloc: bloc, onSkip: (_) {}),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        File(
          'screenshots/${e.key}.png',
        ).writeAsBytesSync(bytes.buffer.asUint8List());
      });
      bloc.close();
      await t.pump();
    });
  }
}
