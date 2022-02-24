import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';

class AppTheme {
  // use themeDataFromColors to change theme data
  static final darkTheme = _themeDataFromColors(
    // for selected/clickable things
    primary: const Color(0xffa8d8ff),
    // only for small accents
    secondary: const Color(0xffba2f2f),
    brightness: Brightness.dark,
  );

  static final lightTheme = _themeDataFromColors(
    primary: const Color(0xff1f67a3), // for selected things
    secondary:
        const Color(0xffffa896), // for important things that you can click
    brightness: Brightness.light,
  );
}

ThemeData _themeDataFromColors({
  required Color primary,
  required Color secondary,
  required Brightness brightness,
}) {
  final cs = brightness == Brightness.dark
      ? ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          brightness: brightness,
        )
      : ColorScheme.light(
          primary: primary,
          secondary: secondary,
          brightness: brightness,
        );
  final appBarBackgroundColor =
      brightness == Brightness.light ? cs.primary : cs.surface;
  return ThemeData(
    appBarTheme: AppBarTheme(
        foregroundColor:
            brightness == Brightness.light ? cs.onPrimary : cs.onSurface,
        backgroundColor: appBarBackgroundColor),
    bottomAppBarTheme: BottomAppBarTheme(color: appBarBackgroundColor),
    bottomAppBarColor: appBarBackgroundColor,
    colorScheme: cs,
    primaryColor: cs.primary,
    primarySwatch: _generateMaterialColor(cs.primary),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: cs.primary,
    ),
    toggleableActiveColor: cs.primary,
    // ignore: deprecated_member_use
    accentColor: cs.primary, // still needed for expansion tile cards
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: Defaults.borderRadius.big,
      ),
    ),
    textTheme: const TextTheme(
      caption: TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 15,
      ),
      subtitle1: TextStyle(
        fontSize: 20,
      ),
    ),
  );
}

Color primaryColorOf(BuildContext context) {
  return Theme.of(context).colorScheme.primary;
}

Color primaryVariantOf(BuildContext context) {
  return _shadeColor(Theme.of(context).colorScheme.primary, 0.4);
}

Color onPrimaryColorOf(BuildContext context) {
  return Theme.of(context).colorScheme.onPrimary;
}

Color secondaryColorOf(BuildContext context) {
  return Theme.of(context).colorScheme.secondary;
}

Color secondaryVariantOf(BuildContext context) {
  return _shadeColor(Theme.of(context).colorScheme.secondary, 0.4);
}

Color onSecondaryColorOf(BuildContext context) {
  return Theme.of(context).colorScheme.onSecondary;
}

Color surfaceColorOf(BuildContext context) {
  return Theme.of(context).colorScheme.surface;
}

Color onSurfaceColorOf(BuildContext context) {
  return Theme.of(context).colorScheme.onSurface;
}

Color backgroundColorOf(BuildContext context) {
  return Theme.of(context).colorScheme.background;
}

Color onBackgroundColorOf(BuildContext context) {
  return Theme.of(context).colorScheme.onBackground;
}

Color disabledColorOf(BuildContext context) {
  return Theme.of(context).disabledColor;
}

MaterialColor _generateMaterialColor(Color color) {
  return MaterialColor(color.value, {
    50: _tintColor(color, 0.9),
    100: _tintColor(color, 0.8),
    200: _tintColor(color, 0.6),
    300: _tintColor(color, 0.4),
    400: _tintColor(color, 0.2),
    500: color,
    600: _shadeColor(color, 0.1),
    700: _shadeColor(color, 0.2),
    800: _shadeColor(color, 0.3),
    900: _shadeColor(color, 0.4),
  });
}

int _tintValue(int value, double factor) =>
    max(0, min((value + ((255 - value) * factor)).round(), 255));

Color _tintColor(Color color, double factor) => Color.fromRGBO(
    _tintValue(color.red, factor),
    _tintValue(color.green, factor),
    _tintValue(color.blue, factor),
    1);

int _shadeValue(int value, double factor) =>
    max(0, min(value - (value * factor).round(), 255));

Color _shadeColor(Color color, double factor) => Color.fromRGBO(
    _shadeValue(color.red, factor),
    _shadeValue(color.green, factor),
    _shadeValue(color.blue, factor),
    1);
