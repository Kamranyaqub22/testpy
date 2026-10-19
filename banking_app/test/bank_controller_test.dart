import 'package:banking_app/services/bank_repository.dart';
import 'package:banking_app/state/bank_controller.dart';
import 'package:banking_app/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryBankRepository repo;
  late BankController bank;
  late DateTime now;

  setUp(() async {
    repo = InMemoryBankRepository();
    now = DateTime(2026, 10, 19, 12);
    bank = BankController(repo, clock: () => now);
    await bank.init();
  });

  test('starts in setup and registers with seeded accounts', () async {
    expect(bank.status, AuthStatus.needsSetup);
    await bank.register(name: 'Jordan Smith', pin: '1234');
    expect(bank.status, AuthStatus.unlocked);
    expect(bank.accounts, hasLength(2));
    // Balances are derived from the seed history.
    final fromHistory = bank.transactions.fold<int>(
      0,
      (s, t) => s + t.amountCents,
    );
    expect(bank.totalBalanceCents, fromHistory);
  });

  test('rejects invalid PINs at registration', () async {
    expect(
      () => bank.register(name: 'A', pin: '12'),
      throwsA(isA<BankException>()),
    );
    expect(
      () => bank.register(name: 'A', pin: 'abcd'),
      throwsA(isA<BankException>()),
    );
  });

  test('lock and unlock, with lockout after repeated failures', () async {
    await bank.register(name: 'Jordan', pin: '1234');
    bank.lock();
    expect(bank.status, AuthStatus.locked);
    for (var i = 0; i < BankController.maxPinAttempts; i++) {
      expect(bank.unlock('0000'), isFalse);
    }
    expect(() => bank.unlock('1234'), throwsA(isA<BankException>()));
    now = now.add(BankController.lockoutDuration + const Duration(seconds: 1));
    expect(bank.unlock('1234'), isTrue);
    expect(bank.status, AuthStatus.unlocked);
  });

  test('data persists across app restarts', () async {
    await bank.register(name: 'Jordan', pin: '1234');
    final total = bank.totalBalanceCents;
    final restarted = BankController(repo, clock: () => now);
    await restarted.init();
    expect(restarted.status, AuthStatus.locked);
    expect(restarted.unlock('1234'), isTrue);
    expect(restarted.totalBalanceCents, total);
  });

  test('transfer between own accounts moves money and keeps total', () async {
    await bank.register(name: 'Jordan', pin: '1234');
    final chk = bank.accountById('chk').balanceCents;
    final sav = bank.accountById('sav').balanceCents;
    final total = bank.totalBalanceCents;

    await bank.transferBetweenAccounts(
      fromId: 'chk',
      toId: 'sav',
      amountCents: 10050,
      note: 'rainy day',
    );

    expect(bank.accountById('chk').balanceCents, chk - 10050);
    expect(bank.accountById('sav').balanceCents, sav + 10050);
    expect(bank.totalBalanceCents, total);
    expect(bank.transactions.first.note, 'rainy day');
  });

  test('rejects overdrafts, zero amounts and same-account transfers', () async {
    await bank.register(name: 'Jordan', pin: '1234');
    final chk = bank.accountById('chk').balanceCents;
    expect(
      () => bank.transferBetweenAccounts(
        fromId: 'chk',
        toId: 'sav',
        amountCents: chk + 1,
      ),
      throwsA(isA<BankException>()),
    );
    expect(
      () => bank.transferBetweenAccounts(
        fromId: 'chk',
        toId: 'sav',
        amountCents: 0,
      ),
      throwsA(isA<BankException>()),
    );
    expect(
      () => bank.transferBetweenAccounts(
        fromId: 'chk',
        toId: 'chk',
        amountCents: 100,
      ),
      throwsA(isA<BankException>()),
    );
    expect(bank.accountById('chk').balanceCents, chk);
  });

  test('pay a new payee', () async {
    await bank.register(name: 'Jordan', pin: '1234');
    final payee = await bank.addPayee(
      name: 'Riley',
      accountNumber: '1234 5678 90',
    );
    expect(payee.accountNumber, '1234567890');
    final total = bank.totalBalanceCents;
    await bank.sendToPayee(fromId: 'chk', payeeId: payee.id, amountCents: 2500);
    expect(bank.totalBalanceCents, total - 2500);
    expect(bank.transactions.first.description, 'Payment to Riley');
    expect(
      () => bank.addPayee(name: 'X', accountNumber: '12'),
      throwsA(isA<BankException>()),
    );
  });

  test('change PIN', () async {
    await bank.register(name: 'Jordan', pin: '1234');
    expect(
      () => bank.changePin(currentPin: '9999', newPin: '5555'),
      throwsA(isA<BankException>()),
    );
    await bank.changePin(currentPin: '1234', newPin: '5555');
    bank.lock();
    expect(bank.unlock('1234'), isFalse);
    expect(bank.unlock('5555'), isTrue);
  });

  test('reset erases everything', () async {
    await bank.register(name: 'Jordan', pin: '1234');
    await bank.reset();
    expect(bank.status, AuthStatus.needsSetup);
    expect(await repo.load(), isNull);
  });

  group('money helpers', () {
    test('parseAmountToCents', () {
      expect(parseAmountToCents('12'), 1200);
      expect(parseAmountToCents('12.5'), 1250);
      expect(parseAmountToCents('1,234.56'), 123456);
      expect(parseAmountToCents('0.01'), 1);
      expect(parseAmountToCents('0'), isNull);
      expect(parseAmountToCents('1.234'), isNull);
      expect(parseAmountToCents('abc'), isNull);
      expect(parseAmountToCents('-5'), isNull);
    });

    test('formatCents', () {
      expect(formatCents(123456), '\$1,234.56');
      expect(formatCents(-500), '-\$5.00');
      expect(formatCents(500, showSign: true), '+\$5.00');
    });
  });
}
