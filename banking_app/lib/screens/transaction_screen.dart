import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../design/hz.dart';
import '../models/models.dart';
import '../state/bank_controller.dart';
import '../utils/money.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key, required this.txId});

  final String txId;

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final t = bank.transactionById(txId);
    final theme = Theme.of(context);
    final atMerchant = bank.transactions.where(
      (x) => x.title == t.title && !x.isDeclined,
    );
    final merchantTotal = atMerchant.fold(0, (s, x) => s + x.amountCents);
    final roundUp = bank.roundUpFor(t);
    final canSplit =
        !t.isIncoming &&
        !t.isDeclined &&
        t.kind != TxKind.pot &&
        t.kind != TxKind.roundUp;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ResponsiveBody(
            maxWidth: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: MerchantAvatar(
                    category: t.category,
                    size: 76,
                    declined: t.isDeclined,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  t.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  t.isIncoming
                      ? formatMoney(t.amountCents, showPlus: true)
                      : formatMoney(t.amountCents.abs()),
                  key: const Key('txAmount'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: t.isIncoming ? context.hz.positive : null,
                    decoration: t.isDeclined
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('EEEE d MMMM y, HH:mm').format(t.date),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Center(child: _StatusChip(t)),
                if (t.isDeclined) ...[
                  const SizedBox(height: 16),
                  _DeclinedHelp(t),
                ],
                const SizedBox(height: 20),
                Panel(
                  child: Column(
                    children: [
                      ListTile(
                        key: const Key('categoryRow'),
                        leading: Icon(
                          HzIcons.category(t.category),
                          color: context.hz.category(t.category),
                        ),
                        title: const Text('Category'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t.category.label,
                              style: HzType.bodyStrong.copyWith(
                                color: context.hz.ink,
                              ),
                            ),
                            Icon(HzIcons.chevron, color: context.hz.inkSubtle),
                          ],
                        ),
                        onTap: () => _pickCategory(context, t),
                      ),
                      const Divider(indent: 20, endIndent: 20),
                      ListTile(
                        leading: const Icon(HzIcons.note),
                        title: Text(t.note ?? 'Add a note'),
                        textColor: t.note == null
                            ? theme.colorScheme.primary
                            : null,
                        onTap: () => _editNote(context, t),
                      ),
                      if (roundUp != null) ...[
                        const Divider(indent: 20, endIndent: 20),
                        ListTile(
                          leading: Icon(
                            HzIcons.coins,
                            color: context.hz.catSavings,
                          ),
                          title: Text(
                            '${formatMoney(-roundUp.amountCents)} rounded up',
                          ),
                          subtitle: Text(
                            'Saved to ${roundUp.title.replaceFirst('Round-up to ', '')}',
                          ),
                        ),
                      ],
                      if (canSplit) ...[
                        const Divider(indent: 20, endIndent: 20),
                        ListTile(
                          key: const Key('splitBill'),
                          leading: const Icon(HzIcons.split),
                          title: Text(
                            t.splitRequestIds.isEmpty
                                ? 'Split the bill'
                                : 'Split with ${t.splitRequestIds.length} '
                                      '${t.splitRequestIds.length == 1 ? 'person' : 'people'}',
                          ),
                          trailing: const Icon(HzIcons.chevron),
                          onTap: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => _SplitSheet(tx: t),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SectionHeader('Details'),
                Panel(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      _Detail('Type', _kindLabel(t.kind)),
                      if (t.isCardPayment)
                        _Detail('Card', 'Debit card •••• ${bank.card.last4}'),
                      if (t.location != null) _Detail('Location', t.location!),
                      if (t.reference != null)
                        _Detail('Reference', t.reference!),
                      if (t.potId != null &&
                          bank.pots.any((p) => p.id == t.potId))
                        _Detail('Pot', bank.potById(t.potId!).name),
                      _Detail(
                        'Reference no.',
                        'HZN-${t.id.split('-').last.toUpperCase()}',
                      ),
                    ],
                  ),
                ),
                if (atMerchant.length > 1) ...[
                  const SectionHeader('History'),
                  Panel(
                    child: ListTile(
                      leading: const Icon(HzIcons.history),
                      title: Text(
                        '${atMerchant.length} payments with ${t.title}',
                      ),
                      subtitle: Text(
                        merchantTotal < 0
                            ? 'You’ve spent ${formatMoney(-merchantTotal)} in total'
                            : 'You’ve received ${formatMoney(merchantTotal)} in total',
                      ),
                    ),
                  ),
                ],
                const SectionHeader('Help'),
                Panel(
                  child: ListTile(
                    leading: const Icon(HzIcons.help),
                    title: Text(
                      t.disputed
                          ? 'We’re looking into this payment'
                          : 'Something wrong with this payment?',
                    ),
                    subtitle: t.disputed
                        ? const Text('We’ll update you within 10 working days.')
                        : null,
                    onTap: t.disputed || t.isIncoming
                        ? null
                        : () async {
                            final ok = await confirm(
                              context,
                              title: 'Report a problem',
                              message:
                                  'We’ll investigate this payment with ${t.title}. '
                                  'If you don’t recognise it, freeze your card first.',
                              action: 'Report payment',
                            );
                            if (ok) {
                              await bank.disputeTransaction(t.id);
                              if (context.mounted) {
                                showSnack(context, 'Thanks, we’re on it.');
                              }
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _kindLabel(TxKind k) => switch (k) {
    TxKind.card => 'Chip & PIN',
    TxKind.contactless => 'Contactless',
    TxKind.online => 'Online payment',
    TxKind.fasterPayment => 'Faster Payment',
    TxKind.directDebit => 'Direct Debit',
    TxKind.standingOrder => 'Standing order',
    TxKind.pot => 'Pot transfer',
    TxKind.roundUp => 'Round-up',
    TxKind.atm => 'Cash withdrawal',
    TxKind.income => 'Bank credit',
    TxKind.refund => 'Refund',
  };

  void _pickCategory(BuildContext context, BankTransaction t) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a category',
                style: Theme.of(sheet).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in TxCategory.values)
                    ChoiceChip(
                      avatar: Icon(
                        HzIcons.category(c),
                        color: sheet.hz.category(c),
                        size: 18,
                      ),
                      label: Text(c.label),
                      selected: c == t.category,
                      onSelected: (_) {
                        context.read<BankController>().setCategory(t.id, c);
                        Navigator.pop(sheet);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editNote(BuildContext context, BankTransaction t) async {
    final controller = TextEditingController(text: t.note);
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(hintText: 'e.g. Birthday present'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note != null && context.mounted) {
      await context.read<BankController>().setNote(t.id, note);
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.t);
  final BankTransaction t;

  @override
  Widget build(BuildContext context) => t.isDeclined
      ? const StatusPill(
          'Declined',
          tone: StatusTone.negative,
          icon: HzIcons.declined,
        )
      : t.disputed
      ? const StatusPill(
          'Disputed',
          tone: StatusTone.warning,
          icon: HzIcons.warning,
        )
      : t.status == TxStatus.pending
      ? const StatusPill(
          'Pending',
          tone: StatusTone.pending,
          icon: HzIcons.clock,
        )
      : const StatusPill(
          'Completed',
          tone: StatusTone.positive,
          icon: HzIcons.success,
        );
}

class _DeclinedHelp extends StatelessWidget {
  const _DeclinedHelp(this.t);
  final BankTransaction t;

  @override
  Widget build(BuildContext context) {
    final bank = context.read<BankController>();
    final frozen = t.declineReason == 'Your card is frozen' && bank.card.frozen;
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why was this declined?',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${t.declineReason}. No money left your account.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (frozen)
            OutlinedButton(
              onPressed: () async {
                await bank.setCardFrozen(false);
                if (context.mounted) showSnack(context, 'Card unfrozen');
              },
              child: const Text('Unfreeze card'),
            )
          else if (t.isCardPayment)
            OutlinedButton(
              onPressed: () {
                final shell = HomeShell.of(context);
                Navigator.popUntil(context, (r) => r.isFirst);
                shell?.goTo(ShellTab.card);
              },
              child: const Text('Check card settings'),
            ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _SplitSheet extends StatefulWidget {
  const _SplitSheet({required this.tx});
  final BankTransaction tx;

  @override
  State<_SplitSheet> createState() => _SplitSheetState();
}

class _SplitSheetState extends State<_SplitSheet> {
  final _people = <String>[];
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final name = _input.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _people.add(name);
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.read<BankController>();
    final share = widget.tx.amountCents.abs() ~/ (_people.length + 1);
    final suggestions = bank.payees
        .map((p) => p.name)
        .where((n) => !_people.contains(n) && !n.contains('Ltd'));
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Split ${formatMoney(widget.tx.amountCents.abs())}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Everyone pays an equal share. We’ll send each person a request.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const Chip(label: Text('You')),
              for (final p in _people)
                InputChip(
                  label: Text(p),
                  onDeleted: () => setState(() => _people.remove(p)),
                ),
              for (final s in suggestions)
                ActionChip(
                  avatar: const Icon(HzIcons.add, size: 16),
                  label: Text(s),
                  onPressed: () => setState(() => _people.add(s)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('splitName'),
            controller: _input,
            decoration: InputDecoration(
              labelText: 'Add someone',
              suffixIcon: IconButton(
                icon: const Icon(HzIcons.add),
                onPressed: _add,
              ),
            ),
            onSubmitted: (_) => _add(),
          ),
          const SizedBox(height: 16),
          if (_people.isNotEmpty)
            Text(
              'Each person pays ${formatMoney(share)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('sendSplit'),
            onPressed: _people.isEmpty
                ? null
                : () async {
                    await bank.splitTransaction(widget.tx.id, _people);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    showSnack(
                      context,
                      'Requests sent to ${_people.join(', ')}',
                    );
                  },
            child: const Text('Send requests'),
          ),
        ],
      ),
    );
  }
}
