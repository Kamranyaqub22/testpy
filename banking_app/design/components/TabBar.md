# TabBar

The five-tab app navigation: a bottom bar on phones, a side rail from 840px wide.

**Flutter:** `HomeShell` uses `NavigationBar` and `NavigationRail`, both styled by the theme. Tabs: Home (`HzIcons.home`), Insights (`insights`), Payments (`payments`), Pots (`pots`), Card (`card`). The rail's top shows the logo mark.

**The consumer provides:** nothing. Switch tabs from anywhere with `HomeShell.of(context)?.goTo(ShellTab.card)`.

- Active tab: icon in `brand` on a `brand-tint` pill, label in `ink`. Inactive tabs: `ink-muted`.
- Always show labels. Keep exactly these five tabs; anything else goes under Profile.
