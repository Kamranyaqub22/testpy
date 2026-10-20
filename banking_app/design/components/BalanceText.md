# BalanceText

The big balance figure: pounds at full size, pence at 55%, tabular figures, with the brand-deep hero band around it on Home.

**Flutter:** `BalanceText(cents, hidden: bank.hideBalance, color: context.hz.onHero)`. The hero band is `_Hero` in `home_screen.dart`: `brand-deep` fill, `radius-xl` bottom corners, the logo's sunrise drawn small and low on the right.

**The consumer provides:** the amount in pence, and whether balances are hidden (then it shows "£ ••••").

- Style `amount-hero`. On the hero, put the label above it in `on-hero-muted` and the amount in `on-hero`.
- Put summary pills under it (`hero-chip` fill, 15px icon + `caption`). A frozen card adds a `frost` pill.
- Respect `hideBalance` everywhere money appears in a summary (pots, spent today).
