import 'package:flutter/material.dart';

/// Spending categories, each with its own icon and colour so the feed,
/// insights and budgets all read the same way.
enum TxCategory {
  groceries('Groceries', Icons.shopping_basket_rounded, Color(0xFF2FA36B)),
  eatingOut('Eating out', Icons.restaurant_rounded, Color(0xFFF2994A)),
  transport('Transport', Icons.directions_bus_rounded, Color(0xFF2D9CDB)),
  shopping('Shopping', Icons.shopping_bag_rounded, Color(0xFFBB6BD9)),
  entertainment('Entertainment', Icons.movie_rounded, Color(0xFFEB5757)),
  bills('Bills', Icons.receipt_long_rounded, Color(0xFF5B6CFF)),
  holidays('Holidays', Icons.flight_rounded, Color(0xFF00A3A3)),
  personalCare('Personal care', Icons.spa_rounded, Color(0xFFE56FA6)),
  general('General', Icons.category_rounded, Color(0xFF8A8FA3)),
  cash('Cash', Icons.local_atm_rounded, Color(0xFF6FA34A)),
  income('Income', Icons.payments_rounded, Color(0xFF1E9E5A)),
  transfers('Transfers', Icons.swap_horiz_rounded, Color(0xFF7A869A)),
  savings('Savings', Icons.savings_rounded, Color(0xFFE0A100));

  const TxCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  /// Categories that count as spending in insights and budgets.
  bool get isSpending => this != income && this != transfers && this != savings;

  static List<TxCategory> get spending =>
      values.where((c) => c.isSpending).toList();
}
