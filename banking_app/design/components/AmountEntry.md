# AmountEntry

Big amount display with an on-screen number pad, for payments, requests and pot moves.

**Flutter:** `AmountEntry(onChanged: (cents, raw) {…}, helper: 'Balance £1,808.98', errorText: …)` from `widgets/keypads.dart`. A physical keyboard works too.

**The consumer provides:** `onChanged`, the helper line (the balance or limit), and an error message when the amount can't be sent.

- Display style `amount-large`, `ink-subtle` while empty ("£0"). Error text in `negative` replaces the helper.
- At most 2 decimal places and 7 digits. Amounts are parsed as pence, never as doubles.
- Put the primary button ("Next") directly under the pad, disabled until the amount is valid.
