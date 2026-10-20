import 'dart:math';

import '../models/models.dart';

/// A merchant the demo can generate card payments for.
class MerchantPreset {
  const MerchantPreset(
    this.name,
    this.category,
    this.minPence,
    this.maxPence, {
    this.kind = TxKind.contactless,
    this.location = 'London, UK',
    this.gambling = false,
    this.abroad = false,
  });

  final String name;
  final TxCategory category;
  final int minPence;
  final int maxPence;
  final TxKind kind;
  final String location;
  final bool gambling;
  final bool abroad;
}

/// Sample customer data so a new profile has a realistic history. All
/// merchant and people names are fictional.
class DemoData {
  static const merchants = [
    MerchantPreset('FreshCo', TxCategory.groceries, 1240, 6850),
    MerchantPreset('Green Basket Market', TxCategory.groceries, 420, 2190),
    MerchantPreset('Bean & Leaf Coffee', TxCategory.eatingOut, 285, 640),
    MerchantPreset('Noodle Bar 88', TxCategory.eatingOut, 1150, 3200),
    MerchantPreset('Slice Pizza Co', TxCategory.eatingOut, 1400, 2900),
    MerchantPreset('CityRail', TxCategory.transport, 280, 1460),
    MerchantPreset('Hop Bikes', TxCategory.transport, 150, 450),
    MerchantPreset(
      'ZipRide',
      TxCategory.transport,
      890,
      2400,
      kind: TxKind.online,
      location: 'Online',
    ),
    MerchantPreset('Northwind Books', TxCategory.shopping, 899, 2499),
    MerchantPreset(
      'Parcelly',
      TxCategory.shopping,
      1299,
      7499,
      kind: TxKind.online,
      location: 'Online',
    ),
    MerchantPreset(
      'Odeon Lane Cinema',
      TxCategory.entertainment,
      1150,
      2600,
      kind: TxKind.card,
    ),
    MerchantPreset('Glow Pharmacy', TxCategory.personalCare, 349, 1899),
    MerchantPreset(
      'Sharp Cuts Barbers',
      TxCategory.personalCare,
      1800,
      3200,
      kind: TxKind.card,
    ),
    MerchantPreset(
      'ATM Withdrawal',
      TxCategory.cash,
      2000,
      6000,
      kind: TxKind.atm,
    ),
    MerchantPreset(
      'Café Lumière Paris',
      TxCategory.holidays,
      680,
      2400,
      location: 'Paris, France',
      abroad: true,
    ),
    MerchantPreset(
      'LuckySpin Casino',
      TxCategory.entertainment,
      1000,
      5000,
      kind: TxKind.online,
      location: 'Online',
      gambling: true,
    ),
  ];

  /// Registered account holder names, used to simulate Confirmation of Payee.
  /// Unknown account numbers are treated as matching, except numbers that
  /// start with 0, which simulate a bank that can't be checked.
  static const payeeDirectory = {
    '41234567': 'Alex Morgan',
    '52345678': 'Priya Shah',
    '63456789': 'Oakwood Lettings Ltd',
    '12345678': 'Jonathan Smith',
    '87654321': 'Emma Clarke',
  };

  static List<Payee> payees() => [
    Payee(
      id: 'p1',
      name: 'Alex Morgan',
      sortCode: '204577',
      accountNumber: '41234567',
      hasBeenPaid: true,
    ),
    Payee(
      id: 'p2',
      name: 'Priya Shah',
      sortCode: '309912',
      accountNumber: '52345678',
      hasBeenPaid: true,
    ),
    Payee(
      id: 'p3',
      name: 'Oakwood Lettings Ltd',
      sortCode: '401276',
      accountNumber: '63456789',
      hasBeenPaid: true,
    ),
  ];

  static List<Pot> pots() => [
    Pot(
      id: 'pot-holiday',
      name: 'Lisbon trip',
      icon: 'palm',
      colorValue: 0xFF0F8F9C,
      goalCents: 150000,
    ),
    Pot(
      id: 'pot-rainy',
      name: 'Rainy day',
      icon: 'umbrella',
      colorValue: 0xFF4A5BD4,
    ),
    Pot(
      id: 'pot-tech',
      name: 'New laptop',
      icon: 'laptop',
      colorValue: 0xFF9A4FD0,
      goalCents: 120000,
    ),
  ];

  static BankCard newCard(Random r, DateTime now) {
    final digits = List.generate(12, (_) => r.nextInt(10)).join();
    final expiry = DateTime(now.year + 4, now.month);
    return BankCard(
      number: '5355$digits',
      expiry:
          '${expiry.month.toString().padLeft(2, '0')}/${(expiry.year % 100).toString().padLeft(2, '0')}',
      cvv: List.generate(3, (_) => r.nextInt(10)).join(),
      pin: List.generate(4, (_) => r.nextInt(10)).join(),
    );
  }

