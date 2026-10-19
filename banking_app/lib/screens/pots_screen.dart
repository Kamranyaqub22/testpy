import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/bank_controller.dart';
import '../utils/money.dart';
import '../widgets/common.dart';
import '../widgets/keypads.dart';
import 'transaction_screen.dart';

const _potEmojis = [
  '🏝️',
  '☔',
  '💻',
  '🏠',
  '🚗',
  '🎁',
  '🎓',
  '💍',
  '🐶',
  '🎸',
  '✈️',
  '🍼',
];
const _potColors = [
  0xFF00A3A3,
  0xFF5B6CFF,
  0xFFBB6BD9,
  0xFFF2994A,
  0xFF2FA36B,
  0xFFE56FA6,
];

class PotsScreen extends StatelessWidget {
  const PotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final theme = Theme.of(context);
    final roundUpPot = bank.roundUpPotId == null
        ? null
        : bank.pots.where((p) => p.id == bank.roundUpPotId).firstOrNull;
    return SafeArea(
      child: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text('Pots', style: theme.textTheme.headlineMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total saved',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        BalanceText(
                          bank.potsTotalCents,
                          hidden: bank.hideBalance,
                          size: 34,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('createPot'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('New pot'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreatePotScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Panel(
              child: ListTile(
                leading: const Text('🪙', style: TextStyle(fontSize: 26)),
                title: const Text(
                  'Round-ups',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  roundUpPot == null
                      ? 'Off. Round card payments up to the nearest pound and save the change.'
                      : 'Spare change goes to ${roundUpPot.name}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _chooseRoundUpPot(context),
              ),
            ),
            const SizedBox(height: 6),
            for (final p in bank.pots)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _PotCard(pot: p, hidden: bank.hideBalance),
              ),
          ],
        ),
      ),
    );
  }

  static void _chooseRoundUpPot(BuildContext context) {
    final bank = context.read<BankController>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: RadioGroup<String?>(
          groupValue: bank.roundUpPotId,
          onChanged: (v) {
            bank.setRoundUpPot(v);
            Navigator.pop(sheet);
          },
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Save your round-ups in',
                  style: Theme.of(sheet).textTheme.titleLarge,
                ),
              ),
              const RadioListTile<String?>(
                value: null,
                title: Text('Turn off round-ups'),
              ),
              for (final p in bank.pots)
                RadioListTile<String?>(
                  value: p.id,
                  title: Text('${p.emoji}  ${p.name}'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PotCard extends StatelessWidget {
  const _PotCard({required this.pot, required this.hidden});
  final Pot pot;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(pot.colorValue);
    return Panel(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PotDetailScreen(potId: pot.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: pot.goalCents == null ? 1 : pot.progress,
                        strokeWidth: 5,
                        color: color,
                        backgroundColor: color.withValues(alpha: .15),
                      ),
                    ),
                    Text(pot.emoji, style: const TextStyle(fontSize: 24)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pot.name, style: theme.textTheme.titleMedium),
                    Text(
                      pot.goalCents == null
                          ? 'No goal'
                          : '${(pot.progress * 100).round()}% of ${formatMoney(pot.goalCents!, compact: true)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                hidden ? '£••' : formatMoney(pot.balanceCents),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreatePotScreen extends StatefulWidget {
  const CreatePotScreen({super.key});

  @override
  State<CreatePotScreen> createState() => _CreatePotScreenState();
}

class _CreatePotScreenState extends State<CreatePotScreen> {
  final _name = TextEditingController();
  final _goal = TextEditingController();
  String _emoji = _potEmojis.first;
  int _color = _potColors.first;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final goal = _goal.text.trim().isEmpty
        ? null
        : parseAmountToCents(_goal.text);
    if (_goal.text.trim().isNotEmpty && goal == null) {
      setState(() => _error = 'Enter a valid goal amount');
      return;
    }
    try {
      final pot = await context.read<BankController>().createPot(
        name: _name.text,
        emoji: _emoji,
        colorValue: _color,
        goalCents: goal,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PotDetailScreen(potId: pot.id)),
      );
    } on BankException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('New pot')),
      body: ResponsiveBody(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(_color).withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: Text(_emoji, style: const TextStyle(fontSize: 46)),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in _potEmojis)
                  ChoiceChip(
                    label: Text(e, style: const TextStyle(fontSize: 20)),
                    selected: e == _emoji,
                    onSelected: (_) => setState(() => _emoji = e),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final c in _potColors)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c == _color
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('potName'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'What are you saving for?',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('potGoal'),
              controller: _goal,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Savings goal (optional)',
                prefixText: '£ ',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('savePot'),
              onPressed: _create,
              child: const Text('Create pot'),
            ),
          ],
        ),
      ),
    );
  }
}

