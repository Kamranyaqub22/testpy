import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/bank_controller.dart';
import '../widgets/common.dart';
import '../widgets/keypads.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = context.read<BankController>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ResponsiveBody(
              maxWidth: 400,
              child: Column(
                children: [
                  InitialsAvatar(bank.profile.name, size: 64),
                  const SizedBox(height: 16),
                  PasscodeEntry(
                    key: const Key('unlockPasscode'),
                    title: 'Welcome back, ${bank.profile.firstName}',
                    subtitle: 'Enter your passcode',
                    onCompleted: (code) {
                      try {
                        return bank.unlock(code) ? null : 'Wrong passcode';
                      } on BankException catch (e) {
                        return e.message;
                      }
                    },
                    footer: TextButton(
                      onPressed: () async {
                        final ok = await confirm(
                          context,
                          title: 'Forgotten your passcode?',
                          message:
                              'In this demo, the only way back in is to erase '
                              'the account on this device and start again.',
                          action: 'Erase and start again',
                          destructive: true,
                        );
                        if (ok) await bank.reset();
                      },
                      child: const Text('Forgotten your passcode?'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
