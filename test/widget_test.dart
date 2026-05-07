// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_byte/main.dart';

void main() {
  testWidgets('Loads app and can add a task', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const FocusByteApp());
    await tester.pumpAndSettle();

    // Verify main screen renders.
    expect(find.text('FocusByte'), findsOneWidget);
    expect(find.text('No tasks yet'), findsOneWidget);

    // Add a task and verify it appears.
    await tester.enterText(find.byType(TextField), 'Write tests');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('Write tests'), findsOneWidget);
  });
}
