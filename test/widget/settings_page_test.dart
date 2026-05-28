import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karl_mobile/features/navigation/presentation/pages/settings_page.dart';

void main() {
  testWidgets('Settings page shows language options', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('Українська'), findsOneWidget);
    expect(find.text('Polski'), findsOneWidget);
  });
}
