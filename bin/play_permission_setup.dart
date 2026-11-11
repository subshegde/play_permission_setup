import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:play_permission_setup/scanner.dart';

const _usage = '''
play_permission_setup – scan AndroidManifest.xml, Info.plist, entitlements and the
Podfile, find mistakes, and generate the permission list for the setup page.

Usage:
  dart run play_permission_setup scan      [options]   print report (exit 1 on errors)
  dart run play_permission_setup generate  [options]   write lib/play_permission_setup.g.dart

Options:
''';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'path',
      abbr: 'p',
      help:
          'Flutter app root (default: nearest parent folder that is a Flutter app)',
    )
    ..addOption('output', abbr: 'o', defaultsTo: 'lib/play_permission_setup.g.dart')
    ..addOption(
      'required',
      help: 'Comma list of kinds that block "Continue", e.g. camera,location',
    )
    ..addOption('exclude', help: 'Comma list of kinds to leave out')
    ..addFlag('strict', negatable: false, help: 'Treat warnings as errors')
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults r;
  try {
    r = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    exit(64);
  }
  if (r['help'] as bool) {
    stdout.writeln('$_usage${parser.usage}');
    return;
  }

  final command = r.rest.isEmpty ? 'scan' : r.rest.first;
  if (command != 'scan' && command != 'generate') {
    stderr.writeln('Unknown command "$command".\n$_usage${parser.usage}');
    exit(64);
  }

  Set<PermissionKind> kinds(String? csv) {
    if (csv == null || csv.trim().isEmpty) return {};
    final out = <PermissionKind>{};
    for (final n
        in csv.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)) {
      final k = PermissionKind.values.where((k) => k.name == n);
      if (k.isEmpty) {
        stderr.writeln(
          'Unknown permission "$n". Known: ${PermissionKind.values.map((e) => e.name).join(', ')}',
        );
        exit(64);
      }
      out.add(k.first);
    }
    return out;
  }

  final root = _resolveRoot(r['path'] as String?);
  stdout.writeln('Project: $root');
  final result = ProjectScanner(root).scan();
  _printReport(result);

  var failed =
      result.hasErrors || ((r['strict'] as bool) && result.hasWarnings);

  if (command == 'generate' && !result.hasErrors) {
    final src = generateDartSource(
      result,
      required: kinds(r['required'] as String?),
      exclude: kinds(r['exclude'] as String?),
    );
    final out = File(
      p.isAbsolute(r['output'] as String)
          ? r['output'] as String
          : p.join(root, r['output'] as String),
    );
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(src);
    stdout.writeln('\nWrote ${p.relative(out.path, from: root)}');
  } else if (command == 'generate') {
    stderr.writeln('\nNot generating: fix the errors above first.');
  }
  if (failed) exit(1);
}

void _printReport(ScanResult r) {
  stdout.writeln(
    'Scanned: ${r.files.isEmpty ? '(nothing)' : r.files.join(', ')}\n',
  );
  final cols = [
    PermissionPlatform.android,
    PermissionPlatform.ios,
    PermissionPlatform.macos,
  ].where(r.scanned.contains).toList();

  if (r.declared.isEmpty) {
    stdout.writeln('No runtime permissions found.');
  } else {
    final w = PermissionKind.values
        .map((k) => k.name.length)
        .reduce((a, b) => a > b ? a : b);
    stdout.writeln(
      '${'Permission'.padRight(w)}  ${cols.map((c) => c.name.padRight(7)).join(' ')}',
    );
    for (final k in PermissionKind.values) {
      final d = r.declared[k];
      if (d == null) continue;
      stdout.writeln(
        '${k.name.padRight(w)}  ${cols.map((c) {
          if (!k.platforms.contains(c)) return '-'.padRight(7);
          return (d.contains(c) ? 'yes' : 'MISSING').padRight(7);
        }).join(' ')}',
      );
    }
  }

  if (r.issues.isNotEmpty) {
    stdout.writeln('');
    final order = {
      IssueSeverity.error: 0,
      IssueSeverity.warning: 1,
      IssueSeverity.info: 2,
    };
    final sorted = [...r.issues]
      ..sort((a, b) => order[a.severity]! - order[b.severity]!);
    for (final i in sorted) {
      stdout.writeln(i);
    }
  }
  final e = r.issues.where((i) => i.severity == IssueSeverity.error).length;
  final w = r.issues.where((i) => i.severity == IssueSeverity.warning).length;
  stdout.writeln('\n$e error(s), $w warning(s).');
}

/// Uses --path if given, else the nearest parent that is a Flutter app.
/// Exits with a helpful message (and suggestions) when nothing is found.
String _resolveRoot(String? given) {
  if (given != null) return p.normalize(p.absolute(given));
  final found = findProjectRoot('.');
  if (found != null) return found;

  stderr.writeln(
    'No Flutter app found in ${p.normalize(p.absolute('.'))} or any parent folder.',
  );
  stderr.writeln(
    '(An app has a pubspec.yaml plus an android/, ios/ or macos/ folder; '
    'a package/plugin without them has nothing to scan.)',
  );
  final nearby = findNearbyProjects('.');
  if (nearby.isNotEmpty) {
    stderr.writeln('\nFlutter apps nearby – run one of:');
    for (final n in nearby) {
      stderr.writeln('  dart run play_permission_setup scan --path "$n"');
    }
  } else {
    stderr.writeln(
      '\nRun it from your app folder, or pass --path <app folder>.',
    );
  }
  exit(64);
}
