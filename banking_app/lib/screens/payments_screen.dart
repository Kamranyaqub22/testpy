import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/bank_controller.dart';
import '../utils/money.dart';
import '../widgets/common.dart';
import 'pay_flow.dart';
import 'request_screen.dart';
import 'standing_order_screen.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final pending = bank.requests
        .where((r) => r.status == RequestStatus.pending)
        .toList();
    final owed = pending.fold(0, (s, r) => s + r.amountCents);
    final theme = Theme.of(context);

    Widget action(
      IconData icon,
      String title,
      String sub,
      VoidCallback onTap, {
      Key? key,
    }) => Expanded(
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 28),
                const SizedBox(height: 18),
                Text(title, style: theme.textTheme.titleSmall),
                Text(sub, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );

    return SafeArea(
      child: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text('Payments', style: theme.textTheme.headlineMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  action(
                    Icons.arrow_upward_rounded,
                    'Pay someone',
                    'Bank transfer',
                    () => startPayFlow(context),
                    key: const Key('paySomeone'),
                  ),
                  const SizedBox(width: 10),
                  action(
                    Icons.arrow_downward_rounded,
                    'Request',
                    'Get paid back',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RequestScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Panel(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.event_repeat_rounded),
                    title: const Text(
                      'Direct Debits & standing orders',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${bank.scheduled.length} active'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScheduledPaymentsScreen(),
                      ),
                    ),
                  ),
                  const Divider(indent: 20, endIndent: 20),
                  ListTile(
                    leading: const Icon(Icons.mark_email_unread_outlined),
                    title: const Text(
                      'Requests',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      pending.isEmpty
                          ? 'Nobody owes you money'
                          : '${pending.length} waiting · ${formatMoney(owed)} owed to you',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RequestsListScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader('Payees'),
            Panel(
              child: Column(
                children: [
                  for (final p in bank.payees)
                    ListTile(
                      leading: InitialsAvatar(p.name, size: 40),
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(p.maskedDetails),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Payee options',
                        onSelected: (v) async {
                          if (v == 'pay') {
                            startPayFlow(context, payee: p);
                          } else if (v == 'regular') {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StandingOrderScreen(payeeId: p.id),
                              ),
                            );
                          } else {
                            final ok = await confirm(
                              context,
                              title: 'Delete ${p.name}?',
                              message: 'You’ll need their details again to pay them.',
                              action: 'Delete',
                              destructive: true,
                            );
                            if (ok) await bank.removePayee(p.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'pay', child: Text('Pay')),
                          PopupMenuItem(
                            value: 'regular',
                            child: Text('Set up a standing order'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                      onTap: () => startPayFlow(context, payee: p),
                    ),
                  ListTile(
                    leading: const Icon(Icons.person_add_alt_1_rounded),
                    title: const Text('Add a new payee'),
                    textColor: theme.colorScheme.primary,
                    iconColor: theme.colorScheme.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewPayeeScreen()),
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
