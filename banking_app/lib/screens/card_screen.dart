import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/bank_controller.dart';
import '../widgets/common.dart';
import '../widgets/theme.dart';
import 'passcode_sheet.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  bool _revealed = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleReveal() async {
    if (_revealed) {
      setState(() => _revealed = false);
      return;
    }
    final ok = await confirmWithPasscode(
      context,
      title: 'Show card details',
      subtitle: 'Enter your passcode to see your card number and CVV.',
    );
    if (!ok || !mounted) return;
    setState(() => _revealed = true);
    // Hide sensitive details again automatically.
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) setState(() => _revealed = false);
    });
  }

  Future<void> _showPin() async {
    final bank = context.read<BankController>();
    final ok = await confirmWithPasscode(context, title: 'View your PIN');
    if (!ok || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your card PIN'),
        content: Text(
          bank.card.pin.split('').join('  '),
          key: const Key('cardPin'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _lostOrStolen() async {
    final bank = context.read<BankController>();
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'What happened to your card?',
                style: Theme.of(sheet).textTheme.titleLarge,
              ),
            ),
            for (final r in const [
              ('lost', '🔍', 'I’ve lost it'),
              ('stolen', '🚨', 'It’s been stolen'),
              ('damaged', '🪫', 'It’s damaged or not working'),
            ])
              ListTile(
                key: Key('reason-${r.$1}'),
                leading: Text(r.$2, style: const TextStyle(fontSize: 24)),
                title: Text(r.$3),
                onTap: () => Navigator.pop(sheet, r.$1),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;
    final ok = await confirm(
      context,
      title: 'Cancel this card and order a new one?',
      message: reason == 'damaged'
          ? 'Your current card will stop working when you activate the new one.'
          : 'Your current card will be cancelled straight away. You’ll get a '
                'new card number, and Direct Debits will carry on as normal.',
      action: 'Order new card',
    );
    if (!ok) return;
    await bank.replaceCard();
    if (mounted) {
      showBanner(
        context,
        emoji: '📬',
        title: 'New card ordered',
        body:
            'It’ll arrive in 3–5 working days. Use the new details online now.',
      );
    }
  }

  Future<void> _activate() async {
    final bank = context.read<BankController>();
    final controller = TextEditingController();
    final digits = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activate your new card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the last 4 digits of the card you received. '
              '(Demo: they’re ${bank.card.last4}.)',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('activateDigits'),
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (digits == null || !mounted) return;
    try {
      await bank.activateCard(digits);
      if (mounted) showSnack(context, 'Card activated. Enjoy!');
    } on BankException catch (e) {
      if (mounted) showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final card = bank.card;
    final theme = Theme.of(context);

    Widget control(
      String title,
      String subtitle,
      IconData icon,
      bool value,
      void Function(bool) onChanged, {
      Key? key,
    }) => SwitchListTile(
      key: key,
      secondary: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );

    return SafeArea(
      child: ResponsiveBody(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text('Card', style: theme.textTheme.headlineMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: GestureDetector(
                    onTap: _toggleReveal,
                    child: CardVisual(
                      card: card,
                      holder: bank.profile.name,
                      revealed: _revealed,
                    ),
                  ),
                ),
              ),
            ),
            if (_revealed)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy number'),
                        onPressed: () => copyToClipboard(
                          context,
                          card.number,
                          'Card number',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (card.replacementOrdered)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Panel(
                  child: ListTile(
                    key: const Key('activateCard'),
                    leading: const Text('📬', style: TextStyle(fontSize: 26)),
                    title: const Text(
                      'Your new card is on its way',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Tap here to activate it when it arrives',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _activate,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: QuickAction(
                      key: const Key('freezeCard'),
                      icon: Icons.ac_unit_rounded,
                      label: card.frozen ? 'Unfreeze' : 'Freeze',
                      highlighted: card.frozen,
                      onTap: () => bank.setCardFrozen(!card.frozen),
                    ),
                  ),
                  Expanded(
                    child: QuickAction(
                      key: const Key('showDetails'),
                      icon: _revealed
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      label: _revealed ? 'Hide details' : 'Show details',
                      onTap: _toggleReveal,
                    ),
                  ),
                  Expanded(
                    child: QuickAction(
                      key: const Key('viewPin'),
                      icon: Icons.pin_outlined,
                      label: 'View PIN',
                      onTap: _showPin,
                    ),
                  ),
                ],
              ),
            ),
            if (card.frozen)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Brand.frost.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Your card is frozen. Card payments and cash withdrawals '
                    'will be declined. Direct Debits and transfers still work.',
                    style: TextStyle(color: Brand.ink),
                  ),
                ),
              ),
            const SectionHeader('Security & controls'),
            Panel(
              child: Column(
                children: [
                  control(
                    'Contactless',
                    'Tap to pay in shops',
                    Icons.contactless_outlined,
                    card.contactless,
                    (v) => bank.updateCardControls(contactless: v),
                  ),
                  control(
                    'Online payments',
                    'Shopping on websites and in apps',
                    Icons.language_rounded,
                    card.online,
                    (v) => bank.updateCardControls(online: v),
                    key: const Key('onlineToggle'),
                  ),
                  control(
                    'ATM withdrawals',
                    'Taking out cash',
                    Icons.local_atm_rounded,
                    card.atm,
                    (v) => bank.updateCardControls(atm: v),
                  ),
                  control(
                    'Payments abroad',
                    'Use your card outside the UK',
                    Icons.public_rounded,
                    card.abroad,
                    (v) => bank.updateCardControls(abroad: v),
                  ),
                  control(
                    'Block gambling',
                    'Decline payments to betting and gambling sites',
                    Icons.casino_outlined,
                    card.gamblingBlock,
                    (v) => bank.updateCardControls(gamblingBlock: v),
                    key: const Key('gamblingToggle'),
                  ),
                ],
              ),
            ),
            const SectionHeader('Something wrong?'),
            Panel(
              child: ListTile(
                key: const Key('lostCard'),
                leading: const Icon(
                  Icons.report_gmailerrorred_rounded,
                  color: Brand.danger,
                ),
                title: const Text(
                  'Report lost, stolen or damaged',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Cancel this card and get a new one'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _lostOrStolen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
