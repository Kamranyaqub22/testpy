import '../models/account.dart';
import '../models/bank_transaction.dart';
import '../models/payee.dart';

/// Sample accounts and history so a new user has something to explore.
class DemoData {
  static List<Account> accounts() => [
    Account(
      id: 'chk',
      name: 'Everyday Checking',
      type: AccountType.checking,
      number: '4001002003004821',
      balanceCents: 0,
    ),
    Account(
      id: 'sav',
      name: 'High-Yield Savings',
      type: AccountType.savings,
      number: '4001002003009377',
      balanceCents: 0,
    ),
  ];

  static List<Payee> payees() => [
    Payee(id: 'p1', name: 'Alex Morgan', accountNumber: '7712345678'),
    Payee(id: 'p2', name: 'City Power & Light', accountNumber: '5520099881'),
    Payee(id: 'p3', name: 'Sam Lee', accountNumber: '3398765432'),
  ];

  /// History relative to [now]. Account balances are derived from these
  /// entries, so the two can never disagree.
  static List<BankTransaction> transactions(DateTime now) {
    var n = 0;
    BankTransaction tx(
      String account,
      int cents,
      String description,
      TxCategory category,
      int daysAgo,
    ) {
      n++;
      return BankTransaction(
        id: 'seed$n',
        accountId: account,
        amountCents: cents,
        description: description,
        category: category,
        date: now.subtract(Duration(days: daysAgo, hours: n)),
      );
    }

    return [
      tx('sav', 1250000, 'Opening deposit', TxCategory.income, 45),
      tx('chk', 420000, 'Salary – Acme Corp', TxCategory.income, 30),
      tx('chk', -145000, 'Rent – Oak Street Apartments', TxCategory.bills, 29),
      tx('chk', -8642, 'FreshMart Groceries', TxCategory.groceries, 26),
      tx('chk', -1299, 'StreamFlix', TxCategory.entertainment, 24),
      tx('chk', -4520, 'Metro Transit Card', TxCategory.transport, 21),
      tx('chk', -6375, 'Bella Italia', TxCategory.dining, 18),
      tx('chk', -11250, 'City Power & Light', TxCategory.bills, 15),
      tx('chk', 420000, 'Salary – Acme Corp', TxCategory.income, 14),
      tx(
        'chk',
        -50000,
        'Transfer to High-Yield Savings',
        TxCategory.transfer,
        13,
      ),
      tx(
        'sav',
        50000,
        'Transfer from Everyday Checking',
        TxCategory.transfer,
        13,
      ),
      tx('chk', -12999, 'TechHub Online', TxCategory.shopping, 10),
      tx('chk', -9410, 'FreshMart Groceries', TxCategory.groceries, 7),
      tx('chk', -2450, 'Corner Coffee', TxCategory.dining, 4),
      tx('sav', 3125, 'Interest payment', TxCategory.income, 2),
      tx('chk', -3800, 'RideNow', TxCategory.transport, 1),
    ];
  }
}
