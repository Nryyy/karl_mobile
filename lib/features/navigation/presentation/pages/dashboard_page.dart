import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:karl_mobile/features/ai_chat/ai_chat_service.dart';
import 'package:karl_mobile/features/ai_chat/chat_screen.dart';
import 'package:karl_mobile/generated/app_localizations.dart';
import 'package:karl_mobile/core/config/api_config.dart';

import '../../../documents/data/documents_repository.dart';
import '../../../documents/domain/document_models.dart';
import '../../../documents/domain/document_visibility.dart';

/// Mobile-first dashboard page that summarizes the user's documents.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.repository});

  final DocumentsRepository repository;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final Future<_DashboardStats> _statsFuture;
  late final Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
    _notificationsFuture = _loadNotifications();
  }

  Future<_DashboardStats> _loadStats() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return const _DashboardStats();
    }

    final email = firebaseUser.email ?? '';
    final profile = await widget.repository.fetchCurrentUser(email);
    final results = await Future.wait([
      widget.repository.fetchDocuments(archived: false),
      widget.repository.fetchDocumentsSentToMe(profile.id, archived: false),
    ]);

    final allDocuments = results[0];
    final sentToMe = results[1];
    final visibleDocuments = mergeVisibleDocuments(
      currentUserId: profile.id,
      allDocuments: allDocuments,
      sentToMe: sentToMe,
    );

    return _DashboardStats(
      pending: visibleDocuments
          .where((document) => isPendingApprovalForUser(document, profile.id))
          .length,
      approved: visibleDocuments.where(isApprovedDocument).length,
      recent: visibleDocuments.where(isRecentDocument).length,
      total: visibleDocuments.length,
    );
  }

  Future<List<AppNotification>> _loadNotifications() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return const [];
    final email = firebaseUser.email ?? '';
    try {
      final profile = await widget.repository.fetchCurrentUser(email);
      developer.log(
        'Loading notifications for userId=${profile.id}',
        name: 'karl.dashboard',
      );
      final notifications =
          await widget.repository.fetchUnreadNotifications(profile.id);
      developer.log(
        'Loaded ${notifications.length} notifications',
        name: 'karl.dashboard',
      );
      return notifications;
    } catch (e, st) {
      developer.log(
        'Failed to load notifications',
        name: 'karl.dashboard',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userName = _resolveUserName();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Add extra bottom padding equal to navigation bar height to avoid
    // small leftover overflows on devices where reserved space differs.
    const double _navBarHeight = 64.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.dashboard ?? 'Dashboard'),
        actions: const <Widget>[],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomPadding + _navBarHeight),
        children: <Widget>[
          _AnimatedGreeting(userName: userName),
          const SizedBox(height: 20),
          FutureBuilder<_DashboardStats>(
            future: _statsFuture,
            builder: (context, snapshot) {
              final stats = snapshot.data ?? const _DashboardStats();
              return _StatsGrid(stats: stats);
            },
          ),
          const SizedBox(height: 14),
          _QuickActionsCard(
            onCreateDocument: () => GoRouter.of(context).go('/documents/new'),
            onOpenTemplates: () => GoRouter.of(context).go('/templates'),
          ),
          const SizedBox(height: 14),
          _ActivityCard(
            notificationsFuture: _notificationsFuture,
            repository: widget.repository,
          ),
          const SizedBox(height: 14),
          const _GoogleDriveCard(),
          const SizedBox(height: 14),
          const _HelpCard(),
        ],
      ),
    );
  }

  String _resolveUserName() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return AppLocalizations.of(context)?.unknownAuthor ?? 'User';
  }
}

