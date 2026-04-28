import 'package:flutter_test/flutter_test.dart';

import 'package:karl_mobile/main.dart';

void main() {
  testWidgets('shows the Karl login page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Вхід до системи'), findsOneWidget);
    expect(find.text('Увійти через email'), findsOneWidget);
    expect(find.text('Увійти через Google'), findsOneWidget);
  });
}
