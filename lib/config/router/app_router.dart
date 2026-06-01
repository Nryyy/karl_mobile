import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/password_reset_page.dart';
import '../../features/documents/data/documents_repository.dart';
import '../../features/documents/presentation/pages/approvals_page.dart';
import '../../features/documents/presentation/pages/documents_page.dart';
import '../../features/documents/presentation/pages/archive_page.dart';
import '../../features/documents/domain/document_models.dart';
import '../../features/navigation/presentation/pages/account_page.dart';
import '../../features/navigation/presentation/pages/dashboard_page.dart';
import '../../features/navigation/presentation/pages/section_page.dart';
import '../../features/navigation/presentation/pages/settings_page.dart';
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
    final isOnPasswordReset = location == '/password-reset';

    if (!isLoggedIn) {
      return (isOnLogin || isOnRegister || isOnPasswordReset) ? null : '/';
    }

    if (isOnLogin || isOnRegister) {
      return '/dashboard';
    }

    if (isOnPasswordReset) {
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
    GoRoute(
      path: '/password-reset',
      builder: (context, state) => const PasswordResetPage(),
      name: 'password-reset',
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
          builder: (context, state) => DashboardPage(
            repository: HttpDocumentsRepository(
              accessTokenProvider: _firebaseAccessToken,
            ),
          ),
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
            final doc = state.extra is DocumentListItem
                ? state.extra as DocumentListItem
                : null;
            return DocumentDetailPage(document: doc);
          },
        ),
        GoRoute(
          path: '/approvals',
          name: 'approvals',
          builder: (context, state) => const ApprovalsPage(),
        ),
        GoRoute(
          path: '/approvals/:id',
          name: 'approval_detail',
          builder: (context, state) {
            final args = state.extra is ApprovalDetailArgs
                ? state.extra as ApprovalDetailArgs
                : null;
            return ApprovalDetailPage(args: args);
          },
        ),
        GoRoute(
          path: '/templates',
          name: 'templates',
          builder: (context, state) => SectionPage(
            title: AppLocalizations.of(context)?.templates ?? 'Templates',
            icon: Icons.article_outlined,
            description:
                AppLocalizations.of(context)?.templatesDescription ??
                'Here you can store templates for your documents.',
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
          builder: (context, state) => ArchivePage(
            repository: HttpDocumentsRepository(
              accessTokenProvider: _firebaseAccessToken,
            ),
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
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/help',
          name: 'help',
          builder: (context, state) => SectionPage(
            title: AppLocalizations.of(context)?.help ?? 'Help',
            icon: Icons.help_outline,
            description:
                AppLocalizations.of(context)?.helpDescription ??
                'Support, FAQ and useful resources.',
          ),
        ),
        GoRoute(
          path: '/admin',
          name: 'admin',
          builder: (context, state) => SectionPage(
            title: AppLocalizations.of(context)?.adminPanel ?? 'Admin panel',
            icon: Icons.admin_panel_settings_outlined,
            description:
                AppLocalizations.of(context)?.adminDescription ??
                'Administration tools for the system.',
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

  return 'User';
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
