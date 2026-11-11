// Prints the permission catalogue table used in the README.
//   dart run tool/print_catalogue.dart
// ignore_for_file: avoid_print
import 'package:play_permission_setup/scanner.dart';

void main() {
  String c(Iterable<String> v) =>
      v.isEmpty ? '–' : v.map((e) => '`$e`').join('<br>');
  print(
    '| `PermissionKind` | Android (`android.permission.*`) | iOS / macOS `Info.plist` | iOS Podfile macro | macOS entitlement | Platforms |',
  );
  print('|---|---|---|---|---|---|');
  for (final k in PermissionKind.values) {
    final d = k.descriptor;
    final pl = (d.platforms.toList()..sort((a, b) => a.index - b.index))
        .map((p) => p.name)
        .join(', ');
    print(
      '| `${k.name}` | ${c(d.android)} | ${c(d.iosKeys)} | ${d.podMacro == null ? '–' : '`${d.podMacro}`'} | ${c(d.macosEntitlements.map((e) => e.replaceFirst('com.apple.security.', '…')))} | $pl |',
    );
  }
}
