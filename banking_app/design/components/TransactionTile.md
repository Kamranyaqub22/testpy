# TransactionTile

One payment in a list: category tile, merchant name, status or category, amount, and a round-up hint.

**Flutter:** `TransactionTile(transaction: t, onTap: …, roundUpCents: …)`. Lists use `TransactionFeed`, which groups payments by day ("TODAY", "YESTERDAY", "SATURDAY 17 OCTOBER") with each day's spending total, one `Panel` per day.

**The consumer provides:** a `BankTransaction`, a tap handler, and optionally the round-up for that payment.

- Title `body-strong` in `ink`, subtitle `caption` in `ink-muted`. Pending subtitles use `info`, declined ones `negative` and read "Declined · reason".
- Money in: `positive` with a `+` sign. Money out: `ink`, no minus sign. Declined: `ink-subtle`, struck through, and the tile turns grey with a block badge.
- Hide round-up rows from the main feed. Show the round-up as a 12px coin icon and "88p" under the amount instead.
