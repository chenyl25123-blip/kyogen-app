import 'package:flutter_test/flutter_test.dart';

import 'package:kyogen/main.dart';

void main() {
  testWidgets('KyogenApp renders the startup frame', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KyogenApp());
    await tester.pump();

    expect(find.byType(KyogenApp), findsOneWidget);
  });
}
