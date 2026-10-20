import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../design/hz.dart';
import '../models/models.dart';
import '../state/bank_controller.dart';
import '../utils/money.dart';
import '../widgets/common.dart';
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
    final hz = context.hz;
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
      color: hz.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Hero(hidden: hidden)),
          SliverToBoxAdapter(
            child: ResponsiveBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: HzSpace.s4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: HzSpace.s3),
                    child: Row(
                      children: [
                        Expanded(
                          child: QuickAction(
                            icon: HzIcons.pay,
                            label: 'Pay',
                            onTap: () => startPayFlow(context),
                          ),
                        ),
                        Expanded(
                          child: QuickAction(
                            icon: HzIcons.request,
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
                            icon: HzIcons.pots,
                            label: 'Pots',
                            onTap: () =>
                                HomeShell.of(context)?.goTo(ShellTab.pots),
                          ),
                        ),
                        Expanded(
                          child: QuickAction(
                            icon: HzIcons.details,
                            label: 'Details',
                            onTap: () => showAccountDetails(context),
                          ),
                        ),
                        Expanded(
                          child: QuickAction(
                            icon: HzIcons.freeze,
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
                      icon: HzIcons.mail,
                      color: hz.brand,
                      title: 'Your new card is on its way',
                      body: 'Got it? Activate it from the Card tab.',
                      onTap: () => HomeShell.of(context)?.goTo(ShellTab.card),
                    ),
                  for (final r in pendingRequests.take(2))
                    _Notice(
                      icon: HzIcons.request,
                      color: hz.catSavings,
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
                              leading: s.kind == ScheduleKind.directDebit
                                  ? MerchantAvatar(
                                      category: s.category,
                                      size: 40,
                                    )
                                  : InitialsAvatar(s.name, size: 40),
                              title: Text(s.name),
                              subtitle: Text(
                                '${s.kind == ScheduleKind.directDebit ? 'Direct Debit' : 'Standing order'} · ${_dueLabel(s.nextDate, bank.now)}',
                              ),
                              trailing: Text(
                                formatMoney(s.amountCents),
                                style: HzType.amountRow.copyWith(color: hz.ink),
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
                    height: 132,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: HzSpace.s4,
                      ),
                      children: [
                        for (final p in bank.pots)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _PotChip(pot: p, hidden: hidden),
                          ),
                        const _NewPotChip(),
                      ],
                    ),
                  ),
                  TransactionFeed(
                    transactions: bank.feed,
                    now: bank.now,
                    onTap: openTx,
                    roundUpFor: bank.roundUpFor,
                  ),
                  const SizedBox(height: HzSpace.s8),
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

/// The brand-deep band at the top of Home: greeting, balance and pills,
/// with the logo's sun rising behind the balance.
class _Hero extends StatelessWidget {
  const _Hero({required this.hidden});
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final hz = context.hz;
    return Container(
      decoration: BoxDecoration(
        color: hz.brandDeep,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(HzRadius.xl),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ResponsiveBody(
              child: CustomPaint(
                painter: _HeroSunPainter(hz.sun, hz.brandTint),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    HzSpace.s4,
                    HzSpace.s2,
                    HzSpace.s2,
                    HzSpace.s6,
                  ),
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
                              decoration: BoxDecoration(
                                color: hz.surfaceRaised,
                                shape: BoxShape.circle,
                              ),
                              child: InitialsAvatar(
                                bank.profile.name,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Hi ${bank.profile.firstName}',
                              style: HzType.bodyStrong.copyWith(
                                color: hz.onHero,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _HeroIconButton(
                            tooltip: 'Search',
                            icon: HzIcons.search,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SearchScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: HzSpace.s2),
                          _HeroIconButton(
                            tooltip: hidden ? 'Show balance' : 'Hide balance',
                            icon: hidden ? HzIcons.hide : HzIcons.show,
                            onTap: () => bank.setHideBalance(!hidden),
                          ),
                        ],
                      ),
                      const SizedBox(height: HzSpace.s6),
                      Padding(
                        padding: const EdgeInsets.only(left: HzSpace.s1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current account',
                              style: HzType.caption.copyWith(
                                color: hz.onHeroMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            BalanceText(
                              bank.account.balanceCents,
                              key: const Key('balance'),
                              hidden: hidden,
                              color: hz.onHero,
                            ),
                            const SizedBox(height: HzSpace.s4),
                            Wrap(
                              spacing: HzSpace.s2,
                              runSpacing: HzSpace.s2,
                              children: [
                                _HeroPill(
                                  icon: HzIcons.calendar,
                                  text:
                                      'Spent today ${hidden ? '••' : formatMoney(bank.spentTodayCents)}',
                                ),
                                _HeroPill(
                                  icon: HzIcons.pots,
                                  text:
                                      'In pots ${hidden ? '••' : formatMoney(bank.potsTotalCents)}',
                                ),
                                if (bank.card.frozen)
                                  const _HeroPill(
                                    icon: HzIcons.freeze,
                                    text: 'Card frozen',
                                    frost: true,
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
          ),
        ],
      ),
    );
  }
}

/// The logo's sunrise, small and crisp, low on the hero's right edge.
class _HeroSunPainter extends CustomPainter {
  _HeroSunPainter(this.sun, this.line);
  final Color sun;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    const r = 28.0;
    final cx = size.width - 58;
    final horizon = size.height - 96;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, horizon), radius: r),
      3.14159,
      3.14159,
      true,
      Paint()..color = sun,
    );
    RRect bar(double w, double y, double h) => RRect.fromLTRBR(
      cx - w / 2,
      y,
      cx + w / 2,
      y + h,
      Radius.circular(h / 2),
    );
    canvas.drawRRect(
      bar(78, horizon + 6, 7),
      Paint()..color = line.withValues(alpha: .9),
    );
    canvas.drawRRect(
      bar(46, horizon + 19, 6),
      Paint()..color = line.withValues(alpha: .45),
    );
  }

  @override
  bool shouldRepaint(_HeroSunPainter old) => old.sun != sun || old.line != line;
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: hz.heroChip,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: hz.onHero),
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.text, this.frost = false});

  final IconData icon;
  final String text;
  final bool frost;

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    final fg = frost ? hz.onFrost : hz.onHero;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: frost ? hz.frost : hz.heroChip,
        borderRadius: BorderRadius.circular(HzRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(text, style: HzType.caption.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: HzSpace.s3),
    child: Panel(
      child: ListTile(
        onTap: onTap,
        leading: IconTile(icon: icon, color: color, size: 40, circle: true),
        title: Text(title),
        subtitle: Text(body),
        trailing: Icon(HzIcons.chevron, color: context.hz.inkSubtle),
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
    final hz = context.hz;
    final color = Color(pot.colorValue);
    return SizedBox(
      width: 150,
      child: Material(
        color: hz.surfaceRaised,
        borderRadius: BorderRadius.circular(HzRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(HzRadius.lg),
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
                    IconTile(
                      icon: HzIcons.pot(pot.icon),
                      color: color,
                      size: 36,
                    ),
                    const Spacer(),
                    if (pot.goalCents != null)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          value: pot.progress,
                          strokeWidth: 3.5,
                          strokeCap: StrokeCap.round,
                          color: color,
                          backgroundColor: color.withValues(alpha: .16),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  pot.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HzType.caption.copyWith(color: hz.inkMuted),
                ),
                Text(
                  hidden ? '£••' : formatMoney(pot.balanceCents),
                  style: HzType.title3.copyWith(color: hz.ink),
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
  const _NewPotChip();

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    return SizedBox(
      width: 110,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HzRadius.lg),
          side: BorderSide(color: hz.line, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(HzRadius.lg),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePotScreen()),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(HzIcons.add, color: hz.brand),
              const SizedBox(height: HzSpace.s1),
              Text(
                'New pot',
                style: HzType.bodyStrong.copyWith(color: hz.brand),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
