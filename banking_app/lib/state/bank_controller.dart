import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../models/bank_data.dart';
import '../models/bank_transaction.dart';
import '../models/payee.dart';
import '../services/bank_repository.dart';
import '../services/demo_data.dart';

enum AuthStatus { loading, needsSetup, locked, unlocked }

/// A user-facing error, e.g. "Insufficient funds".
class BankException implements Exception {
  BankException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Holds the app's state and all banking rules. Screens read from it and call
/// its methods; they never change balances themselves.
class BankController extends ChangeNotifier {
  BankController(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const maxPinAttempts = 5;
  static const lockoutDuration = Duration(seconds: 30);

  final BankRepository _repository;
  final DateTime Function() _clock;
  final _random = Random.secure();

  BankData? _data;
  AuthStatus _status = AuthStatus.loading;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  AuthStatus get status => _status;
  String get userName => _data?.userName ?? '';
  List<Account> get accounts => List.unmodifiable(_data?.accounts ?? []);
  List<Payee> get payees => List.unmodifiable(_data?.payees ?? []);

  /// All transactions, newest first.
  List<BankTransaction> get transactions {
    final list = [...?_data?.transactions];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  int get totalBalanceCents =>
      accounts.fold(0, (sum, a) => sum + a.balanceCents);

  Account accountById(String id) =>
      _requireData().accounts.firstWhere((a) => a.id == id);

  /// Money in and out of all accounts for the current calendar month,
  /// excluding transfers between the user's own accounts.
  ({int income, int spending}) get thisMonthSummary {
    final now = _clock();
    var income = 0, spending = 0;
    for (final t in transactions) {
      if (t.date.year != now.year || t.date.month != now.month) continue;
      if (t.category == TxCategory.transfer) continue;
      if (t.isCredit) {
        income += t.amountCents;
      } else {
        spending += -t.amountCents;
      }
    }
    return (income: income, spending: spending);
  }

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    _data = await _repository.load();
    _status = _data == null ? AuthStatus.needsSetup : AuthStatus.locked;
    notifyListeners();
  }

  Future<void> register({required String name, required String pin}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw BankException('Please enter your name.');
    _validatePin(pin);

    final salt = _newSalt();
    final now = _clock();
    final accounts = DemoData.accounts();
    final history = DemoData.transactions(now);
    for (final t in history) {
      accounts.firstWhere((a) => a.id == t.accountId).balanceCents +=
          t.amountCents;
    }
    _data = BankData(
      userName: trimmed,
      pinHash: _hashPin(pin, salt),
      pinSalt: salt,
      accounts: accounts,
      transactions: history,
      payees: DemoData.payees(),
    );
    await _repository.save(_data!);
    _status = AuthStatus.unlocked;
    notifyListeners();
  }

  /// Time left before another PIN attempt is allowed, or null if not locked.
  Duration? get lockoutRemaining {
    final until = _lockedUntil;
    if (until == null) return null;
    final left = until.difference(_clock());
    return left.isNegative ? null : left;
  }

  /// Returns true when the PIN is correct.
  bool unlock(String pin) {
    final data = _requireData();
    final remaining = lockoutRemaining;
    if (remaining != null) {
      throw BankException(
        'Too many attempts. Try again in ${remaining.inSeconds + 1}s.',
      );
    }
    if (_hashPin(pin, data.pinSalt) == data.pinHash) {
      _failedAttempts = 0;
      _lockedUntil = null;
      _status = AuthStatus.unlocked;
      notifyListeners();
      return true;
    }
    _failedAttempts++;
    if (_failedAttempts >= maxPinAttempts) {
      _failedAttempts = 0;
      _lockedUntil = _clock().add(lockoutDuration);
    }
    return false;
  }

  void lock() {
    if (_data == null) return;
    _status = AuthStatus.locked;
    notifyListeners();
  }

  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    final data = _requireData();
    if (_hashPin(currentPin, data.pinSalt) != data.pinHash) {
      throw BankException('Current PIN is incorrect.');
    }
    _validatePin(newPin);
    data.pinSalt = _newSalt();
    data.pinHash = _hashPin(newPin, data.pinSalt);
    await _repository.save(data);
  }

  /// Deletes all data on this device and returns to the setup screen.
  Future<void> reset() async {
    await _repository.clear();
    _data = null;
    _status = AuthStatus.needsSetup;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Money movement
  // ---------------------------------------------------------------------------

  Future<void> transferBetweenAccounts({
    required String fromId,
    required String toId,
    required int amountCents,
    String? note,
  }) async {
    if (fromId == toId) {
      throw BankException('Choose two different accounts.');
    }
    final from = accountById(fromId);
    final to = accountById(toId);
    _checkFunds(from, amountCents);

    final now = _clock();
    from.balanceCents -= amountCents;
    to.balanceCents += amountCents;
    _requireData().transactions.addAll([
      _newTx(
        from.id,
        -amountCents,
        'Transfer to ${to.name}',
        TxCategory.transfer,
        now,
        note,
      ),
      _newTx(
        to.id,
        amountCents,
        'Transfer from ${from.name}',
        TxCategory.transfer,
        now,
        note,
      ),
    ]);
    await _persist();
  }

  Future<void> sendToPayee({
    required String fromId,
    required String payeeId,
    required int amountCents,
    String? note,
  }) async {
    final from = accountById(fromId);
    final payee = _requireData().payees.firstWhere((p) => p.id == payeeId);
    _checkFunds(from, amountCents);

    from.balanceCents -= amountCents;
    _requireData().transactions.add(
      _newTx(
        from.id,
        -amountCents,
        'Payment to ${payee.name}',
        TxCategory.other,
        _clock(),
        note,
      ),
    );
    await _persist();
  }

  Future<Payee> addPayee({
    required String name,
    required String accountNumber,
  }) async {
    final trimmedName = name.trim();
    final digits = accountNumber.replaceAll(RegExp(r'\s'), '');
    if (trimmedName.isEmpty) throw BankException('Please enter a name.');
    if (!RegExp(r'^\d{6,17}$').hasMatch(digits)) {
      throw BankException('Account number must be 6–17 digits.');
    }
    final payee = Payee(id: _newId(), name: trimmedName, accountNumber: digits);
    _requireData().payees.add(payee);
    await _persist();
    return payee;
  }

  Future<void> removePayee(String id) async {
    _requireData().payees.removeWhere((p) => p.id == id);
    await _persist();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  BankData _requireData() {
    final data = _data;
    if (data == null) throw StateError('No user is set up yet.');
    return data;
  }

  Future<void> _persist() async {
    await _repository.save(_requireData());
    notifyListeners();
  }

  void _checkFunds(Account from, int amountCents) {
    if (amountCents <= 0) throw BankException('Enter an amount above zero.');
    if (amountCents > from.balanceCents) {
      throw BankException('Insufficient funds in ${from.name}.');
    }
  }

  void _validatePin(String pin) {
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      throw BankException('PIN must be 4–6 digits.');
    }
  }

  BankTransaction _newTx(
    String accountId,
    int cents,
    String description,
    TxCategory category,
    DateTime date,
    String? note,
  ) => BankTransaction(
    id: _newId(),
    accountId: accountId,
    amountCents: cents,
    description: description,
    category: category,
    date: date,
    note: (note == null || note.trim().isEmpty) ? null : note.trim(),
  );

  String _newId() =>
      '${_clock().microsecondsSinceEpoch}-${_random.nextInt(0x7fffffff)}';

  String _newSalt() =>
      base64Encode(List.generate(16, (_) => _random.nextInt(256)));

  String _hashPin(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
}
