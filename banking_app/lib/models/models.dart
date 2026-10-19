import 'category.dart';

export 'category.dart';

/// The user's current account (UK style: sort code + 8-digit number).
class Account {
  Account({
    required this.sortCode,
    required this.accountNumber,
    required this.balanceCents,
  });

  /// Six digits, stored without dashes.
  final String sortCode;
  final String accountNumber;

  /// Balance in pence. All money is held as whole minor units.
  int balanceCents;

  String get formattedSortCode =>
      '${sortCode.substring(0, 2)}-${sortCode.substring(2, 4)}-${sortCode.substring(4)}';

  /// A valid-format IBAN for this demo bank (bank code HRZN).
  String get iban {
    const bankCode = 'HRZN';
    final bban = '$bankCode$sortCode$accountNumber';
    // ISO 13616 check digits: move "GB00" to the end, letters -> numbers.
    final rearranged = '${bban}GB00';
    final digits = rearranged.split('').map((c) {
      final code = c.codeUnitAt(0);
      return code >= 65 ? '${code - 55}' : c;
    }).join();
    final check = 98 - (BigInt.parse(digits) % BigInt.from(97)).toInt();
    final raw = 'GB${check.toString().padLeft(2, '0')}$bban';
    return [
      for (var i = 0; i < raw.length; i += 4)
        raw.substring(i, i + 4 > raw.length ? raw.length : i + 4),
    ].join(' ');
  }

  Map<String, dynamic> toJson() => {
    'sortCode': sortCode,
    'accountNumber': accountNumber,
    'balanceCents': balanceCents,
  };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
    sortCode: j['sortCode'] as String,
    accountNumber: j['accountNumber'] as String,
    balanceCents: j['balanceCents'] as int,
  );
}

/// A savings pot kept separate from the main balance.
class Pot {
  Pot({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    this.balanceCents = 0,
    this.goalCents,
  });

  final String id;
  String name;
  String emoji;
  int colorValue;
  int balanceCents;
  int? goalCents;

  double get progress => goalCents == null || goalCents == 0
      ? 0
      : (balanceCents / goalCents!).clamp(0, 1).toDouble();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'colorValue': colorValue,
    'balanceCents': balanceCents,
    'goalCents': goalCents,
  };

  factory Pot.fromJson(Map<String, dynamic> j) => Pot(
    id: j['id'] as String,
    name: j['name'] as String,
    emoji: j['emoji'] as String,
    colorValue: j['colorValue'] as int,
    balanceCents: j['balanceCents'] as int,
    goalCents: j['goalCents'] as int?,
  );
}

enum TxKind {
  card,
  contactless,
  online,
  fasterPayment,
  directDebit,
  standingOrder,
  pot,
  roundUp,
  atm,
  income,
  refund,
}

enum TxStatus { pending, settled, declined }

class BankTransaction {
  BankTransaction({
    required this.id,
    required this.title,
    required this.amountCents,
    required this.category,
    required this.kind,
    required this.date,
    this.status = TxStatus.settled,
    this.emoji,
    this.note,
    this.reference,
    this.location,
    this.potId,
    this.declineReason,
    this.disputed = false,
    this.splitRequestIds = const [],
  });

  final String id;

  /// Merchant or counterparty name shown in the feed.
  final String title;

  /// Positive for money in, negative for money out. Declined transactions
  /// keep the attempted amount but never change a balance.
  final int amountCents;
  TxCategory category;
  final TxKind kind;
  final DateTime date;
  TxStatus status;
  final String? emoji;
  String? note;
  final String? reference;
  final String? location;
  final String? potId;
  final String? declineReason;
  bool disputed;
  List<String> splitRequestIds;

  bool get isIncoming => amountCents > 0;
  bool get isDeclined => status == TxStatus.declined;
  bool get isCardPayment =>
      kind == TxKind.card ||
      kind == TxKind.contactless ||
      kind == TxKind.online ||
      kind == TxKind.atm;

  /// Counts towards spending insights and "spent today".
  bool get countsAsSpending =>
      !isDeclined && !isIncoming && category.isSpending;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amountCents': amountCents,
    'category': category.name,
    'kind': kind.name,
    'date': date.toIso8601String(),
    'status': status.name,
    'emoji': emoji,
    'note': note,
    'reference': reference,
    'location': location,
    'potId': potId,
    'declineReason': declineReason,
    'disputed': disputed,
    'splitRequestIds': splitRequestIds,
  };

  factory BankTransaction.fromJson(Map<String, dynamic> j) => BankTransaction(
    id: j['id'] as String,
    title: j['title'] as String,
    amountCents: j['amountCents'] as int,
    category: TxCategory.values.byName(j['category'] as String),
    kind: TxKind.values.byName(j['kind'] as String),
    date: DateTime.parse(j['date'] as String),
    status: TxStatus.values.byName(j['status'] as String),
    emoji: j['emoji'] as String?,
    note: j['note'] as String?,
    reference: j['reference'] as String?,
    location: j['location'] as String?,
    potId: j['potId'] as String?,
    declineReason: j['declineReason'] as String?,
    disputed: j['disputed'] as bool? ?? false,
    splitRequestIds: [...?(j['splitRequestIds'] as List?)?.cast<String>()],
  );
}

