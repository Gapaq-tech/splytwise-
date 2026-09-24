import 'package:flutter/material.dart';

import 'tokens.dart';

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: SplytPalette.gold,
        secondary: SplytPalette.gold,
        tertiary: SplytPalette.gold,
        surface: SplytPalette.lightSurface,
        error: SplytPalette.coral,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: SplytPalette.lightInk,
      ),
      scaffoldBackgroundColor: SplytPalette.lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: SplytPalette.lightInk,
      ),
      cardTheme: CardTheme(
        color: SplytPalette.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SplytPalette.line),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: SplytPalette.goldSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ).copyWith(
            color: selected ? Colors.black : SplytPalette.mute,
          );
        }),
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: SplytPalette.gold,
        secondary: SplytPalette.gold,
        tertiary: SplytPalette.gold,
        surface: SplytPalette.lightSurface,
        error: SplytPalette.coral,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: SplytPalette.lightInk,
      ),
      scaffoldBackgroundColor: SplytPalette.lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: SplytPalette.lightInk,
        titleTextStyle: TextStyle(
          color: SplytPalette.lightInk,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardTheme(
        color: SplytPalette.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SplytPalette.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SplytPalette.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: const TextStyle(color: SplytPalette.mute),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SplytPalette.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SplytPalette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SplytPalette.gold, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: SplytPalette.gold,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            inherit: true,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SplytPalette.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SplytPalette.lightSurface,
        selectedColor: SplytPalette.goldSoft,
        side: const BorderSide(color: SplytPalette.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(
          color: SplytPalette.lightInk,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class MoneyText extends StatelessWidget {
  const MoneyText(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.fontSize = 32,
  });

  final String text;
  final TextStyle? style;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style ?? const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1))
          .copyWith(
        color: color ?? Theme.of(context).colorScheme.onSurface,
        fontSize: fontSize,
        fontFamilyFallback: const ['Noto Sans', 'Noto Sans Symbols'],
      ),
    );
  }
}
