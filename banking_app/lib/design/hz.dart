import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/category.dart';
import 'tokens.g.dart';

export 'tokens.g.dart';

/// Shorthand for the current theme's Horizon palette: `context.hz.brand`.
extension HzContext on BuildContext {
  HzPalette get hz => Theme.of(this).extension<HzPalette>()!;
}

/// The one icon set Horizon uses: Lucide, 2px rounded strokes. Use these
/// names instead of picking icons ad hoc, so the same idea always has the
/// same icon.
abstract final class HzIcons {
  // Navigation
  static const home = LucideIcons.house;
  static const insights = LucideIcons.chartPie;
  static const payments = LucideIcons.arrowLeftRight;
  static const pots = LucideIcons.piggyBank;
  static const card = LucideIcons.creditCard;

  // Actions
  static const pay = LucideIcons.arrowUpRight;
  static const request = LucideIcons.arrowDownLeft;
  static const details = LucideIcons.hash;
  static const freeze = LucideIcons.snowflake;
  static const search = LucideIcons.search;
  static const show = LucideIcons.eye;
  static const hide = LucideIcons.eyeOff;
  static const add = LucideIcons.plus;
  static const remove = LucideIcons.minus;
  static const copy = LucideIcons.copy;
  static const share = LucideIcons.share2;
  static const edit = LucideIcons.pencil;
  static const note = LucideIcons.notebookPen;
  static const split = LucideIcons.split;
  static const repeat = LucideIcons.repeat;
  static const calendar = LucideIcons.calendar;
  static const send = LucideIcons.send;
  static const more = LucideIcons.ellipsisVertical;
  static const close = LucideIcons.x;
  static const back = LucideIcons.arrowLeft;
  static const chevron = LucideIcons.chevronRight;
  static const chevronLeft = LucideIcons.chevronLeft;
  static const delete = LucideIcons.trash2;
  static const tune = LucideIcons.slidersHorizontal;
  static const lock = LucideIcons.lockKeyhole;
  static const pin = LucideIcons.keyRound;
  static const backspace = LucideIcons.delete;

  // People & things
  static const person = LucideIcons.userRound;
  static const addPerson = LucideIcons.userPlus;
  static const bank = LucideIcons.landmark;
  static const statement = LucideIcons.fileText;
  static const bell = LucideIcons.bell;
  static const mail = LucideIcons.mail;
  static const history = LucideIcons.history;
  static const help = LucideIcons.headset;
  static const palette = LucideIcons.palette;
  static const coins = LucideIcons.coins;
  static const parcel = LucideIcons.package;

  // Card controls
  static const contactless = LucideIcons.nfc;
  static const online = LucideIcons.globe;
  static const atm = LucideIcons.banknote;
  static const abroad = LucideIcons.plane;
  static const gambling = LucideIcons.dices;
  static const report = LucideIcons.shieldAlert;

  // Status
  static const success = LucideIcons.check;
  static const verified = LucideIcons.badgeCheck;
  static const warning = LucideIcons.triangleAlert;
  static const info = LucideIcons.info;
  static const question = LucideIcons.circleHelp;
  static const declined = LucideIcons.ban;
  static const shield = LucideIcons.shieldCheck;
  static const sparkle = LucideIcons.sparkles;
  static const trendUp = LucideIcons.trendingUp;
  static const trendDown = LucideIcons.trendingDown;
  static const clock = LucideIcons.clock;

  static IconData category(TxCategory c) => switch (c) {
    TxCategory.groceries => LucideIcons.shoppingBasket,
    TxCategory.eatingOut => LucideIcons.utensils,
    TxCategory.transport => LucideIcons.bus,
    TxCategory.shopping => LucideIcons.shoppingBag,
    TxCategory.entertainment => LucideIcons.clapperboard,
    TxCategory.bills => LucideIcons.receiptText,
    TxCategory.holidays => LucideIcons.plane,
    TxCategory.personalCare => LucideIcons.sparkles,
    TxCategory.general => LucideIcons.shapes,
    TxCategory.cash => LucideIcons.banknote,
    TxCategory.income => LucideIcons.briefcaseBusiness,
    TxCategory.transfers => LucideIcons.arrowLeftRight,
    TxCategory.savings => LucideIcons.piggyBank,
  };

