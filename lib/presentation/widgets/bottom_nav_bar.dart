import 'package:flutter/material.dart';

typedef NavigateCallback = void Function(String route);

/// Material 3 NavigationBar with modern styling and animations.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  final String currentRoute;
  final NavigateCallback onNavigate;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(
      label: 'Головна',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: '/dashboard',
    ),
    _NavItem(
      label: 'Документи',
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
      route: '/documents',
    ),
    _NavItem(
      label: 'Погодження',
      icon: Icons.pending_actions_outlined,
      selectedIcon: Icons.pending_actions,
      route: '/approvals',
    ),
    _NavItem(
      label: 'Архів',
      icon: Icons.archive_outlined,
      selectedIcon: Icons.archive,
      route: '/archive',
    ),
    _NavItem(
      label: 'Акаунт',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      route: '/account',
    ),
  ];

  int get _currentIndex {
    final idx = _items.indexWhere((e) => currentRoute.startsWith(e.route));
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) => onNavigate(_items[index].route),
      backgroundColor: colorScheme.surfaceContainer,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 80,
      destinations: _items.map((item) {
        return NavigationDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon),
          label: item.label,
          tooltip: item.label,
        );
      }).toList(),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}
