import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karl_mobile/features/auth/presentation/widgets/login_form.dart';

void main() {
  testWidgets('LoginForm renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LoginForm(
              onEmailPasswordSubmitted: (email, password) async {},
              onGooglePressed: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify login form elements are present
    expect(find.byType(LoginForm), findsOneWidget);
    expect(find.text('Увійти через Google'), findsOneWidget);
    expect(find.byIcon(Icons.g_mobiledata_rounded), findsOneWidget);
  });
}
