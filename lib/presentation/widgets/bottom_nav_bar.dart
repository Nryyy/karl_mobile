import 'package:flutter/material.dart';

typedef NavigateCallback = void Function(String route);

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    Key? key,
    required this.currentRoute,
    required this.onNavigate,
  }) : super(key: key);

  final String currentRoute;
  final NavigateCallback onNavigate;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(
      label: 'Головна',
      icon: Icons.dashboard_outlined,
      route: '/dashboard',
    ),
    _NavItem(
      label: 'Документи',
      icon: Icons.description_outlined,
      route: '/documents',
    ),
    _NavItem(
      label: 'Погодження',
      icon: Icons.pending_actions_outlined,
      route: '/approvals',
    ),
    _NavItem(label: 'Архів', icon: Icons.archive_outlined, route: '/archive'),
    _NavItem(label: 'Акаунт', icon: Icons.person_outline, route: '/account'),
  ];

  int get _currentIndex {
    final idx = _items.indexWhere((e) => currentRoute.startsWith(e.route));
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) => onNavigate(_items[index].route),
      items: _items
          .map(
            (i) => BottomNavigationBarItem(icon: Icon(i.icon), label: i.label),
          )
          .toList(),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
  final String label;
  final IconData icon;
  final String route;
}
