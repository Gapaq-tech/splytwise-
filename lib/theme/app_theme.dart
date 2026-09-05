import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: SplytPalette.mint,
        secondary: SplytPalette.coral,
        tertiary: SplytPalette.gold,
        surface: SplytPalette.ink,
        error: SplytPalette.coral,
        onPrimary: SplytPalette.deep,
        onSecondary: SplytPalette.cream,
        onSurface: SplytPalette.cream,
      ),
    );
    return _withFonts(base).copyWith(
      scaffoldBackgroundColor: SplytPalette.deep,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: SplytPalette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: SplytPalette.ink,
        indicatorColor: SplytPalette.mint.withOpacity(0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? SplytPalette.mint : SplytPalette.mute,
          );
        }),
      ),
    );
  }

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: SplytPalette.mintDeep,
        secondary: SplytPalette.coral,
        tertiary: SplytPalette.gold,
        surface: SplytPalette.lightSurface,
        error: SplytPalette.coral,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: SplytPalette.lightInk,
      ),
    );
    return _withFonts(base).copyWith(
      scaffoldBackgroundColor: SplytPalette.lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: SplytPalette.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  static ThemeData _withFonts(ThemeData base) {
    final body = GoogleFonts.outfitTextTheme(base.textTheme);
    final numbers = GoogleFonts.soraTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: body.copyWith(
        displayLarge: numbers.displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.4),
        displayMedium: numbers.displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.2),
        headlineLarge: numbers.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
        headlineMedium: numbers.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: body.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
      style: (style ?? GoogleFonts.sora(fontWeight: FontWeight.w800, letterSpacing: -1)).copyWith(
        color: color ?? Theme.of(context).colorScheme.onSurface,
        fontSize: fontSize,
      ),
    );
  }
}
