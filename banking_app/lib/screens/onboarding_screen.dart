import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/hz.dart';
import '../models/models.dart';
import '../state/bank_controller.dart';
import '../widgets/common.dart';
import '../widgets/keypads.dart';

enum _Step { welcome, name, email, passcode, confirm, cardOrdered }

/// New-customer journey: intro slides, details, passcode, then a card
/// "on its way" before landing in the account.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  _Step _step = _Step.welcome;
  final _name = TextEditingController();
  final _email = TextEditingController();
  String _passcode = '';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _go(_Step s) => setState(() => _step = s);

  void _back() => _go(switch (_step) {
    _Step.name => _Step.welcome,
    _Step.email => _Step.name,
    _Step.passcode => _Step.email,
    _Step.confirm => _Step.passcode,
    _ => _step,
  });

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      await context.read<BankController>().register(
        name: _name.text,
        email: _email.text,
        passcode: _passcode,
      );
    } on BankException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBack = _step != _Step.welcome && _step != _Step.cardOrdered;
    return Scaffold(
      appBar: showBack
          ? AppBar(
              leading: BackButton(onPressed: _back),
              title: _Progress(step: _step.index, of: 4),
            )
          : null,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(key: ValueKey(_step), child: _body()),
        ),
      ),
    );
  }

  Widget _body() => switch (_step) {
    _Step.welcome => _Welcome(onStart: () => _go(_Step.name)),
    _Step.name => _FieldStep(
      title: 'What’s your full name?',
      subtitle: 'As it appears on your ID. It’ll go on your card.',
      controller: _name,
      label: 'Full name',
      fieldKey: const Key('nameField'),
      keyboard: TextInputType.name,
      validate: (v) => v.trim().split(RegExp(r'\s+')).length < 2
          ? 'Enter your first and last name'
          : null,
      onNext: () => _go(_Step.email),
    ),
    _Step.email => _FieldStep(
      title: 'What’s your email?',
      subtitle: 'We’ll send your statements and important updates here.',
      controller: _email,
      label: 'Email address',
      fieldKey: const Key('emailField'),
      keyboard: TextInputType.emailAddress,
      validate: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
          ? null
          : 'Enter a valid email address',
      onNext: () => _go(_Step.passcode),
    ),
    _Step.passcode => _CenteredPad(
      child: PasscodeEntry(
        key: const Key('createPasscode'),
        title: 'Create a passcode',
        subtitle:
            'You’ll use these 6 digits to open the app and approve payments.',
        onCompleted: (code) {
          if (RegExp(r'^(\d)\1+$').hasMatch(code) ||
              '0123456789'.contains(code) ||
              '9876543210'.contains(code)) {
            return 'That’s too easy to guess';
          }
          _passcode = code;
          _go(_Step.confirm);
          return null;
        },
      ),
    ),
    _Step.confirm => _CenteredPad(
      child: PasscodeEntry(
        key: const Key('confirmPasscode'),
        title: 'Confirm your passcode',
        onCompleted: (code) {
          if (code != _passcode) return 'Passcodes don’t match';
          _go(_Step.cardOrdered);
          return null;
        },
      ),
    ),
    _Step.cardOrdered => _CardOrdered(
      name: _name.text.trim(),
      busy: _busy,
      onContinue: _finish,
    ),
  };
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step, required this.of});
  final int step;
  final int of;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 220),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(value: step / of, minHeight: 6),
    ),
  );
}

class _Welcome extends StatefulWidget {
  const _Welcome({required this.onStart});
  final VoidCallback onStart;

  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome> {
  final _pages = PageController();
  int _page = 0;

  static const _slides = [
    (
      icon: HzIcons.sparkle,
      title: 'Banking that\nlooks ahead',
      body: 'See every payment the moment it happens, with spending sorted for you.',
    ),
    (
      icon: HzIcons.pots,
      title: 'Save in Pots',
      body: 'Set money aside for the things you care about. Round up your spare change automatically.',
    ),
    (
      icon: HzIcons.shield,
      title: 'You’re in control',
      body: 'Freeze your card in a tap, block gambling, and check who you’re paying before you send.',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsiveBody(
      maxWidth: 520,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const HorizonLogo(height: 34),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.hz.sunTint,
                    borderRadius: BorderRadius.circular(HzRadius.pill),
                  ),
                  child: Text(
                    'DEMO',
                    style: HzType.overline.copyWith(color: context.hz.onSun),
                  ),
                ),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      i == 0
                          ? Container(
                              width: 112,
                              height: 112,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: context.hz.brandDeep,
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: const HorizonMark(
                                size: 84,
                                reversed: true,
                              ),
                            )
                          : IconTile(
                              icon: s.icon,
                              color: context.hz.brand,
                              size: 112,
                            ),
                      const SizedBox(height: 32),
                      Text(s.title, style: theme.textTheme.displaySmall),
                      const SizedBox(height: 16),
                      Text(
                        s.body,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    width: i == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Panel(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(HzIcons.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Demo app – not a real bank. Data stays on this device. '
                      'Don’t use a real banking passcode.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('getStarted'),
              onPressed: widget.onStart,
              child: const Text('Open an account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldStep extends StatefulWidget {
  const _FieldStep({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.label,
    required this.fieldKey,
    required this.keyboard,
    required this.validate,
    required this.onNext,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;
  final String label;
  final Key fieldKey;
  final TextInputType keyboard;
  final String? Function(String) validate;
  final VoidCallback onNext;

  @override
  State<_FieldStep> createState() => _FieldStepState();
}

class _FieldStepState extends State<_FieldStep> {
  String? _error;

  void _next() {
    final error = widget.validate(widget.controller.text);
    setState(() => _error = error);
    if (error == null) widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsiveBody(
      maxWidth: 520,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              key: widget.fieldKey,
              controller: widget.controller,
              autofocus: true,
              keyboardType: widget.keyboard,
              textCapitalization: widget.keyboard == TextInputType.name
                  ? TextCapitalization.words
                  : TextCapitalization.none,
              decoration: InputDecoration(
                labelText: widget.label,
                errorText: _error,
              ),
              onSubmitted: (_) => _next(),
            ),
            const Spacer(),
            FilledButton(
              key: const Key('continue'),
              onPressed: _next,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredPad extends StatelessWidget {
  const _CenteredPad({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ResponsiveBody(maxWidth: 400, child: child),
    ),
  );
}

class _CardOrdered extends StatelessWidget {
  const _CardOrdered({
    required this.name,
    required this.busy,
    required this.onContinue,
  });

  final String name;
  final bool busy;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewCard = BankCard(
      number: '5355000000000000',
      expiry: '',
      cvv: '',
      pin: '',
    );
    return ResponsiveBody(
      maxWidth: 520,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .85, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: CardVisual(card: previewCard, holder: name),
            ),
            const SizedBox(height: 36),
            Text(
              'Welcome to Horizon, ${name.split(' ').first}!',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Your account is open and your card is on its way. It should '
              'arrive in 3–5 working days. You can start using your card '
              'details online right now.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const Spacer(),
            FilledButton(
              key: const Key('finishOnboarding'),
              onPressed: busy ? null : onContinue,
              child: const Text('Go to my account'),
            ),
          ],
        ),
      ),
    );
  }
}
