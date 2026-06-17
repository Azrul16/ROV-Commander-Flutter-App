import 'package:flutter_test/flutter_test.dart';

import 'package:rov/app.dart';

void main() {
  testWidgets('shows ROV Commander while bootstrapping', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RovCommanderApp());
    await tester.pump();

    expect(find.text('ROV Commander'), findsOneWidget);
    expect(find.text('Real-Time Surveillance ROV'), findsOneWidget);
  });
}
