import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/bank_controller.dart';
import '../utils/money.dart';
import '../widgets/common.dart';
import '../widgets/keypads.dart';
import '../widgets/theme.dart';

String requestLink(PaymentRequest r) =>
    'https://pay.horizon-demo.example/r/${r.id.split('-').last}';

/// Ask someone to pay you: amount, who, and an optional note, then a link
/// to share.
class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  int? _cents;
  bool _amountDone = false;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    try {
      final req = await context.read<BankController>().requestMoney(
        fromName: _name.text,
        amountCents: _cents!,
        note: _note.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => _RequestReady(request: req)),
      );
    } on BankException catch (e) {
      showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.read<BankController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Request money')),
      body: SafeArea(
        child: !_amountDone
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ResponsiveBody(
                    maxWidth: 400,
                    child: Column(
                      children: [
                        AmountEntry(
                          helper: 'How much are you asking for?',
                          onChanged: (c, _) => setState(() => _cents = c),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          key: const Key('requestAmountNext'),
                          onPressed: _cents == null
                              ? null
                              : () => setState(() => _amountDone = true),
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ResponsiveBody(
                maxWidth: 560,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Request ${formatMoney(_cents!)}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('requestName'),
                      controller: _name,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Who’s paying?',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final p in bank.payees.where(
                          (p) => !p.name.contains('Ltd'),
                        ))
                          ActionChip(
                            label: Text(p.name),
                            onPressed: () => _name.text = p.name,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _note,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'What’s it for? (optional)',
                        hintText: 'e.g. Pizza night 🍕',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const Key('createRequest'),
                      onPressed: _create,
                      child: const Text('Create request'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _RequestReady extends StatelessWidget {
  const _RequestReady({required this.request});
  final PaymentRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message =
        'Hi ${request.fromName.split(' ').first}, please pay me '
        '${formatMoney(request.amountCents)}'
        '${request.note == null ? '' : ' for ${request.note}'}: '
        '${requestLink(request)}';
    return Scaffold(
      appBar: AppBar(),
      body: ResponsiveBody(
        maxWidth: 520,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Center(child: Text('💌', style: TextStyle(fontSize: 64))),
            const SizedBox(height: 16),
            Text(
              'Your request is ready',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Send this message to ${request.fromName}. We’ll let you know '
              'when they pay.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Panel(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              child: SelectableText(message),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy message'),
              onPressed: () => copyToClipboard(context, message, 'Message'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

/// All requests the user has sent, with simulated "they paid" for the demo.
class RequestsListScreen extends StatelessWidget {
  const RequestsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final reqs = bank.requests;
    return Scaffold(
      appBar: AppBar(title: const Text('Requests')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New request'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RequestScreen()),
        ),
      ),
      body: ResponsiveBody(
        child: reqs.isEmpty
            ? const Center(child: Text('You haven’t requested any money yet'))
            : ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  for (final r in reqs)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Panel(
                        child: ListTile(
                          leading: InitialsAvatar(r.fromName, size: 40),
                          title: Text(
                            '${r.fromName} · ${formatMoney(r.amountCents)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${r.note ?? 'Request'} · ${DateFormat('d MMM').format(r.createdAt)}',
                          ),
                          trailing: switch (r.status) {
                            RequestStatus.paid => const _Badge(
                              'Paid',
                              Brand.mint,
                            ),
                            RequestStatus.cancelled => const _Badge(
                              'Cancelled',
                              Colors.grey,
                            ),
                            RequestStatus.pending => PopupMenuButton<String>(
                              tooltip: 'Request options',
                              onSelected: (v) async {
                                if (v == 'paid') {
                                  await bank.markRequestPaid(r.id);
                                  if (context.mounted) {
                                    showBanner(
                                      context,
                                      emoji: '💸',
                                      title:
                                          '${r.fromName} paid you ${formatMoney(r.amountCents)}',
                                      body: r.note ?? 'Payment request',
                                    );
                                  }
                                } else if (v == 'remind') {
                                  await copyToClipboard(
                                    context,
                                    'Friendly reminder: ${requestLink(r)}',
                                    'Reminder',
                                  );
                                } else {
                                  await bank.cancelRequest(r.id);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'paid',
                                  child: Text('Simulate: they paid'),
                                ),
                                PopupMenuItem(
                                  value: 'remind',
                                  child: Text('Copy reminder'),
                                ),
                                PopupMenuItem(
                                  value: 'cancel',
                                  child: Text('Cancel request'),
                                ),
                              ],
                            ),
                          },
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
    ),
  );
}
