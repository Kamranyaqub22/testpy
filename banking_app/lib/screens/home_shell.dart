import 'package:flutter/material.dart';

import '../widgets/common.dart';
import 'card_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'payments_screen.dart';
import 'pots_screen.dart';

/// Main navigation: a bottom bar on phones and a side rail on wide screens,
/// from the same code.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static final globalKey = GlobalKey<HomeShellState>();

  /// Lets any screen switch tabs, including pushed screens that sit above
  /// the shell in the navigator, e.g. "Check card settings".
  static HomeShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<HomeShellState>() ??
      globalKey.currentState;

  @override
  State<HomeShell> createState() => HomeShellState();
}

enum ShellTab { home, insights, payments, pots, card }

class HomeShellState extends State<HomeShell> {
  ShellTab _tab = ShellTab.home;

  static const _items = {
    ShellTab.home: (Icons.home_outlined, Icons.home_rounded, 'Home'),
    ShellTab.insights: (
      Icons.donut_large_outlined,
      Icons.donut_large_rounded,
      'Insights',
    ),
    ShellTab.payments: (
      Icons.swap_horiz_outlined,
      Icons.swap_horiz_rounded,
      'Payments',
    ),
    ShellTab.pots: (Icons.savings_outlined, Icons.savings_rounded, 'Pots'),
    ShellTab.card: (Icons.credit_card_outlined, Icons.credit_card, 'Card'),
  };

  void goTo(ShellTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(
      index: _tab.index,
      children: const [
        HomeScreen(),
        InsightsScreen(),
        PaymentsScreen(),
        PotsScreen(),
        CardScreen(),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= wideLayoutBreakpoint) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: _tab.index,
                    onDestinationSelected: (i) => goTo(ShellTab.values[i]),
                    labelType: NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'horizon',
                        style: TextStyle(
                          fontSize: 17,
                          letterSpacing: -.4,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    destinations: [
                      for (final e in _items.values)
                        NavigationRailDestination(
                          icon: Icon(e.$1),
                          selectedIcon: Icon(e.$2),
                          label: Text(e.$3),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab.index,
            onDestinationSelected: (i) => goTo(ShellTab.values[i]),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final e in _items.values)
                NavigationDestination(
                  icon: Icon(e.$1),
                  selectedIcon: Icon(e.$2),
                  label: e.$3,
                ),
            ],
          ),
        );
      },
    );
  }
}
