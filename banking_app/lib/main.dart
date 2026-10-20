import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/bank_repository.dart';
import 'state/bank_controller.dart';
import 'state/settings_controller.dart';
import 'design/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bank = BankController(LocalBankRepository());
  final settings = SettingsController();
  await Future.wait([bank.init(), settings.init()]);
  runApp(BankingApp(bank: bank, settings: settings));
}

class BankingApp extends StatelessWidget {
  const BankingApp({super.key, required this.bank, required this.settings});

  final BankController bank;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: bank),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) => MaterialApp(
          title: 'Horizon Bank',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: buildHorizonTheme(Brightness.light),
          darkTheme: buildHorizonTheme(Brightness.dark),
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

/// Shows onboarding, the lock screen or the app depending on auth state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final status = context.select<BankController, AuthStatus>((b) => b.status);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: switch (status) {
        AuthStatus.loading => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        AuthStatus.needsSetup => const OnboardingScreen(),
        AuthStatus.locked => const LockScreen(),
        AuthStatus.unlocked => HomeShell(key: HomeShell.globalKey),
      },
    );
  }
}
