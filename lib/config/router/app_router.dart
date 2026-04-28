import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/greeting_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';

/// Application router configuration using go_router.
/// Manages navigation between app screens.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
      name: 'login',
    ),
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) {
        final userName = state.uri.queryParameters['name'] ?? 'користувач';
        return GreetingPage(userName: userName);
      },
    ),
  ],
);
