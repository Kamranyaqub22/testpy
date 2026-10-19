class Payee {
  Payee({required this.id, required this.name, required this.accountNumber});

  final String id;
  final String name;
  final String accountNumber;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'accountNumber': accountNumber,
  };

  factory Payee.fromJson(Map<String, dynamic> json) => Payee(
    id: json['id'] as String,
    name: json['name'] as String,
    accountNumber: json['accountNumber'] as String,
  );
}
