import 'account.dart';
import 'bank_transaction.dart';
import 'payee.dart';

/// Everything the app persists for one user.
class BankData {
  BankData({
    required this.userName,
    required this.pinHash,
    required this.pinSalt,
    required this.accounts,
    required this.transactions,
    required this.payees,
  });

  String userName;
  String pinHash;
  String pinSalt;
  final List<Account> accounts;
  final List<BankTransaction> transactions;
  final List<Payee> payees;

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'pinHash': pinHash,
    'pinSalt': pinSalt,
    'accounts': accounts.map((a) => a.toJson()).toList(),
    'transactions': transactions.map((t) => t.toJson()).toList(),
    'payees': payees.map((p) => p.toJson()).toList(),
  };

  factory BankData.fromJson(Map<String, dynamic> json) => BankData(
    userName: json['userName'] as String,
    pinHash: json['pinHash'] as String,
    pinSalt: json['pinSalt'] as String,
    accounts: (json['accounts'] as List)
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList(),
    transactions: (json['transactions'] as List)
        .map((e) => BankTransaction.fromJson(e as Map<String, dynamic>))
        .toList(),
    payees: (json['payees'] as List)
        .map((e) => Payee.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
