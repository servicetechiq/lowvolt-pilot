import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lowvoltpilot/features/home/home_page.dart';
import 'package:lowvoltpilot/main.dart';

void main() {
  testWidgets('shows Supabase setup screen when not configured', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LowVoltPilotApp(configuredOverride: false));

    expect(find.text('LowVolt Pilot'), findsOneWidget);
    expect(find.text('Account service not configured'), findsOneWidget);
  });

  testWidgets('LowVolt Pilot home screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    expect(find.text('LowVolt Pilot'), findsOneWidget);
    expect(find.text('What are you doing today?'), findsOneWidget);
    expect(find.text('Design a System'), findsOneWidget);
    expect(find.text('Install / Commission'), findsOneWidget);
    expect(find.text('Troubleshoot'), findsOneWidget);
    expect(find.text('Jobs'), findsOneWidget);
    expect(find.text('Quick Tools'), findsOneWidget);
    expect(find.text('Reference'), findsOneWidget);
  });
}
