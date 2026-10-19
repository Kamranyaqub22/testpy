import 'dart:math';

import 'package:banking_app/models/models.dart';
import 'package:banking_app/services/bank_repository.dart';
import 'package:banking_app/services/demo_data.dart';
import 'package:banking_app/state/bank_controller.dart';
import 'package:banking_app/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryBankRepository repo;
  late BankController bank;
  late DateTime now;

  BankController make() =>
      BankController(repo, clock: () => now, random: Random(7));

  /// Balance must always equal the sum of every non-declined transaction.
  void expectLedgerBalanced(BankController b) {
    final sum = b.transactions
        .where((t) => !t.isDeclined)
        .fold(0, (s, t) => s + t.amountCents);
    expect(b.account.balanceCents, sum);
    for (final p in b.pots) {
      final potSum = b.transactions
          .where((t) => t.potId == p.id && !t.isDeclined)
          .fold(0, (s, t) => s - t.amountCents);
      expect(p.balanceCents, potSum, reason: p.name);
    }
  }

  setUp(() async {
    repo = InMemoryBankRepository();
    now = DateTime(2026, 10, 19, 12);
    bank = make();
    await bank.init();
    await bank.register(
      name: 'Jordan Smith',
      email: 'jordan@example.com',
      passcode: '135790',
    );
  });

  group('onboarding & security', () {
    test('seeds a realistic account whose ledger balances', () {
      expect(bank.status, AuthStatus.unlocked);
      expect(bank.transactions.length, greaterThan(60));
      expect(bank.pots, hasLength(3));
      expect(bank.account.balanceCents, greaterThan(0));
      expect(bank.account.sortCode, hasLength(6));
      expect(bank.account.accountNumber, hasLength(8));
      expectLedgerBalanced(bank);
    });

    test('IBAN has valid check digits', () {
      final iban = bank.account.iban.replaceAll(' ', '');
      expect(iban, startsWith('GB'));
      final rearranged = iban.substring(4) + iban.substring(0, 4);
      final digits = rearranged.split('').map((c) {
        final code = c.codeUnitAt(0);
        return code >= 65 ? '${code - 55}' : c;
      }).join();
      expect(BigInt.parse(digits) % BigInt.from(97), BigInt.one);
    });

    test('rejects weak passcodes and bad emails', () async {
      final fresh = BankController(InMemoryBankRepository());
      await fresh.init();
      for (final weak in ['111111', '123456', '987654', '12345']) {
        expect(
          () => fresh.register(name: 'A B', email: 'a@b.co', passcode: weak),
          throwsA(isA<BankException>()),
          reason: weak,
        );
      }
      expect(
        () => fresh.register(name: 'A B', email: 'nope', passcode: '135790'),
        throwsA(isA<BankException>()),
      );
    });

    test('locks out after 5 wrong passcodes', () {
      bank.lock();
      for (var i = 0; i < BankController.maxPasscodeAttempts; i++) {
        expect(bank.unlock('000000'), isFalse);
      }
      expect(() => bank.unlock('135790'), throwsA(isA<BankException>()));
      now = now.add(const Duration(seconds: 31));
      expect(bank.unlock('135790'), isTrue);
    });

    test('data survives a restart and passcode can be changed', () async {
      final balance = bank.account.balanceCents;
      await bank.changePasscode(current: '135790', next: '246813');
      final restarted = make();
      await restarted.init();
      expect(restarted.status, AuthStatus.locked);
      expect(restarted.unlock('135790'), isFalse);
      expect(restarted.unlock('246813'), isTrue);
      expect(restarted.account.balanceCents, balance);
    });
  });

  group('payments', () {
    test('pays a payee and blocks overdrafts and limits', () async {
      final before = bank.account.balanceCents;
      await bank.payPayee(payeeId: 'p1', amountCents: 2500, reference: 'Tea');
      expect(bank.account.balanceCents, before - 2500);
      expect(bank.transactions.first.reference, 'Tea');
      expect(
        () => bank.payPayee(payeeId: 'p1', amountCents: before * 10),
        throwsA(isA<BankException>()),
      );
      expectLedgerBalanced(bank);
    });

    test('Confirmation of Payee outcomes', () {
      expect(
        bank.checkPayee(name: 'Alex Morgan', accountNumber: '41234567').outcome,
        CopOutcome.match,
      );
      final close = bank.checkPayee(
        name: 'Jon Smith',
        accountNumber: '12345678',
      );
      expect(close.outcome, CopOutcome.closeMatch);
      expect(close.registeredName, 'Jonathan Smith');
      expect(
        bank.checkPayee(name: 'Bob Jones', accountNumber: '87654321').outcome,
        CopOutcome.noMatch,
      );
      expect(
        bank.checkPayee(name: 'Anyone', accountNumber: '01234567').outcome,
        CopOutcome.unavailable,
      );
    });

    test('new payees are validated and first payment is flagged', () async {
      expect(
        () => bank.addPayee(name: 'X', sortCode: '12', accountNumber: '1'),
        throwsA(isA<BankException>()),
      );
      final p = await bank.addPayee(
        name: 'Emma Clarke',
        sortCode: '11-22-33',
        accountNumber: '87654321',
      );
      expect(p.sortCode, '112233');
      expect(p.hasBeenPaid, isFalse);
      await bank.payPayee(payeeId: p.id, amountCents: 100);
      expect(bank.payeeById(p.id).hasBeenPaid, isTrue);
    });

    test('standing orders run when due and advance', () async {
      final order = await bank.createStandingOrder(
        payeeId: 'p2',
        amountCents: 1000,
        frequency: Frequency.weekly,
        firstDate: now,
      );
      // First payment is due today (06:00), so it runs immediately.
      expect(
        bank.transactions.where(
          (t) =>
              t.title == 'Priya Shah' &&
              t.kind == TxKind.standingOrder &&
              t.date == DateTime(2026, 10, 19, 6),
        ),
        hasLength(1),
      );
      expect(
        bank.scheduled.firstWhere((s) => s.id == order.id).nextDate,
        DateTime(2026, 10, 26, 6),
      );
      expectLedgerBalanced(bank);
    });
  });

  group('requests & splitting', () {
    test('split a bill and get paid back', () async {
      final tx = bank.transactions.firstWhere(
        (t) => t.isCardPayment && !t.isDeclined,
      );
      final reqs = await bank.splitTransaction(tx.id, ['Alex', 'Sam']);
      expect(reqs, hasLength(2));
      expect(reqs.first.amountCents, tx.amountCents.abs() ~/ 3);
      final before = bank.account.balanceCents;
      await bank.markRequestPaid(reqs.first.id);
      expect(bank.account.balanceCents, before + reqs.first.amountCents);
      await bank.markRequestPaid(reqs.first.id); // paying twice is a no-op
      expect(bank.account.balanceCents, before + reqs.first.amountCents);
      expectLedgerBalanced(bank);
    });
  });

  group('pots', () {
    test('create, fund, withdraw and close', () async {
      final total = bank.account.balanceCents + bank.potsTotalCents;
      final pot = await bank.createPot(
        name: 'Car',
        emoji: '🚗',
        colorValue: 0xFF00FF00,
        goalCents: 50000,
      );
      await bank.addToPot(pot.id, 20000);
      expect(bank.potById(pot.id).progress, closeTo(.4, .001));
      await bank.withdrawFromPot(pot.id, 5000);
      expect(
        () => bank.withdrawFromPot(pot.id, 999999),
        throwsA(isA<BankException>()),
      );
      await bank.deletePot(pot.id);
      expect(bank.pots.any((p) => p.id == pot.id), isFalse);
      expect(bank.account.balanceCents + bank.potsTotalCents, total);
      expectLedgerBalanced(bank);
    });
  });

  group('card', () {
    test('frozen card declines without taking money', () async {
      await bank.setCardFrozen(true);
      final before = bank.account.balanceCents;
      final r = await bank.simulateCardPayment(DemoData.merchants.first);
      expect(r.payment.isDeclined, isTrue);
      expect(r.payment.declineReason, 'Your card is frozen');
      expect(bank.account.balanceCents, before);
      expectLedgerBalanced(bank);
    });

    test('card controls are enforced', () async {
      await bank.updateCardControls(gamblingBlock: true, abroad: false);
      final casino = DemoData.merchants.firstWhere((m) => m.gambling);
      final paris = DemoData.merchants.firstWhere((m) => m.abroad);
      expect(
        (await bank.simulateCardPayment(casino)).payment.declineReason,
        'Gambling block is on',
      );
      expect(
        (await bank.simulateCardPayment(paris)).payment.declineReason,
        'Payments abroad are turned off',
      );
    });

    test('card payments round up into the chosen pot', () async {
      final pot = bank.potById(bank.roundUpPotId!);
      final potBefore = pot.balanceCents;
      final r = await bank.simulateCardPayment(DemoData.merchants.first);
      expect(r.payment.isDeclined, isFalse);
      expect(r.roundUpCents, roundUpAmount(r.payment.amountCents));
      expect(bank.potById(pot.id).balanceCents, potBefore + r.roundUpCents);
      if (r.roundUpCents > 0) {
        expect(bank.roundUpFor(r.payment)?.amountCents, -r.roundUpCents);
      }
      expect(bank.feed.any((t) => t.kind == TxKind.roundUp), isFalse);
      expectLedgerBalanced(bank);
    });

    test('replace and activate card', () async {
      final oldNumber = bank.card.number;
      await bank.replaceCard();
      expect(bank.card.number, isNot(oldNumber));
      expect(bank.card.replacementOrdered, isTrue);
      expect(() => bank.activateCard('0000'), throwsA(isA<BankException>()));
      await bank.activateCard(bank.card.last4);
      expect(bank.card.replacementOrdered, isFalse);
    });
  });

  group('insights & statements', () {
    test('spending excludes pots, transfers and declines', () async {
      await bank.setCardFrozen(true);
      await bank.simulateCardPayment(DemoData.merchants.first);
      final spending = bank.spendingByCategory(now);
      expect(spending.keys, isNot(contains(TxCategory.savings)));
      expect(spending.keys, isNot(contains(TxCategory.transfers)));
      expect(spending.values.every((v) => v > 0), isTrue);
    });

    test('statements chain: each closing balance opens the next month', () {
      final months = bank.statementMonths;
      expect(months.length, greaterThanOrEqualTo(3));
      for (var i = 0; i < months.length - 1; i++) {
        final newer = bank.statementFor(months[i]);
        final older = bank.statementFor(months[i + 1]);
        expect(newer.openingCents, older.closingCents);
      }
      expect(
        bank.statementFor(months.first).closingCents,
        bank.account.balanceCents,
      );
    });
  });

  group('money helpers', () {
    test('parse, format and round-up', () {
      expect(parseAmountToCents('12.5'), 1250);
      expect(parseAmountToCents('1,234.56'), 123456);
      expect(parseAmountToCents('0'), isNull);
      expect(parseAmountToCents('1.234'), isNull);
      expect(formatMoney(123456), '£1,234.56');
      expect(formatMoney(-500), '-£5.00');
      expect(formatMoney(500, showPlus: true), '+£5.00');
      expect(formatMoney(150000, compact: true), '£1,500');
      expect(roundUpAmount(320), 80);
      expect(roundUpAmount(400), 0);
    });
  });
}
