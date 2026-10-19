import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'en_US', symbol: '\$');

/// Formats minor units (cents) as a currency string, e.g. 123456 -> $1,234.56.
String formatCents(int cents, {bool showSign = false}) {
  final text = _currency.format(cents.abs() / 100);
  if (cents < 0) return '-$text';
  if (showSign && cents > 0) return '+$text';
  return text;
}

/// Parses user input such as "12", "12.5" or "1,234.56" into cents.
///
/// Parsing is done on the string itself rather than through a double so that
/// amounts are never subject to floating-point rounding. Returns null when the
/// input is not a valid positive amount with at most two decimal places.
int? parseAmountToCents(String input) {
  final cleaned = input.trim().replaceAll(',', '').replaceAll('\$', '');
  final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final whole = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  final cents = whole * 100 + int.parse(fraction);
  return cents > 0 ? cents : null;
}
