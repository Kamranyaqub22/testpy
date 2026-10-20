import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../design/hz.dart';
import '../models/models.dart';
import '../utils/money.dart';

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

/// Large balance with smaller pence, e.g. £1,234.56 (`amount-hero`).
class BalanceText extends StatelessWidget {
  const BalanceText(
    this.cents, {
    super.key,
    this.size = 46,
    this.hidden = false,
    this.color,
  });

  final int cents;
  final double size;
  final bool hidden;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = HzType.amountHero.copyWith(
      fontSize: size,
      height: 1.13,
      letterSpacing: -size * .026,
      color: color ?? context.hz.ink,
    );
    if (hidden) return Text('£ ••••', style: style);
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
      style: style,
    );
  }
}

/// An icon on a tile tinted with the same colour at 14%. Used for merchant
/// avatars, pots, notices and settings rows.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = HzSize.avatar,
    this.circle = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(size * .32),
    ),
    child: Icon(icon, color: color, size: size * .48),
  );
}

/// Merchant "logo": the category icon on its tinted tile. Declined payments
/// get a small block badge.
class MerchantAvatar extends StatelessWidget {
  const MerchantAvatar({
    super.key,
    required this.category,
    this.size = HzSize.avatar,
    this.declined = false,
  });

  final TxCategory category;
  final double size;
  final bool declined;

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconTile(
          icon: HzIcons.category(category),
          color: declined ? hz.inkSubtle : hz.category(category),
          size: size,
        ),
        if (declined)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: hz.surfaceRaised,
                shape: BoxShape.circle,
              ),
              child: Icon(HzIcons.declined, size: 15, color: hz.negative),
            ),
          ),
      ],
    );
  }
}

/// Initials on a tinted circle, for people and payees.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.size = HzSize.avatar});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts
        .take(2)
        .map((p) => p.isEmpty ? '' : p[0])
        .join()
        .toUpperCase();
    final colors = hz.potColors;
    final color =
        colors[name.codeUnits.fold(0, (a, b) => a + b) % colors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: HzType.bodyStrong.copyWith(color: color, fontSize: size * .36),
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

/// One payment in a list: avatar, title, subtitle, amount.
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
    final hz = context.hz;
    final subtitleColor = t.isDeclined
        ? hz.negative
        : t.status == TxStatus.pending
        ? hz.info
        : hz.inkMuted;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HzSpace.s5,
          vertical: HzSpace.s3 - 2,
        ),
        child: Row(
          children: [
            MerchantAvatar(category: t.category, declined: t.isDeclined),
            const SizedBox(width: HzSpace.s3 + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HzType.bodyStrong.copyWith(color: hz.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    txSubtitle(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HzType.caption.copyWith(color: subtitleColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: HzSpace.s2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  t.isIncoming
                      ? formatMoney(t.amountCents, showPlus: true)
                      : formatMoney(t.amountCents.abs()),
                  style: HzType.amountRow.copyWith(
                    color: t.isDeclined
                        ? hz.inkSubtle
                        : t.isIncoming
                        ? hz.positive
                        : hz.ink,
                    decoration: t.isDeclined
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (roundUpCents != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(HzIcons.coins, size: 12, color: hz.catSavings),
                      const SizedBox(width: 3),
                      Text(
                        '${roundUpCents}p',
                        style: HzType.caption.copyWith(
                          fontSize: 12,
                          color: hz.inkMuted,
                        ),
                      ),
                    ],
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

/// Feed grouped by day with each day's spending total. Each day is one
/// panel, like a page of a statement.
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
    final hz = context.hz;
    final groups = <String, List<BankTransaction>>{};
    for (final t in transactions) {
      groups.putIfAbsent(dayLabel(t.date, now), () => []).add(t);
    }
    final overline = HzType.overline.copyWith(color: hz.inkSubtle);
    return Column(
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              HzSpace.s5,
              HzSpace.s5,
              HzSpace.s5,
              HzSpace.s2,
            ),
            child: Row(
              children: [
                Expanded(child: Text(entry.key.toUpperCase(), style: overline)),
                Builder(
                  builder: (context) {
                    final spent = entry.value
                        .where((t) => t.countsAsSpending)
                        .fold(0, (s, t) => s - t.amountCents);
                    return spent == 0
                        ? const SizedBox.shrink()
                        : Text(formatMoney(spent), style: overline);
                  },
                ),
              ],
            ),
          ),
          Panel(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: HzSpace.s1),
              child: Column(
                children: [
                  for (final t in entry.value)
                    TransactionTile(
                      transaction: t,
                      onTap: () => onTap(t),
                      roundUpCents: roundUpFor?.call(t)?.amountCents.abs(),
                    ),
                ],
              ),
            ),
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
    padding:
        padding ??
        const EdgeInsets.fromLTRB(HzSpace.s5, HzSpace.s6, HzSpace.s3, 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: HzType.title3.copyWith(color: context.hz.ink),
          ),
        ),
        ?action,
      ],
    ),
  );
}

/// The raised surface that groups related rows (`surface-raised`,
/// `radius-lg`, flat: no border, no shadow).
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding, this.margin});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: margin ?? const EdgeInsets.symmetric(horizontal: HzSpace.s4),
    child: Material(
      color: context.hz.surfaceRaised,
      borderRadius: BorderRadius.circular(HzRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    ),
  );
}

/// Thin divider between rows inside a [Panel], inset to the text column.
class RowDivider extends StatelessWidget {
  const RowDivider({super.key, this.indent = 76});

