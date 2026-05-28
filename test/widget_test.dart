import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:karl_mobile/main.dart';
import 'package:karl_mobile/features/auth/presentation/widgets/login_form.dart';

void main() {
  testWidgets('shows the Karl login page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify LoginForm is present and Google sign-in button exists
    expect(find.byType(LoginForm), findsOneWidget);
    expect(find.byIcon(Icons.g_mobiledata_rounded), findsOneWidget);
  });
}
