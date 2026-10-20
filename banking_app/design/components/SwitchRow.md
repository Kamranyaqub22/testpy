# SwitchRow

A row with an icon, a title, a one-line explanation and a switch, for card controls and preferences.

**Flutter:** `SwitchListTile(secondary: Icon(HzIcons.contactless), title: Text('Contactless'), subtitle: Text('Tap to pay in shops'), value:, onChanged:)` inside a `Panel`.

**The consumer provides:** the control's name, what it affects in plain words, its value and `onChanged`.

- On: `brand` track with an `on-brand` thumb. Off: `surface-sunken` track with a `line` outline.
- Switches act immediately; never add a Save button under them.
