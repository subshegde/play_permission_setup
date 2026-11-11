// Renders the preset looks to PNGs:
//
//   flutter test tool/preview_test.dart            (writes to screenshots/)
//   PREVIEW_DIR=/some/dir flutter test tool/preview_test.dart
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
    PermissionItem(kind: PermissionKind.notification),
    PermissionItem(kind: PermissionKind.microphone),
    PermissionItem(kind: PermissionKind.location),
    PermissionItem(kind: PermissionKind.photos),
    PermissionItem(kind: PermissionKind.bluetooth, isRequired: false),
    PermissionItem(kind: PermissionKind.contacts, isRequired: false),
  ];
  final dir = Platform.environment['PREVIEW_DIR'] ?? 'screenshots';
  final shots = <String, (Size, Brightness, PermissionSetupStyle)>{
    'crimson_phone': (
      const Size(390, 844),
      Brightness.light,
      PermissionSetupStyle.crimson,
    ),
    'crimson_phone_dark': (
      const Size(390, 844),
      Brightness.dark,
      PermissionSetupStyle.crimson,
    ),
    'crimson_tablet': (
      const Size(768, 1024),
      Brightness.light,
      PermissionSetupStyle.crimson,
    ),
    'crimson_tablet_landscape': (
      const Size(1024, 768),
      Brightness.light,
      PermissionSetupStyle.crimson,
    ),
    'crimson_desktop': (
      const Size(1280, 800),
      Brightness.light,
      PermissionSetupStyle.crimson,
    ),
    'clinical_phone': (
      const Size(390, 844),
      Brightness.dark,
      PermissionSetupStyle.clinical,
    ),
    'clinical_desktop': (
      const Size(1280, 800),
      Brightness.dark,
      PermissionSetupStyle.clinical,
    ),
  };
  for (final e in shots.entries) {
    testWidgets('preview ${e.key}', (t) async {
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
            PermissionKind.notification: PermissionGrant.granted,
            PermissionKind.location: PermissionGrant.granted,
            PermissionKind.photos: PermissionGrant.permanentlyDenied,
            PermissionKind.bluetooth: PermissionGrant.restricted,
            PermissionKind.contacts: PermissionGrant.limited,
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
            home: PermissionSetupPage(
              items: items,
              bloc: bloc,
              style: e.value.$3.copyWith(
                fontFamily: 'Roboto',
                headingFontFamily: 'Roboto',
                dark: e.value.$3.dark?.copyWith(fontFamily: 'Roboto'),
              ),
              onSkip: (_) {},
              onToggleTheme: () {},
              brand: const PermissionSetupBrand(
                appName: 'Lumio',
                badge: 'Setup',
                caption: 'Package: play_permission_setup v0.1.0',
              ),
              strings: const PermissionSetupStrings(
                title: "Let's get things ready",
                subtitle:
                    'Allow a few permissions to unlock all the features and get the best experience from the application.',
                progressBadge: 'BLoC Managed',
                footerNote: 'You can manage permissions anytime in Settings.',
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        Directory(dir).createSync(recursive: true);
        File('$dir/${e.key}.png').writeAsBytesSync(bytes.buffer.asUint8List());
      });
      bloc.close();
      await t.pump();
    });
  }

  // Desktop workstation look.
  for (final size in [const Size(1280, 1024), const Size(1024, 768)]) {
    testWidgets('preview workstation ${size.width.toInt()}', (t) async {
      await _loadFont('Roboto', ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']);
      await _loadFont('MaterialIcons', ['MaterialIcons-Regular.otf']);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final bloc = PermissionSetupBloc(
        items: const [
          PermissionItem(
            kind: PermissionKind.camera,
            title: 'Camera Access',
            description:
                'Allow camera access to capture clinical photos, barcodes, and scan lab documents.',
          ),
          PermissionItem(
            kind: PermissionKind.notification,
            title: 'Bedside Notifications',
            description:
                'Receive important telemetry notifications, emergency triage calls, and application updates.',
          ),
          PermissionItem(
            kind: PermissionKind.microphone,
            title: 'Audio & Microphone',
            description:
                'Enable microphone access for acoustic stethoscope analysis, voice dictation, and audio notes.',
          ),
          PermissionItem(
            kind: PermissionKind.location,
            title: 'Clinical Geofencing',
            description:
                'Allow location access for hospital ward geofencing and automatic medical station pairing.',
          ),
          PermissionItem(
            kind: PermissionKind.photos,
            title: 'Diagnostic Imaging Storage',
            description:
                'Access local DICOM radiology files and patient imaging assets stored on this workstation.',
          ),
          PermissionItem(
            kind: PermissionKind.bluetooth,
            isRequired: false,
            title: 'Bluetooth BLE Telemetry',
            description:
                'Enable Bluetooth connectivity for supported pulse oximeters and ECG monitors.',
          ),
          PermissionItem(
            kind: PermissionKind.contacts,
            isRequired: false,
            title: 'Staff Directory',
            description:
                'Synchronize on-duty attending physician directories and on-call specialist lists.',
          ),
        ],
        service: FakeService(
          initial: {
            PermissionKind.camera: PermissionGrant.granted,
            PermissionKind.notification: PermissionGrant.granted,
            PermissionKind.location: PermissionGrant.granted,
            PermissionKind.photos: PermissionGrant.permanentlyDenied,
            PermissionKind.bluetooth: PermissionGrant.restricted,
            PermissionKind.contacts: PermissionGrant.limited,
          },
        ),
        platform: PermissionPlatform.android,
        autoRefreshOnResume: false,
      );
      final key = GlobalKey();
      final style = PermissionSetupStyle.workstation.copyWith(
        fontFamily: 'Roboto',
        headingFontFamily: 'Roboto',
      );
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark,
              useMaterial3: true,
              fontFamily: 'Roboto',
            ),
            home: PermissionSetupPage(
              items: const [],
              bloc: bloc,
              style: style,
              onSkip: (_) {},
              onToggleTheme: () {},
              brand: const PermissionSetupBrand(
                appName: 'Lumio',
                chip: 'play_permission_setup v0.1.0',
                navItems: [
                  'Overview',
                  'Permissions',
                  'Diagnostics',
                  'Telemetry Summary',
                ],
              ),
              topBanner: PermissionSetupMetaBar(
                style: style,
                leading: 'Runtime engine',
                middle: 'Target: high-precision clinical tablet / workstation',
                trailing: 'Session id: #LM-8849-DX',
                trailingChip: 'Encrypted BLoC bus',
              ),
              bottomBanner: PermissionSetupMetaBar(
                style: style,
                leading: 'Diagnostic telemetry core running',
                trailing: '© Lumio Inc.',
                dotColor: const Color(0xFF3CDDC7),
              ),
              strings: const PermissionSetupStrings(
                title: "Let's get things ready",
                titleHighlight: 'ready',
                subtitle:
                    'Allow a few permissions to unlock all the clinical scanning, live bedside diagnostics, and high-frequency real-time vitals telemetry.',
                heroBadge: 'Lumio SETUP v0.1.0',
                stepLabel: 'STEP 01 / 02',
                progressTag: 'REQ',
                progressStatus: 'BLoC State: PermissionSetupState.inProgress',
                noteTitle: 'Protected Clinical Channel',
                noteBody:
                    'Your privacy is strictly protected. Permissions are solely utilized to provide clinical scanning, live bedside alerts, and offline caching.',
                sectionTitle: 'Required permissions',
                sectionSubtitle:
                    'Review the permissions below to enable all supported diagnostics and data ingestion.',
                allowAll: 'Grant All Missing',
                requiredChip: 'REQUIRED',
                continueLabel: 'Continue to Telemetry Core',
                footerNote:
                    'You can manage and revoke permissions anytime in Settings > Preferences.',
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        Directory(dir).createSync(recursive: true);
        File(
          '$dir/workstation_${size.width.toInt()}.png',
        ).writeAsBytesSync(bytes.buffer.asUint8List());
      });
      bloc.close();
      await t.pump();
    });
  }
}
