import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/documents/presentation/pages/documents_page.dart';

/// Application router configuration using go_router.
/// Manages navigation between app screens.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterAuthRefresh(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isOnLogin = state.matchedLocation == '/';

    if (!isLoggedIn) {
      return isOnLogin ? null : '/';
    }

    if (isOnLogin) {
      return '/documents';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
      name: 'login',
    ),
    GoRoute(
      path: '/documents',
      name: 'documents',
      builder: (context, state) {
        final userName = _resolveUserName(state.extra);
        return DocumentsPage(userName: userName);
      },
    ),
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) {
        final userName = _resolveUserName(state.extra);
        return DocumentsPage(userName: userName);
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

/// Refreshes go_router when the auth stream emits new values.
class GoRouterAuthRefresh extends ChangeNotifier {
  /// Creates a refresh notifier for a stream.
  GoRouterAuthRefresh(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
