// GENERATED from design/tokens.json by tool/gen_tokens.py. Do not edit.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';

/// Horizon colour and shadow tokens for one theme. Read it with
/// `context.hz` (see hz.dart); never hard-code a colour in a widget.
class HzPalette extends ThemeExtension<HzPalette> {
  const HzPalette({
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.line,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.brand,
    required this.brandPressed,
    required this.brandDeep,
    required this.brandTint,
    required this.onBrand,
    required this.onHero,
    required this.onHeroMuted,
    required this.heroChip,
    required this.sun,
    required this.sunTint,
    required this.onSun,
    required this.positive,
    required this.positiveTint,
    required this.negative,
    required this.negativeTint,
    required this.warning,
    required this.info,
    required this.infoTint,
    required this.frost,
    required this.onFrost,
    required this.cardFrom,
    required this.cardTo,
    required this.cardChipFrom,
    required this.cardChipTo,
    required this.catGroceries,
    required this.catEatingOut,
    required this.catTransport,
    required this.catShopping,
    required this.catEntertainment,
    required this.catBills,
    required this.catHolidays,
    required this.catPersonalCare,
    required this.catGeneral,
    required this.catCash,
    required this.catIncome,
    required this.catTransfers,
    required this.catSavings,
    required this.shadowRaised,
    required this.shadowCard,
  });

  /// App background behind every screen and the tab bar's surroundings.
  final Color surface;

  /// Panels, list groups, sheets, the tab bar and quick-action discs.
  final Color surfaceRaised;

  /// Progress tracks, keypad press state, input fills inside panels.
  final Color surfaceSunken;

  /// Dividers inside panels and input borders. Never as a card outline.
  final Color line;

  /// Primary text and amounts on surface, surface-raised and surface-sunken.
  final Color ink;

  /// Secondary text: subtitles, dates, helper text, inactive tab labels, on every surface.
  final Color inkMuted;

  /// Overlines, day headers and placeholder text on every surface (passes 4.5:1, use sparingly).
  final Color inkSubtle;

  /// Horizon Green. Primary buttons, active tab, links, toggles on, focus ring. Text on surface and surface-raised.
  final Color brand;

  /// Pressed state of brand fills.
  final Color brandPressed;

  /// The home hero band, the app icon tile and the card face's dark stop.
  final Color brandDeep;

  /// Selected chips, the active tab pill, secondary button fill, success banners.
  final Color brandTint;

  /// Text and icons on brand and brand-pressed fills.
  final Color onBrand;

  /// Balance and titles on brand-deep.
  final Color onHero;

  /// Labels and secondary text on brand-deep.
  final Color onHeroMuted;

  /// Pills and icon buttons sitting on brand-deep.
  final Color heroChip;

  /// Horizon Sun. The logo's sun, the card's sun, goal-reached moments and one highlight per screen at most. Never text on light surfaces.
  final Color sun;

  /// Background for warnings that are advice, not errors (scam tips, pending requests).
  final Color sunTint;

  /// Text on sun fills.
  final Color onSun;

  /// Money in amounts (always with a + sign), completed status. Text on surface and surface-raised.
  final Color positive;

  /// Completed status pill background.
  final Color positiveTint;

  /// Declines, errors, destructive actions. Always paired with an icon or word, never colour alone.
  final Color negative;

  /// Declined pill and error banner background.
  final Color negativeTint;

  /// Close-match and over-budget states; text on sun-tint and surface-raised.
  final Color warning;

  /// Pending status and neutral notices. Text on surface-raised.
  final Color info;

  /// Pending pill background.
  final Color infoTint;

  /// Frozen-card overlay and the Freeze quick action when on.
  final Color frost;

  /// Text and icons on frost.
  final Color onFrost;

  /// Debit card face, gradient start (top left).
  final Color cardFrom;

  /// Debit card face, gradient end (bottom right).
  final Color cardTo;

  /// Card chip gradient start.
  final Color cardChipFrom;

  /// Card chip gradient end.
  final Color cardChipTo;