class _AnimatedGreeting extends StatelessWidget {
  const _AnimatedGreeting({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${loc?.greetingPrefix ?? 'Welcome,'} $userName',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc?.greetingSubtitle ??
                "Here's what's happening with your documents today",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final _DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 12,
          childAspectRatio: crossAxisCount == 4 ? 3.0 : 2.8,
          children: <Widget>[
            _StatTile(
              label: AppLocalizations.of(context)?.statsWaiting ?? 'Waiting',
              value: stats.pending.toString(),
              valueColor: colorScheme.tertiary,
              icon: Icons.pending_actions,
            ),
            _StatTile(
              label: AppLocalizations.of(context)?.statsApproved ?? 'Approved',
              value: stats.approved.toString(),
              valueColor: colorScheme.primary,
              icon: Icons.check_circle,
            ),
            _StatTile(
              label:
                  AppLocalizations.of(context)?.statsLast7Days ?? 'Last 7 days',
              value: stats.recent.toString(),
              valueColor: colorScheme.secondary,
              icon: Icons.calendar_today,
            ),
            _StatTile(
              label: AppLocalizations.of(context)?.statsTotal ?? 'Total',
              value: stats.total.toString(),
              valueColor: colorScheme.onSurface,
              icon: Icons.folder,
            ),
          ],
        );
      },
    );
  }
}

@immutable
class _DashboardStats {
  const _DashboardStats({
    this.pending = 0,
    this.approved = 0,
    this.recent = 0,
    this.total = 0,
  });

  final int pending;
  final int approved;
  final int recent;
  final int total;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
  });

  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '$label: $value',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: valueColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: valueColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: valueColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onCreateDocument,
    required this.onOpenTemplates,
  });

  final VoidCallback onCreateDocument;
  final VoidCallback onOpenTemplates;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AppLocalizations.of(context)?.quickActions ?? 'Quick actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCreateDocument,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(
                      AppLocalizations.of(context)?.upload ?? 'Upload',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenTemplates,
                    icon: const Icon(Icons.article_outlined),
                    label: Text(
                      AppLocalizations.of(context)?.templates ?? 'Templates',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatefulWidget {
  const _ActivityCard({
    required this.notificationsFuture,
    required this.repository,
  });

  final Future<List<AppNotification>> notificationsFuture;
  final DocumentsRepository repository;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  late List<AppNotification> _notifications = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.notificationsFuture.then((list) {
      if (mounted) setState(() { _notifications = list; _loaded = true; });
    });
  }

  Future<void> _markRead(AppNotification n) async {
    await widget.repository.markNotificationAsRead(n.id);
    if (mounted) {
      setState(() {
        _notifications = _notifications.where((x) => x.id != n.id).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc?.activityTitle ?? 'Activity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_notifications.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_notifications.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onError,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              loc?.activitySubtitle ?? 'Latest notifications',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (!_loaded)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_notifications.isEmpty)
              Text(
                loc?.noNotifications ?? 'No notifications',
                style: Theme.of(context).textTheme.bodyLarge,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _notifications.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final n = _notifications[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _iconForType(n.type),
                      color: n.priority == 'high'
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                    title: Text(
                      n.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: n.relatedDocumentTitle.isNotEmpty
                        ? Text(
                            n.relatedDocumentTitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.check, size: 18),
                      tooltip: 'Позначити як прочитане',
                      onPressed: () => _markRead(n),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    return switch (type.toLowerCase()) {
      'approval' => Icons.approval_outlined,
      'rejection' => Icons.cancel_outlined,
      'signature' => Icons.draw_outlined,
      'system' => Icons.info_outline,
      _ => Icons.notifications_outlined,
    };
  }
}

class _GoogleDriveCard extends StatelessWidget {
  const _GoogleDriveCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Icon(Icons.cloud_done, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)?.googleDrive ?? 'Google Drive',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppLocalizations.of(context)?.connected ?? 'Connected',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)?.googleDriveDescription ??
                            'Files are stored on Google Drive',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.help_outline,
                size: 32,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)?.helpTitle ?? 'Need a hint?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.helpSubtitle ??
                  'Our AI assistant can help you understand system features',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  String? token;
                  if (user != null) token = await user.getIdToken();

                  final service = AiChatService(
                    baseUrl: ApiConfig.baseUrl,
                  );
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatScreen(service: service, bearerToken: token),
                    ),
                  );
                },
                label: Text(
                  AppLocalizations.of(context)?.aiChatTitle ?? 'AI Chat',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
