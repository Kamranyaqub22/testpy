import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/bank_repository.dart';
import '../services/demo_data.dart';
import '../utils/money.dart';

enum AuthStatus { loading, needsSetup, locked, unlocked }

/// A user-facing error, e.g. "You don't have enough money".
class BankException implements Exception {
  BankException(this.message);
  final String message;

  @override
  String toString() => message;
}

enum CopOutcome { match, closeMatch, noMatch, unavailable }

/// Result of a (simulated) Confirmation of Payee name check.
class CopResult {
  const CopResult(this.outcome, [this.registeredName]);
  final CopOutcome outcome;
  final String? registeredName;
}

/// One month of account activity, as shown on a statement.
class MonthStatement {
  MonthStatement({
    required this.month,
    required this.openingCents,
    required this.closingCents,
    required this.inCents,
    required this.outCents,
    required this.transactions,
  });

  final DateTime month;
  final int openingCents;
  final int closingCents;
  final int inCents;
  final int outCents;
  final List<BankTransaction> transactions;
}

/// Holds the app's state and every banking rule. Screens read from it and
/// call its methods; they never change balances themselves.
class BankController extends ChangeNotifier {
  BankController(this._repository, {DateTime Function()? clock, Random? random})
    : _clock = clock ?? DateTime.now,
      _random = random ?? Random.secure();

  static const passcodeLength = 6;
  static const maxPasscodeAttempts = 5;
  static const lockoutDuration = Duration(seconds: 30);
  static const maxPaymentCents = 1000000; // £10,000 per payment

  final BankRepository _repository;
  final DateTime Function() _clock;
  final Random _random;

  BankData? _data;
  AuthStatus _status = AuthStatus.loading;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  DateTime get now => _clock();
  AuthStatus get status => _status;
  BankData get data {
    final d = _data;
    if (d == null) throw StateError('No customer is set up yet.');
    return d;
  }

  Profile get profile => data.profile;
  Account get account => data.account;
  BankCard get card => data.card;
  List<Pot> get pots => List.unmodifiable(data.pots);
  List<Payee> get payees => List.unmodifiable(data.payees);
  bool get hideBalance => data.hideBalance;
  String? get roundUpPotId => data.roundUpPotId;
  int? get monthlyBudgetCents => data.monthlyBudgetCents;
  Map<TxCategory, int> get categoryBudgets =>
      Map.unmodifiable(data.categoryBudgets);

  /// All transactions, newest first.
  List<BankTransaction> get transactions =>
      [...data.transactions]..sort((a, b) => b.date.compareTo(a.date));

  /// Transactions for the main feed: round-ups are shown on the payment they
  /// belong to rather than as rows of their own.
  List<BankTransaction> get feed =>
      transactions.where((t) => t.kind != TxKind.roundUp).toList();

  /// The round-up made for a card payment, if any.
  BankTransaction? roundUpFor(BankTransaction payment) {
    if (!payment.isCardPayment || payment.isDeclined) return null;
    return data.transactions
        .where(
          (t) =>
              t.kind == TxKind.roundUp &&
              t.date.difference(payment.date).inSeconds.abs() <= 2,
        )
        .firstOrNull;
  }

  List<ScheduledPayment> get scheduled =>
      [...data.scheduled]..sort((a, b) => a.nextDate.compareTo(b.nextDate));

  List<PaymentRequest> get requests =>
      [...data.requests]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get potsTotalCents => data.pots.fold(0, (s, p) => s + p.balanceCents);

  BankTransaction transactionById(String id) =>
      data.transactions.firstWhere((t) => t.id == id);
  Pot potById(String id) => data.pots.firstWhere((p) => p.id == id);
  Payee payeeById(String id) => data.payees.firstWhere((p) => p.id == id);

  /// Card and other spending today, excluding pots and transfers.
  int get spentTodayCents {
    final t = now;
    return data.transactions
        .where(
          (x) =>
              x.countsAsSpending &&
              x.date.year == t.year &&
              x.date.month == t.month &&
              x.date.day == t.day,
        )
        .fold(0, (s, x) => s - x.amountCents);
  }

