import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

/// Account page with Material 3 design showing user profile and navigation options.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName?.trim();
    final email = user?.email ?? '';
    final userName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (email.isNotEmpty ? email.split('@').first : 'Користувач');
    final avatarText = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.account ?? 'Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Center(
                      child: Text(
                        avatarText,
                        style: textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader(
            icon: Icons.account_circle_outlined,
            title: AppLocalizations.of(context)?.account ?? 'Account',
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _AccountTile(
                  icon: Icons.cloud_done_outlined,
                  iconColor: colorScheme.primary,
                  title:
                      AppLocalizations.of(context)?.googleDrive ??
                      'Google Drive',
                  subtitle:
                      AppLocalizations.of(context)?.connected ?? 'Connected',
                  trailing: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _AccountTile(
                  icon: Icons.settings_outlined,
                  title: AppLocalizations.of(context)?.settings ?? 'Settings',
                  subtitle:
                      AppLocalizations.of(context)?.settingsSubtitle ??
                      'Theme, language, preferences',
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader(
            icon: Icons.support_outlined,
            title: AppLocalizations.of(context)?.help ?? 'Support',
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _AccountTile(
                  icon: Icons.help_outline,
                  title: AppLocalizations.of(context)?.help ?? 'Help',
                  subtitle:
                      AppLocalizations.of(context)?.helpDescription ??
                      'Support, FAQ and useful resources.',
                  onTap: () => context.go('/help'),
                ),
                const Divider(height: 1, indent: 56),
                _AccountTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title:
                      AppLocalizations.of(context)?.adminPanel ?? 'Admin panel',
                  subtitle:
                      AppLocalizations.of(context)?.adminDescription ??
                      'Administration tools for the system.',
                  onTap: () => context.go('/admin'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          FilledButton.tonalIcon(
            onPressed: () => _showSignOutDialog(context),
            icon: const Icon(Icons.logout),
            label: Text(AppLocalizations.of(context)?.signOut ?? 'Sign out'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.logout, color: colorScheme.primary),
        title: Text(AppLocalizations.of(context)?.signOut ?? 'Sign out'),
        content: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
          ),
          FilledButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.go('/');
              }
            },
            child: Text(AppLocalizations.of(context)?.signOut ?? 'Sign out'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    this.iconColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Color? iconColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: iconColor ?? colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing:
          trailing ??
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
