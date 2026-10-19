import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/bank_controller.dart';
import '../utils/money.dart';
import '../widgets/common.dart';
import 'transaction_details.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onViewAccount,
    required this.onViewAll,
    required this.onTransfer,
  });

  final void Function(String accountId) onViewAccount;
  final VoidCallback onViewAll;
  final VoidCallback onTransfer;

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final theme = Theme.of(context);
    final summary = bank.thisMonthSummary;
    final recent = bank.transactions.take(5).toList();

    return ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${bank.userName.split(' ').first}',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text('Total balance', style: theme.textTheme.bodyMedium),
                      Text(
                        formatCents(bank.totalBalanceCents),
                        key: const Key('totalBalance'),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Lock',
                  icon: const Icon(Icons.lock_outline),
                  onPressed: bank.lock,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LayoutBuilder(
              builder: (context, c) {
                final columns = c.maxWidth >= 600 ? 2 : 1;
                final width = (c.maxWidth - (columns - 1) * 8) / columns;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in bank.accounts)
                      SizedBox(
                        width: width,
                        child: AccountCard(
                          account: a,
                          onTap: () => onViewAccount(a.id),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Money in this month',
                    value: formatCents(summary.income),
                    icon: Icons.arrow_downward,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Spent this month',
                    value: formatCents(summary.spending),
                    icon: Icons.arrow_upward,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: FilledButton.tonalIcon(
              onPressed: onTransfer,
              icon: const Icon(Icons.send),
              label: const Text('Send or transfer money'),
            ),
          ),
          SectionHeader(
            'Recent activity',
            action: TextButton(
              onPressed: onViewAll,
              child: const Text('See all'),
            ),
          ),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No transactions yet.'),
            ),
          for (final t in recent)
            TransactionTile(
              transaction: t,
              onTap: () => showTransactionDetails(context, t),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}
