import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_tank_controller/models/app_user.dart';
import 'package:water_tank_controller/providers/app_providers.dart';
import 'package:water_tank_controller/screens/control_panel_screen.dart';
import 'package:water_tank_controller/screens/dashboard_screen.dart';
import 'package:water_tank_controller/screens/history_screen.dart';
import 'package:water_tank_controller/screens/settings_screen.dart';
import 'package:water_tank_controller/screens/statistics_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).session!.user;
    final destinations = _destinationsFor(user.role);
    if (_index >= destinations.length) _index = 0;

    return Scaffold(
      body: SafeArea(
        child: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation, secondaryAnimation) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: destinations[_index].screen,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: destinations
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  List<_ShellDestination> _destinationsFor(UserRole role) {
    final base = <_ShellDestination>[
      const _ShellDestination(
        screen: DashboardScreen(),
        icon: Icons.dashboard_rounded,
        label: 'Home',
      ),
      const _ShellDestination(
        screen: HistoryScreen(),
        icon: Icons.timeline_rounded,
        label: 'History',
      ),
      const _ShellDestination(
        screen: StatisticsScreen(),
        icon: Icons.bar_chart_rounded,
        label: 'Stats',
      ),
    ];
    if (role == UserRole.administrator) {
      base.insert(
        1,
        const _ShellDestination(
          screen: ControlPanelScreen(),
          icon: Icons.power_settings_new_rounded,
          label: 'Control',
        ),
      );
      base.add(
        const _ShellDestination(
          screen: SettingsScreen(),
          icon: Icons.settings_rounded,
          label: 'Settings',
        ),
      );
    }
    return base;
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.screen,
    required this.icon,
    required this.label,
  });

  final Widget screen;
  final IconData icon;
  final String label;
}
