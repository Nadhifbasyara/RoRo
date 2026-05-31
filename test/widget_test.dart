import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:roro/main.dart';

void main() {
  testWidgets('login page renders hero content', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('SECURE ACCESS'), findsOneWidget);
    expect(find.textContaining('Welcome back to'), findsOneWidget);
    expect(find.text('RoRo'), findsWidgets);
    expect(find.text('Device Login'), findsOneWidget);
    expect(find.text('Scan from Gallery'), findsOneWidget);
    expect(find.textContaining("Don't have an account"), findsOneWidget);
  });

  testWidgets('tapping scan from gallery opens dashboard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Scan from Gallery'));
    await tester.tap(find.text('Scan from Gallery'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'DEMO-ROLLATOR');
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(find.text('RoRo'), findsWidgets);
    expect(find.text("Albert's RoRo"), findsOneWidget);
    expect(find.text('ESP32: Online'), findsOneWidget);
    expect(find.text('BATTERY LEVEL'), findsNothing);
    expect(find.text('FIRE STREAK'), findsOneWidget);
    expect(find.textContaining('Hari'), findsWidgets);
    expect(find.text('STATUS JALAN HARI INI'), findsNothing);
    expect(find.text('Saya Sudah Jalan'), findsNothing);
    expect(find.text('Sudah Ditandai'), findsOneWidget);
    expect(find.text('Current Operating Mode'), findsOneWidget);
    expect(find.text('Gait & Mobility\nInsights'), findsOneWidget);
    expect(find.text('Emergency SOS'), findsOneWidget);
    expect(find.text('DASHBOARD'), findsWidgets);
    expect(find.text('Live Tracking'), findsNothing);
  });

  testWidgets('stored session opens dashboard on app launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'active_rollator_code': 'ROLLATOR-123'});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Device Login'), findsNothing);
    expect(find.text('DASHBOARD'), findsWidgets);
  });
}
