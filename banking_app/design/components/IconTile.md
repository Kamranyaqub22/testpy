# IconTile

An icon on a rounded tile tinted with the same colour at 14%: the building block for merchant avatars, pots, notices and banners.

**Flutter:** `IconTile(icon: HzIcons.category(c), color: context.hz.category(c), size: 44)`, `circle: true` for notices. `MerchantAvatar(category:, declined:)` wraps it for payments.

**The consumer provides:** an `HzIcons` icon and a token colour (a `cat-*` token, `brand`, `negative`…).

- Tile corner radius is 32% of its size (14px at 44px). Icon is 48% of the tile, 2px stroke.
- Every category has exactly one icon and one colour (see Iconography). Never mix them, for example a groceries icon in the transport colour.
- Merchants have no logos in Horizon. Always use the category tile, never a guessed logo or an emoji.
