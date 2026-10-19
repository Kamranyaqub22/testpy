enum AccountType { checking, savings }

class Account {
  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.number,
    required this.balanceCents,
  });

  final String id;
  final String name;
  final AccountType type;

  /// Full account number. Use [maskedNumber] when displaying it.
  final String number;

  /// Balance in minor units (cents) to avoid floating-point rounding errors.
  int balanceCents;

  String get maskedNumber => '•••• ${number.substring(number.length - 4)}';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'number': number,
    'balanceCents': balanceCents,
  };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    name: json['name'] as String,
    type: AccountType.values.byName(json['type'] as String),
    number: json['number'] as String,
    balanceCents: json['balanceCents'] as int,
  );
}
