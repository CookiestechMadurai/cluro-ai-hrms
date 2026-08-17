import 'package:flutter_test/flutter_test.dart';

import 'package:cluro_ai_hrms/app/app.dart';

void main() {
  testWidgets('HRMS app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const HrmsApp());

    await tester.pumpAndSettle();

    expect(find.byType(HrmsApp), findsOneWidget);
  });
}