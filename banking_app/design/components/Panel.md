# Panel

The flat raised surface that groups related rows, with a section header above it.

**Flutter:** `Panel(child: …)` (`surface-raised`, `radius-lg`, 16px side margin, no border, no shadow), `SectionHeader('Coming up', action: TextButton(…))` (`title-3`), and `RowDivider()` between rows inside a panel (inset to the text column).

**The consumer provides:** the rows (usually `ListTile`s, which the theme styles: `body-strong` titles, `caption` subtitles, `ink-muted` icons).

- Panels separate content by contrast with `surface`, never with borders or shadows.
- Leave 12px between stacked panels and 24px above a section header.
- Don't nest panels inside panels.
