import 'package:firebase_auth/firebase_auth.dart';
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
        final userName = _resolveUserName(state.extra);
        return GreetingPage(userName: userName);
      },
    ),
  ],
);

String _resolveUserName(Object? extra) {
  if (extra is String && extra.trim().isNotEmpty) {
    return extra.trim();
  }

  final user = FirebaseAuth.instance.currentUser;
  final displayName = user?.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  final email = user?.email;
  if (email != null && email.isNotEmpty) {
    final localPart = email.split('@').first;
    if (localPart.isNotEmpty) {
      return localPart
          .replaceAll(RegExp(r'[._-]+'), ' ')
          .split(' ')
          .where((part) => part.isNotEmpty)
          .map((part) => part[0].toUpperCase() + part.substring(1))
          .join(' ');
    }
  }

  return 'користувач';
}
