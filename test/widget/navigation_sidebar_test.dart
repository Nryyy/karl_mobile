import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karl_mobile/presentation/widgets/navigation_sidebar.dart';

void main() {
  testWidgets('shows admin panel when isAdmin is true', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NavigationSidebar(
            currentRoute: '/',
            isAdmin: true,
            onNavigate: (_) {},
          ),
        ),
      ),
    );

    // Admin panel label should be present (fallback text since no localization)
    expect(find.text('Admin panel'), findsOneWidget);
  });

  testWidgets('hides admin panel when isAdmin is false', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NavigationSidebar(
            currentRoute: '/',
            isAdmin: false,
            onNavigate: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Admin panel'), findsNothing);
  });
}
