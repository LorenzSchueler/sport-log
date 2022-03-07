import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';

class AppTheme {
  static final darkTheme = _themeDataFromColors(
    const ColorScheme.dark(
      primary: Color(0xffa8d8ff), // for selected/clickable things
      secondary: Color(0xffba2f2f), // only for small accents
      background: Color.fromRGBO(15, 15, 15, 1),
      surface: Color.fromRGBO(30, 30, 30, 1),
      brightness: Brightness.dark,
    ),
  );

  static final lightTheme = _themeDataFromColors(
    const ColorScheme.light(
      primary: Color(0xff1f67a3), // for selected things
      secondary: Color(0xffffa896), // for important things that you can click
      brightness: Brightness.light,
    ),
  );
}

ThemeData _themeDataFromColors(ColorScheme colorScheme) {
  const textTheme = TextTheme(
    caption: TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: 15,
    ),
    subtitle1: TextStyle(
      fontSize: 20,
    ),
  );
  return ThemeData(
    colorScheme: colorScheme,
    primarySwatch: _generateMaterialColor(colorScheme.primary),
    scaffoldBackgroundColor: colorScheme.background,
    appBarTheme: AppBarTheme(
      foregroundColor: colorScheme.onSurface,
      backgroundColor: colorScheme.surface,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: colorScheme.background,
    ),
    iconTheme: IconThemeData(
      color: colorScheme.primary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    ),
    cardTheme: CardTheme(color: colorScheme.surface),
    toggleableActiveColor: colorScheme.primary,
    // ignore: deprecated_member_use
    accentColor: colorScheme.primary, // still needed for expansion tile cards
    dialogTheme: DialogTheme(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: Defaults.borderRadius.big,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.surface,
    ),
    textTheme: textTheme,
  );
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
      1,
    );

int _shadeValue(int value, double factor) =>
    max(0, min(value - (value * factor).round(), 255));

Color _shadeColor(Color color, double factor) => Color.fromRGBO(
      _shadeValue(color.red, factor),
      _shadeValue(color.green, factor),
      _shadeValue(color.blue, factor),
      1,
    );
