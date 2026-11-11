import 'package:xml/xml.dart';

/// Permissions declared in one AndroidManifest.xml.
class AndroidManifestPermissions {
  AndroidManifestPermissions(this.declared, this.removed, this.maxSdk);

  /// Names without the `android.permission.` prefix (custom ones keep theirs).
  final Set<String> declared;

  /// Removed via `tools:node="remove"` (so NOT effectively declared).
  final Set<String> removed;

  /// `android:maxSdkVersion` per permission.
  final Map<String, int> maxSdk;
}

AndroidManifestPermissions parseManifest(String source) {
  final doc = XmlDocument.parse(source);
  final declared = <String>{};
  final removed = <String>{};
  final maxSdk = <String, int>{};

  for (final e in doc.rootElement.childElements) {
    final tag = e.name.qualified;
    if (tag != 'uses-permission' && tag != 'uses-permission-sdk-23') continue;
    final raw = e.getAttribute('android:name');
    if (raw == null || raw.isEmpty) continue;
    final name = raw.startsWith('android.permission.')
        ? raw.substring('android.permission.'.length)
        : raw;
    if (e.getAttribute('tools:node') == 'remove') {
      removed.add(name);
      continue;
    }
    declared.add(name);
    final max = int.tryParse(e.getAttribute('android:maxSdkVersion') ?? '');
    if (max != null) maxSdk[name] = max;
  }
  declared.removeAll(removed);
  return AndroidManifestPermissions(declared, removed, maxSdk);
}
