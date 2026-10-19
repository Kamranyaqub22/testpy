enum TxCategory {
  income,
  transfer,
  groceries,
  dining,
  shopping,
  bills,
  transport,
  entertainment,
  other,
}

class BankTransaction {
  BankTransaction({
    required this.id,
    required this.accountId,
    required this.amountCents,
    required this.description,
    required this.category,
    required this.date,
    this.note,
  });

  final String id;
  final String accountId;

  /// Positive for money in, negative for money out.
  final int amountCents;
  final String description;
  final TxCategory category;
  final DateTime date;
  final String? note;

  bool get isCredit => amountCents > 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'accountId': accountId,
    'amountCents': amountCents,
    'description': description,
    'category': category.name,
    'date': date.toIso8601String(),
    if (note != null) 'note': note,
  };

  factory BankTransaction.fromJson(Map<String, dynamic> json) =>
      BankTransaction(
        id: json['id'] as String,
        accountId: json['accountId'] as String,
        amountCents: json['amountCents'] as int,
        description: json['description'] as String,
        category: TxCategory.values.byName(json['category'] as String),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
      );
}
