import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/bank_controller.dart';
import '../widgets/keypads.dart';

/// Asks for the passcode before a sensitive action. Returns true when it was
/// entered correctly.
Future<bool> confirmWithPasscode(
  BuildContext context, {
  String title = 'Enter your passcode',
  String? subtitle,
}) async {
  final bank = context.read<BankController>();
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: PasscodeEntry(
              key: const Key('confirmPasscodeSheet'),
              title: title,
              subtitle: subtitle,
              onCompleted: (code) {
                if (!bank.verifyPasscode(code)) return 'Wrong passcode';
                Navigator.pop(sheet, true);
                return null;
              },
            ),
          ),
        ),
      ),
    ),
  );
  return ok ?? false;
}
