import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import '../../core/providers/locale_provider.dart';
import '_sidebar_item.dart';

typedef NavigateCallback = void Function(String route);

class NavigationSidebar extends ConsumerStatefulWidget {
  const NavigationSidebar({
    Key? key,
    required this.currentRoute,
    required this.isAdmin,
    required this.onNavigate,
  }) : super(key: key);

  final String currentRoute;
  final bool isAdmin;
  final NavigateCallback onNavigate;

  @override
  ConsumerState<NavigationSidebar> createState() => _NavigationSidebarState();
}

class _NavigationSidebarState extends ConsumerState<NavigationSidebar> {
  static const double _expandedWidth = 240;
  static const double _collapsedWidth = 72;

  bool _collapsed = false;

  void _toggle() => setState(() => _collapsed = !_collapsed);

  @override
  Widget build(BuildContext context) {
    final bool narrow = MediaQuery.of(context).size.width < 600;

    final Widget content = SafeArea(
      child: FocusTraversalGroup(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            crossAxisAlignment: _collapsed
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: _collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  if (!_collapsed)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.dashboard ?? 'Menu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  // Always show language icon so it's visible in collapsed state
                  PopupMenuButton<String>(
                    tooltip: AppLocalizations.of(context)?.language ?? 'Language',
                    icon: const Icon(Icons.language),
                    onSelected: (value) async {
                      Locale? locale;
                      if (value == 'system') locale = null;
                      else locale = Locale(value);
                      await ref.read(localeProvider.notifier).setLocale(locale);
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'system',
                        child: Text(AppLocalizations.of(context)?.languageSystemDefault ?? 'System')),
                      PopupMenuItem(
                        value: 'en', child: Text(AppLocalizations.of(context)?.languageEnglish ?? 'English')),
                      PopupMenuItem(
                        value: 'uk', child: Text(AppLocalizations.of(context)?.languageUkrainian ?? 'Ukrainian')),
                      PopupMenuItem(
                        value: 'pl', child: Text(AppLocalizations.of(context)?.languagePolish ?? 'Polish')),
                    ],
                  ),
                  IconButton(
                    tooltip: _collapsed
                        ? (AppLocalizations.of(context)?.expandSidebar ?? 'Expand')
                        : (AppLocalizations.of(context)?.collapseSidebar ?? 'Collapse'),
                    onPressed: _toggle,
                    icon: Icon(
                      _collapsed ? Icons.arrow_forward : Icons.arrow_back,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    SidebarItem(
                      label: AppLocalizations.of(context)?.dashboard ?? 'Dashboard',
                      icon: Icons.dashboard,
                      selected:
                          widget.currentRoute == '/' ||
                          widget.currentRoute == '/dashboard',
                      onTap: () => widget.onNavigate('/'),
                      tooltip: AppLocalizations.of(context)?.tooltipDashboard ?? 'Home page',
                      showLabel: !_collapsed,
                    ),
                    const SizedBox(height: 6),
                    SidebarItem(
                      label: AppLocalizations.of(context)?.myDocuments ?? 'My Documents',
                      icon: Icons.description,
                      selected: widget.currentRoute == '/documents',
                      onTap: () => widget.onNavigate('/documents'),
                      tooltip: AppLocalizations.of(context)?.tooltipMyDocuments ?? 'All your documents',
                      showLabel: !_collapsed,
                    ),
                    const SizedBox(height: 6),
                    SidebarItem(
                      label: AppLocalizations.of(context)?.archive ?? 'Archive',
                      icon: Icons.archive,
                      selected: widget.currentRoute == '/archive',
                      onTap: () => widget.onNavigate('/archive'),
                      tooltip: AppLocalizations.of(context)?.tooltipArchive ?? 'Archived documents',
                      showLabel: !_collapsed,
                    ),
                    const SizedBox(height: 6),
                    if (widget.isAdmin) ...[
                      SidebarItem(
                        label: AppLocalizations.of(context)?.adminPanel ?? 'Admin panel',
                        icon: Icons.admin_panel_settings,
                        selected: widget.currentRoute == '/admin',
                        onTap: () => widget.onNavigate('/admin'),
                        tooltip: AppLocalizations.of(context)?.tooltipAdminPanel ?? 'Admin panel (admins only)',
                        showLabel: !_collapsed,
                      ),
                      const SizedBox(height: 6),
                    ],
                    SidebarItem(
                      label: AppLocalizations.of(context)?.settings ?? 'Settings',
                      icon: Icons.settings,
                      selected: widget.currentRoute == '/settings',
                      onTap: () => widget.onNavigate('/settings'),
                      tooltip: AppLocalizations.of(context)?.tooltipSettings ?? 'Profile settings',
                      showLabel: !_collapsed,
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    SidebarItem(
                      label: AppLocalizations.of(context)?.help ?? 'Help',
                      icon: Icons.help_outline,
                      selected: widget.currentRoute == '/help',
                      onTap: () => widget.onNavigate('/help'),
                      tooltip: AppLocalizations.of(context)?.help ?? 'Help',
                      showLabel: !_collapsed,
                    ),
                    const SizedBox(height: 8),
                    // Language selector
                    Row(
                      mainAxisAlignment: _collapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        if (!_collapsed)
                          Text(AppLocalizations.of(context)?.language ?? 'Language'),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          tooltip: AppLocalizations.of(context)?.language ?? 'Language',
                          icon: const Icon(Icons.language),
                          onSelected: (value) async {
                            Locale? locale;
                            if (value == 'system') locale = null;
                            else locale = Locale(value);
                            await ref.read(localeProvider.notifier).setLocale(locale);
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'system',
                              child: Text(AppLocalizations.of(context)?.languageSystemDefault ?? 'System')),
                            PopupMenuItem(
                              value: 'en', child: Text(AppLocalizations.of(context)?.languageEnglish ?? 'English')),
                            PopupMenuItem(
                              value: 'uk', child: Text(AppLocalizations.of(context)?.languageUkrainian ?? 'Ukrainian')),
                            PopupMenuItem(
                              value: 'pl', child: Text(AppLocalizations.of(context)?.languagePolish ?? 'Polish')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (narrow) {
      return Drawer(child: content);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _collapsed ? _collapsedWidth : _expandedWidth,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: content,
    );
  }
}
