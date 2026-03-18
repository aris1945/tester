import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic smoke test placeholder
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('DOMPIS'))),
    );
    expect(find.text('DOMPIS'), findsOneWidget);
  });
}
