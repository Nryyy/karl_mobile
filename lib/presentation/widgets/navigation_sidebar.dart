import 'package:flutter/material.dart';
import '_sidebar_item.dart';

typedef NavigateCallback = void Function(String route);

class NavigationSidebar extends StatefulWidget {
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
  State<NavigationSidebar> createState() => _NavigationSidebarState();
}

class _NavigationSidebarState extends State<NavigationSidebar> {
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
                        'Меню',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
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
                child: SidebarItem(
                  label: 'Допомога',
                  icon: Icons.help_outline,
                  selected: widget.currentRoute == '/help',
                  onTap: () => widget.onNavigate('/help'),
                  tooltip: 'Отримати допомогу',
                  showLabel: !_collapsed,
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
