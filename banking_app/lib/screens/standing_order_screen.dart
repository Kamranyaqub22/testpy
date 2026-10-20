import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../design/hz.dart';
import '../models/models.dart';
import '../state/bank_controller.dart';
import '../utils/money.dart';
import '../widgets/common.dart';
import 'pay_flow.dart';

/// Set up a regular payment to a payee.
class StandingOrderScreen extends StatefulWidget {
  const StandingOrderScreen({super.key, this.payeeId, this.amountCents});

  final String? payeeId;
  final int? amountCents;

  @override
  State<StandingOrderScreen> createState() => _StandingOrderScreenState();
}

class _StandingOrderScreenState extends State<StandingOrderScreen> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.amountCents == null
        ? ''
        : (widget.amountCents! / 100).toStringAsFixed(2),
  );
  final _reference = TextEditingController();
  late String? _payeeId = widget.payeeId;
  Frequency _frequency = Frequency.monthly;
  late DateTime _start = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final bank = context.read<BankController>();
    final order = await bank.createStandingOrder(
      payeeId: _payeeId!,
      amountCents: parseAmountToCents(_amount.text)!,
      frequency: _frequency,
      firstDate: _start,
      reference: _reference.text,
    );
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          icon: HzIcons.repeat,
          title: 'Standing order set up',
          body:
              '${formatMoney(order.amountCents)} ${order.frequency.label.toLowerCase()} to '
              '${order.name}, starting ${DateFormat('d MMMM').format(_start)}.',
        ),
      ),
      (r) => r.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    return Scaffold(
      appBar: AppBar(title: const Text('New standing order')),
      body: ResponsiveBody(
        maxWidth: 560,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _payeeId,
                decoration: const InputDecoration(labelText: 'Pay'),
                items: [
                  for (final p in bank.payees)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _payeeId = v),
                validator: (v) => v == null ? 'Choose who to pay' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '£ ',
                ),
                validator: (v) => parseAmountToCents(v ?? '') == null
                    ? 'Enter an amount'
                    : null,
              ),
              const SizedBox(height: 14),
              SegmentedButton<Frequency>(
                segments: [
                  for (final f in Frequency.values)
                    ButtonSegment(value: f, label: Text(f.label)),
                ],
                selected: {_frequency},
                onSelectionChanged: (s) => setState(() => _frequency = s.first),
              ),
              const SizedBox(height: 14),
              Panel(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(HzIcons.calendar),
                  title: const Text('First payment'),
                  subtitle: Text(DateFormat('EEEE d MMMM y').format(_start)),
                  trailing: const Icon(HzIcons.calendar),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _start,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _start = picked);
                  },
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _reference,
                maxLength: 18,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Reference'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _save,
                child: const Text('Set up standing order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Direct Debits and standing orders, with the option to cancel.
class ScheduledPaymentsScreen extends StatelessWidget {
  const ScheduledPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final all = bank.scheduled;
    final monthly = all.fold(
      0,
      (s, p) =>
          s +
          (p.frequency == Frequency.monthly
              ? p.amountCents
              : p.amountCents * 52 ~/ 12),
    );

    Widget list(ScheduleKind kind) {
      final items = all.where((s) => s.kind == kind).toList();
      if (items.isEmpty) {
        return Center(
          child: Text(
            kind == ScheduleKind.directDebit
                ? 'No Direct Debits'
                : 'No standing orders',
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 96),
        children: [
          Panel(
            child: Column(
              children: [
                for (final s in items)
                  ListTile(
                    leading: s.kind == ScheduleKind.directDebit
                        ? MerchantAvatar(category: s.category, size: 40)
                        : InitialsAvatar(s.name, size: 40),
                    title: Text(s.name),
                    subtitle: Text(
                      '${s.frequency.label} · next ${DateFormat('d MMM').format(s.nextDate)}',
                    ),
                    trailing: Text(
                      formatMoney(s.amountCents),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    onTap: () async {
                      final ok = await confirm(
                        context,
                        title: 'Cancel ${s.name}?',
                        message: kind == ScheduleKind.directDebit
                            ? 'Cancelling a Direct Debit doesn’t cancel your '
                                  'contract with ${s.name}. Let them know too.'
                            : 'No more payments will be made to ${s.name}.',
                        action: 'Cancel payment',
                        destructive: true,
                      );
                      if (ok) await bank.cancelScheduled(s.id);
                    },
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Regular payments'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Direct Debits'),
              Tab(text: 'Standing orders'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(HzIcons.add),
          label: const Text('Standing order'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StandingOrderScreen()),
          ),
        ),
        body: ResponsiveBody(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'About ${formatMoney(monthly)} goes out in regular payments each month.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    list(ScheduleKind.directDebit),
                    list(ScheduleKind.standingOrder),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
