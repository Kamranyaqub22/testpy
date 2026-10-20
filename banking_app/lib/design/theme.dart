import 'package:flutter/material.dart';

import 'hz.dart';

/// Builds the Material theme from Horizon tokens only. Widgets read colours
/// through `context.hz` and styles through `HzType`; this file maps the
/// same tokens onto Flutter's built-in components so they match.
ThemeData buildHorizonTheme(Brightness brightness) {
  final hz = brightness == Brightness.dark ? HzPalette.dark : HzPalette.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: hz.brand,
    onPrimary: hz.onBrand,
    primaryContainer: hz.brandTint,
    onPrimaryContainer: hz.ink,
    secondary: hz.sun,
    onSecondary: hz.onSun,
    secondaryContainer: hz.brandTint,
    onSecondaryContainer: hz.ink,
    tertiary: hz.info,
    onTertiary: hz.surfaceRaised,
    error: hz.negative,
    onError: hz.surfaceRaised,
    errorContainer: hz.negativeTint,
    onErrorContainer: hz.negative,
    surface: hz.surface,
    onSurface: hz.ink,
    onSurfaceVariant: hz.inkMuted,
    surfaceContainerLowest: hz.surfaceRaised,
    surfaceContainerLow: hz.surfaceRaised,
    surfaceContainer: hz.surfaceSunken,
    surfaceContainerHigh: hz.surfaceSunken,
    surfaceContainerHighest: hz.surfaceSunken,
    outline: hz.line,
    outlineVariant: hz.line,
    inverseSurface: hz.ink,
    onInverseSurface: hz.surface,
    shadow: Colors.black,
    surfaceTint: Colors.transparent,
  );

  TextStyle t(TextStyle s, [Color? c]) => s.copyWith(color: c ?? hz.ink);
  final text = TextTheme(
    displayLarge: t(HzType.amountHero),
    displayMedium: t(HzType.amountLarge),
    displaySmall: t(HzType.amountLarge),
    headlineLarge: t(HzType.title1),
    headlineMedium: t(HzType.title1),
    headlineSmall: t(HzType.title2),
    titleLarge: t(HzType.title2),
    titleMedium: t(HzType.title3),
    titleSmall: t(HzType.bodyStrong),
    bodyLarge: t(HzType.bodyLarge),
    bodyMedium: t(HzType.body),
    bodySmall: t(HzType.caption, hz.inkMuted),
    labelLarge: t(HzType.bodyStrong),
    labelMedium: t(HzType.caption),
    labelSmall: t(HzType.overline, hz.inkSubtle),
  );

  final buttonShape = const StadiumBorder();
  final buttonText = HzType.bodyStrong.copyWith(fontSize: 16);
  OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(HzRadius.md),
    borderSide: BorderSide(color: c, width: w),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [hz],
    fontFamily: HzType.family,
    textTheme: text,
    scaffoldBackgroundColor: hz.surface,
    canvasColor: hz.surface,
    dividerColor: hz.line,
    splashFactory: InkRipple.splashFactory,
    iconTheme: IconThemeData(color: hz.ink, size: HzSize.icon),
    appBarTheme: AppBarTheme(
      backgroundColor: hz.surface,
      foregroundColor: hz.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: t(HzType.title3),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: hz.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HzRadius.lg),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: hz.brand,
        foregroundColor: hz.onBrand,
        disabledBackgroundColor: hz.surfaceSunken,
        disabledForegroundColor: hz.inkSubtle,
        minimumSize: const Size.fromHeight(HzSize.button),
        shape: buttonShape,
        textStyle: buttonText,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: hz.brand,
        backgroundColor: hz.brandTint,
        minimumSize: const Size.fromHeight(HzSize.button),
        shape: buttonShape,
        side: BorderSide.none,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: hz.brand,
        textStyle: HzType.bodyStrong,
        minimumSize: const Size(HzSize.tap, HzSize.tap),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: hz.ink,
        minimumSize: const Size(HzSize.tap, HzSize.tap),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: hz.brand,
      foregroundColor: hz.onBrand,
      elevation: 0,
      highlightElevation: 0,
      shape: const StadiumBorder(),
      extendedTextStyle: buttonText,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: hz.surfaceRaised,
      labelStyle: HzType.body.copyWith(color: hz.inkMuted),
      floatingLabelStyle: HzType.caption.copyWith(color: hz.brand),
      hintStyle: HzType.body.copyWith(color: hz.inkSubtle),
      helperStyle: HzType.caption.copyWith(color: hz.inkMuted),
      errorStyle: HzType.caption.copyWith(color: hz.negative),
      border: field(hz.line),
      enabledBorder: field(hz.line),
      focusedBorder: field(hz.brand, 2),
      errorBorder: field(hz.negative),
      focusedErrorBorder: field(hz.negative, 2),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: HzSpace.s5,
        vertical: HzSpace.s4 + 2,
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: HzSpace.s5),
      iconColor: hz.inkMuted,
      titleTextStyle: t(HzType.bodyStrong),
      subtitleTextStyle: HzType.caption.copyWith(color: hz.inkMuted),
      minVerticalPadding: HzSpace.s3,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: hz.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      indicatorColor: hz.brandTint,
      height: 68,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => HzType.caption.copyWith(
          fontSize: 12,
          color: s.contains(WidgetState.selected) ? hz.ink : hz.inkMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: HzSize.icon,
          color: s.contains(WidgetState.selected) ? hz.brand : hz.inkMuted,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: hz.surfaceRaised,
      indicatorColor: hz.brandTint,
      selectedIconTheme: IconThemeData(color: hz.brand, size: HzSize.icon),
      unselectedIconTheme: IconThemeData(color: hz.inkMuted, size: HzSize.icon),
      selectedLabelTextStyle: HzType.caption.copyWith(color: hz.ink),
      unselectedLabelTextStyle: HzType.caption.copyWith(color: hz.inkMuted),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: hz.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: hz.surfaceRaised,
      showDragHandle: true,
      dragHandleColor: hz.line,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HzRadius.xl)),
      ),
      constraints: const BoxConstraints(maxWidth: 640),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: hz.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HzRadius.xl),
      ),
      titleTextStyle: t(HzType.title2),
      contentTextStyle: HzType.body.copyWith(color: hz.inkMuted),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? hz.onBrand : hz.inkSubtle,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? hz.brand : hz.surfaceSunken,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? hz.brand : hz.line,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? hz.brand : hz.inkMuted,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: hz.surfaceRaised,
      selectedColor: hz.brandTint,
      side: BorderSide(color: hz.line),
      shape: const StadiumBorder(),
      labelStyle: HzType.caption.copyWith(color: hz.ink),
      checkmarkColor: hz.brand,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? hz.brandTint
              : hz.surfaceRaised,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? hz.brand : hz.inkMuted,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: hz.line)),
        textStyle: WidgetStatePropertyAll(HzType.caption),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: hz.brand,
      unselectedLabelColor: hz.inkMuted,
      indicatorColor: hz.brand,
      labelStyle: HzType.bodyStrong,
      unselectedLabelStyle: HzType.body,
      dividerColor: hz.line,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: hz.brand,
      linearTrackColor: hz.surfaceSunken,
      circularTrackColor: hz.surfaceSunken,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: hz.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      textStyle: HzType.body.copyWith(color: hz.ink),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HzRadius.md),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: hz.ink,
      contentTextStyle: HzType.body.copyWith(color: hz.surface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HzRadius.md),
      ),
    ),
    dividerTheme: DividerThemeData(color: hz.line, space: 1, thickness: 1),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: hz.surfaceRaised,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