  final double indent;

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: indent, endIndent: HzSpace.s5);
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

  /// "On" state, e.g. Freeze while the card is frozen (`frost`).
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HzRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: HzSize.quickAction,
                height: HzSize.quickAction,
                decoration: BoxDecoration(
                  color: highlighted ? hz.frost : hz.surfaceRaised,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: highlighted ? hz.onFrost : hz.brand,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HzType.caption.copyWith(color: hz.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum StatusTone { positive, pending, negative, warning, neutral }

/// Small pill that names a state in words (never colour alone).
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, required this.tone, this.icon});

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    final (bg, fg) = switch (tone) {
      StatusTone.positive => (hz.positiveTint, hz.positive),
      StatusTone.pending => (hz.infoTint, hz.info),
      StatusTone.negative => (hz.negativeTint, hz.negative),
      StatusTone.warning => (hz.sunTint, hz.warning),
      StatusTone.neutral => (hz.surfaceSunken, hz.inkMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(HzRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: HzSpace.s1),
          ],
          Text(label, style: HzType.caption.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// The debit card face: Horizon Green gradient, the rising sun on the
/// horizon line from the logo, chip, number, holder.
class CardVisual extends StatelessWidget {
  const CardVisual({
    super.key,
    required this.card,
    required this.holder,
    this.revealed = false,
  });

  final BankCard card;
  final String holder;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    const white = Colors.white;
    final number = HzType.amountRow.copyWith(
      color: white,
      fontSize: 17,
      letterSpacing: 2,
    );
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [hz.cardFrom, hz.cardTo],
          ),
          borderRadius: BorderRadius.circular(HzRadius.card),
          boxShadow: hz.shadowCard,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _CardSunPainter(hz.sun)),
            ),
            Padding(
              padding: const EdgeInsets.all(HzSpace.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const HorizonLogo(height: 26, reversed: true),
                      const Spacer(),
                      Icon(
                        HzIcons.contactless,
                        color: white.withValues(alpha: .9),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [hz.cardChipFrom, hz.cardChipTo],
                      ),
                    ),
                  ),
                  const SizedBox(height: HzSpace.s3),
                  Text(
                    revealed ? card.groupedNumber : '••••  ${card.last4}',
                    style: number,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          holder.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HzType.caption.copyWith(
                            color: white.withValues(alpha: .9),
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
                        Text(
                          'DEBIT',
                          style: HzType.overline.copyWith(
                            color: white,
                            fontSize: 12,
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
                  color: hz.frost.withValues(alpha: .86),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(HzIcons.freeze, color: hz.onFrost, size: 36),
                      const SizedBox(height: 6),
                      Text(
                        'Card frozen',
                        style: HzType.title3.copyWith(color: hz.onFrost),
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
        style: HzType.overline.copyWith(color: Colors.white70, fontSize: 9),
      ),
      Text(
        value,
        style: HzType.amountRow.copyWith(color: Colors.white, fontSize: 13),
      ),
    ],
  );
}

/// The logo's sun and horizon line, large and low on the card's right.
class _CardSunPainter extends CustomPainter {
  _CardSunPainter(this.sun);

  final Color sun;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height * .26;
    final cx = size.width * .80;
    final horizon = size.height * .52;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, horizon), radius: r),
      3.14159,
      3.14159,
      true,
      Paint()..color = sun,
    );
    final line = Paint()..color = Colors.white.withValues(alpha: .28);
    final h = size.height * .028;
    for (final (w, dy) in [(.44, 1.4), (.26, 3.2), (.12, 4.9)]) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          cx - size.width * w / 2,
          horizon + h * dy,
          cx + size.width * w / 2,
          horizon + h * (dy + 1),
          Radius.circular(h / 2),
        ),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_CardSunPainter old) => old.sun != sun;
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

enum BannerTone { info, positive, negative, celebrate }

/// An in-app notification that slides down from the top, like a push
/// notification. Works the same on every platform.
void showBanner(
  BuildContext context, {
  required String title,
  required String body,
  IconData icon = HzIcons.bell,
  BannerTone tone = BannerTone.info,
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
    builder: (context) => _Banner(
      title: title,
      body: body,
      icon: icon,
      tone: tone,
      onDismiss: remove,
    ),
  );
  overlay.insert(entry);
}

class _Banner extends StatefulWidget {
  const _Banner({
    required this.title,
    required this.body,
    required this.icon,
    required this.tone,
    required this.onDismiss,
  });

  final String title;
  final String body;
  final IconData icon;
  final BannerTone tone;
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
    final hz = context.hz;
    final color = switch (widget.tone) {
      BannerTone.info => hz.brand,
      BannerTone.positive => hz.positive,
      BannerTone.negative => hz.negative,
      BannerTone.celebrate => hz.catSavings,
    };
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
                padding: const EdgeInsets.all(HzSpace.s3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: hz.surfaceRaised,
                    borderRadius: BorderRadius.circular(HzRadius.lg),
                    boxShadow: hz.shadowRaised,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(HzRadius.lg),
                      onTap: _close,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            IconTile(icon: widget.icon, color: color, size: 40),
                            const SizedBox(width: HzSpace.s3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: HzType.bodyStrong.copyWith(
                                      color: hz.ink,
                                    ),
                                  ),
                                  Text(
                                    widget.body,
                                    style: HzType.caption.copyWith(
                                      color: hz.inkMuted,
                                    ),
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
  final hz = context.hz;
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
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            backgroundColor: destructive ? hz.negative : hz.brand,
            foregroundColor: destructive ? hz.surfaceRaised : hz.onBrand,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}