class BankCard {
  BankCard({
    required this.number,
    required this.expiry,
    required this.cvv,
    required this.pin,
    this.frozen = false,
    this.contactless = true,
    this.online = true,
    this.atm = true,
    this.abroad = true,
    this.gamblingBlock = false,
    this.replacementOrdered = false,
  });

  final String number;

  /// MM/YY
  final String expiry;
  final String cvv;
  final String pin;
  bool frozen;
  bool contactless;
  bool online;
  bool atm;
  bool abroad;
  bool gamblingBlock;
  bool replacementOrdered;

  String get last4 => number.substring(number.length - 4);
  String get groupedNumber =>
      [for (var i = 0; i < number.length; i += 4) number.substring(i, i + 4)]
          .join(' ');

  Map<String, dynamic> toJson() => {
    'number': number,
    'expiry': expiry,
    'cvv': cvv,
    'pin': pin,
    'frozen': frozen,
    'contactless': contactless,
    'online': online,
    'atm': atm,
    'abroad': abroad,
    'gamblingBlock': gamblingBlock,
    'replacementOrdered': replacementOrdered,
  };

  factory BankCard.fromJson(Map<String, dynamic> j) => BankCard(
    number: j['number'] as String,
    expiry: j['expiry'] as String,
    cvv: j['cvv'] as String,
    pin: j['pin'] as String,
    frozen: j['frozen'] as bool,
    contactless: j['contactless'] as bool,
    online: j['online'] as bool,
    atm: j['atm'] as bool,
    abroad: j['abroad'] as bool,
    gamblingBlock: j['gamblingBlock'] as bool,
    replacementOrdered: j['replacementOrdered'] as bool,
  );
}

class Payee {
  Payee({
    required this.id,
    required this.name,
    required this.sortCode,
    required this.accountNumber,
    this.hasBeenPaid = false,
  });

  final String id;
  final String name;
  final String sortCode;
  final String accountNumber;

  /// First payments to a payee get an extra scam check.
  bool hasBeenPaid;

  String get maskedDetails =>
      '${sortCode.substring(0, 2)}-${sortCode.substring(2, 4)}-${sortCode.substring(4)} · ••${accountNumber.substring(accountNumber.length - 4)}';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sortCode': sortCode,
    'accountNumber': accountNumber,
    'hasBeenPaid': hasBeenPaid,
  };

  factory Payee.fromJson(Map<String, dynamic> j) => Payee(
    id: j['id'] as String,
    name: j['name'] as String,
    sortCode: j['sortCode'] as String,
    accountNumber: j['accountNumber'] as String,
    hasBeenPaid: j['hasBeenPaid'] as bool? ?? false,
  );
}

enum ScheduleKind { standingOrder, directDebit }

enum Frequency {
  weekly('Weekly'),
  monthly('Monthly');

  const Frequency(this.label);
  final String label;
}

class ScheduledPayment {
  ScheduledPayment({
    required this.id,
    required this.kind,
    required this.name,
    required this.amountCents,
    required this.frequency,
    required this.nextDate,
    required this.category,
    this.payeeId,
    this.reference,
    this.emoji,
  });

  final String id;
  final ScheduleKind kind;
  final String name;
  final int amountCents;
  final Frequency frequency;
  DateTime nextDate;
  final TxCategory category;
  final String? payeeId;
  final String? reference;
  final String? emoji;

  DateTime get followingDate => frequency == Frequency.weekly
      ? nextDate.add(const Duration(days: 7))
      : DateTime(nextDate.year, nextDate.month + 1, nextDate.day);

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'name': name,
    'amountCents': amountCents,
    'frequency': frequency.name,
    'nextDate': nextDate.toIso8601String(),
    'category': category.name,
    'payeeId': payeeId,
    'reference': reference,
    'emoji': emoji,
  };

  factory ScheduledPayment.fromJson(Map<String, dynamic> j) => ScheduledPayment(
    id: j['id'] as String,
    kind: ScheduleKind.values.byName(j['kind'] as String),
    name: j['name'] as String,
    amountCents: j['amountCents'] as int,
    frequency: Frequency.values.byName(j['frequency'] as String),
    nextDate: DateTime.parse(j['nextDate'] as String),
    category: TxCategory.values.byName(j['category'] as String),
    payeeId: j['payeeId'] as String?,
    reference: j['reference'] as String?,
    emoji: j['emoji'] as String?,
  );
}

