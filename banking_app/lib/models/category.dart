/// Spending categories. Their icon and colour live in the design system
/// (`HzIcons.category` and the `cat-*` tokens), not here.
enum TxCategory {
  groceries('Groceries'),
  eatingOut('Eating out'),
  transport('Transport'),
  shopping('Shopping'),
  entertainment('Entertainment'),
  bills('Bills'),
  holidays('Holidays'),
  personalCare('Personal care'),
  general('General'),
  cash('Cash'),
  income('Income'),
  transfers('Transfers'),
  savings('Savings');

  const TxCategory(this.label);

  final String label;

  /// Categories that count as spending in insights and budgets.
  bool get isSpending => this != income && this != transfers && this != savings;

  static List<TxCategory> get spending =>
      values.where((c) => c.isSpending).toList();
}
