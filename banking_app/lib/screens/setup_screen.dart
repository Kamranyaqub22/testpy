import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/bank_controller.dart';
import '../widgets/common.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<BankController>().register(
        name: _name.text,
        pin: _pin.text,
      );
    } on BankException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinFormatters = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(6),
    ];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ResponsiveBody(
              maxWidth: 420,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to Horizon Bank',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your profile and a PIN to secure the app. '
                      'Demo accounts with sample activity will be added.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('Demo app – not a real bank'),
                        subtitle: Text(
                          'Data stays on this device. Do not use a real '
                          'banking PIN or password.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pin,
                      decoration: const InputDecoration(
                        labelText: 'PIN (4–6 digits)',
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: pinFormatters,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.length < 4)
                          ? 'PIN must be 4–6 digits'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      decoration: const InputDecoration(
                        labelText: 'Confirm PIN',
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: pinFormatters,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) =>
                          v != _pin.text ? 'PINs do not match' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Create account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
