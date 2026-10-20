# Banner

An in-app notification that slides down from the top, like a push notification, for things that just happened.

**Flutter:** `showBanner(context, title: '£24.12 at FreshCo', body: '88p rounded up to your pot', icon: HzIcons.category(tx.category), tone: BannerTone.info)`. Tones: `info`, `positive`, `negative`, `celebrate`.

**The consumer provides:** a title that leads with the money or the event, a one-line body, an icon and a tone.

- `surface-raised` with `shadow-raised` and `radius-lg`. It dismisses after 4 seconds or on tap.
- Use it for card payments, money received, declines and goals reached. For confirming the user's own action ("PIN updated") use a snackbar instead.
