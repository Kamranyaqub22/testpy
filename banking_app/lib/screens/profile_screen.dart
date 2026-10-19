import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/demo_data.dart';
import '../state/bank_controller.dart';
import '../state/settings_controller.dart';
import '../utils/money.dart';
import '../widgets/common.dart';
import '../widgets/keypads.dart';
import '../widgets/theme.dart';
import 'account_details_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);

    Widget tile(
      IconData icon,
      String title, {
      String? subtitle,
      VoidCallback? onTap,
      Widget? trailing,
      Color? color,
      Key? key,
    }) => ListTile(
      key: key,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w700, color: color),
      ),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing:
          trailing ??
          (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
      onTap: onTap,
    );

    Future<void> simulate(Future<void> Function() action) => action();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ResponsiveBody(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Center(child: InitialsAvatar(bank.profile.name, size: 76)),
            const SizedBox(height: 10),
            Center(
              child: Text(bank.profile.name, style: theme.textTheme.titleLarge),
            ),
            Center(
              child: Text(
                bank.profile.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SectionHeader('Account'),
            Panel(
              child: Column(
                children: [
                  tile(
                    Icons.numbers_rounded,
                    'Account details',
                    subtitle:
                        '${bank.account.formattedSortCode} · ${bank.account.accountNumber}',
                    onTap: () => showAccountDetails(context),
                  ),
                  tile(
                    Icons.description_outlined,
                    'Statements',
                    subtitle: 'Monthly statements for your current account',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StatementsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader('Security'),
            Panel(
              child: Column(
                children: [
                  tile(
                    Icons.password_rounded,
                    'Change passcode',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _ChangePasscodeScreen(),
                      ),
                    ),
                  ),
                  tile(
                    Icons.lock_outline_rounded,
                    'Lock app now',
                    key: const Key('lockApp'),
                    onTap: () {
                      Navigator.popUntil(context, (r) => r.isFirst);
                      bank.lock();
                    },
                  ),
                ],
              ),
            ),
            const SectionHeader('Preferences'),
            Panel(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.visibility_off_outlined),
                    title: const Text(
                      'Hide balances',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('Useful when using the app in public'),
                    value: bank.hideBalance,
                    onChanged: bank.setHideBalance,
                  ),
                  const ListTile(
                    leading: Icon(Icons.palette_outlined),
                    title: Text(
                      'Appearance',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Auto'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (s) => settings.setThemeMode(s.first),
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader('Demo tools'),
            Panel(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: Text(
                      'Simulate events a real card network would send, to try '
                      'out notifications, declines and round-ups.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  tile(
                    Icons.contactless_outlined,
                    'Simulate a card payment',
                    key: const Key('simulateCard'),
                    onTap: () => simulate(() => _simulateCard(context)),
                  ),
                  tile(
                    Icons.casino_outlined,
                    'Simulate a gambling payment',
                    onTap: () => simulate(
                      () => _simulateCard(
                        context,
                        DemoData.merchants.firstWhere((m) => m.gambling),
                      ),
                    ),
                  ),
                  tile(
                    Icons.public_rounded,
                    'Simulate a payment abroad',
                    onTap: () => simulate(
                      () => _simulateCard(
                        context,
                        DemoData.merchants.firstWhere((m) => m.abroad),
                      ),
                    ),
                  ),
                  tile(
                    Icons.call_received_rounded,
                    'Simulate money coming in',
                    onTap: () => simulate(() async {
                      final tx = await bank.simulateIncomingPayment();
                      if (context.mounted) {
                        showBanner(
                          context,
                          emoji: '💸',
                          title:
                              '${tx.title} sent you ${formatMoney(tx.amountCents)}',
                          body: tx.reference ?? 'Bank transfer',
                        );
                      }
                    }),
                  ),
                ],
              ),
            ),
            const SectionHeader('Help'),
            Panel(
              child: Column(
                children: [
                  for (final faq in _faqs)
                    ExpansionTile(
                      shape: const Border(),
                      title: Text(
                        faq.$1,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      expandedAlignment: Alignment.centerLeft,
                      children: [Text(faq.$2)],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Panel(
              child: tile(
                Icons.delete_forever_outlined,
                'Close account and erase data',
                color: Brand.danger,
                onTap: () async {
                  final ok = await confirm(
                    context,
                    title: 'Close your account?',
                    message:
                        'Everything stored on this device will be erased. '
                        'This can’t be undone.',
                    action: 'Close account',
                    destructive: true,
                  );
                  if (ok && context.mounted) {
                    Navigator.popUntil(context, (r) => r.isFirst);
                    await bank.reset();
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Horizon Bank demo · not a real bank',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _faqs = [
    (
      'How do I freeze my card?',
      'Tap Freeze on the home screen or the Card tab. Card payments and cash '
          'withdrawals are declined until you unfreeze it. Direct Debits and '
          'bank transfers keep working.',
    ),
    (
      'What are round-ups?',
      'When you pay by card, we round the payment up to the nearest pound and '
          'move the spare change into the pot you choose.',
    ),
    (
      'What is Confirmation of Payee?',
      'When you add a new payee, we check the name you enter against the name '
          'on their account, so your money goes to the right person.',
    ),
    (
      'How long do payments take?',
      'Payments to UK accounts usually arrive in seconds, and always within '
          '2 hours.',
    ),
  ];

  static Future<void> _simulateCard(
    BuildContext context, [
    MerchantPreset? merchant,
  ]) async {
    final bank = context.read<BankController>();
    final result = await bank.simulateCardPayment(merchant);
    if (!context.mounted) return;
    final tx = result.payment;
    if (tx.isDeclined) {
      showBanner(
        context,
        emoji: '⛔',
        title: 'Payment declined at ${tx.title}',
        body: '${formatMoney(-tx.amountCents)} · ${tx.declineReason}',
      );
    } else {
      showBanner(
        context,
        emoji: tx.emoji ?? '💳',
        title: '${formatMoney(-tx.amountCents)} at ${tx.title}',
        body: result.roundUpCents > 0
            ? '${formatMoney(result.roundUpCents)} rounded up to your pot'
            : 'Balance ${formatMoney(bank.account.balanceCents)}',
      );
    }
  }
}

class _ChangePasscodeScreen extends StatefulWidget {
  const _ChangePasscodeScreen();

  @override
  State<_ChangePasscodeScreen> createState() => _ChangePasscodeScreenState();
}

class _ChangePasscodeScreenState extends State<_ChangePasscodeScreen> {
  int _stage = 0;
  String _current = '';
  String _next = '';

  @override
  Widget build(BuildContext context) {
    final bank = context.read<BankController>();
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ResponsiveBody(
            maxWidth: 380,
            child: switch (_stage) {
              0 => PasscodeEntry(
                key: const ValueKey(0),
                title: 'Enter your current passcode',
                onCompleted: (c) {
                  if (!bank.verifyPasscode(c)) return 'Wrong passcode';
                  setState(() {
                    _current = c;
                    _stage = 1;
                  });
                  return null;
                },
              ),
              1 => PasscodeEntry(
                key: const ValueKey(1),
                title: 'Choose a new passcode',
                onCompleted: (c) {
                  setState(() {
                    _next = c;
                    _stage = 2;
                  });
                  return null;
                },
              ),
              _ => PasscodeEntry(
                key: const ValueKey(2),
                title: 'Confirm your new passcode',
                onCompleted: (c) async {
                  if (c != _next) return 'Passcodes don’t match';
                  try {
                    await bank.changePasscode(current: _current, next: _next);
                  } on BankException catch (e) {
                    setState(() => _stage = 1);
                    return e.message;
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    showSnack(context, 'Passcode changed');
                  }
                  return null;
                },
              ),
            },
          ),
        ),
      ),
    );
  }
}

class StatementsScreen extends StatelessWidget {
  const StatementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Statements')),
      body: ResponsiveBody(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.only(top: 8),
          children: [
            Panel(
              child: Column(
                children: [
                  for (final m in bank.statementMonths)
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(
                        DateFormat('MMMM y').format(m),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        m.month == bank.now.month && m.year == bank.now.year
                            ? 'So far this month'
                            : 'Closing balance ${formatMoney(bank.statementFor(m).closingCents)}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StatementScreen(month: m),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A printable-style statement: header, summary box and a running balance.
class StatementScreen extends StatelessWidget {
  const StatementScreen({super.key, required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final s = bank.statementFor(month);
    final theme = Theme.of(context);
    var running = s.openingCents;
    final small = theme.textTheme.bodySmall;
    final tabular = const [FontFeature.tabularFigures()];

    return Scaffold(
      appBar: AppBar(title: Text(DateFormat('MMMM y').format(month))),
      body: ResponsiveBody(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Panel(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'horizon',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Text('Current account statement', style: small),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(bank.profile.name, style: theme.textTheme.titleSmall),
                  Text(
                    'Sort code ${bank.account.formattedSortCode} · '
                    'Account ${bank.account.accountNumber}',
                    style: small,
                  ),
                  Text(
                    '${DateFormat('d MMM y').format(s.month)} – '
                    '${DateFormat('d MMM y').format(DateTime(month.year, month.month + 1, 0))}',
                    style: small,
                  ),
                  const Divider(height: 28),
                  for (final r in [
                    ('Opening balance', s.openingCents),
                    ('Money in', s.inCents),
                    ('Money out', -s.outCents),
                    ('Closing balance', s.closingCents),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(child: Text(r.$1)),
                          Text(
                            formatMoney(r.$2),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFeatures: tabular,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Panel(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final t in s.transactions)
                    Builder(
                      builder: (context) {
                        running += t.amountCents;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 54,
                                child: Text(
                                  DateFormat('d MMM').format(t.date),
                                  style: small,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  t.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 86,
                                child: Text(
                                  formatMoney(t.amountCents),
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: tabular,
                                    color: t.amountCents > 0
                                        ? Brand.mint
                                        : null,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 92,
                                child: Text(
                                  formatMoney(running),
                                  textAlign: TextAlign.end,
                                  style: small?.copyWith(fontFeatures: tabular),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
