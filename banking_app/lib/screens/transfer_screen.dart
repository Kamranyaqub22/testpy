import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/bank_controller.dart';
import '../utils/money.dart';
import '../widgets/common.dart';

enum _Mode { ownAccounts, payee }

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  _Mode _mode = _Mode.ownAccounts;
  String? _fromId;
  String? _toId;
  String? _payeeId;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final bank = context.read<BankController>();
    final cents = parseAmountToCents(_amount.text)!;
    final from = bank.accountById(_fromId!);
    final recipient = _mode == _Mode.ownAccounts
        ? bank.accountById(_toId!).name
        : bank.payees.firstWhere((p) => p.id == _payeeId).name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm transfer'),
        content: Text(
          'Send ${formatCents(cents)} from ${from.name} to $recipient?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      if (_mode == _Mode.ownAccounts) {
        await bank.transferBetweenAccounts(
          fromId: _fromId!,
          toId: _toId!,
          amountCents: cents,
          note: _note.text,
        );
      } else {
        await bank.sendToPayee(
          fromId: _fromId!,
          payeeId: _payeeId!,
          amountCents: cents,
          note: _note.text,
        );
      }
      if (!mounted) return;
      showSnack(context, 'Sent ${formatCents(cents)} to $recipient');
      _amount.clear();
      _note.clear();
      widget.onDone();
    } on BankException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addPayee() async {
    final payee = await showDialog<String>(
      context: context,
      builder: (_) => const _AddPayeeDialog(),
    );
    if (payee != null) setState(() => _payeeId = payee);
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final accounts = bank.accounts;
    final payees = bank.payees;
    // Drop selections that no longer exist (e.g. a removed payee).
    if (_payeeId != null && !payees.any((p) => p.id == _payeeId)) {
      _payeeId = null;
    }

    return ResponsiveBody(
      maxWidth: 560,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Text(
              'Move money',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SegmentedButton<_Mode>(
              segments: const [
                ButtonSegment(
                  value: _Mode.ownAccounts,
                  icon: Icon(Icons.swap_horiz),
                  label: Text('My accounts'),
                ),
                ButtonSegment(
                  value: _Mode.payee,
                  icon: Icon(Icons.person_outline),
                  label: Text('Pay someone'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              isExpanded: true,
              key: const Key('fromAccount'),
              initialValue: _fromId,
              decoration: const InputDecoration(labelText: 'From'),
              items: [
                for (final a in accounts)
                  DropdownMenuItem(
                    value: a.id,
                    child: Text(
                      '${a.name} · ${formatCents(a.balanceCents)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _fromId = v),
              validator: (v) => v == null ? 'Choose an account' : null,
            ),
            const SizedBox(height: 16),
            if (_mode == _Mode.ownAccounts)
              DropdownButtonFormField<String>(
                isExpanded: true,
                key: const Key('toAccount'),
                initialValue: _toId,
                decoration: const InputDecoration(labelText: 'To'),
                items: [
                  for (final a in accounts)
                    DropdownMenuItem(
                      value: a.id,
                      child: Text(a.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _toId = v),
                validator: (v) {
                  if (v == null) return 'Choose an account';
                  if (v == _fromId) return 'Choose a different account';
                  return null;
                },
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      key: ValueKey('payee-$_payeeId'),
                      initialValue: _payeeId,
                      decoration: const InputDecoration(labelText: 'To'),
                      items: [
                        for (final p in payees)
                          DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              '${p.name} · ••${p.accountNumber.substring(p.accountNumber.length - 4)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _payeeId = v),
                      validator: (v) => v == null ? 'Choose a payee' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: IconButton.filledTonal(
                      tooltip: 'Add payee',
                      onPressed: _addPayee,
                      icon: const Icon(Icons.person_add_alt),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('amount'),
              controller: _amount,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              validator: (v) {
                final cents = parseAmountToCents(v ?? '');
                if (cents == null) return 'Enter a valid amount';
                if (_fromId != null &&
                    cents > bank.accountById(_fromId!).balanceCents) {
                  return 'Insufficient funds';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('submitTransfer'),
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.send),
              label: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Review & send'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Returns the new payee's id when saved.
class _AddPayeeDialog extends StatefulWidget {
  const _AddPayeeDialog();

  @override
  State<_AddPayeeDialog> createState() => _AddPayeeDialogState();
}

class _AddPayeeDialogState extends State<_AddPayeeDialog> {
  final _name = TextEditingController();
  final _number = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final payee = await context.read<BankController>().addPayee(
        name: _name.text,
        accountNumber: _number.text,
      );
      if (mounted) Navigator.pop(context, payee.id);
    } on BankException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add payee'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _number,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Account number',
            errorText: _error,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}
