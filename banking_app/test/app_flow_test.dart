import 'dart:math';

import 'package:banking_app/main.dart';
import 'package:banking_app/services/bank_repository.dart';
import 'package:banking_app/state/bank_controller.dart';
import 'package:banking_app/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const passcode = '135790';

Future<BankController> pumpApp(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final bank = BankController(InMemoryBankRepository(), random: Random(3));
  final settings = SettingsController();
  await tester.runAsync(() => Future.wait([bank.init(), settings.init()]));
  await tester.pumpWidget(BankingApp(bank: bank, settings: settings));
  await tester.pumpAndSettle();
  return bank;
}

/// Lets in-memory saves complete, then settles animations.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<void> typeCode(WidgetTester tester, String code) async {
  for (final d in code.split('')) {
    await tester.tap(find.byKey(Key('key-$d')).last);
    await tester.pump();
  }
  await settle(tester);
}

Future<void> onboard(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('getStarted')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('nameField')), 'Jordan Smith');
  await tester.tap(find.byKey(const Key('continue')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('emailField')),
    'jordan@example.com',
  );
  await tester.tap(find.byKey(const Key('continue')));
  await tester.pumpAndSettle();
  await typeCode(tester, '123456'); // too easy: rejected
  expect(find.text('That’s too easy to guess'), findsOneWidget);
  await typeCode(tester, passcode);
  await typeCode(tester, passcode);
  expect(find.text('Welcome to Horizon, Jordan!'), findsOneWidget);
  await tester.tap(find.byKey(const Key('finishOnboarding')));
  await settle(tester);
}

void main() {
  testWidgets('onboarding, lock and unlock with the passcode', (tester) async {
    final bank = await pumpApp(tester, const Size(400, 860));
    await onboard(tester);
    expect(find.text('Hi Jordan'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    bank.lock();
    await tester.pumpAndSettle();
    await typeCode(tester, '000000');
    expect(find.text('Wrong passcode'), findsOneWidget);
    await typeCode(tester, passcode);
    expect(find.text('Hi Jordan'), findsOneWidget);
  });

  testWidgets('pay a new payee: name check, scam check, passcode, success', (
    tester,
  ) async {
    final bank = await pumpApp(tester, const Size(400, 860));
    await onboard(tester);
    final before = bank.account.balanceCents;

    await tester.tap(find.text('Payments').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('paySomeone')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newPayee')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('payeeName')), 'Jon Smith');
    await tester.enterText(find.byKey(const Key('payeeSortCode')), '112233');
    await tester.enterText(find.byKey(const Key('payeeAccount')), '12345678');
    expect(find.text('11-22-33'), findsOneWidget);
    await tester.tap(find.byKey(const Key('checkPayee')));
    await tester.pumpAndSettle();
    expect(find.text('Did you mean Jonathan Smith?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('useSuggestedName')));
    await settle(tester);

    // Amount keypad: £42.50
    await typeCode(tester, '42');
    await tester.tap(find.byKey(const Key('key-.')));
    await tester.pump();
    await typeCode(tester, '5');
    expect(find.text('£42.5'), findsOneWidget);
    await tester.tap(find.byKey(const Key('amountNext')));
    await tester.pumpAndSettle();
    expect(find.text('to Jonathan Smith'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('reference')), 'GIG');
    await tester.ensureVisible(find.byKey(const Key('sendPayment')));
    await tester.tap(find.byKey(const Key('sendPayment')));
    await tester.pumpAndSettle();

    // First payment to a new payee: scam check.
    await tester.tap(find.byKey(const Key('reason-friends')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scamContinue')));
    await tester.pumpAndSettle();
    await typeCode(tester, passcode);
    expect(find.text('£42.50 sent'), findsOneWidget);
    expect(bank.account.balanceCents, before - 4250);
    await tester.tap(find.byKey(const Key('done')));
    await tester.pumpAndSettle();
    expect(find.text('Payments'), findsWidgets);
  });

  testWidgets('freeze card, then a simulated card payment is declined', (
    tester,
  ) async {
    final bank = await pumpApp(tester, const Size(400, 860));
    await onboard(tester);
    await tester.tap(find.text('Card').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('freezeCard')));
    await settle(tester);
    expect(bank.card.frozen, isTrue);
    expect(find.text('Card frozen'), findsWidgets);

    // Reveal card details needs the passcode.
    await tester.tap(find.byKey(const Key('showDetails')));
    await tester.pumpAndSettle();
    await typeCode(tester, passcode);
    expect(find.text(bank.card.groupedNumber), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openProfile')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('simulateCard')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final before = bank.account.balanceCents;
    await tester.tap(find.byKey(const Key('simulateCard')));
    await settle(tester);
    expect(find.textContaining('Payment declined at'), findsOneWidget);
    expect(bank.account.balanceCents, before);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('create a pot and add money with the keypad', (tester) async {
    final bank = await pumpApp(tester, const Size(400, 860));
    await onboard(tester);
    await tester.tap(find.text('Pots').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('createPot')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('potName')), 'Concert');
    await tester.enterText(find.byKey(const Key('potGoal')), '200');
    await tester.tap(find.byKey(const Key('savePot')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('addToPot')));
    await tester.pumpAndSettle();
    await typeCode(tester, '50');
    await tester.tap(find.byKey(const Key('confirmPotMove')));
    await settle(tester);
    final pot = bank.pots.firstWhere((p) => p.name == 'Concert');
    expect(pot.balanceCents, 5000);
    expect(find.textContaining('£150.00 to go'), findsOneWidget);
  });

  testWidgets('desktop/web layout: navigation rail and insights', (
    tester,
  ) async {
    await pumpApp(tester, const Size(1280, 860));
    await onboard(tester);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('monthSpent')), findsOneWidget);
    expect(find.text('Monthly budget'), findsOneWidget);
  });
}
