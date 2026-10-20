# Horizon Bank: working on this app

A Flutter banking app (Android, iOS, web, Windows, macOS, Linux) built on the
**Horizon design system**. Every screen must follow it.

## Before any UI change

1. Read `design/README.md` (the brand book) and the guide for each component
   you touch in `design/components/<Name>.md`. The same system, with live
   previews, is hosted at https://claude.ai/artifact/DeWpmqp8Qjy1aeFtwVnKXh.
2. Reuse what exists: `lib/widgets/common.dart` (Panel, TransactionTile,
   TransactionFeed, IconTile, MerchantAvatar, InitialsAvatar, QuickAction,
   StatusPill, CardVisual, BalanceText, showBanner, confirm) and
   `lib/widgets/keypads.dart` (PasscodeEntry, AmountEntry, NumberPad).

## Rules the tests enforce (`test/design_system_test.dart`)

- **Colours** come only from tokens: `context.hz.<token>` (e.g.
  `context.hz.brand`, `context.hz.inkMuted`, `context.hz.category(c)`).
  Never write `Color(0x…)` or `Colors.<name>` in `lib/screens/` or
  `lib/widgets/`. `Colors.transparent` is fine anywhere; `Colors.white` is
  allowed only in `lib/widgets/common.dart` for the card face, which is white
  on Horizon Green in both themes.
- **Icons** come only from `HzIcons` (Lucide). Never use Material `Icons.*`.
  If an icon is missing, add a named entry to `HzIcons` in `lib/design/hz.dart`.
- **No emoji** in source strings. Emoji may appear only in text people type.

## Other rules

- Type: `HzType.<style>` (amountHero, amountLarge, amountRow, title1–3,
  bodyLarge, body, bodyStrong, caption, overline). Spacing: `HzSpace.s1…s10`.
  Radii: `HzRadius.sm/md/lg/xl/card/pill`. Sizes: `HzSize.tap/button/…`.
- Let the theme (`lib/design/theme.dart`) style stock widgets: FilledButton,
  OutlinedButton, TextButton, TextField, ListTile, SwitchListTile,
  NavigationBar and sheets. Don't restyle them per screen.
- Money is integer pence. Format with `formatMoney`, parse with
  `parseAmountToCents`. Money in shows `+` in `positive`; never signal state by
  colour alone.
- Copy: sentence case, "you", buttons that say what happens ("Send £42.50"),
  errors that say how to fix it. See "Voice and copy" in `design/README.md`.

## Changing the design system itself

- Edit `design/tokens.json`, then run `python3 tool/gen_tokens.py` and
  `dart format lib/design`. Never edit `lib/design/tokens.g.dart` by hand.
- Keep every text pair at 4.5:1 contrast in both themes (3:1 for icons).
- Logos are in `design/assets/Logos/`. Never redraw them; use `HorizonLogo` and
  `HorizonMark`. Regenerate app icons with `dart run flutter_launcher_icons`.
- Update `design/README.md` or `design/components/*.md` when a rule changes.

## Checks before committing

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
