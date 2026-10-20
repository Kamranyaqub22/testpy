# Horizon design system

Hosted with live previews: https://claude.ai/artifact/DeWpmqp8Qjy1aeFtwVnKXh (private until shared). This file is the same brand book; `tokens.json` here is the source of truth.

Horizon is a UK app bank. It should feel calm, exact and on your side: money first, no clutter, and every number explained. The identity is one idea, a **sunrise over the horizon**. Horizon Green is the ground, Horizon Sun is the light, and everything else stays quiet.

## Voice and copy

- Write to one person as "you". The bank is "we". Use sentence case everywhere, including buttons and titles.
- Lead with the money and the fact: "£42.50 sent", "£24.12 at FreshCo", "Alex Morgan owes you £18.50".
- Buttons say exactly what happens: "Send £42.50", "Create pot", "Order new card", "Erase and start again". Never "Submit", "OK" or "Confirm".
- Errors say what went wrong and how to fix it, with no apology: "Account numbers have 8 digits." "You don’t have enough money. Your balance is £1,808.98."
- Declines give the reason and what stays safe: "Your card is frozen. No money left your account."
- Use plain UK banking words: sort code, Direct Debit, standing order, pot, payee. Use the curly apostrophe (’) and the en dash in ranges (3–5 working days).
- Use no emoji in the interface. Emoji may appear only in text people write themselves (notes, references, request messages).
- Say "Demo app – not a real bank" wherever a real person might mistake it for one.

## Logo

- The mark is a `sun` half-disc on a horizon line with two shorter reflections below. The lockup sets the lowercase wordmark "horizon" beside it in Manrope 800. Files: `assets/Logos/`.
- On light grounds, the horizon lines are `brand` and the wordmark is `ink`. On `brand-deep`, use the reversed files (`*-reversed.svg`): lines in `brand-tint` and Horizon Mint, wordmark white.
- Use the lockup on onboarding, the lock screen, the card face and statements. Use the mark alone in the desktop rail, the app icon and favicons.
- Keep clear space of at least half the mark's height on all sides. Minimum sizes: mark 20px, lockup 24px high.
- The app icon is the reversed mark on a `brand-deep` squircle (`horizon-app-icon.svg`). Adaptive and maskable icons put the mark in the central 66%.
- Never recolour the sun, outline, stretch or animate the mark, put it on a photo, or capitalise the wordmark.

## Colour

Horizon is green and neutral first. The sun is a highlight, not a theme colour.

- **Grounds.** `surface` is every screen's background. `surface-raised` is panels, sheets and the tab bar. `surface-sunken` is tracks and pressed keys. Separate content by these steps, not by borders.
- **Text.** Use `ink` for primary text and amounts, `ink-muted` for secondary text, and `ink-subtle` only for overlines and placeholders. All three pass 4.5:1 on every surface in both themes.
- **Brand.** `brand` (Horizon Green) is for primary buttons, the active tab, links, switches that are on, and the focus ring. `brand-tint` is for secondary buttons, selected chips and the active-tab pill. Put `on-brand` text on `brand`.
- **Hero.** `brand-deep` is the Home hero band, the app icon and the card's dark stop. On it, use `on-hero` and `on-hero-muted` for text and `hero-chip` for pills and icon buttons.
- **Sun.** `sun` is the logo's sun, the card's sun, goal-reached moments and at most one highlight per screen. Never use it as text on light surfaces. Use `sun-tint` behind advice (scam tips, money owed to you).
- **Meaning.** `positive` is money in (always with a `+`) and completed states. `negative` is declines, errors and destructive actions. `warning` is close matches and spending near a budget. `info` is pending states. Each has a `*-tint` background for pills. Always pair them with a word or icon: green and red are never the only signal.
- **Frozen.** `frost` and `on-frost` mean only one thing: the card is frozen.
- **Categories.** Each spending category has one `cat-*` colour and one icon (see Iconography). Show the colour at 14% behind its icon, and use it in charts. Pot colours come from the same set.
- **Dark theme.** Every token has a dark value. Never invert colours by hand, and never write a hex value in a component: read the token.

## Typography

