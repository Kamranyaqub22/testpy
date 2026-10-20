# QuickAction

Round icon button with a label underneath, used for the row of shortcuts on Home and Card.

**Flutter:** `QuickAction(icon: HzIcons.pay, label: 'Pay', onTap: …, highlighted: false)` from `widgets/common.dart`.

**The consumer provides:** a Horizon icon, a one-word label, `onTap`, and `highlighted` for an "on" state.

- Disc `size-quick-action` (52px) on `surface-raised`, icon in `brand`, label `caption` in `ink`.
- `highlighted` switches the disc to `frost` with `on-frost`. Use it only for a toggle that is currently on (Freeze → "Unfreeze").
- Use 3–5 in a row, spread evenly (wrap each in `Expanded`). Never scroll quick actions sideways.
