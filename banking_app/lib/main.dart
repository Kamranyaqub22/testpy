import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/lock_screen.dart';
import 'screens/setup_screen.dart';
import 'services/bank_repository.dart';
import 'state/bank_controller.dart';
import 'state/settings_controller.dart';

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
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: const _AuthGate(),
        ),
      ),
    );
  }

  ThemeData _theme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B5FFF),
      brightness: brightness,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

/// Picks the first screen based on whether the user is set up and unlocked.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final status = context.select<BankController, AuthStatus>((b) => b.status);
    return switch (status) {
      AuthStatus.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthStatus.needsSetup => const SetupScreen(),
      AuthStatus.locked => const LockScreen(),
      AuthStatus.unlocked => const HomeShell(),
    };
  }
}
