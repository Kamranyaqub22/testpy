import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../design/hz.dart';
import '../models/models.dart';
import '../state/bank_controller.dart';
import '../utils/money.dart';
import '../widgets/common.dart';
import 'search_screen.dart';

/// Monthly spending by category against budgets.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _monthsBack = 0;

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final theme = Theme.of(context);
    final now = bank.now;
    final month = DateTime(now.year, now.month - _monthsBack);
    final prev = DateTime(month.year, month.month - 1);
    final byCat = bank.spendingByCategory(month);
    final total = byCat.values.fold(0, (s, v) => s + v);
    // Compare like for like: this month so far against the same days of
    // last month.
    final prevTotal = bank
        .spendingByCategory(prev, upToDay: _monthsBack == 0 ? now.day : null)
        .values
        .fold(0, (s, v) => s + v);
    final income = bank.incomeForMonth(month);
    final budget = bank.monthlyBudgetCents;
    final isCurrent = _monthsBack == 0;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final daysLeft = isCurrent ? daysInMonth - now.day + 1 : 0;
    final canGoBack = bank.statementMonths.length > _monthsBack + 1;

    return SafeArea(
      child: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Insights',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Previous month',
                    onPressed: canGoBack
                        ? () => setState(() => _monthsBack++)
                        : null,
                    icon: const Icon(HzIcons.chevronLeft),
                  ),
                  Text(
                    DateFormat('MMM y').format(month),
                    style: theme.textTheme.titleSmall,
                  ),
                  IconButton(
                    tooltip: 'Next month',
                    onPressed: _monthsBack > 0
                        ? () => setState(() => _monthsBack--)
                        : null,
                    icon: const Icon(HzIcons.chevron),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Panel(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    height: 210,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          key: ValueKey(month),
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, t, _) => CustomPaint(
                            size: const Size.square(210),
                            painter: _DonutPainter(
                              byCat,
                              t,
                              theme.colorScheme.surfaceContainer,
                              context.hz,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Spent', style: theme.textTheme.bodySmall),
                            Text(
                              formatMoney(total),
                              key: const Key('monthSpent'),
                              style: theme.textTheme.headlineSmall,
                            ),
                            if (prevTotal > 0)
                              _Trend(current: total, previous: prevTotal),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Stat(
                        'Money in',
                        formatMoney(income),
                        context.hz.positive,
                      ),
                      _Stat(
                        'Left to spend',
                        budget == null
                            ? '–'
                            : formatMoney(max(0, budget - total)),
                        theme.colorScheme.primary,
                      ),
                      _Stat(
                        isCurrent ? 'Per day left' : 'Daily average',
                        isCurrent
                            ? (budget == null || daysLeft == 0
                                  ? '–'
                                  : formatMoney(
                                      max(0, budget - total) ~/ daysLeft,
                                    ))
                            : formatMoney(total ~/ daysInMonth),
                        theme.colorScheme.onSurface,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SectionHeader(
              'Monthly budget',
              action: TextButton(
                key: const Key('editBudget'),
                onPressed: () => _editBudget(context, null),
                child: Text(budget == null ? 'Set budget' : 'Edit'),
              ),
            ),
            if (budget != null)
              Panel(
                padding: const EdgeInsets.all(18),
                child: _BudgetBar(spent: total, budget: budget),
              ),
            const SectionHeader('Categories'),
            if (byCat.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('No spending this month yet.'),
              ),
            Panel(
              child: Column(
                children: [
                  for (final e in byCat.entries)
                    _CategoryRow(
                      category: e.key,
                      spent: e.value,
                      share: total == 0 ? 0 : e.value / total,
                      budget: bank.categoryBudgets[e.key],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SearchScreen(category: e.key),
                        ),
                      ),
                      onBudget: () => _editBudget(context, e.key),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editBudget(BuildContext context, TxCategory? category) async {
    final bank = context.read<BankController>();
    final current = category == null
        ? bank.monthlyBudgetCents
        : bank.categoryBudgets[category];
    final controller = TextEditingController(
      text: current == null ? '' : (current / 100).toStringAsFixed(0),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          category == null ? 'Monthly budget' : '${category.label} budget',
        ),
        content: TextField(
          key: const Key('budgetField'),
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: '£ ',
            helperText: 'How much do you want to spend each month?',
          ),
        ),
        actions: [
          if (current != null)
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Remove'),
            ),
          TextButton(
            key: const Key('saveBudget'),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    final cents = result.trim().isEmpty ? null : parseAmountToCents(result);
    if (result.trim().isNotEmpty && cents == null) return;
    if (category == null) {
      await bank.setMonthlyBudget(cents);
    } else {
      await bank.setCategoryBudget(category, cents);
    }
  }
}

class _Trend extends StatelessWidget {
  const _Trend({required this.current, required this.previous});
  final int current;
  final int previous;

  @override
  Widget build(BuildContext context) {
    final diff = current - previous;
    final pct = (diff.abs() / previous * 100).round();
    final up = diff > 0;
    return SizedBox(
      width: 130,
      child: Text(
        '${up ? '▲' : '▼'} $pct% vs same time last month',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: up ? context.hz.negative : context.hz.positive,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: color),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({required this.spent, required this.budget});
  final int spent;
  final int budget;

  @override
  Widget build(BuildContext context) {
    final ratio = budget == 0 ? 0.0 : spent / budget;
    final color = ratio >= 1
        ? context.hz.negative
        : ratio >= .8
        ? context.hz.warning
        : context.hz.positive;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${formatMoney(spent)} of ${formatMoney(budget, compact: true)}',
                style: theme.textTheme.titleSmall,
              ),
            ),
            Text(
              ratio >= 1
                  ? 'Over by ${formatMoney(spent - budget)}'
                  : '${formatMoney(budget - spent)} left',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.clamp(0, 1).toDouble(),
            minHeight: 10,
            color: color,
            backgroundColor: theme.colorScheme.surfaceContainer,
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.spent,
    required this.share,
    required this.budget,
    required this.onTap,
    required this.onBudget,
  });

  final TxCategory category;
  final int spent;
  final double share;
  final int? budget;
  final VoidCallback onTap;
  final VoidCallback onBudget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = budget == null || budget == 0 ? null : spent / budget!;
    return InkWell(
      onTap: onTap,
      onLongPress: onBudget,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
        child: Row(
          children: [
            MerchantAvatar(category: category, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.label,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        formatMoney(spent),
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (ratio ?? share).clamp(0, 1).toDouble(),
                      minHeight: 6,
                      color: ratio != null && ratio >= 1
                          ? context.hz.negative
                          : context.hz.category(category),
                      backgroundColor: theme.colorScheme.surfaceContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    budget == null
                        ? '${(share * 100).round()}% of spending'
                        : ratio! >= 1
                        ? 'Over budget by ${formatMoney(spent - budget!)}'
                        : '${formatMoney(budget! - spent)} left of ${formatMoney(budget!, compact: true)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Set ${category.label} budget',
              icon: const Icon(HzIcons.tune, size: 20),
              onPressed: onBudget,
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.data, this.progress, this.track, this.hz);

  final Map<TxCategory, int> data;
  final double progress;
  final Color track;
  final HzPalette hz;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - stroke / 2,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, 2 * pi, false, base);
    final total = data.values.fold(0, (s, v) => s + v);
    if (total == 0) return;
    const gap = 0.03;
    var start = -pi / 2;
    for (final e in data.entries) {
      final sweep = (e.value / total) * 2 * pi * progress;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = hz.category(e.key);
      canvas.drawArc(
        rect,
        start,
        max(0, sweep - (data.length > 1 ? gap : 0)),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.data != data || old.track != track;
}
