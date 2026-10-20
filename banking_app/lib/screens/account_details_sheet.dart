import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/hz.dart';
import '../state/bank_controller.dart';
import '../widgets/common.dart';

/// Sort code, account number and IBAN with copy buttons, plus one tap to
/// copy everything for sharing.
void showAccountDetails(BuildContext context) {
  final bank = context.read<BankController>();
  final a = bank.account;
  final rows = [
    ('Name', bank.profile.name),
    ('Sort code', a.formattedSortCode),
    ('Account number', a.accountNumber),
    ('IBAN', a.iban),
    ('BIC', 'HRZNGB2L'),
  ];
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Account details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            for (final r in rows)
              ListTile(
                title: Text(r.$1, style: Theme.of(context).textTheme.bodySmall),
                subtitle: Text(
                  r.$2,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: IconButton(
                  tooltip: 'Copy ${r.$1.toLowerCase()}',
                  icon: const Icon(HzIcons.copy),
                  onPressed: () => copyToClipboard(context, r.$2, r.$1),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: FilledButton.icon(
                icon: const Icon(HzIcons.share),
                label: const Text('Copy all details'),
                onPressed: () => copyToClipboard(
                  context,
                  'Name: ${bank.profile.name}\n'
                      'Sort code: ${a.formattedSortCode}\n'
                      'Account number: ${a.accountNumber}',
                  'Account details',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
