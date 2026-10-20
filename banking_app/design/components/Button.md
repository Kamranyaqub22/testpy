# Button

Pill-shaped buttons for actions: one primary per screen, secondary for the alternative, text for low-emphasis links, danger for destructive confirms.

**Flutter:** `FilledButton` (primary), `OutlinedButton` (secondary: `brand-tint` fill, no border), `TextButton` (text). All are styled by `buildHorizonTheme`; don't restyle them per screen. Danger: `FilledButton.styleFrom(backgroundColor: context.hz.negative)`.

**The consumer provides:** a label that says exactly what happens ("Send £42.50", "Create pot", "Erase and start again"), and `onPressed` (null disables it).

- Height `size-button` (54px), full width in flows, `radius-pill`, label `body-strong` at 16px.
- One primary button per screen, at the bottom of a flow. Put the secondary directly under it.
- Put the amount in payment buttons: "Send £42.50", never "Submit".
- Don't use the sun colour for buttons, and don't put icons in primary buttons except `HzIcons.add` ("New pot") or `HzIcons.share`.
