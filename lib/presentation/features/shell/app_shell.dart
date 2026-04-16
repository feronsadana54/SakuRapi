import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../router/app_router.dart';

/// Root scaffold that wraps all main tab screens.
/// Renders [BottomNavigationBar] on mobile and [NavigationRail] on tablet.
class AppShell extends StatelessWidget {
  final Widget child;
  final String location;

  const AppShell({
    required this.child,
    required this.location,
    super.key,
  });

  static const _tabs = [
    AppRoutes.home,
    AppRoutes.transactionList,
    AppRoutes.reports,
    AppRoutes.settings,
  ];

  int get _currentIndex {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  void _onTabTap(BuildContext context, int index) {
    if (_currentIndex == index) return;
    context.go(_tabs[index]);
  }

  static const _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: AppStrings.navHome,
    ),
    _NavItem(
      icon: Icons.swap_horiz_outlined,
      activeIcon: Icons.swap_horiz_rounded,
      label: AppStrings.navTransactions,
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: AppStrings.navReports,
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: AppStrings.navSettings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (context.isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => _onTabTap(context, i),
              labelType: NavigationRailLabelType.selected,
              leading: const SizedBox(height: 8),
              destinations: _navItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.activeIcon),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    final showLabels = !context.isSmall;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => _onTabTap(context, i),
        showSelectedLabels: showLabels,
        showUnselectedLabels: showLabels,
        items: _navItems
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label});
}
