import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/bank_controller.dart';
import '../utils/money.dart';
import '../widgets/common.dart';
import '../widgets/theme.dart';
import 'account_details_sheet.dart';
import 'home_shell.dart';
import 'pay_flow.dart';
import 'pots_screen.dart';
import 'profile_screen.dart';
import 'request_screen.dart';
import 'search_screen.dart';
import 'transaction_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final upcoming = bank.upcoming(days: 7).take(3).toList();
    final pendingRequests = bank.requests
        .where((r) => r.status == RequestStatus.pending)
        .toList();
    final hidden = bank.hideBalance;

    void openTx(BankTransaction t) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransactionScreen(txId: t.id)),
    );

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Hero(hidden: hidden)),
          SliverToBoxAdapter(
            child: ResponsiveBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: QuickAction(
                            icon: Icons.arrow_upward_rounded,
                            label: 'Pay',
                            onTap: () => startPayFlow(context),
                          ),
                        ),
                        Expanded(
                          child: QuickAction(
                            icon: Icons.arrow_downward_rounded,
                            label: 'Request',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RequestScreen(),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: QuickAction(
                            icon: Icons.savings_outlined,
                            label: 'Pots',
                            onTap: () =>
                                HomeShell.of(context)?.goTo(ShellTab.pots),
                          ),
                        ),
                        Expanded(
                          child: QuickAction(
                            icon: Icons.numbers_rounded,
                            label: 'Details',
                            onTap: () => showAccountDetails(context),
                          ),
                        ),
                        Expanded(
                          child: QuickAction(
                            icon: Icons.ac_unit_rounded,
                            label: bank.card.frozen ? 'Unfreeze' : 'Freeze',
                            highlighted: bank.card.frozen,
                            onTap: () async {
                              await bank.setCardFrozen(!bank.card.frozen);
                              if (context.mounted) {
                                showSnack(
                                  context,
                                  bank.card.frozen
                                      ? 'Card frozen. Card payments will be declined.'
                                      : 'Card unfrozen',
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (bank.card.replacementOrdered)
                    _Notice(
                      emoji: '📬',
                      title: 'Your new card is on its way',
                      body: 'Got it? Activate it from the Card tab.',
                      onTap: () => HomeShell.of(context)?.goTo(ShellTab.card),
                    ),
                  for (final r in pendingRequests.take(2))
                    _Notice(
                      emoji: '💬',
                      title:
                          '${r.fromName} owes you ${formatMoney(r.amountCents)}',
                      body: r.note ?? 'Payment request',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RequestsListScreen(),
                        ),
                      ),
                    ),
                  if (upcoming.isNotEmpty) ...[
                    const SectionHeader('Coming up'),
                    Panel(
                      child: Column(
                        children: [
                          for (final s in upcoming)
                            ListTile(
                              leading: MerchantAvatar(
                                emoji: s.emoji,
                                category: s.category,
                                size: 40,
                              ),
                              title: Text(
                                s.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${s.kind == ScheduleKind.directDebit ? 'Direct Debit' : 'Standing order'} · ${_dueLabel(s.nextDate, bank.now)}',
                              ),
                              trailing: Text(
                                formatMoney(s.amountCents),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  SectionHeader(
                    'Pots',
                    action: TextButton(
                      onPressed: () =>
                          HomeShell.of(context)?.goTo(ShellTab.pots),
                      child: const Text('See all'),
                    ),
                  ),
                  SizedBox(
                    height: 124,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final p in bank.pots)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _PotChip(pot: p, hidden: hidden),
                          ),
                        _NewPotChip(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TransactionFeed(
                    transactions: bank.feed,
                    now: bank.now,
                    onTap: openTx,
                    roundUpFor: bank.roundUpFor,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _dueLabel(DateTime d, DateTime now) {
    final days = DateTime(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'tomorrow';
    return 'in $days days · ${DateFormat('EEE d MMM').format(d)}';
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.hidden});
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    const white = Colors.white;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Brand.ink, Color(0xFF1B2A6B)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: ResponsiveBody(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      key: const Key('openProfile'),
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: white,
                          shape: BoxShape.circle,
                        ),
                        child: InitialsAvatar(bank.profile.name, size: 36),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hi ${bank.profile.firstName}',
                        style: const TextStyle(
                          color: white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Search',
                      color: white,
                      icon: const Icon(Icons.search_rounded),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      ),
                    ),
                    IconButton(
                      tooltip: hidden ? 'Show balance' : 'Hide balance',
                      color: white,
                      icon: Icon(
                        hidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => bank.setHideBalance(!hidden),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balance',
                        style: TextStyle(
                          color: white.withValues(alpha: .7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      BalanceText(
                        bank.account.balanceCents,
                        key: const Key('balance'),
                        hidden: hidden,
                        size: 46,
                        color: white,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeroPill(
                            icon: Icons.today_rounded,
                            text:
                                'Spent today ${hidden ? '••' : formatMoney(bank.spentTodayCents)}',
                          ),
                          _HeroPill(
                            icon: Icons.savings_outlined,
                            text:
                                'In pots ${hidden ? '••' : formatMoney(bank.potsTotalCents)}',
                          ),
                          if (bank.card.frozen)
                            const _HeroPill(
                              icon: Icons.ac_unit_rounded,
                              text: 'Card frozen',
                              highlight: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.text,
    this.highlight = false,
  });

  final IconData icon;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: highlight ? Brand.frost : Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: highlight ? Brand.ink : Colors.white),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: highlight ? Brand.ink : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.emoji,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Panel(
      child: ListTile(
        onTap: onTap,
        leading: Text(emoji, style: const TextStyle(fontSize: 26)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(body),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    ),
  );
}

class _PotChip extends StatelessWidget {
  const _PotChip({required this.pot, required this.hidden});
  final Pot pot;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(pot.colorValue);
    return SizedBox(
      width: 150,
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PotDetailScreen(potId: pot.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(pot.emoji, style: const TextStyle(fontSize: 22)),
                    const Spacer(),
                    if (pot.goalCents != null)
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          value: pot.progress,
                          strokeWidth: 3.5,
                          color: color,
                          backgroundColor: color.withValues(alpha: .18),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  pot.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  hidden ? '£••' : formatMoney(pot.balanceCents),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewPotChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 110,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePotScreen()),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: theme.colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                'New pot',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