  /// Icons a person can pick for a pot, keyed by the name stored on the pot.
  static const potIcons = <String, IconData>{
    'palm': LucideIcons.treePalm,
    'umbrella': LucideIcons.umbrella,
    'laptop': LucideIcons.laptop,
    'home': LucideIcons.house,
    'car': LucideIcons.car,
    'gift': LucideIcons.gift,
    'study': LucideIcons.graduationCap,
    'heart': LucideIcons.heart,
    'pet': LucideIcons.dog,
    'music': LucideIcons.guitar,
    'baby': LucideIcons.baby,
    'plane': LucideIcons.plane,
  };

  static IconData pot(String key) => potIcons[key] ?? LucideIcons.piggyBank;
}

/// Category colours come from the `cat-*` tokens.
extension HzCategoryColor on HzPalette {
  Color category(TxCategory c) => switch (c) {
    TxCategory.groceries => catGroceries,
    TxCategory.eatingOut => catEatingOut,
    TxCategory.transport => catTransport,
    TxCategory.shopping => catShopping,
    TxCategory.entertainment => catEntertainment,
    TxCategory.bills => catBills,
    TxCategory.holidays => catHolidays,
    TxCategory.personalCare => catPersonalCare,
    TxCategory.general => catGeneral,
    TxCategory.cash => catCash,
    TxCategory.income => catIncome,
    TxCategory.transfers => catTransfers,
    TxCategory.savings => catSavings,
  };

  /// The pot colours a person can choose from (all from the category set, so
  /// they stay in the brand's range).
  List<Color> get potColors => [
    catHolidays,
    catBills,
    catShopping,
    catEatingOut,
    catGroceries,
    catPersonalCare,
  ];
}

/// The Horizon mark: a sun rising over the horizon, with two reflections.
/// Drawn from the same geometry as design/assets/Logos/horizon-mark.svg.
class HorizonMark extends StatelessWidget {
  const HorizonMark({super.key, this.size = 32, this.reversed = false});

  final double size;

  /// Use on brand-deep or other dark grounds.
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    return CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(
        sun: HzPalette.light.sun,
        line: reversed ? HzPalette.light.brandTint : hz.brand,
        reflection: reversed ? HzPalette.dark.brand : hz.brand,
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({
    required this.sun,
    required this.line,
    required this.reflection,
  });

  final Color sun;
  final Color line;
  final Color reflection;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 96;
    canvas.scale(s);
    canvas.drawArc(
      const Rect.fromLTWH(22, 30, 52, 52),
      3.14159,
      3.14159,
      true,
      Paint()..color = sun,
    );
    RRect bar(double x, double y, double w, double h) =>
        RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(h / 2));
    canvas.drawRRect(bar(12, 62, 72, 7), Paint()..color = line);
    final r = Paint()..color = reflection;
    canvas.drawRRect(bar(26, 74, 44, 6), r);
    canvas.drawRRect(bar(38, 85, 20, 5), r);
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.sun != sun || old.line != line || old.reflection != reflection;
}

/// Mark + "horizon" wordmark, set in Manrope ExtraBold.
class HorizonLogo extends StatelessWidget {
  const HorizonLogo({super.key, this.height = 32, this.reversed = false});

  final double height;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final color = reversed ? HzPalette.light.onHero : context.hz.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HorizonMark(size: height, reversed: reversed),
        SizedBox(width: height * .1),
        Text(
          'horizon',
          style: TextStyle(
            fontFamily: HzType.family,
            fontWeight: FontWeight.w800,
            fontSize: height * .66,
            letterSpacing: -height * .02,
            height: 1,
            color: color,
          ),
        ),
      ],
    );
  }
}
