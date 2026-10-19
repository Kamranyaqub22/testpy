import 'package:banking_app/main.dart';
import 'package:banking_app/services/bank_repository.dart';
import 'package:banking_app/state/bank_controller.dart';
import 'package:banking_app/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<BankController> _pumpApp(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final bank = BankController(InMemoryBankRepository());
  final settings = SettingsController();
  await tester.runAsync(() => Future.wait([bank.init(), settings.init()]));
  await tester.pumpWidget(BankingApp(bank: bank, settings: settings));
  await tester.pumpAndSettle();
  return bank;
}

Future<void> _register(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Full name'),
    'Jordan Smith',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'PIN (4–6 digits)'),
    '1234',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Confirm PIN'),
    '1234',
  );
  await tester.tap(find.text('Create account'));
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('phone layout: setup, dashboard, transfer, lock/unlock', (
    tester,
  ) async {
    final bank = await _pumpApp(tester, const Size(400, 860));
    expect(find.text('Welcome to Horizon Bank'), findsOneWidget);

    await _register(tester);
    expect(find.text('Hello, Jordan'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Transfer $25 from checking to savings.
    final checkingBefore = bank.accountById('chk').balanceCents;
    await tester.tap(find.text('Transfer').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fromAccount')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Everyday Checking ·').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toAccount')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High-Yield Savings').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amount')), '25');
    await tester.tap(find.byKey(const Key('submitTransfer')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(bank.accountById('chk').balanceCents, checkingBefore - 2500);
    expect(find.text('Hello, Jordan'), findsOneWidget);

    // Lock, then unlock with the PIN.
    await tester.tap(find.byTooltip('Lock'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pinField')), '0000');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect PIN'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('pinField')), '1234');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Jordan'), findsOneWidget);
  });

  testWidgets('desktop/web layout uses a navigation rail', (tester) async {
    await _pumpApp(tester, const Size(1280, 800));
    await _register(tester);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'salary');
    await tester.pumpAndSettle();
    expect(find.text('Salary – Acme Corp'), findsNWidgets(2));
  });
}
