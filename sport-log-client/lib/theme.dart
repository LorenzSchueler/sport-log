import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';

class AppTheme {
  AppTheme._();

  static const Color _warning = Colors.redAccent;
  static const Color _ok = Colors.lightGreen;

  static final darkTheme = _themeDataFromColors(
    const ColorScheme.dark(
      primary: Color(0xffa8d8ff),
      background: Color.fromARGB(255, 15, 15, 15),
      surface: Color.fromARGB(255, 30, 30, 30),
      surfaceVariant: Color.fromARGB(255, 45, 45, 45),
      onSurfaceVariant: Colors.white,
      error: _warning,
      errorContainer: _ok, // used for opposite of error like ok, start, ...
      surfaceTint: Colors.transparent,
    ),
  );

  static final lightTheme = _themeDataFromColors(
    const ColorScheme.light(
      primary: Color(0xff1f67a3),
      // background: Colors.white,
      surface: Color.fromARGB(255, 230, 230, 230),
      surfaceVariant: Color.fromARGB(255, 215, 215, 215),
      onSurfaceVariant: Colors.black,
      error: _warning,
      errorContainer: _ok, // used for opposite of error like ok, start, ...
    ),
  );

  // ignore: long-method
  static ThemeData _themeDataFromColors(ColorScheme colorScheme) {
    final buttonStyle = ButtonStyle(
      textStyle: MaterialStateProperty.all(
        const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      primarySwatch: _generateMaterialColor(colorScheme.primary),
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: AppBarTheme(
        foregroundColor: colorScheme.onSurface,
        backgroundColor: colorScheme.surface,
      ),
      dividerTheme: DividerThemeData(color: colorScheme.surfaceVariant),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.background,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: buttonStyle,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: buttonStyle,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          iconSize: const MaterialStatePropertyAll(24),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return colorScheme.primary.withAlpha(200);
            }
            return null;
          }),
        ),
      ),
      iconTheme: IconThemeData(
        color: colorScheme.primary,
      ),
      cardTheme: CardTheme(color: colorScheme.surface),
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: MaterialStatePropertyAll(colorScheme.primary),
        trackColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? null
              : Colors.transparent,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 65,
        indicatorColor: colorScheme.primary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? colorScheme.primary
              : null,
        ),
      ),
      // input decoration for InputDecorator, TextField, and TextFormField
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(vertical: 5),
        border: InputBorder.none,
        iconColor: EditTile.iconCaptionColor,
        labelStyle: const TextStyle(color: EditTile.iconCaptionColor),
        floatingLabelStyle: MaterialStateTextStyle.resolveWith(
          (states) => TextStyle(
            color: states.contains(MaterialState.selected)
                ? colorScheme.primary
                : EditTile.iconCaptionColor,
            fontSize: 18,
          ),
        ),
      ),
      textTheme: const TextTheme(
        // TextFormField
        bodyLarge: TextStyle(
          fontSize: 20,
          height: 1,
        ),
      ),
    );
  }

  static MaterialColor _generateMaterialColor(Color color) {
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

  static int _tintValue(int value, double factor) =>
      max(0, min((value + ((255 - value) * factor)).round(), 255));

  static Color _tintColor(Color color, double factor) => Color.fromARGB(
        255,
        _tintValue(color.red, factor),
        _tintValue(color.green, factor),
        _tintValue(color.blue, factor),
      );

  static int _shadeValue(int value, double factor) =>
      max(0, min(value - (value * factor).round(), 255));

  static Color _shadeColor(Color color, double factor) => Color.fromARGB(
        255,
        _shadeValue(color.red, factor),
        _shadeValue(color.green, factor),
        _shadeValue(color.blue, factor),
      );
}
