import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyogen/common_widgets.dart';

void main() {
  testWidgets('AppCard renders its child', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCard(
            child: Text('まもりんく'),
          ),
        ),
      ),
    );

    expect(find.text('まもりんく'), findsOneWidget);
    expect(find.byType(AppCard), findsOneWidget);
  });
}
