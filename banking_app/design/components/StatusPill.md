# StatusPill

A small pill that names a state in words, with an icon, so state is never shown by colour alone.

**Flutter:** `StatusPill('Pending', tone: StatusTone.pending, icon: HzIcons.clock)`. Tones: `positive`, `pending`, `negative`, `warning`, `neutral`.

**The consumer provides:** the word (Completed, Pending, Declined, Disputed, Paid, Cancelled), the tone and an icon.

- Each tone is a `*-tint` fill with its matching text token: `positive-tint`/`positive`, `info-tint`/`info`, `negative-tint`/`negative`, `sun-tint`/`warning`, `surface-sunken`/`ink-muted`.
- Use one word. Put explanations in the body text beside the pill, not in it.
