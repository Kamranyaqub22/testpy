import 'package:flutter/material.dart';

import '../design/hz.dart';
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
    ShellTab.home: (HzIcons.home, HzIcons.home, 'Home'),
    ShellTab.insights: (HzIcons.insights, HzIcons.insights, 'Insights'),
    ShellTab.payments: (HzIcons.payments, HzIcons.payments, 'Payments'),
    ShellTab.pots: (HzIcons.pots, HzIcons.pots, 'Pots'),
    ShellTab.card: (HzIcons.card, HzIcons.card, 'Card'),
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
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: HzSpace.s5),
                      child: HorizonMark(size: 40),
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
