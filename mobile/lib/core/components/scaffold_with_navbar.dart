import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'premium_nav_bar.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({required this.navigationShell, Key? key})
    : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for floating effect
      body: navigationShell,
      bottomNavigationBar: PremiumNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
        items: const [
          PremiumNavItem(
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            label: 'Students',
          ),
          PremiumNavItem(
            icon: Icons.checklist_rtl_outlined,
            selectedIcon: Icons.checklist_rtl,
            label: 'Attendance',
          ),
          PremiumNavItem(
            icon: Icons.class_outlined,
            selectedIcon: Icons.class_,
            label: 'Classes',
          ),
          PremiumNavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
