import 'package:flutter/material.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

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

  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    final List<_NavItem> items = <_NavItem>[
      _NavItem(label: loc?.dashboard ?? 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, route: '/dashboard'),
      _NavItem(label: loc?.documents ?? 'Documents', icon: Icons.description_outlined, selectedIcon: Icons.description, route: '/documents'),
      _NavItem(label: loc?.approvals ?? 'Approvals', icon: Icons.pending_actions_outlined, selectedIcon: Icons.pending_actions, route: '/approvals'),
      _NavItem(label: loc?.archive ?? 'Archive', icon: Icons.archive_outlined, selectedIcon: Icons.archive, route: '/archive'),
      _NavItem(label: loc?.account ?? 'Account', icon: Icons.person_outline, selectedIcon: Icons.person, route: '/account'),
    ];

    return NavigationBar(
      selectedIndex: items.indexWhere((e) => currentRoute.startsWith(e.route)) >= 0 ? items.indexWhere((e) => currentRoute.startsWith(e.route)) : 0,
      onDestinationSelected: (index) => onNavigate(items[index].route),
      backgroundColor: colorScheme.surfaceContainer,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 80,
      destinations: items.map((item) {
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