  /// Direct debits and standing orders, with their next date after [now].
  static List<ScheduledPayment> scheduled(DateTime now) {
    DateTime next(int day) {
      final thisMonth = DateTime(now.year, now.month, day, 6);
      return thisMonth.isAfter(now)
          ? thisMonth
          : DateTime(now.year, now.month + 1, day, 6);
    }

    return [
      ScheduledPayment(
        id: 's-rent',
        kind: ScheduleKind.standingOrder,
        name: 'Oakwood Lettings Ltd',
        amountCents: 115000,
        frequency: Frequency.monthly,
        nextDate: next(1),
        category: TxCategory.bills,
        payeeId: 'p3',
        reference: 'FLAT 4B RENT',
      ),
      ScheduledPayment(
        id: 's-council',
        kind: ScheduleKind.directDebit,
        name: 'Riverside Council Tax',
        amountCents: 14200,
        frequency: Frequency.monthly,
        nextDate: next(5),
        category: TxCategory.bills,
      ),
      ScheduledPayment(
        id: 's-stream',
        kind: ScheduleKind.directDebit,
        name: 'Streamly',
        amountCents: 1099,
        frequency: Frequency.monthly,
        nextDate: next(8),
        category: TxCategory.entertainment,
      ),
      ScheduledPayment(
        id: 's-energy',
        kind: ScheduleKind.directDebit,
        name: 'Brightwave Energy',
        amountCents: 8600,
        frequency: Frequency.monthly,
        nextDate: next(12),
        category: TxCategory.bills,
      ),
      ScheduledPayment(
        id: 's-gym',
        kind: ScheduleKind.directDebit,
        name: 'PulseFit Gym',
        amountCents: 3499,
        frequency: Frequency.monthly,
        nextDate: next(15),
        category: TxCategory.personalCare,
      ),
      ScheduledPayment(
        id: 's-phone',
        kind: ScheduleKind.directDebit,
        name: 'Orbit Mobile',
        amountCents: 1800,
        frequency: Frequency.monthly,
        nextDate: next(20),
        category: TxCategory.bills,
      ),
    ];
  }

  /// About ten weeks of history ending at [now]. Balances are derived from
  /// these entries, so the feed and the balance always agree.
  static List<BankTransaction> history(DateTime now, List<ScheduledPayment> s) {
    final r = Random(42);
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 70));
    final txs = <BankTransaction>[];
    var n = 0;
    void add(
      DateTime date,
      String title,
      int amount,
      TxCategory category,
      TxKind kind, {
      String? reference,
      String? location,
      String? potId,
    }) {
      if (date.isAfter(now)) return;
      txs.add(
        BankTransaction(
          id: 'seed-${n++}',
          title: title,
          amountCents: amount,
          category: category,
          kind: kind,
          date: date,
          reference: reference,
          location: location,
          potId: potId,
        ),
      );
    }

    add(
      start,
      'Opening deposit',
      240000,
      TxCategory.income,
      TxKind.fasterPayment,
      reference: 'WELCOME',
    );

    for (var d = 0; d <= 70; d++) {
      final day = start.add(Duration(days: d));
      DateTime at(int h, int m) => DateTime(day.year, day.month, day.day, h, m);

      if (day.day == 25) {
        add(
          at(7, 2),
          'Acme Studio Ltd',
          285000,
          TxCategory.income,
          TxKind.income,
          reference: 'SALARY',
        );
        add(
          at(9, 15),
          'Lisbon trip',
          -20000,
          TxCategory.savings,
          TxKind.pot,
          potId: 'pot-holiday',
        );
        add(
          at(9, 16),
          'Rainy day',
          -15000,
          TxCategory.savings,
          TxKind.pot,
          potId: 'pot-rainy',
        );
      }
      for (final p in s) {
        if (p.nextDate.day == day.day && d > 0) {
          add(
            at(6, 0),
            p.name,
            -p.amountCents,
            p.category,
            p.kind == ScheduleKind.directDebit
                ? TxKind.directDebit
                : TxKind.standingOrder,
            reference: p.reference,
          );
        }
      }
      if (d == 30) {
        add(
          at(19, 40),
          'Priya Shah',
          2450,
          TxCategory.transfers,
          TxKind.fasterPayment,
          reference: 'Dinner split',
        );
      }
      if (d == 18) {
        add(
          at(10, 0),
          'New laptop',
          -30000,
          TxCategory.savings,
          TxKind.pot,
          potId: 'pot-tech',
        );
      }

      // Everyday card spending: 1–3 purchases most days.
      final count = r.nextInt(4);
      for (var i = 0; i < count; i++) {
        final everyday = merchants.where(
          (m) => !m.gambling && !m.abroad && m.kind != TxKind.atm,
        );
        final m = everyday.elementAt(r.nextInt(everyday.length));
        final amount = m.minPence + r.nextInt(m.maxPence - m.minPence);
        final time = at(8 + r.nextInt(13), r.nextInt(60));
        add(time, m.name, -amount, m.category, m.kind, location: m.location);
        if (d > 40 && amount % 100 != 0) {
          add(
            time.add(const Duration(seconds: 1)),
            'Round-up to Lisbon trip',
            -(100 - amount % 100),
            TxCategory.savings,
            TxKind.roundUp,
            potId: 'pot-holiday',
          );
        }
      }
      if (d % 16 == 7) {
        final atm = merchants.firstWhere((m) => m.kind == TxKind.atm);
        add(
          at(13, 5),
          atm.name,
          -2000 * (1 + r.nextInt(3)),
          atm.category,
          atm.kind,
          location: 'High Street, London',
        );
      }
    }
    // The most recent card payments are still pending, as at a real bank.
    txs.sort((a, b) => a.date.compareTo(b.date));
    for (final t in txs.reversed.where((t) => t.isCardPayment).take(2)) {
      t.status = TxStatus.pending;
    }
    return txs;
  }
}