enum RequestStatus { pending, paid, cancelled }

/// Money the user has asked someone else to pay them.
class PaymentRequest {
  PaymentRequest({
    required this.id,
    required this.fromName,
    required this.amountCents,
    required this.createdAt,
    this.note,
    this.status = RequestStatus.pending,
  });

  final String id;
  final String fromName;
  final int amountCents;
  final DateTime createdAt;
  final String? note;
  RequestStatus status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromName': fromName,
    'amountCents': amountCents,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
    'status': status.name,
  };

  factory PaymentRequest.fromJson(Map<String, dynamic> j) => PaymentRequest(
    id: j['id'] as String,
    fromName: j['fromName'] as String,
    amountCents: j['amountCents'] as int,
    createdAt: DateTime.parse(j['createdAt'] as String),
    note: j['note'] as String?,
    status: RequestStatus.values.byName(j['status'] as String),
  );
}

class Profile {
  Profile({required this.name, required this.email});

  String name;
  String email;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  Map<String, dynamic> toJson() => {'name': name, 'email': email};

  factory Profile.fromJson(Map<String, dynamic> j) =>
      Profile(name: j['name'] as String, email: j['email'] as String);
}

/// Everything the app persists for one customer.
class BankData {
  BankData({
    required this.profile,
    required this.passcodeHash,
    required this.passcodeSalt,
    required this.account,
    required this.card,
    required this.pots,
    required this.transactions,
    required this.payees,
    required this.scheduled,
    required this.requests,
    this.monthlyBudgetCents,
    Map<TxCategory, int>? categoryBudgets,
    this.roundUpPotId,
    this.hideBalance = false,
  }) : categoryBudgets = categoryBudgets ?? {};

  final Profile profile;
  String passcodeHash;
  String passcodeSalt;
  final Account account;
  BankCard card;
  final List<Pot> pots;
  final List<BankTransaction> transactions;
  final List<Payee> payees;
  final List<ScheduledPayment> scheduled;
  final List<PaymentRequest> requests;
  int? monthlyBudgetCents;
  final Map<TxCategory, int> categoryBudgets;
  String? roundUpPotId;
  bool hideBalance;

  Map<String, dynamic> toJson() => {
    'profile': profile.toJson(),
    'passcodeHash': passcodeHash,
    'passcodeSalt': passcodeSalt,
    'account': account.toJson(),
    'card': card.toJson(),
    'pots': pots.map((e) => e.toJson()).toList(),
    'transactions': transactions.map((e) => e.toJson()).toList(),
    'payees': payees.map((e) => e.toJson()).toList(),
    'scheduled': scheduled.map((e) => e.toJson()).toList(),
    'requests': requests.map((e) => e.toJson()).toList(),
    'monthlyBudgetCents': monthlyBudgetCents,
    'categoryBudgets': {
      for (final e in categoryBudgets.entries) e.key.name: e.value,
    },
    'roundUpPotId': roundUpPotId,
    'hideBalance': hideBalance,
  };

  factory BankData.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        (j[key] as List).map((e) => f(e as Map<String, dynamic>)).toList();
    return BankData(
      profile: Profile.fromJson(j['profile'] as Map<String, dynamic>),
      passcodeHash: j['passcodeHash'] as String,
      passcodeSalt: j['passcodeSalt'] as String,
      account: Account.fromJson(j['account'] as Map<String, dynamic>),
      card: BankCard.fromJson(j['card'] as Map<String, dynamic>),
      pots: list('pots', Pot.fromJson),
      transactions: list('transactions', BankTransaction.fromJson),
      payees: list('payees', Payee.fromJson),
      scheduled: list('scheduled', ScheduledPayment.fromJson),
      requests: list('requests', PaymentRequest.fromJson),
      monthlyBudgetCents: j['monthlyBudgetCents'] as int?,
      categoryBudgets: {
        for (final e in (j['categoryBudgets'] as Map<String, dynamic>).entries)
          TxCategory.values.byName(e.key): e.value as int,
      },
      roundUpPotId: j['roundUpPotId'] as String?,
      hideBalance: j['hideBalance'] as bool? ?? false,
    );
  }
}
