import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/account.dart';
import '../models/bank_transaction.dart';
import '../utils/money.dart';

/// Breakpoint above which the app uses a side rail and wider layouts.
const wideLayoutBreakpoint = 840.0;

/// Centers content and caps its width so pages look right on phones, tablets,
/// desktop windows and browsers alike.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.maxWidth = 960});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.account, this.onTap});

  final Account account;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSavings = account.type == AccountType.savings;
    final background = isSavings
        ? scheme.tertiaryContainer
        : scheme.primaryContainer;
    final foreground = isSavings
        ? scheme.onTertiaryContainer
        : scheme.onPrimaryContainer;

    return Card(
      color: background,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isSavings ? Icons.savings_outlined : Icons.account_balance,
                    color: foreground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      account.name,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    account.maskedNumber,
                    style: TextStyle(color: foreground.withValues(alpha: .7)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Available balance',
                style: TextStyle(color: foreground.withValues(alpha: .7)),
              ),
              const SizedBox(height: 4),
              Text(
                formatCents(account.balanceCents),
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: foreground, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData categoryIcon(TxCategory category) => switch (category) {
  TxCategory.income => Icons.payments_outlined,
  TxCategory.transfer => Icons.swap_horiz,
  TxCategory.groceries => Icons.local_grocery_store_outlined,
  TxCategory.dining => Icons.restaurant_outlined,
  TxCategory.shopping => Icons.shopping_bag_outlined,
  TxCategory.bills => Icons.receipt_long_outlined,
  TxCategory.transport => Icons.directions_bus_outlined,
  TxCategory.entertainment => Icons.movie_outlined,
  TxCategory.other => Icons.send_outlined,
};

String categoryLabel(TxCategory category) =>
    category.name[0].toUpperCase() + category.name.substring(1);

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onTap});

  final BankTransaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final credit = transaction.isCredit;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        foregroundColor: scheme.onSecondaryContainer,
        child: Icon(categoryIcon(transaction.category)),
      ),
      title: Text(
        transaction.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(DateFormat.yMMMd().format(transaction.date)),
      trailing: Text(
        formatCents(transaction.amountCents, showSign: true),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: credit ? Colors.green.shade600 : scheme.onSurface,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?action,
      ],
    ),
  );
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
