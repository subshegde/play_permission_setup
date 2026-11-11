import 'dart:io';

import 'package:path/path.dart' as p;

bool _isFlutterApp(String dir) =>
    File(p.join(dir, 'pubspec.yaml')).existsSync() &&
    [
      'android',
      'ios',
      'macos',
    ].any((d) => Directory(p.join(dir, d)).existsSync());

/// Walks up from [start] to the first folder that looks like a Flutter app
/// (has a `pubspec.yaml` and an `android/`, `ios/` or `macos/` folder).
String? findProjectRoot(String start) {
  var dir = p.normalize(p.absolute(start));
  while (true) {
    if (_isFlutterApp(dir)) return dir;
    final parent = p.dirname(dir);
    if (parent == dir) return null;
    dir = parent;
  }
}

/// Flutter apps one or two levels below [start] (used for "did you mean…").
List<String> findNearbyProjects(String start) {
  final out = <String>[];
  final root = p.normalize(p.absolute(start));
  try {
    for (final a in Directory(root).listSync().whereType<Directory>()) {
      if (_isFlutterApp(a.path)) out.add(a.path);
      if (p.basename(a.path).startsWith('.')) continue;
      for (final b in a.listSync().whereType<Directory>()) {
        if (_isFlutterApp(b.path)) out.add(b.path);
      }
    }
  } on FileSystemException {
    // unreadable folder: just no suggestions
  }
  out.sort();
  return out;
}
