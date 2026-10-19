import 'package:flutter/material.dart';

import '../widgets/common.dart';
import 'activity_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'transfer_screen.dart';

/// Main navigation. Shows a bottom bar on narrow screens (phones) and a side
/// rail on wide ones (tablets, desktop, browser) from the same code.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _index = 0;
  String? _activityAccountId;

  static const _destinations = [
    (icon: Icons.home_outlined, selected: Icons.home, label: 'Home'),
    (
      icon: Icons.receipt_long_outlined,
      selected: Icons.receipt_long,
      label: 'Activity',
    ),
    (
      icon: Icons.swap_horiz_outlined,
      selected: Icons.swap_horiz,
      label: 'Transfer',
    ),
    (
      icon: Icons.settings_outlined,
      selected: Icons.settings,
      label: 'Settings',
    ),
  ];

  void _select(int index) => setState(() {
    _index = index;
    if (index != 1) _activityAccountId = null;
  });

  /// Opens the Activity tab, optionally filtered to one account.
  void showActivity({String? accountId}) => setState(() {
    _index = 1;
    _activityAccountId = accountId;
  });

  void showTransfer() => _select(2);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onViewAccount: (id) => showActivity(accountId: id),
        onViewAll: showActivity,
        onTransfer: showTransfer,
      ),
      ActivityScreen(
        key: ValueKey(_activityAccountId),
        initialAccountId: _activityAccountId,
      ),
      TransferScreen(onDone: () => _select(0)),
      const SettingsScreen(),
    ];
    final body = IndexedStack(index: _index, children: pages);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= wideLayoutBreakpoint) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Icon(
                        Icons.account_balance,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    destinations: [
                      for (final d in _destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selected),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          body: SafeArea(bottom: false, child: body),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selected),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }
}
