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

  testWidgets('opening firmware provisioning page from login works', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Firmware Provisioning'));
    await tester.pumpAndSettle();

    expect(find.text('Firmware Provisioning'), findsOneWidget);
    expect(find.textContaining('Alur provisioning'), findsOneWidget);
    expect(find.text('Scan QR perangkat'), findsOneWidget);
  });

  testWidgets('stored session opens dashboard on app launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'active_rollator_code': 'ROLLATOR-123'});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Device Login'), findsNothing);
    expect(find.text('DASHBOARD'), findsWidgets);
  });
}
