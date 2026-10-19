import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/bank_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final settings = context.watch<SettingsController>();

    return ResponsiveBody(
      maxWidth: 640,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ListTile(
            leading: CircleAvatar(
              child: Text(bank.userName.isEmpty ? '?' : bank.userName[0]),
            ),
            title: Text(bank.userName),
            subtitle: Text('${bank.accounts.length} accounts'),
          ),
          const SectionHeader('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Dark'),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settings.setThemeMode(s.first),
            ),
          ),
          const SectionHeader('Payees'),
          if (bank.payees.isEmpty)
            const ListTile(title: Text('No saved payees')),
          for (final p in bank.payees)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(p.name),
              subtitle: Text(
                '•••• ${p.accountNumber.substring(p.accountNumber.length - 4)}',
              ),
              trailing: IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => bank.removePayee(p.id),
              ),
            ),
          const SectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('Change PIN'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => const _ChangePinDialog(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Lock app'),
            onTap: bank.lock,
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Erase all data on this device',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Erase all data?'),
                  content: const Text(
                    'Your profile, accounts and history on this device will be deleted.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Erase'),
                    ),
                  ],
                ),
              );
              if (ok == true) await bank.reset();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ChangePinDialog extends StatefulWidget {
  const _ChangePinDialog();

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await context.read<BankController>().changePin(
        currentPin: _current.text,
        newPin: _next.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, 'PIN updated');
    } on BankException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatters = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(6),
    ];
    return AlertDialog(
      title: const Text('Change PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _current,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: formatters,
            decoration: const InputDecoration(labelText: 'Current PIN'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _next,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: formatters,
            decoration: InputDecoration(
              labelText: 'New PIN (4–6 digits)',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
