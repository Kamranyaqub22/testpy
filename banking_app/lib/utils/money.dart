import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'en_GB', symbol: '£');
final _whole = NumberFormat.currency(
  locale: 'en_GB',
  symbol: '£',
  decimalDigits: 0,
);

/// Formats pence as pounds, e.g. 123456 -> £1,234.56.
String formatMoney(int cents, {bool showPlus = false, bool compact = false}) {
  final abs = cents.abs();
  final text = compact && abs % 100 == 0
      ? _whole.format(abs / 100)
      : _currency.format(abs / 100);
  if (cents < 0) return '-$text';
  if (showPlus && cents > 0) return '+$text';
  return text;
}

/// Splits pence into pounds and pence parts for large balance displays.
({String pounds, String pence}) splitMoney(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final pounds = NumberFormat.decimalPattern('en_GB').format(abs ~/ 100);
  return (
    pounds: '${negative ? '-' : ''}£$pounds',
    pence: '.${(abs % 100).toString().padLeft(2, '0')}',
  );
}

/// Parses user input such as "12", "12.5" or "1,234.56" into pence.
///
/// Parsing works on the string rather than a double so amounts never pick up
/// floating-point rounding. Returns null for anything that isn't a positive
/// amount with at most two decimal places.
int? parseAmountToCents(String input) {
  final cleaned = input.trim().replaceAll(',', '').replaceAll('£', '');
  final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final whole = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  final cents = whole * 100 + int.parse(fraction);
  return cents > 0 ? cents : null;
}

/// Round-up to the next whole pound: £3.20 -> 80p, £4.00 -> 0p.
int roundUpAmount(int spendCents) {
  final rem = spendCents.abs() % 100;
  return rem == 0 ? 0 : 100 - rem;
}
