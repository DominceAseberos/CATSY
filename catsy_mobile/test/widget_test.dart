import 'package:flutter_test/flutter_test.dart';

import 'package:catsy_pos/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CatsyPosApp());
    // Just verify the app can render without errors
    expect(find.byType(CatsyPosApp), findsOneWidget);
  });
}