  /// Scheduled payments due in the next [days] days.
  List<ScheduledPayment> upcoming({int days = 7}) {
    final limit = now.add(Duration(days: days));
    return scheduled.where((s) => s.nextDate.isBefore(limit)).toList();
  }

  // ---------------------------------------------------------------------------
  // Onboarding & security
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    _data = await _repository.load();
    if (_data == null) {
      _status = AuthStatus.needsSetup;
    } else {
      _status = AuthStatus.locked;
      _runDailyJobs();
      await _repository.save(_data!);
    }
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String passcode,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw BankException('Please enter your name.');
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      throw BankException('Please enter a valid email address.');
    }
    _validatePasscode(passcode);

    final t = now;
    final salt = _newSalt();
    final scheduled = DemoData.scheduled(t);
    final history = DemoData.history(t, scheduled);
    final account = Account(
      sortCode: '04${_digits(4)}',
      accountNumber: _digits(8),
      balanceCents: 0,
    );
    final pots = DemoData.pots();
    for (final tx in history) {
      account.balanceCents += tx.amountCents;
      if (tx.potId != null) {
        pots.firstWhere((p) => p.id == tx.potId).balanceCents -= tx.amountCents;
      }
    }
    _data = BankData(
      profile: Profile(name: trimmed, email: email.trim()),
      passcodeHash: _hash(passcode, salt),
      passcodeSalt: salt,
      account: account,
      card: DemoData.newCard(_random, t),
      pots: pots,
      transactions: history,
      payees: DemoData.payees(),
      scheduled: scheduled,
      requests: [
        PaymentRequest(
          id: 'req-seed',
          fromName: 'Alex Morgan',
          amountCents: 1850,
          createdAt: t.subtract(const Duration(days: 2)),
          note: 'Cinema tickets 🎬',
        ),
      ],
      monthlyBudgetCents: 220000,
      categoryBudgets: {
        TxCategory.eatingOut: 18000,
        TxCategory.groceries: 30000,
        TxCategory.transport: 9000,
      },
      roundUpPotId: 'pot-holiday',
    );
    await _repository.save(_data!);
    _status = AuthStatus.unlocked;
    notifyListeners();
  }

  /// Time left before another passcode attempt is allowed.
  Duration? get lockoutRemaining {
    final until = _lockedUntil;
    if (until == null) return null;
    final left = until.difference(now);
    return left.isNegative ? null : left;
  }

  /// Returns true when the passcode is correct.
  bool unlock(String passcode) {
    final remaining = lockoutRemaining;
    if (remaining != null) {
      throw BankException(
        'Too many attempts. Try again in ${remaining.inSeconds + 1}s.',
      );
    }
    if (_hash(passcode, data.passcodeSalt) == data.passcodeHash) {
      _failedAttempts = 0;
      _lockedUntil = null;
      _status = AuthStatus.unlocked;
      _runDailyJobs();
      _persist();
      return true;
    }
    _failedAttempts++;
    if (_failedAttempts >= maxPasscodeAttempts) {
      _failedAttempts = 0;
      _lockedUntil = now.add(lockoutDuration);
    }
    return false;
  }

  /// Checks the passcode without changing lock state, for sensitive actions
  /// such as revealing card details or confirming a payment.
  bool verifyPasscode(String passcode) =>
      _hash(passcode, data.passcodeSalt) == data.passcodeHash;

  void lock() {
    if (_data == null) return;
    _status = AuthStatus.locked;
    notifyListeners();
  }

  Future<void> changePasscode({
    required String current,
    required String next,
  }) async {
    if (!verifyPasscode(current)) {
      throw BankException('Your current passcode is incorrect.');
    }
    _validatePasscode(next);
    data.passcodeSalt = _newSalt();
    data.passcodeHash = _hash(next, data.passcodeSalt);
    await _persist();
  }

  Future<void> updateProfile({String? name, String? email}) async {
    if (name != null && name.trim().isNotEmpty) profile.name = name.trim();
    if (email != null && email.trim().isNotEmpty) profile.email = email.trim();
    await _persist();
  }

  Future<void> setHideBalance(bool hide) async {
    data.hideBalance = hide;
    await _persist();
  }

  /// Deletes everything on this device and returns to onboarding.
  Future<void> reset() async {
    await _repository.clear();
    _data = null;
    _status = AuthStatus.needsSetup;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Payees & payments
  // ---------------------------------------------------------------------------

  /// Simulated Confirmation of Payee: checks the name against the name the
  /// receiving bank holds for that account.
  CopResult checkPayee({required String name, required String accountNumber}) {
    if (accountNumber.startsWith('0')) {
      return const CopResult(CopOutcome.unavailable);
    }
    final registered = DemoData.payeeDirectory[accountNumber];
    if (registered == null) return CopResult(CopOutcome.match, name.trim());
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), '').trim();
    final a = norm(name), b = norm(registered);
    if (a == b) return CopResult(CopOutcome.match, registered);
    final aParts = a.split(RegExp(r'\s+')), bParts = b.split(RegExp(r'\s+'));
    final sameSurname = aParts.length > 1 && aParts.last == bParts.last;
    final firstClose =
        aParts.first.isNotEmpty &&
        bParts.first.isNotEmpty &&
        aParts.first[0] == bParts.first[0];
    if ((sameSurname && firstClose) || _distance(a, b) <= 2) {
      return CopResult(CopOutcome.closeMatch, registered);
    }
    return CopResult(CopOutcome.noMatch, registered);
  }

  Future<Payee> addPayee({
    required String name,
    required String sortCode,
    required String accountNumber,
  }) async {
    final sc = sortCode.replaceAll(RegExp(r'\D'), '');
    final acc = accountNumber.replaceAll(RegExp(r'\D'), '');
    if (name.trim().isEmpty) throw BankException('Enter the payee’s name.');
    if (sc.length != 6) throw BankException('Sort codes have 6 digits.');
    if (acc.length != 8) throw BankException('Account numbers have 8 digits.');
    final existing = data.payees.where(
      (p) => p.sortCode == sc && p.accountNumber == acc,
    );
    if (existing.isNotEmpty) return existing.first;
    final payee = Payee(
      id: _newId(),
      name: name.trim(),
      sortCode: sc,
      accountNumber: acc,
    );
    data.payees.add(payee);
    await _persist();
    return payee;
  }

  Future<void> removePayee(String id) async {
    data.payees.removeWhere((p) => p.id == id);
    await _persist();
  }

  Future<BankTransaction> payPayee({
    required String payeeId,
    required int amountCents,
    String? reference,
  }) async {
    final payee = payeeById(payeeId);
    _checkCanSpend(amountCents);
    if (amountCents > maxPaymentCents) {
      throw BankException(
        'The most you can send in one payment is ${formatMoney(maxPaymentCents)}.',
      );
    }
    account.balanceCents -= amountCents;
    payee.hasBeenPaid = true;
    final tx = _addTx(
      title: payee.name,
      amount: -amountCents,
      category: TxCategory.transfers,
      kind: TxKind.fasterPayment,
      reference: _clean(reference),
    );
    await _persist();
    return tx;
  }

  Future<ScheduledPayment> createStandingOrder({
    required String payeeId,
    required int amountCents,
    required Frequency frequency,
    required DateTime firstDate,
    String? reference,
  }) async {
    final payee = payeeById(payeeId);
    if (amountCents <= 0) throw BankException('Enter an amount above zero.');
    final order = ScheduledPayment(
      id: _newId(),
      kind: ScheduleKind.standingOrder,
      name: payee.name,
      amountCents: amountCents,
      frequency: frequency,
      nextDate: DateTime(firstDate.year, firstDate.month, firstDate.day, 6),
      category: TxCategory.transfers,
      payeeId: payee.id,
      reference: _clean(reference),
    );
    data.scheduled.add(order);
    _runDailyJobs();
    await _persist();
    return order;
  }

  Future<void> cancelScheduled(String id) async {
    data.scheduled.removeWhere((s) => s.id == id);
    await _persist();
  }

  // ---------------------------------------------------------------------------
  // Requests & bill splitting
  // ---------------------------------------------------------------------------

  Future<PaymentRequest> requestMoney({
    required String fromName,
    required int amountCents,
    String? note,
  }) async {
    if (fromName.trim().isEmpty) throw BankException('Who is paying you?');
    if (amountCents <= 0) throw BankException('Enter an amount above zero.');
    final req = PaymentRequest(
      id: _newId(),
      fromName: fromName.trim(),
      amountCents: amountCents,
      createdAt: now,
      note: _clean(note),
    );
    data.requests.add(req);
    await _persist();
    return req;
  }

  /// Splits a payment equally between the user and [people], creating a
  /// request to each person for their share.
  Future<List<PaymentRequest>> splitTransaction(
    String txId,
    List<String> people,
  ) async {
    final tx = transactionById(txId);
    final names = people.map((p) => p.trim()).where((p) => p.isNotEmpty);
    if (names.isEmpty) throw BankException('Add at least one person.');
    if (tx.isIncoming || tx.isDeclined) {
      throw BankException('Only completed payments can be split.');
    }
    final share = tx.amountCents.abs() ~/ (names.length + 1);
    final created = [
      for (final n in names)
        PaymentRequest(
          id: _newId(),
          fromName: n,
          amountCents: share,
          createdAt: now,
          note: 'Split: ${tx.title}',
        ),
    ];
    data.requests.addAll(created);
    tx.splitRequestIds = [...tx.splitRequestIds, ...created.map((r) => r.id)];
    await _persist();
    return created;
  }

  /// Marks a request as paid and credits the money (simulates the other
  /// person paying).
  Future<void> markRequestPaid(String id) async {
    final req = data.requests.firstWhere((r) => r.id == id);
    if (req.status != RequestStatus.pending) return;
    req.status = RequestStatus.paid;
    account.balanceCents += req.amountCents;
    _addTx(
      title: req.fromName,
      amount: req.amountCents,
      category: TxCategory.transfers,
      kind: TxKind.fasterPayment,
      reference: req.note,
      emoji: '👋',
    );
    await _persist();
  }

  Future<void> cancelRequest(String id) async {
    data.requests.firstWhere((r) => r.id == id).status =
        RequestStatus.cancelled;
    await _persist();
  }

  // ---------------------------------------------------------------------------
  // Pots
  // ---------------------------------------------------------------------------

  Future<Pot> createPot({
    required String name,
    required String emoji,
    required int colorValue,
    int? goalCents,
  }) async {
    if (name.trim().isEmpty) throw BankException('Give your pot a name.');
    final pot = Pot(
      id: _newId(),
      name: name.trim(),
      emoji: emoji,
      colorValue: colorValue,
      goalCents: goalCents,
    );
    data.pots.add(pot);
    await _persist();
    return pot;
  }

  Future<void> updatePot(
    String id, {
    String? name,
    String? emoji,
    int? goalCents,
    bool clearGoal = false,
  }) async {
    final pot = potById(id);
    if (name != null && name.trim().isNotEmpty) pot.name = name.trim();
    if (emoji != null) pot.emoji = emoji;
    if (clearGoal) {
      pot.goalCents = null;
    } else if (goalCents != null) {
      pot.goalCents = goalCents;
    }
    await _persist();
  }

  Future<void> addToPot(String id, int amountCents) async {
    final pot = potById(id);
    _checkCanSpend(amountCents);
    account.balanceCents -= amountCents;
    pot.balanceCents += amountCents;
    _addTx(
      title: pot.name,
      amount: -amountCents,
      category: TxCategory.savings,
      kind: TxKind.pot,
      emoji: pot.emoji,
      potId: pot.id,
    );
    await _persist();
  }

  Future<void> withdrawFromPot(String id, int amountCents) async {
    final pot = potById(id);
    if (amountCents <= 0) throw BankException('Enter an amount above zero.');
    if (amountCents > pot.balanceCents) {
      throw BankException(
        'There’s only ${formatMoney(pot.balanceCents)} in this pot.',
      );
    }
    pot.balanceCents -= amountCents;
    account.balanceCents += amountCents;
    _addTx(
      title: pot.name,
      amount: amountCents,
      category: TxCategory.savings,
      kind: TxKind.pot,
      emoji: pot.emoji,
      potId: pot.id,
    );
    await _persist();
  }

  /// Closes a pot, moving anything left in it back to the main balance.
  Future<void> deletePot(String id) async {
    final pot = potById(id);
    if (pot.balanceCents > 0) await withdrawFromPot(id, pot.balanceCents);
    data.pots.removeWhere((p) => p.id == id);
    if (data.roundUpPotId == id) data.roundUpPotId = null;
    await _persist();
  }

  Future<void> setRoundUpPot(String? potId) async {
    data.roundUpPotId = potId;
    await _persist();
  }

  // ---------------------------------------------------------------------------
  // Card
  // ---------------------------------------------------------------------------

  Future<void> setCardFrozen(bool frozen) async {
    card.frozen = frozen;
    await _persist();
  }

  Future<void> updateCardControls({
    bool? contactless,
    bool? online,
    bool? atm,
    bool? abroad,
    bool? gamblingBlock,
  }) async {
    if (contactless != null) card.contactless = contactless;
    if (online != null) card.online = online;
    if (atm != null) card.atm = atm;
    if (abroad != null) card.abroad = abroad;
    if (gamblingBlock != null) card.gamblingBlock = gamblingBlock;
    await _persist();
  }

  /// Cancels the current card and orders a new one with new details.
  Future<void> replaceCard() async {
    final old = card;
    data.card = DemoData.newCard(_random, now)
      ..replacementOrdered = true
      ..contactless = old.contactless
      ..online = old.online
      ..atm = old.atm
      ..abroad = old.abroad
      ..gamblingBlock = old.gamblingBlock;
    await _persist();
  }

  /// Activates a replacement card. The customer confirms the last 4 digits
  /// printed on the card they received.
  Future<void> activateCard(String last4) async {
    if (last4 != card.last4) {
      throw BankException('Those digits don’t match your new card.');
    }
    card.replacementOrdered = false;
    await _persist();
  }

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  Future<void> setCategory(String txId, TxCategory category) async {
    transactionById(txId).category = category;
    await _persist();
  }

  Future<void> setNote(String txId, String note) async {
    transactionById(txId).note = _clean(note);
    await _persist();
  }

  Future<void> disputeTransaction(String txId) async {
    transactionById(txId).disputed = true;
    await _persist();
  }

  // ---------------------------------------------------------------------------
  // Insights & budgets
  // ---------------------------------------------------------------------------

  /// Spending per category in [month], largest first. With [upToDay], only
  /// days 1..upToDay count, for like-for-like comparisons with this month.
  Map<TxCategory, int> spendingByCategory(DateTime month, {int? upToDay}) {
    final result = <TxCategory, int>{};
    for (final t in data.transactions) {
      if (!t.countsAsSpending) continue;
      if (t.date.year != month.year || t.date.month != month.month) continue;
      if (upToDay != null && t.date.day > upToDay) continue;
      result.update(
        t.category,
        (v) => v - t.amountCents,
        ifAbsent: () => -t.amountCents,
      );
    }
    final sorted = result.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  int incomeForMonth(DateTime month) => data.transactions
      .where(
        (t) =>
            !t.isDeclined &&
            t.isIncoming &&
            t.category == TxCategory.income &&
            t.date.year == month.year &&
            t.date.month == month.month,
      )
      .fold(0, (s, t) => s + t.amountCents);

  Future<void> setMonthlyBudget(int? cents) async {
    data.monthlyBudgetCents = cents;
    await _persist();
  }

  Future<void> setCategoryBudget(TxCategory c, int? cents) async {
    if (cents == null) {
      data.categoryBudgets.remove(c);
    } else {
      data.categoryBudgets[c] = cents;
    }
    await _persist();
  }

  /// Months with activity, newest first.
  List<DateTime> get statementMonths {
    if (data.transactions.isEmpty) return [];
    final first = data.transactions
        .map((t) => t.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final months = <DateTime>[];
    var m = DateTime(now.year, now.month);
    while (!m.isBefore(DateTime(first.year, first.month))) {
      months.add(m);
      m = DateTime(m.year, m.month - 1);
    }
    return months;
  }

  MonthStatement statementFor(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final settled = data.transactions.where((t) => !t.isDeclined);
    final after = settled
        .where((t) => !t.date.isBefore(start))
        .fold(0, (s, t) => s + t.amountCents);
    final opening = account.balanceCents - after;
    final inMonth =
        settled
            .where((t) => !t.date.isBefore(start) && t.date.isBefore(end))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final inCents = inMonth
        .where((t) => t.amountCents > 0)
        .fold(0, (s, t) => s + t.amountCents);
    final outCents = inMonth
        .where((t) => t.amountCents < 0)
        .fold(0, (s, t) => s - t.amountCents);
    return MonthStatement(
      month: start,
      openingCents: opening,
      closingCents: opening + inCents - outCents,
      inCents: inCents,
      outCents: outCents,
      transactions: inMonth,
    );
  }

  // ---------------------------------------------------------------------------
  // Demo tools: simulate events that would normally come from the card network
  // ---------------------------------------------------------------------------

  /// Simulates a card payment at [merchant] (random when null). Card controls
  /// are enforced, so this is how declines and round-ups can be tried out.
  /// Returns the new transaction and any round-up made.
  Future<({BankTransaction payment, int roundUpCents})> simulateCardPayment([
    MerchantPreset? merchant,
  ]) async {
    final m =
        merchant ??
        DemoData.merchants[_random.nextInt(DemoData.merchants.length - 2)];
    final amount = m.minPence + _random.nextInt(m.maxPence - m.minPence);
    final reason = _declineReason(m, amount);
    final tx = _addTx(
      title: m.name,
      amount: -amount,
      category: m.category,
      kind: m.kind,
      emoji: m.emoji,
      location: m.location,
      status: reason == null ? TxStatus.pending : TxStatus.declined,
      declineReason: reason,
    );
    var roundUp = 0;
    if (reason == null) {
      account.balanceCents -= amount;
      final pot = data.roundUpPotId == null
          ? null
          : data.pots.where((p) => p.id == data.roundUpPotId).firstOrNull;
      roundUp = roundUpAmount(amount);
      if (pot != null && roundUp > 0 && account.balanceCents >= roundUp) {
        account.balanceCents -= roundUp;
        pot.balanceCents += roundUp;
        _addTx(
          title: 'Round-up to ${pot.name}',
          amount: -roundUp,
          category: TxCategory.savings,
          kind: TxKind.roundUp,
          emoji: pot.emoji,
          potId: pot.id,
          date: tx.date.add(const Duration(seconds: 1)),
        );
      } else {
        roundUp = 0;
      }
    }
    await _persist();
    return (payment: tx, roundUpCents: roundUp);
  }

  Future<BankTransaction> simulateIncomingPayment() async {
    const senders = [
      ('Priya Shah', 'Coffee money ☕', 640),
      ('Alex Morgan', 'Gig tickets', 4500),
      ('Marketplace Sale', 'Old bike', 12000),
    ];
    final s = senders[_random.nextInt(senders.length)];
    account.balanceCents += s.$3;
    final tx = _addTx(
      title: s.$1,
      amount: s.$3,
      category: TxCategory.transfers,
      kind: TxKind.fasterPayment,
      reference: s.$2,
      emoji: '💸',
    );
    await _persist();
    return tx;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String? _declineReason(MerchantPreset m, int amount) {
    if (card.frozen) return 'Your card is frozen';
    if (m.gambling && card.gamblingBlock) return 'Gambling block is on';
    if (m.kind == TxKind.online && !card.online) {
      return 'Online payments are turned off';
    }
    if (m.kind == TxKind.contactless && !card.contactless) {
      return 'Contactless is turned off';
    }
    if (m.kind == TxKind.atm && !card.atm) return 'ATM withdrawals are off';
    if (m.abroad && !card.abroad) return 'Payments abroad are turned off';
    if (amount > account.balanceCents) return 'Not enough money';
    return null;
  }

  /// Settles old pending card payments and makes any scheduled payments
  /// that have fallen due.
  void _runDailyJobs() {
    final t = now;
    for (final tx in data.transactions) {
      if (tx.status == TxStatus.pending &&
          t.difference(tx.date) > const Duration(days: 1)) {
        tx.status = TxStatus.settled;
      }
    }
    for (final s in data.scheduled) {
      while (!s.nextDate.isAfter(t)) {
        if (s.amountCents <= account.balanceCents) {
          account.balanceCents -= s.amountCents;
          _addTx(
            title: s.name,
            amount: -s.amountCents,
            category: s.category,
            kind: s.kind == ScheduleKind.directDebit
                ? TxKind.directDebit
                : TxKind.standingOrder,
            emoji: s.emoji,
            reference: s.reference,
            date: s.nextDate,
          );
        } else {
          _addTx(
            title: s.name,
            amount: -s.amountCents,
            category: s.category,
            kind: s.kind == ScheduleKind.directDebit
                ? TxKind.directDebit
                : TxKind.standingOrder,
            emoji: s.emoji,
            date: s.nextDate,
            status: TxStatus.declined,
            declineReason: 'Not enough money',
          );
        }
        s.nextDate = s.followingDate;
      }
    }
  }

  BankTransaction _addTx({
    required String title,
    required int amount,
    required TxCategory category,
    required TxKind kind,
    String? emoji,
    String? reference,
    String? location,
    String? potId,
    DateTime? date,
    TxStatus status = TxStatus.settled,
    String? declineReason,
  }) {
    final tx = BankTransaction(
      id: _newId(),
      title: title,
      amountCents: amount,
      category: category,
      kind: kind,
      date: date ?? now,
      status: status,
      emoji: emoji,
      reference: reference,
      location: location,
      potId: potId,
      declineReason: declineReason,
    );
    data.transactions.add(tx);
    return tx;
  }

  Future<void> _persist() async {
    await _repository.save(data);
    notifyListeners();
  }

  void _checkCanSpend(int amountCents) {
    if (amountCents <= 0) throw BankException('Enter an amount above zero.');
    if (amountCents > account.balanceCents) {
      throw BankException(
        'You don’t have enough money. Your balance is ${formatMoney(account.balanceCents)}.',
      );
    }
  }

  void _validatePasscode(String passcode) {
    if (!RegExp('^\\d{$passcodeLength}\$').hasMatch(passcode)) {
      throw BankException('Your passcode must be $passcodeLength digits.');
    }
    if (RegExp(r'^(\d)\1+$').hasMatch(passcode) ||
        '0123456789'.contains(passcode) ||
        '9876543210'.contains(passcode)) {
      throw BankException('Choose a passcode that’s harder to guess.');
    }
  }

  static String? _clean(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();

  String _digits(int n) => List.generate(n, (_) => _random.nextInt(10)).join();

  String _newId() =>
      '${now.microsecondsSinceEpoch}-${_random.nextInt(0x7fffffff)}';

  String _newSalt() =>
      base64Encode(List.generate(16, (_) => _random.nextInt(256)));

  static String _hash(String passcode, String salt) =>
      sha256.convert(utf8.encode('$salt:$passcode')).toString();

  static int _distance(String a, String b) {
    final dp = List.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      var prev = dp[0];
      dp[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final tmp = dp[j];
        dp[j] = a[i - 1] == b[j - 1]
            ? prev
            : 1 + [prev, dp[j], dp[j - 1]].reduce(min);
        prev = tmp;
      }
    }
    return dp[b.length];
  }
}
