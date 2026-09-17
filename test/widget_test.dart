import 'package:flutter_test/flutter_test.dart';
import 'package:lowvoltpilot/main.dart';

void main() {
  testWidgets('LowVolt Pilot home screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const LowVoltPilotApp());

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
