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
                      const PopupMenuItem(value: 'system', child: Text('System')),
                      const PopupMenuItem(value: 'en', child: Text('English')),
                      const PopupMenuItem(value: 'uk', child: Text('Українська')),
                      const PopupMenuItem(value: 'pl', child: Text('Polski')),
                    ],
                  ),
                  IconButton(
                    tooltip: _collapsed ? 'Розгорнути' : 'Згорнути',
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
                      label: 'Dashboard',
                      icon: Icons.dashboard,
                      selected:
                          widget.currentRoute == '/' ||
                          widget.currentRoute == '/dashboard',
                      onTap: () => widget.onNavigate('/'),
                      tooltip: 'Головна сторінка',
                      showLabel: !_collapsed,
                    ),
                    const SizedBox(height: 6),
                    SidebarItem(
                      label: 'Мої документи',
                      icon: Icons.description,
                      selected: widget.currentRoute == '/documents',
                      onTap: () => widget.onNavigate('/documents'),
                      tooltip: 'Всі ваші документи',
                      showLabel: !_collapsed,
                    ),
                    const SizedBox(height: 6),
                    SidebarItem(
                      label: 'Архів',
                      icon: Icons.archive,
                      selected: widget.currentRoute == '/archive',
                      onTap: () => widget.onNavigate('/archive'),
                      tooltip: 'Архівовані документи',
                      showLabel: !_collapsed,
                    ),
                    const SizedBox(height: 6),
                    if (widget.isAdmin) ...[
                      SidebarItem(
                        label: 'Адмін панель',
                        icon: Icons.admin_panel_settings,
                        selected: widget.currentRoute == '/admin',
                        onTap: () => widget.onNavigate('/admin'),
                        tooltip: 'Адмін-панель (тільки для адміністраторів)',
                        showLabel: !_collapsed,
                      ),
                      const SizedBox(height: 6),
                    ],
                    SidebarItem(
                      label: 'Налаштування',
                      icon: Icons.settings,
                      selected: widget.currentRoute == '/settings',
                      onTap: () => widget.onNavigate('/settings'),
                      tooltip: 'Налаштування профілю',
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
                            const PopupMenuItem(value: 'system', child: Text('System')),
                            const PopupMenuItem(value: 'en', child: Text('English')),
                            const PopupMenuItem(value: 'uk', child: Text('Українська')),
                            const PopupMenuItem(value: 'pl', child: Text('Polski')),
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
