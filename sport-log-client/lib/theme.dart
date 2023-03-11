import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
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
    return ThemeData(
      //useMaterial3: true,
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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all(
            const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: Defaults.borderRadius.normal,
            ),
          ),
        ),
      ),
      segmentedButtonTheme: const SegmentedButtonThemeData(
        style: ButtonStyle(
          iconSize: MaterialStatePropertyAll(24),
        ),
      ),
      iconTheme: IconThemeData(
        color: colorScheme.primary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      cardTheme: CardTheme(color: colorScheme.surface),
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: Defaults.borderRadius.normal,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
      ),
      textTheme: const TextTheme(
        //headline1    96.0  light
        //Extremely large text.
        //
        //headline2    60.0  light
        //Very, very large text.
        //Used for the date in the dialog shown by showDatePicker.
        //
        //headline3    48.0  regular
        //Very large text.
        //
        //headline4    34.0  regular
        //Large text.
        //
        //headlineSmall    24.0  regular
        //Used for large text in dialogs (e.g., the month and year in the dialog shown by showDatePicker).
        //
        //titleLarge    20.0  medium
        //Used for the primary text in app bars and dialogs (e.g., AppBar.title and AlertDialog.title).
        //
        //titleMedium    16.0  regular
        //Used for the primary text in lists (e.g., ListTile.title).
        // TextField, EditTile
        titleMedium: TextStyle(
          fontSize: 20,
          height: 1,
        ),
        //
        //titleSmall    14.0  medium
        //For medium emphasis text that's a little smaller than titleMedium.
        //
        //bodyLarge        16.0  regular
        //Used for emphasizing text that would otherwise be bodyText2.
        // ListTile
        //
        //bodyText2        14.0  regular
        //The default text style for Material.
        //
        //button       14.0  medium
        //Used for text on ElevatedButton, TextButton and OutlinedButton.
        //
        //bodySmall      12.0  regular
        //Used for auxiliary text associated with images.
        // validator message
        bodySmall: TextStyle(
          fontSize: 14,
        ),
        //
        //overline     10.0  regular
        //The smallest style.
        //Typically used for captions or to introduce a (larger) headline.
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

extension ThemeDataExtension on ThemeData {
  InputDecoration get textFormFieldDecoration => const InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 5),
        border: InputBorder.none,
        iconColor: EditTile.iconCaptionColor,
      );
}
