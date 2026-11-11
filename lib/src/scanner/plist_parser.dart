import 'package:xml/xml.dart';

/// Reads the top-level keys of an XML property list (Info.plist,
/// *.entitlements). Strings keep their text, booleans become `true`/`false`,
/// everything else becomes an empty marker `'<...>'`.
class PlistParseException implements Exception {
  PlistParseException(this.message);
  final String message;
  @override
  String toString() => message;
}

Map<String, String> parsePlist(String source) {
  if (source.startsWith('bplist')) {
    throw PlistParseException(
      'binary plist – convert with `plutil -convert xml1 <file>`',
    );
  }
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(source);
  } on XmlException catch (e) {
    throw PlistParseException('invalid XML: ${e.message}');
  }
  final dict = doc.rootElement.getElement('dict');
  if (dict == null) throw PlistParseException('no top-level <dict>');

  final out = <String, String>{};
  String? key;
  for (final node in dict.childElements) {
    if (node.name.local == 'key') {
      key = node.innerText.trim();
      continue;
    }
    if (key == null) continue;
    switch (node.name.local) {
      case 'string':
        out[key] = node.innerText.trim();
      case 'true':
        out[key] = 'true';
      case 'false':
        out[key] = 'false';
      default:
        out[key] = '<${node.name.local}>';
    }
    key = null;
  }
  return out;
}