- Use one family, **Manrope** (`fonts/`, SIL Open Font License), weights 400–800. Its geometric, open shapes keep figures legible at small sizes.
- **Money:** `amount-hero` (46/52, 800) for the balance with pence at 55%, `amount-large` (36/42, 800) for amount entry and payment headers, `amount-row` (15/20, 700) at the end of list rows. Money styles always use tabular figures.
- **Headings:** `title-1` (28/34, 800) for tab screen titles, `title-2` (22/28, 800) for flow questions, sheet titles and success messages, `title-3` (17/22, 700) for section headers.
- **Text:** `body-large` for explanations under a `title-2`, `body` as the default, `body-strong` for row titles, merchant names and button labels, `caption` for subtitles, helper text and tab labels (12px variant), `overline` for day headers (uppercase, +0.9px tracking).
- Use sentence case and no italics. Bold is 700; reserve 800 for money and titles.

## Iconography

- Use one set: **Lucide**, 2px rounded strokes (`icon-stroke`), 22px by default (`size-icon`), 20px in rows, 15–16px in pills. In Flutter, use the `lucide_icons_flutter` package through the names in `HzIcons`. The SVGs are in `assets/Icons/`.
- One idea, one icon: Pay is `arrow-up-right`, Request is `arrow-down-left`, Pots is `piggy-bank`, Freeze is `snowflake`, Details is `hash`, Contactless is `nfc`.
- Categories: Groceries `shopping-basket`, Eating out `utensils`, Transport `bus`, Shopping `shopping-bag`, Entertainment `clapperboard`, Bills `receipt-text`, Holidays `plane`, Personal care `sparkles`, General `shapes`, Cash `banknote`, Income `briefcase-business`, Transfers `arrow-left-right`, Savings `piggy-bank`.
- Pot icons: `tree-palm`, `umbrella`, `laptop`, `house`, `car`, `gift`, `graduation-cap`, `heart`, `dog`, `guitar`, `baby`, `plane`.
- Colour icons with text tokens (`ink`, `ink-muted`, `brand`) or with their category colour inside an `IconTile`. Never use filled icons, emoji, or icons from Material or other sets.

## Layout and spacing

- Use the 4px-based scale: `space-1` 4, `space-2` 8, `space-3` 12, `space-4` 16, `space-5` 20, `space-6` 24, `space-8` 32, `space-10` 40.
- Phone gutter is `space-4`. Row content is inset `space-5`. Leave `space-3` between stacked panels and `space-6` above a section header.
- Content columns are capped at 720px (flows 520–560px, keypads 400px) and centered, so phones, tablets, desktop and web share one layout. From 840px, the bottom tab bar becomes a side rail.
- Touch targets are at least `size-tap` (48px). Buttons are `size-button` (54px) and full width in flows.

## Shape and elevation

- Radii: `radius-sm` 10 for small badges, `radius-md` 16 for inputs and option rows, `radius-lg` 22 for panels, `radius-xl` 28 for sheet tops and the hero's bottom corners, `radius-card` 18 for the card face, `radius-pill` for buttons, pills and chips.
- Panels are flat: no border, no shadow. Use only `shadow-raised` (banners, sheets) and `shadow-card` (the card face).

## Motion

- Keep motion short and physical: 200–320ms ease-out for sheets and banners, a 600ms ease-out-back pop for the card on "card ordered", an elastic pop for the success tick, and a shake on a wrong passcode.
- Rings and the spending donut fill from zero over about 700ms.
- Never loop animations, and never animate money while the user reads it.

## Accessibility

- Every text token pair named above passes WCAG 2 AA (4.5:1) in both themes. Icons and focus rings pass 3:1.
- Never signal state by colour alone. Pills carry a word and an icon, money in carries a `+`, and declines say "Declined".
- Give every tappable thing a label (quick actions and icon buttons carry tooltips or semantics labels). Keypads also accept a physical keyboard.

## Building with Horizon in Flutter

- Tokens live in `design/tokens.json`. Generate the Dart side with `python3 tool/gen_tokens.py` and never edit `lib/design/tokens.g.dart` by hand.
- Read colours with `context.hz.<token>` (`context.hz.brand`, `context.hz.inkMuted`), type with `HzType.<style>`, spacing with `HzSpace.s4`, radii with `HzRadius.lg`, sizes with `HzSize.button`, and icons with `HzIcons.<name>`.
- `buildHorizonTheme` maps the tokens onto Material's buttons, inputs, lists, navigation, sheets and dialogs. Use the stock widgets and let the theme style them.
- Shared components are in `lib/widgets/common.dart` and `lib/widgets/keypads.dart`. Reuse them before writing new UI.
- `test/design_system_test.dart` fails the build if a screen uses a colour literal, a Material icon or an emoji.
