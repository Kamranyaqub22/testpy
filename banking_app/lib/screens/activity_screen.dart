import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bank_transaction.dart';
import '../state/bank_controller.dart';
import '../widgets/common.dart';
import 'transaction_details.dart';

enum _Direction { all, moneyIn, moneyOut }

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, this.initialAccountId});

  final String? initialAccountId;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late String? _accountId = widget.initialAccountId;
  _Direction _direction = _Direction.all;
  String _query = '';

  bool _matches(BankTransaction t) {
    if (_accountId != null && t.accountId != _accountId) return false;
    if (_direction == _Direction.moneyIn && !t.isCredit) return false;
    if (_direction == _Direction.moneyOut && t.isCredit) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return t.description.toLowerCase().contains(q) ||
        (t.note?.toLowerCase().contains(q) ?? false) ||
        t.category.name.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final items = bank.transactions.where(_matches).toList();

    return ResponsiveBody(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Activity',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                DropdownButton<String?>(
                  value: _accountId,
                  underline: const SizedBox.shrink(),
                  onChanged: (v) => setState(() => _accountId = v),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All accounts'),
                    ),
                    for (final a in bank.accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search transactions',
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_Direction>(
                segments: const [
                  ButtonSegment(value: _Direction.all, label: Text('All')),
                  ButtonSegment(value: _Direction.moneyIn, label: Text('In')),
                  ButtonSegment(value: _Direction.moneyOut, label: Text('Out')),
                ],
                selected: {_direction},
                onSelectionChanged: (s) => setState(() => _direction = s.first),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No matching transactions.'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) => TransactionTile(
                      transaction: items[i],
                      onTap: () => showTransactionDetails(context, items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
