import 'package:flutter/material.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';

class AppTheme {
  AppTheme._();

  static final _buttonStyle = ButtonStyle(
    textStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
    ),
  );

  static const _background = Color.fromARGB(255, 15, 15, 15);

  static const _colorScheme = ColorScheme.dark(
    primary: Color(0xffa8d8ff),
    surface: Color.fromARGB(255, 30, 30, 30),
    surfaceContainerHighest: Color.fromARGB(255, 45, 45, 45),
    error: Colors.redAccent,
    errorContainer:
        Colors.lightGreen, // used for opposite of error like ok, start, ...
  );

  // ignore: long-method
  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: _background,
    appBarTheme: AppBarTheme(
      foregroundColor: _colorScheme.onSurface,
      backgroundColor: _colorScheme.surface,
    ),
    dividerTheme: DividerThemeData(color: _colorScheme.surfaceContainerHighest),
    drawerTheme: const DrawerThemeData(backgroundColor: _background),
    elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle),
    filledButtonTheme: FilledButtonThemeData(style: _buttonStyle),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        iconSize: const WidgetStatePropertyAll(24),
        iconColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? _colorScheme.surface
              : Colors.white,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? _colorScheme.primary.withAlpha(200)
              : null,
        ),
      ),
    ),
    iconTheme: IconThemeData(color: _colorScheme.primary),
    dialogTheme: DialogTheme(backgroundColor: _colorScheme.surface),
    snackBarTheme: SnackBarThemeData(backgroundColor: _colorScheme.surface),
    tabBarTheme: TabBarTheme(
      dividerColor: _colorScheme.surfaceContainerHighest,
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStatePropertyAll(_colorScheme.primary),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? null : Colors.transparent,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 65,
      indicatorColor: _colorScheme.primary,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? _colorScheme.primary : null,
      ),
    ),
    sliderTheme: SliderThemeData(overlayShape: SliderComponentShape.noOverlay),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearTrackColor: _colorScheme.surfaceContainerHighest,
    ),
    // input decoration for InputDecorator, TextField, and TextFormField
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      border: InputBorder.none,
      iconColor: EditTile.iconCaptionColor,
      labelStyle: const TextStyle(color: EditTile.iconCaptionColor),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? _colorScheme.primary
              : EditTile.iconCaptionColor,
          fontSize: 18,
        ),
      ),
    ),
    textTheme: const TextTheme(
      // TextFormField
      bodyLarge: TextStyle(fontSize: 20, height: 1),
    ),
  );
}
