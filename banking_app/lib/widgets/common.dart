import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../utils/money.dart';
import 'theme.dart';

/// Above this width the app uses a side rail and wider layouts.
const wideLayoutBreakpoint = 840.0;

/// Centers content and caps its width so pages look right on phones,
/// tablets, desktop windows and browsers.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.maxWidth = 720});

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

/// Large balance with smaller pence, e.g. £1,234.56.
class BalanceText extends StatelessWidget {
  const BalanceText(
    this.cents, {
    super.key,
    this.size = 44,
    this.hidden = false,
    this.color,
  });

  final int cents;
  final double size;
  final bool hidden;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    if (hidden) {
      return Text(
        '£ ••••',
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: c,
          letterSpacing: -1,
        ),
      );
    }
    final parts = splitMoney(cents);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: parts.pounds),
          TextSpan(
            text: parts.pence,
            style: TextStyle(fontSize: size * .55),
          ),
        ],
      ),
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: c,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Merchant "logo": an emoji or category icon on a tinted circle.
class MerchantAvatar extends StatelessWidget {
  const MerchantAvatar({
    super.key,
    this.emoji,
    required this.category,
    this.size = 44,
    this.declined = false,
  });

  final String? emoji;
  final TxCategory category;
  final double size;
  final bool declined;

  @override
  Widget build(BuildContext context) {
    final color = declined ? Colors.grey : category.color;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(size * .32),
          ),
          child: emoji != null
              ? Text(emoji!, style: TextStyle(fontSize: size * .5))
              : Icon(category.icon, color: color, size: size * .52),
        ),
        if (declined)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(1),
              child: const Icon(Icons.block, size: 16, color: Brand.danger),
            ),
          ),
      ],
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.size = 44});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts
        .take(2)
        .map((p) => p.isEmpty ? '' : p[0])
        .join()
        .toUpperCase();
    final hue = (name.codeUnits.fold(0, (a, b) => a + b) * 37) % 360;
    final color = HSLColor.fromAHSL(1, hue.toDouble(), .55, .55).toColor();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .18),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: size * .36,
        ),
      ),
    );
  }
}

String txSubtitle(BankTransaction t) {
  if (t.isDeclined) return 'Declined · ${t.declineReason ?? ''}';
  if (t.disputed) return 'Disputed';
  if (t.status == TxStatus.pending) return 'Pending';
  if (t.note != null) return t.note!;
  return switch (t.kind) {
    TxKind.directDebit => 'Direct Debit',
    TxKind.standingOrder => 'Standing order',
    TxKind.pot => t.isIncoming ? 'Withdrawn from pot' : 'Added to pot',
    TxKind.roundUp => 'Round-up',
    TxKind.fasterPayment => t.reference ?? 'Bank transfer',
    _ => t.category.label,
  };
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.roundUpCents,
  });

  final BankTransaction transaction;
  final VoidCallback? onTap;

  /// Shown as a small "+12p" under the amount when the payment was rounded up.
  final int? roundUpCents;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final amountStyle = theme.textTheme.titleMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      color: t.isDeclined
          ? scheme.onSurfaceVariant
          : t.isIncoming
          ? Brand.mint
          : scheme.onSurface,
      decoration: t.isDeclined ? TextDecoration.lineThrough : null,
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            MerchantAvatar(
              emoji: t.emoji,
              category: t.category,
              declined: t.isDeclined,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    txSubtitle(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: t.isDeclined
                          ? Brand.danger
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  t.isIncoming
                      ? formatMoney(t.amountCents, showPlus: true)
                      : formatMoney(t.amountCents.abs()),
                  style: amountStyle,
                ),
                if (roundUpCents != null)
                  Text(
                    '🪙 ${roundUpCents}p',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Today", "Yesterday", or e.g. "Monday 14 October".
String dayLabel(DateTime date, DateTime now) {
  final d = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (d.year == today.year) return DateFormat('EEEE d MMMM').format(d);
  return DateFormat('EEEE d MMMM y').format(d);
}

/// Feed grouped by day with each day's spending total, like a bank statement
/// you can scroll.
class TransactionFeed extends StatelessWidget {
  const TransactionFeed({
    super.key,
    required this.transactions,
    required this.now,
    required this.onTap,
    this.roundUpFor,
  });

  final List<BankTransaction> transactions;
  final DateTime now;
  final void Function(BankTransaction) onTap;

  /// Looks up the round-up for a payment, to show it on the payment's row.
  final BankTransaction? Function(BankTransaction)? roundUpFor;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<BankTransaction>>{};
    for (final t in transactions) {
      groups.putIfAbsent(dayLabel(t.date, now), () => []).add(t);
    }
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Builder(
                  builder: (context) {
                    final spent = entry.value
                        .where((t) => t.countsAsSpending)
                        .fold(0, (s, t) => s - t.amountCents);
                    return spent == 0
                        ? const SizedBox.shrink()
                        : Text(
                            formatMoney(spent),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                  },
                ),
              ],
            ),
          ),
          for (final t in entry.value)
            TransactionTile(
              transaction: t,
              onTap: () => onTap(t),
              roundUpCents: roundUpFor?.call(t)?.amountCents.abs(),
            ),
        ],
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.padding});

  final String title;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? const EdgeInsets.fromLTRB(20, 24, 12, 8),
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

