import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../design/hz.dart';

import 'package:flutter/services.dart';

import '../utils/money.dart';

/// On-screen number pad shared by the passcode and amount screens.
/// Also accepts a physical keyboard on desktop and web.
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onDecimal,
  });

  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onDecimal;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, Widget? child}) => Expanded(
      child: AspectRatio(
        aspectRatio: 1.6,
        child: InkWell(
          key: Key('key-$label'),
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Center(
            child:
                child ??
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ),
      ),
    );

    Widget row(List<String> digits) => Row(
      children: [for (final d in digits) key(d, onTap: () => onDigit(d))],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row(['1', '2', '3']),
          row(['4', '5', '6']),
          row(['7', '8', '9']),
          Row(
            children: [
              onDecimal == null
                  ? const Expanded(child: SizedBox())
                  : key('.', onTap: onDecimal),
              key('0', onTap: () => onDigit('0')),
              key(
                'back',
                onTap: onBackspace,
                child: const Icon(HzIcons.backspace, size: 26),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lets a physical keyboard drive a [NumberPad].
class KeyboardDigits extends StatelessWidget {
  const KeyboardDigits({
    super.key,
    required this.child,
    required this.onDigit,
    required this.onBackspace,
    this.onDecimal,
    this.onSubmit,
  });

  final Widget child;
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onDecimal;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: (node, event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }
      final char = event.character;
      if (char != null && RegExp(r'^\d$').hasMatch(char)) {
        onDigit(char);
        return KeyEventResult.handled;
      }
      if (char == '.' && onDecimal != null) {
        onDecimal!();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        onBackspace();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter && onSubmit != null) {
        onSubmit!();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: child,
  );
}

/// Passcode entry: dots that fill as digits are typed, a shake on a wrong
/// code, and a number pad.
class PasscodeEntry extends StatefulWidget {
  const PasscodeEntry({
    super.key,
    required this.title,
    required this.onCompleted,
    this.subtitle,
    this.length = 6,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final int length;
  final Widget? footer;

  /// Return null to accept, or an error message to shake and clear.
  final FutureOr<String?> Function(String code) onCompleted;

  @override
  State<PasscodeEntry> createState() => _PasscodeEntryState();
}

class _PasscodeEntryState extends State<PasscodeEntry>
    with SingleTickerProviderStateMixin {
  String _code = '';
  String? _error;
  bool _busy = false;
  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _digit(String d) async {
    if (_busy || _code.length >= widget.length) return;
    setState(() {
      _code += d;
      _error = null;
    });
    if (_code.length == widget.length) {
      _busy = true;
      final error = await widget.onCompleted(_code);
      if (!mounted) return;
      _busy = false;
      if (error != null) {
        HapticFeedback.heavyImpact();
        _shake.forward(from: 0);
        setState(() {
          _error = error;
          _code = '';
        });
      }
    }
  }

  void _back() {
    if (_busy || _code.isEmpty) return;
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return KeyboardDigits(
      onDigit: _digit,
      onBackspace: _back,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 28),
          AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.translate(
              offset: Offset(
                sin(_shake.value * pi * 6) * 12 * (1 - _shake.value),
                0,
              ),
              child: child,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _code.length
                          ? (_error != null
                                ? context.hz.negative
                                : theme.colorScheme.primary)
                          : Colors.transparent,
                      border: Border.all(
                        color: _error != null
                            ? context.hz.negative
                            : theme.colorScheme.onSurfaceVariant,
                        width: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: Center(
              child: Text(
                _error ?? '',
                key: const Key('passcodeError'),
                style: TextStyle(
                  color: context.hz.negative,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          NumberPad(onDigit: _digit, onBackspace: _back),
          ?widget.footer,
        ],
      ),
    );
  }
}

/// Big amount display with a number pad, e.g. for payments and pots.
class AmountEntry extends StatefulWidget {
  const AmountEntry({
    super.key,
    required this.onChanged,
    this.helper,
    this.errorText,
  });

  final void Function(int? cents, String raw) onChanged;
  final String? helper;
  final String? errorText;

  @override
  State<AmountEntry> createState() => _AmountEntryState();
}

class _AmountEntryState extends State<AmountEntry> {
  String _raw = '';

  void _set(String v) {
    setState(() => _raw = v);
    widget.onChanged(parseAmountToCents(v), v);
  }

  void _digit(String d) {
    if (_raw.contains('.') && _raw.split('.')[1].length >= 2) return;
    if (_raw.replaceAll('.', '').length >= 7) return;
    if (_raw == '0' && d == '0') return;
    _set(_raw == '0' ? d : _raw + d);
  }

  void _decimal() {
    if (_raw.contains('.')) return;
    _set(_raw.isEmpty ? '0.' : '$_raw.');
  }

  void _back() {
    if (_raw.isEmpty) return;
    _set(_raw.substring(0, _raw.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = _raw.isEmpty ? '0' : _raw;
    return KeyboardDigits(
      onDigit: _digit,
      onBackspace: _back,
      onDecimal: _decimal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            child: Text(
              '£$display',
              key: const Key('amountDisplay'),
              style: theme.textTheme.displayMedium?.copyWith(
                color: _raw.isEmpty
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.errorText ?? widget.helper ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: widget.errorText != null
                  ? context.hz.negative
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          NumberPad(onDigit: _digit, onBackspace: _back, onDecimal: _decimal),
        ],
      ),
    );
  }
}
