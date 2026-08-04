// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rideksa/screens/auth/role_select_screen.dart';

void main() {
  testWidgets('role selection exposes the main onboarding purposes', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RoleSelectScreen()));

    expect(find.text('I want to travel'), findsOneWidget);
    expect(find.text('Become a Captain'), findsOneWidget);
    expect(find.text('Customer Company'), findsOneWidget);
    expect(find.text('Partner / Transport Company'), findsOneWidget);
  });
}
