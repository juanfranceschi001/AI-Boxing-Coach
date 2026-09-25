import 'package:flutter_test/flutter_test.dart';

import 'package:ai_boxing_coach/app.dart';

void main() {
  testWidgets('Home screen shows workout mode choices',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AiBoxingCoachApp());

    expect(find.text('Choose a workout'), findsOneWidget);
    expect(find.text('Round Timer'), findsOneWidget);
    expect(find.text('Free / Shadow Box'), findsOneWidget);
  });
}