  /// Groceries category icon; its tile is this colour at 14%.
  final Color catGroceries;

  /// Eating out category.
  final Color catEatingOut;

  /// Transport category.
  final Color catTransport;

  /// Shopping category.
  final Color catShopping;

  /// Entertainment category.
  final Color catEntertainment;

  /// Bills category.
  final Color catBills;

  /// Holidays category.
  final Color catHolidays;

  /// Personal care category.
  final Color catPersonalCare;

  /// General category.
  final Color catGeneral;

  /// Cash category.
  final Color catCash;

  /// Income category.
  final Color catIncome;

  /// Transfers category.
  final Color catTransfers;

  /// Savings and pot movements.
  final Color catSavings;

  /// Notification banners and sheets only. Panels stay flat.
  final List<BoxShadow> shadowRaised;

  /// The debit card face.
  final List<BoxShadow> shadowCard;

  static const light = HzPalette(
    surface: Color(0xFFF4F6F5),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFE8EDEB),
    line: Color(0xFFDDE3E0),
    ink: Color(0xFF0D1A16),
    inkMuted: Color(0xFF4F5E59),
    inkSubtle: Color(0xFF5D6C67),
    brand: Color(0xFF0B6B4F),
    brandPressed: Color(0xFF08573F),
    brandDeep: Color(0xFF063A2C),
    brandTint: Color(0xFFDCEFE7),
    onBrand: Color(0xFFFFFFFF),
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFFB9D2C8),
    heroChip: Color(0xFF11503E),
    sun: Color(0xFFFFB13B),
    sunTint: Color(0xFFFFF0D6),
    onSun: Color(0xFF2A1A00),
    positive: Color(0xFF0A7448),
    positiveTint: Color(0xFFDCF2E7),
    negative: Color(0xFFC2352B),
    negativeTint: Color(0xFFFCE8E6),
    warning: Color(0xFF995700),
    info: Color(0xFF2556C4),
    infoTint: Color(0xFFE2EAFB),
    frost: Color(0xFFD7ECF7),
    onFrost: Color(0xFF0D2A3A),
    cardFrom: Color(0xFF0B6B4F),
    cardTo: Color(0xFF063A2C),
    cardChipFrom: Color(0xFFEBDDB4),
    cardChipTo: Color(0xFFC7A75A),
    catGroceries: Color(0xFF1F9D63),
    catEatingOut: Color(0xFFD9701A),
    catTransport: Color(0xFF2F6FD6),
    catShopping: Color(0xFF9A4FD0),
    catEntertainment: Color(0xFFD6456B),
    catBills: Color(0xFF4A5BD4),
    catHolidays: Color(0xFF0F8F9C),
    catPersonalCare: Color(0xFFC45AA0),
    catGeneral: Color(0xFF5D6C67),
    catCash: Color(0xFF5D8F2F),
    catIncome: Color(0xFF0A7448),
    catTransfers: Color(0xFF4F5E59),
    catSavings: Color(0xFFB67A00),
    shadowRaised: [
      BoxShadow(color: Color(0x1A063A2C), offset: Offset(0, 8), blurRadius: 24),
    ],
    shadowCard: [
      BoxShadow(
        color: Color(0x47063A2C),
        offset: Offset(0, 16),
        blurRadius: 32,
      ),
    ],
  );

  static const dark = HzPalette(
    surface: Color(0xFF0A110F),
    surfaceRaised: Color(0xFF121B18),
    surfaceSunken: Color(0xFF1B2622),
    line: Color(0xFF25332E),
    ink: Color(0xFFE8F0ED),
    inkMuted: Color(0xFFA3B3AD),
    inkSubtle: Color(0xFF8A9A94),
    brand: Color(0xFF3CCF9B),
    brandPressed: Color(0xFF2FB585),
    brandDeep: Color(0xFF062B21),
    brandTint: Color(0xFF123A2E),
    onBrand: Color(0xFF03261B),
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFFA9C2B8),
    heroChip: Color(0xFF0D3D30),
    sun: Color(0xFFFFC063),
    sunTint: Color(0xFF3A2A0C),
    onSun: Color(0xFF2A1A00),
    positive: Color(0xFF4CD69D),
    positiveTint: Color(0xFF123528),
    negative: Color(0xFFFF7D72),
    negativeTint: Color(0xFF3B1714),
    warning: Color(0xFFF0B04D),
    info: Color(0xFF86A9FF),
    infoTint: Color(0xFF16233F),
    frost: Color(0xFF1C3442),
    onFrost: Color(0xFFD7ECF7),
    cardFrom: Color(0xFF0B6B4F),
    cardTo: Color(0xFF04271D),
    cardChipFrom: Color(0xFFEBDDB4),
    cardChipTo: Color(0xFFC7A75A),
    catGroceries: Color(0xFF43C98A),
    catEatingOut: Color(0xFFF39A52),
    catTransport: Color(0xFF79A6F2),
    catShopping: Color(0xFFC493EC),
    catEntertainment: Color(0xFFF1849F),
    catBills: Color(0xFF8E9BF0),
    catHolidays: Color(0xFF4FC8D3),
    catPersonalCare: Color(0xFFE89ACB),
    catGeneral: Color(0xFFA3B3AD),
    catCash: Color(0xFF9CCC6A),
    catIncome: Color(0xFF4CD69D),
    catTransfers: Color(0xFFA3B3AD),
    catSavings: Color(0xFFFFC063),
    shadowRaised: [
      BoxShadow(color: Color(0x73000000), offset: Offset(0, 8), blurRadius: 24),
    ],
    shadowCard: [
      BoxShadow(
        color: Color(0x8C000000),
        offset: Offset(0, 16),
        blurRadius: 32,
      ),
    ],
  );

  @override
  HzPalette copyWith() => this;

  @override
  HzPalette lerp(HzPalette? other, double t) {
    if (other == null) return this;
    return HzPalette(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkSubtle: Color.lerp(inkSubtle, other.inkSubtle, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandPressed: Color.lerp(brandPressed, other.brandPressed, t)!,
      brandDeep: Color.lerp(brandDeep, other.brandDeep, t)!,
      brandTint: Color.lerp(brandTint, other.brandTint, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      onHeroMuted: Color.lerp(onHeroMuted, other.onHeroMuted, t)!,
      heroChip: Color.lerp(heroChip, other.heroChip, t)!,
      sun: Color.lerp(sun, other.sun, t)!,
      sunTint: Color.lerp(sunTint, other.sunTint, t)!,
      onSun: Color.lerp(onSun, other.onSun, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      positiveTint: Color.lerp(positiveTint, other.positiveTint, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      negativeTint: Color.lerp(negativeTint, other.negativeTint, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoTint: Color.lerp(infoTint, other.infoTint, t)!,
      frost: Color.lerp(frost, other.frost, t)!,
      onFrost: Color.lerp(onFrost, other.onFrost, t)!,
      cardFrom: Color.lerp(cardFrom, other.cardFrom, t)!,
      cardTo: Color.lerp(cardTo, other.cardTo, t)!,
      cardChipFrom: Color.lerp(cardChipFrom, other.cardChipFrom, t)!,
      cardChipTo: Color.lerp(cardChipTo, other.cardChipTo, t)!,
      catGroceries: Color.lerp(catGroceries, other.catGroceries, t)!,
      catEatingOut: Color.lerp(catEatingOut, other.catEatingOut, t)!,
      catTransport: Color.lerp(catTransport, other.catTransport, t)!,
      catShopping: Color.lerp(catShopping, other.catShopping, t)!,
      catEntertainment: Color.lerp(
        catEntertainment,
        other.catEntertainment,
        t,
      )!,
      catBills: Color.lerp(catBills, other.catBills, t)!,
      catHolidays: Color.lerp(catHolidays, other.catHolidays, t)!,
      catPersonalCare: Color.lerp(catPersonalCare, other.catPersonalCare, t)!,
      catGeneral: Color.lerp(catGeneral, other.catGeneral, t)!,
      catCash: Color.lerp(catCash, other.catCash, t)!,
      catIncome: Color.lerp(catIncome, other.catIncome, t)!,
      catTransfers: Color.lerp(catTransfers, other.catTransfers, t)!,
      catSavings: Color.lerp(catSavings, other.catSavings, t)!,
      shadowRaised: t < .5 ? shadowRaised : other.shadowRaised,
      shadowCard: t < .5 ? shadowCard : other.shadowCard,
    );
  }
}

/// Spacing scale (logical pixels).
abstract final class HzSpace {
  /// Icon-to-label gaps inside pills.
  static const double s1 = 4;

  /// Between chips; between a title and its subtitle.
  static const double s2 = 8;

  /// Between stacked panels; inside compact pills.
  static const double s3 = 12;

  /// Screen side gutter on phones; panel inner padding.
  static const double s4 = 16;

  /// List row horizontal padding; section header indent.
  static const double s5 = 20;

  /// Space above a section header; flow screen padding.
  static const double s6 = 24;

  /// Between a hero and the content below it.
  static const double s8 = 32;

  /// Top padding on success and empty states.
  static const double s10 = 40;
}

/// Corner radii (logical pixels).
abstract final class HzRadius {
  /// Merchant avatar tiles at 40px, small badges.
  static const double sm = 10;

  /// Inputs, option rows, pot chips.
  static const double md = 16;

  /// Panels and list groups.
  static const double lg = 22;

  /// Bottom sheets (top corners) and the home hero's bottom corners.
  static const double xl = 28;

  /// The debit card face (ISO ratio 1.586).
  static const double card = 18;

  /// Buttons, status pills, chips, tab indicator.
  static const double pill = 999;
}

/// Component sizes (logical pixels).
abstract final class HzSize {
  /// Minimum touch target for anything tappable.
  static const double tap = 48;

  /// Height of primary and secondary buttons.
  static const double button = 54;

  /// Merchant and person avatars in list rows.
  static const double avatar = 44;

  /// Quick-action discs on Home and Card.
  static const double quickAction = 52;

  /// Default icon size; 20px in rows, 26px in quick actions.
  static const double icon = 22;

  /// Lucide stroke width at every size.
  static const double iconStroke = 2;
}

/// Type styles. Colour comes from the theme; apply with `.copyWith(color:)`.
abstract final class HzType {
  static const family = 'Manrope';

  /// The balance on Home. Pence drop to 55% size. Tabular figures.
  static const amountHero = TextStyle(
    fontFamily: family,
    fontSize: 46,
    height: 1.13,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Amount keypad, transaction and payment-review headers.
  static const amountLarge = TextStyle(
    fontFamily: family,
    fontSize: 36,
    height: 1.167,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Amounts at the end of list rows. Tabular figures.
  static const amountRow = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 1.333,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Tab screen titles.
  static const title1 = TextStyle(
    fontFamily: family,
    fontSize: 28,
    height: 1.214,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  /// Flow step questions, sheet titles, success messages.
  static const title2 = TextStyle(
    fontFamily: family,
    fontSize: 22,
    height: 1.273,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
  );

  /// Section headers inside a screen.
  static const title3 = TextStyle(
    fontFamily: family,
    fontSize: 17,
    height: 1.294,
    fontWeight: FontWeight.w700,
  );

  /// Explanations under a title-2.
  static const bodyLarge = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );

  /// Default text.
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 1.467,
    fontWeight: FontWeight.w500,
  );

  /// Row titles, button labels, merchant names.
  static const bodyStrong = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 1.467,
    fontWeight: FontWeight.w700,
  );

  /// Row subtitles, helper text, tab labels (12px variant).
  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 13,
    height: 1.385,
    fontWeight: FontWeight.w600,
  );

  /// Day headers in the feed; always uppercase.
  static const overline = TextStyle(
    fontFamily: family,
    fontSize: 11,
    height: 1.273,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.9,
  );
}
