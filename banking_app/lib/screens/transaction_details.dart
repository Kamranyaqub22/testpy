import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/bank_transaction.dart';
import '../state/bank_controller.dart';
import '../utils/money.dart';
import '../widgets/common.dart';

void showTransactionDetails(BuildContext context, BankTransaction t) {
  final account = context.read<BankController>().accountById(t.accountId);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) {
      final theme = Theme.of(context);
      Widget row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label, style: theme.textTheme.bodySmall),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  formatCents(t.amountCents, showSign: true),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(child: Text(t.description, textAlign: TextAlign.center)),
              const Divider(height: 32),
              row('Date', DateFormat.yMMMMd().add_jm().format(t.date)),
              row('Account', '${account.name} (${account.maskedNumber})'),
              row('Category', categoryLabel(t.category)),
              if (t.note != null) row('Note', t.note!),
              row('Reference', t.id),
            ],
          ),
        ),
      );
    },
  );
}