/// A rounded white panel used to group related rows.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding, this.margin});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: margin ?? const EdgeInsets.symmetric(horizontal: 16),
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    ),
  );
}

/// Round quick-action button with a label underneath.
class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: highlighted
                      ? Brand.frost
                      : scheme.surfaceContainerLowest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: highlighted ? Brand.ink : scheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The payment card, front side. Shows full details when [revealed].
class CardVisual extends StatelessWidget {
  const CardVisual({
    super.key,
    required this.card,
    required this.holder,
    this.revealed = false,
    this.width,
  });

  final BankCard card;
  final String holder;
  final bool revealed;
  final double? width;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final mono = TextStyle(
      color: white,
      fontWeight: FontWeight.w700,
      fontSize: 17,
      letterSpacing: 2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          gradient: Brand.cardGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Brand.blue.withValues(alpha: .3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Rising sun motif.
            Positioned(
              right: -40,
              bottom: -70,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Brand.sunrise.withValues(alpha: .95),
                      Brand.sunrise.withValues(alpha: .0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'horizon',
                        style: TextStyle(
                          color: white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: -.5,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.contactless_outlined,
                        color: white.withValues(alpha: .9),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 38,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE9D7A8), Color(0xFFC9A85A)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    revealed ? card.groupedNumber : '••••  ${card.last4}',
                    style: mono,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          holder.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: white.withValues(alpha: .9),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      if (revealed) ...[
                        _label('EXP', card.expiry),
                        const SizedBox(width: 14),
                        _label('CVV', card.cvv),
                      ] else
                        const Text(
                          'DEBIT',
                          style: TextStyle(
                            color: white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (card.frozen)
              Positioned.fill(
                child: Container(
                  color: Brand.frost.withValues(alpha: .72),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.ac_unit_rounded, color: Brand.ink, size: 40),
                      SizedBox(height: 6),
                      Text(
                        'Card frozen',
                        style: TextStyle(
                          color: Brand.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    ],
  );
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<void> copyToClipboard(
  BuildContext context,
  String value,
  String label,
) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (context.mounted) showSnack(context, '$label copied');
}

/// An in-app notification that slides down from the top, like a push
/// notification. Works the same on every platform.
void showBanner(
  BuildContext context, {
  required String title,
  required String body,
  String emoji = '🔔',
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  var removed = false;
  void remove() {
    if (removed) return;
    removed = true;
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (context) =>
        _Banner(title: title, body: body, emoji: emoji, onDismiss: remove),
  );
  overlay.insert(entry);
}

class _Banner extends StatefulWidget {
  const _Banner({
    required this.title,
    required this.body,
    required this.emoji,
    required this.onDismiss,
  });

  final String title;
  final String body;
  final String emoji;
  final VoidCallback onDismiss;

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 4), _close);
  }

  Future<void> _close() async {
    _timer?.cancel();
    if (!mounted) return;
    await _c.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, -1.4),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _close,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Text(
                            widget.emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  widget.body,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple yes/no confirmation dialog.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Brand.danger,
                  minimumSize: const Size(0, 44),
                )
              : FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}
