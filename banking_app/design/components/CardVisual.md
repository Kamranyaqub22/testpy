# CardVisual

The debit card face: a Horizon Green gradient with the logo's sunrise, chip, number and holder name. Frozen cards are frosted over.

**Flutter:** `CardVisual(card: bank.card, holder: bank.profile.name, revealed: false)`.

**The consumer provides:** the card, the holder's name, and `revealed` (only after the passcode is entered; hide it again after 30 seconds).

- ISO ratio 1.586, `radius-card`, `shadow-card`, gradient `card-from` → `card-to`, sun in `sun`, horizon lines in white at 28%.
- When hidden, show only "•••• 2281". When revealed, show the full number, EXP and CVV.
- Frozen: overlay `frost` at 86% with the snowflake icon and "Card frozen" in `on-frost`.
- Max width 400px. Center it on wide screens and never stretch it.
