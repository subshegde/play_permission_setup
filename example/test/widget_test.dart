import 'package:flutter_test/flutter_test.dart';
import 'package:permission_playground/main.dart';

void main() {
  testWidgets('shows the permission setup page', (tester) async {
    await tester.pumpWidget(const PlaygroundApp());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Gate), findsOneWidget);
  });
}