class PotDetailScreen extends StatelessWidget {
  const PotDetailScreen({super.key, required this.potId});
  final String potId;

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    if (!bank.pots.any((p) => p.id == potId)) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final pot = bank.potById(potId);
    final theme = Theme.of(context);
    final color = Color(pot.colorValue);
    final history = bank.transactions.where((t) => t.potId == pot.id).toList();
    final isRoundUpPot = bank.roundUpPotId == pot.id;

    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Pot options',
            onSelected: (v) async {
              if (v == 'goal') {
                await _editGoal(context, pot);
              } else if (v == 'close') {
                final ok = await confirm(
                  context,
                  title: 'Close ${pot.name}?',
                  message: pot.balanceCents > 0
                      ? '${formatMoney(pot.balanceCents)} will go back to your balance.'
                      : 'This pot will be removed.',
                  action: 'Close pot',
                  destructive: true,
                );
                if (ok && context.mounted) {
                  Navigator.pop(context);
                  await bank.deletePot(pot.id);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'goal', child: Text('Change goal')),
              PopupMenuItem(value: 'close', child: Text('Close pot')),
            ],
          ),
        ],
      ),
      body: ResponsiveBody(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: pot.goalCents == null ? 1 : pot.progress,
                        ),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => CircularProgressIndicator(
                          value: v,
                          strokeWidth: 10,
                          strokeCap: StrokeCap.round,
                          color: color,
                          backgroundColor: color.withValues(alpha: .15),
                        ),
                      ),
                    ),
                    Text(pot.emoji, style: const TextStyle(fontSize: 56)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: Text(pot.name, style: theme.textTheme.titleLarge)),
            Center(
              child: BalanceText(
                pot.balanceCents,
                key: const Key('potBalance'),
                size: 38,
              ),
            ),
            if (pot.goalCents != null)
              Center(
                child: Text(
                  pot.balanceCents >= pot.goalCents!
                      ? 'Goal reached! 🎉'
                      : '${formatMoney(pot.goalCents! - pot.balanceCents)} to go to reach ${formatMoney(pot.goalCents!, compact: true)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('addToPot'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add money'),
                      onPressed: () => _move(context, pot, adding: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('withdrawFromPot'),
                      icon: const Icon(Icons.remove),
                      label: const Text('Withdraw'),
                      onPressed: pot.balanceCents == 0
                          ? null
                          : () => _move(context, pot, adding: false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Panel(
              child: SwitchListTile(
                secondary: const Text('🪙', style: TextStyle(fontSize: 24)),
                title: const Text(
                  'Save round-ups here',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Card payments are rounded up to the nearest pound.',
                ),
                value: isRoundUpPot,
                onChanged: (v) => bank.setRoundUpPot(v ? pot.id : null),
              ),
            ),
            const SectionHeader('Activity'),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Nothing here yet. Add some money to get started.'),
              ),
            TransactionFeed(
              transactions: history
                  .map(
                    (t) => BankTransaction(
                      id: t.id,
                      title: t.kind == TxKind.roundUp
                          ? 'Round-up'
                          : t.amountCents < 0
                          ? 'Added from balance'
                          : 'Moved to balance',
                      // From the pot's point of view the sign is reversed.
                      amountCents: -t.amountCents,
                      category: t.category,
                      kind: t.kind,
                      date: t.date,
                      emoji: t.kind == TxKind.roundUp ? '🪙' : t.emoji,
                    ),
                  )
                  .toList(),
              now: bank.now,
              onTap: (t) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionScreen(txId: t.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editGoal(BuildContext context, Pot pot) async {
    final controller = TextEditingController(
      text: pot.goalCents == null
          ? ''
          : (pot.goalCents! / 100).toStringAsFixed(0),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Savings goal'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '£ '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Remove goal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !context.mounted) return;
    final bank = context.read<BankController>();
    if (result.trim().isEmpty) {
      await bank.updatePot(pot.id, clearGoal: true);
    } else {
      final cents = parseAmountToCents(result);
      if (cents != null) await bank.updatePot(pot.id, goalCents: cents);
    }
  }

  Future<void> _move(
    BuildContext context,
    Pot pot, {
    required bool adding,
  }) async {
    final bank = context.read<BankController>();
    final max = adding ? bank.account.balanceCents : pot.balanceCents;
    int? cents;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setState) {
          final over = cents != null && cents! > max;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    children: [
                      Text(
                        adding ? 'Add to ${pot.name}' : 'Withdraw to balance',
                        style: Theme.of(sheet).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      AmountEntry(
                        helper: adding
                            ? 'Balance ${formatMoney(max)}'
                            : 'In pot ${formatMoney(max)}',
                        errorText: over
                            ? 'You only have ${formatMoney(max)}'
                            : null,
                        onChanged: (c, _) => setState(() => cents = c),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        key: const Key('confirmPotMove'),
                        onPressed: cents == null || over
                            ? null
                            : () => Navigator.pop(sheet, true),
                        child: Text(adding ? 'Add money' : 'Withdraw'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    if (ok != true || cents == null) return;
    try {
      if (adding) {
        await bank.addToPot(pot.id, cents!);
      } else {
        await bank.withdrawFromPot(pot.id, cents!);
      }
      if (!context.mounted) return;
      final updated = bank.potById(pot.id);
      if (adding &&
          updated.goalCents != null &&
          updated.balanceCents >= updated.goalCents! &&
          updated.balanceCents - cents! < updated.goalCents!) {
        showBanner(
          context,
          emoji: '🎉',
          title: 'You reached your ${pot.name} goal!',
          body: '${formatMoney(updated.balanceCents)} saved. Nice work.',
        );
      } else {
        showSnack(
          context,
          adding
              ? '${formatMoney(cents!)} added to ${pot.name}'
              : '${formatMoney(cents!)} moved to your balance',
        );
      }
    } on BankException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }
}
