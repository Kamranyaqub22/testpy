import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../design/hz.dart';
import '../models/models.dart';
import '../state/bank_controller.dart';
import '../utils/money.dart';
import '../widgets/common.dart';
import '../widgets/keypads.dart';
import 'passcode_sheet.dart';
import 'standing_order_screen.dart';

/// Starts the "Pay someone" journey, optionally for a known payee.
void startPayFlow(BuildContext context, {Payee? payee}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => payee == null
          ? const ChoosePayeeScreen()
          : AmountScreen(payeeId: payee.id),
    ),
  );
}

class ChoosePayeeScreen extends StatefulWidget {
  const ChoosePayeeScreen({super.key});

  @override
  State<ChoosePayeeScreen> createState() => _ChoosePayeeScreenState();
}

class _ChoosePayeeScreenState extends State<ChoosePayeeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final payees = bank.payees
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Pay someone')),
      body: ResponsiveBody(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(HzIcons.search),
                  hintText: 'Search payees',
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            Panel(
              child: ListTile(
                key: const Key('newPayee'),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary
                      .withValues(alpha: .14),
                  child: Icon(
                    HzIcons.addPerson,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text('New payee'),
                subtitle: const Text('Pay with a sort code and account number'),
                trailing: const Icon(HzIcons.chevron),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewPayeeScreen()),
                ),
              ),
            ),
            const SectionHeader('Your payees'),
            if (payees.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No payees found'),
              ),
            if (payees.isNotEmpty)
              Panel(
                child: Column(
                  children: [
                    for (final p in payees)
                      ListTile(
                        leading: InitialsAvatar(p.name, size: 40),
                        title: Text(p.name),
                        subtitle: Text(p.maskedDetails),
                        trailing: const Icon(HzIcons.chevron),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AmountScreen(payeeId: p.id),
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

class NewPayeeScreen extends StatefulWidget {
  const NewPayeeScreen({super.key});

  @override
  State<NewPayeeScreen> createState() => _NewPayeeScreenState();
}

class _NewPayeeScreenState extends State<NewPayeeScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sort = TextEditingController();
  final _account = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _sort.dispose();
    _account.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_form.currentState!.validate()) return;
    final bank = context.read<BankController>();
    final result = bank.checkPayee(
      name: _name.text,
      accountNumber: _account.text,
    );
    final chosenName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CopSheet(typedName: _name.text.trim(), result: result),
    );
    if (chosenName == null || !mounted) return;
    try {
      final payee = await bank.addPayee(
        name: chosenName,
        sortCode: _sort.text,
        accountNumber: _account.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AmountScreen(payeeId: payee.id)),
      );
    } on BankException catch (e) {
      if (mounted) showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('New payee')),
      body: ResponsiveBody(
        maxWidth: 560,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Who are you paying?', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'We’ll check the name with their bank before you pay.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('payeeName'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name or business name',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter their name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('payeeSortCode'),
                controller: _sort,
                keyboardType: TextInputType.number,
                // Digits only: inserting dashes while typing can drop
                // keystrokes on the web, so the formatted value is shown
                // underneath instead.
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Sort code',
                  hintText: '6 digits',
                  helperText: _sort.text.length == 6
                      ? '${_sort.text.substring(0, 2)}-${_sort.text.substring(2, 4)}-${_sort.text.substring(4)}'
                      : null,
                ),
                validator: (v) =>
                    (v ?? '').length != 6 ? 'Sort codes have 6 digits' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('payeeAccount'),
                controller: _account,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: const InputDecoration(labelText: 'Account number'),
                validator: (v) => (v ?? '').length != 8
                    ? 'Account numbers have 8 digits'
                    : null,
              ),
              const SizedBox(height: 16),
              Panel(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Demo tip: try account 12345678 with the name “Jon Smith” '
                  'to see a close match, or any number starting with 0 to '
                  'see a bank that can’t be checked.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('checkPayee'),
                onPressed: _continue,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirmation of Payee outcome. Pops with the name to save, or null.
class _CopSheet extends StatelessWidget {
  const _CopSheet({required this.typedName, required this.result});

  final String typedName;
  final CopResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registered = result.registeredName ?? typedName;
    final (icon, color, title, body) = switch (result.outcome) {
      CopOutcome.match => (
        HzIcons.verified,
        context.hz.positive,
        'Name matches',
        'The account is held by $registered.',
      ),
      CopOutcome.closeMatch => (
        HzIcons.question,
        context.hz.warning,
        'Did you mean $registered?',
        'The name you entered is close to the name on the account. '
            'Check it with the person you’re paying.',
      ),
      CopOutcome.noMatch => (
        HzIcons.report,
        context.hz.negative,
        'The name doesn’t match',
        'This account isn’t held by $typedName. If you continue, your money '
            'could go to the wrong person and you may not get it back.',
      ),
      CopOutcome.unavailable => (
        HzIcons.info,
        context.hz.info,
        'We couldn’t check this name',
        'Their bank doesn’t support name checks. Make sure the details are '
            'right before you pay.',
      ),
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          key: Key('cop-${result.outcome.name}'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, color: color, size: 56),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (result.outcome == CopOutcome.closeMatch) ...[
              FilledButton(
                key: const Key('useSuggestedName'),
                onPressed: () => Navigator.pop(context, registered),
                child: Text('Use $registered'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Edit details'),
              ),
            ] else if (result.outcome == CopOutcome.match) ...[
              FilledButton(
                key: const Key('copContinue'),
                onPressed: () => Navigator.pop(context, registered),
                child: const Text('Continue'),
              ),
            ] else ...[
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Edit details'),
              ),
              const SizedBox(height: 10),
              TextButton(
                key: const Key('copContinueAnyway'),
                style: TextButton.styleFrom(
                  foregroundColor: result.outcome == CopOutcome.noMatch
                      ? context.hz.negative
                      : null,
                ),
                onPressed: () => Navigator.pop(context, typedName),
                child: const Text('Continue anyway'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AmountScreen extends StatefulWidget {
  const AmountScreen({super.key, required this.payeeId});
  final String payeeId;

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  int? _cents;

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final payee = bank.payeeById(widget.payeeId);
    final balance = bank.account.balanceCents;
    final tooMuch = _cents != null && _cents! > balance;
    final overLimit =
        _cents != null && _cents! > BankController.maxPaymentCents;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            InitialsAvatar(payee.name, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payee.name, overflow: TextOverflow.ellipsis),
                  Text(
                    payee.maskedDetails,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ResponsiveBody(
              maxWidth: 400,
              child: Column(
                children: [
                  AmountEntry(
                    helper: 'Balance ${formatMoney(balance)}',
                    errorText: tooMuch
                        ? 'You only have ${formatMoney(balance)}'
                        : overLimit
                        ? 'The limit is ${formatMoney(BankController.maxPaymentCents)} per payment'
                        : null,
                    onChanged: (c, _) => setState(() => _cents = c),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('amountNext'),
                    onPressed: _cents == null || tooMuch || overLimit
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewPaymentScreen(
                                payeeId: payee.id,
                                amountCents: _cents!,
                              ),
                            ),
                          ),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReviewPaymentScreen extends StatefulWidget {
  const ReviewPaymentScreen({
    super.key,
    required this.payeeId,
    required this.amountCents,
  });

  final String payeeId;
  final int amountCents;

  @override
  State<ReviewPaymentScreen> createState() => _ReviewPaymentScreenState();
}

class _ReviewPaymentScreenState extends State<ReviewPaymentScreen> {
  final _reference = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final bank = context.read<BankController>();
    final payee = bank.payeeById(widget.payeeId);
    if (!payee.hasBeenPaid) {
      final proceed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ScamCheckScreen(payeeName: payee.name),
        ),
      );
      if (proceed != true || !mounted) return;
    }
    final ok = await confirmWithPasscode(
      context,
      title: 'Approve payment',
      subtitle: '${formatMoney(widget.amountCents)} to ${payee.name}',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await bank.payPayee(
        payeeId: payee.id,
        amountCents: widget.amountCents,
        reference: _reference.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            title: '${formatMoney(widget.amountCents)} sent',
            body:
                'to ${payee.name}. It should arrive within 2 hours, '
                'usually in seconds.',
          ),
        ),
        (r) => r.isFirst,
      );
    } on BankException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final payee = bank.payeeById(widget.payeeId);
    final theme = Theme.of(context);
    Widget row(String l, String v) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Text(v),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Check and pay')),
      body: ResponsiveBody(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Center(
              child: Text(
                formatMoney(widget.amountCents),
                style: theme.textTheme.displaySmall,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'to ${payee.name}',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 24),
            Panel(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  row('Sort code', payee.maskedDetails.split(' · ').first),
                  row('Account', '•••• ${payee.accountNumber.substring(4)}'),
                  row('From', 'Current account'),
                  row('When', 'Now'),
                  row(
                    'Balance after',
                    formatMoney(bank.account.balanceCents - widget.amountCents),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                key: const Key('reference'),
                controller: _reference,
                maxLength: 18,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Reference (optional)',
                  helperText: 'This shows on their statement',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                icon: const Icon(HzIcons.repeat),
                label: const Text('Make this a regular payment instead'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StandingOrderScreen(
                      payeeId: payee.id,
                      amountCents: widget.amountCents,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                key: const Key('sendPayment'),
                onPressed: _busy ? null : _send,
                child: Text('Send ${formatMoney(widget.amountCents)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks what a first payment to a new payee is for and warns about common
/// scams. Pops true to continue.
class ScamCheckScreen extends StatefulWidget {
  const ScamCheckScreen({super.key, required this.payeeName});
  final String payeeName;

  @override
  State<ScamCheckScreen> createState() => _ScamCheckScreenState();
}

class _ScamCheckScreenState extends State<ScamCheckScreen> {
  static const _reasons = [
    ('friends', LucideIcons.users, 'Paying friends or family', null),
    (
      'bill',
      LucideIcons.receiptText,
      'Paying a bill or invoice',
      'Invoice scams are common. If '
          'bank details came by email or changed recently, call the company on '
          'a number you trust to check.',
    ),
    (
      'buying',
      LucideIcons.shoppingBag,
      'Buying something',
      'If you haven’t seen the item in '
          'person, a bank transfer gives you less protection than a card. '
          'Be wary of prices that seem too good to be true.',
    ),
    (
      'investment',
      LucideIcons.trendingUp,
      'Making an investment',
      'Investment scams promise '
          'high, guaranteed returns. Check the firm is registered with the '
          'financial regulator before you pay.',
    ),
    (
      'safe',
      LucideIcons.siren,
      'Someone told me to move my money',
      'Stop. Banks and the '
          'police will never ask you to move money to a “safe account”. This is '
          'almost certainly a scam.',
    ),
  ];

  String? _choice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _reasons.where((r) => r.$1 == _choice).firstOrNull;
    final warning = selected?.$4;
    final blocked = _choice == 'safe';
    return Scaffold(
      appBar: AppBar(title: const Text('Before you pay')),
      body: ResponsiveBody(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'What’s this payment to ${widget.payeeName} for?',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'It’s your first payment to them. Your answer helps us spot scams.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            RadioGroup<String>(
              groupValue: _choice,
              onChanged: (v) => setState(() => _choice = v),
              child: Column(
                children: [
                  for (final r in _reasons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        child: RadioListTile<String>(
                          key: Key('reason-${r.$1}'),
                          value: r.$1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          secondary: Icon(r.$2, color: context.hz.inkMuted),
                          controlAffinity: ListTileControlAffinity.trailing,
                          title: Text(r.$3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (warning != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (blocked
                      ? context.hz.negativeTint
                      : context.hz.sunTint),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      HzIcons.warning,
                      color: blocked ? context.hz.negative : context.hz.warning,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(warning)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (blocked)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: context.hz.negative,
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel this payment'),
              )
            else
              FilledButton(
                key: const Key('scamContinue'),
                onPressed: _choice == null
                    ? null
                    : () => Navigator.pop(context, true),
                child: Text(
                  warning == null ? 'Continue' : 'I understand, continue',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.title,
    required this.body,
    this.icon = HzIcons.success,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: 480,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  builder: (context, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Center(
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: context.hz.brand,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, color: context.hz.onBrand, size: 52),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  title,
                  key: const Key('successTitle'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  key: const Key('done'),
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
