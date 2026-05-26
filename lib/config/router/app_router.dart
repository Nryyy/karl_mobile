import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/documents/data/documents_repository.dart';
import '../../features/documents/presentation/pages/documents_page.dart';
import '../../features/documents/domain/document_models.dart';
import '../../features/navigation/presentation/pages/account_page.dart';
import '../../features/navigation/presentation/pages/dashboard_page.dart';
import '../../features/navigation/presentation/pages/section_page.dart';
import '../../presentation/widgets/bottom_nav_bar.dart';

/// Application router configuration using go_router.
/// Manages navigation between app screens.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterAuthRefresh(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final location = state.matchedLocation;
    final isOnLogin = location == '/';
    final isOnRegister = location == '/register';

    if (!isLoggedIn) {
      return (isOnLogin || isOnRegister) ? null : '/';
    }

    if (isOnLogin || isOnRegister) {
      return '/dashboard';
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
      path: '/register',
      builder: (context, state) => const RegisterPage(),
      name: 'register',
    ),
    ShellRoute(
      builder: (context, state, child) {
        return Column(
          children: <Widget>[
            Expanded(child: child),
            BottomNavBar(
              currentRoute: state.uri.toString(),
              onNavigate: (route) => GoRouter.of(context).go(route),
            ),
          ],
        );
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/documents',
          name: 'documents',
          builder: (context, state) {
            final userName = _resolveUserName(state.extra);
            return DocumentsPage(
              userName: userName,
              repository: HttpDocumentsRepository(
                accessTokenProvider: _firebaseAccessToken,
              ),
            );
          },
        ),
        GoRoute(
          path: '/documents/new',
          name: 'document_new',
          builder: (context, state) => const DocumentEditorPage(),
        ),
        GoRoute(
          path: '/documents/:id',
          name: 'document_detail',
          builder: (context, state) {
            final doc = state.extra is DocumentListItem ? state.extra as DocumentListItem : null;
            return DocumentDetailPage(document: doc);
          },
        ),
        GoRoute(
          path: '/templates',
          name: 'templates',
          builder: (context, state) => const SectionPage(
            title: 'Шаблони',
            icon: Icons.article_outlined,
            description: 'Тут зберігаються шаблони ваших документів.',
          ),
        ),
        GoRoute(
          path: '/welcome',
          name: 'welcome',
          builder: (context, state) {
            final userName = _resolveUserName(state.extra);
            return DocumentsPage(
              userName: userName,
              repository: HttpDocumentsRepository(
                accessTokenProvider: _firebaseAccessToken,
              ),
            );
          },
        ),
        GoRoute(
          path: '/archive',
          name: 'archive',
          builder: (context, state) => const SectionPage(
            title: 'Архів',
            icon: Icons.archive_outlined,
            description: 'Архівовані документи та історія.',
          ),
        ),
        GoRoute(
          path: '/account',
          name: 'account',
          builder: (context, state) => const AccountPage(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SectionPage(
            title: 'Налаштування',
            icon: Icons.settings_outlined,
            description: 'Налаштування профілю та параметри безпеки.',
          ),
        ),
        GoRoute(
          path: '/help',
          name: 'help',
          builder: (context, state) => const SectionPage(
            title: 'Допомога',
            icon: Icons.help_outline,
            description: 'Підтримка, FAQ та корисні матеріали.',
          ),
        ),
        GoRoute(
          path: '/admin',
          name: 'admin',
          builder: (context, state) => const SectionPage(
            title: 'Адмін панель',
            icon: Icons.admin_panel_settings_outlined,
            description: 'Інструменти адміністрування системи.',
          ),
        ),
      ],
    ),
  ],
);

Future<String?> _firebaseAccessToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return null;
  }
  return user.getIdToken();
}

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
