import 'package:material_ui/material_ui.dart';

/// App specific colors that have no role in [ColorScheme].
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.success});

  /// Used for positive actions like ok, start or resume.
  final Color success;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({Color? success}) =>
      AppColors(success: success ?? this.success);

  @override
  AppColors lerp(AppColors? other, double t) => other == null
      ? this
      : AppColors(success: Color.lerp(success, other.success, t)!);
}

class AppTheme {
  AppTheme._();

  static final _buttonStyle = ButtonStyle(
    textStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
    ),
  );

  static const _primary = Color(0xffa8d8ff);

  /// Gray surfaces without the tint of the primary color.
  static final _neutral = ColorScheme.fromSeed(
    seedColor: _primary,
    brightness: Brightness.dark,
    dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
  );

  static final _colorScheme = ColorScheme.fromSeed(
    seedColor: _primary,
    brightness: Brightness.dark,
    primary: _primary,
    onPrimary: Colors.black,
    error: Colors.redAccent,
    surface: _neutral.surface,
    onSurface: _neutral.onSurface,
    surfaceDim: _neutral.surfaceDim,
    surfaceBright: _neutral.surfaceBright,
    surfaceContainerLowest: _neutral.surfaceContainerLowest,
    surfaceContainerLow: _neutral.surfaceContainerLow,
    surfaceContainer: _neutral.surfaceContainer,
    surfaceContainerHigh: _neutral.surfaceContainerHigh,
    surfaceContainerHighest: _neutral.surfaceContainerHighest,
    onSurfaceVariant: _neutral.onSurfaceVariant,
    outline: _neutral.outline,
    outlineVariant: _neutral.outlineVariant,
    inverseSurface: _neutral.inverseSurface,
    onInverseSurface: _neutral.onInverseSurface,
  );

  /// Style for [FilledButton.tonal] with a neutral background, so colored labels stand out.
  /// Not part of the theme, because [FilledButtonThemeData] also applies to regular [FilledButton]s
  /// and [ColorScheme.secondaryContainer] also colors the navigation and segmented button indicators.
  static ButtonStyle tonalButtonStyle({Color? foregroundColor}) =>
      FilledButton.styleFrom(
        backgroundColor: _colorScheme.surfaceContainerHighest,
        foregroundColor: foregroundColor ?? _colorScheme.primary,
      );

  /// Borderless 24 px high [DropdownMenu.inputDecorationTheme].
  /// Passed to each [DropdownMenu] because its trailing icon button ignores [DropdownMenuThemeData].
  static const dropdownMenuDecoration = InputDecorationThemeData(
    isCollapsed: true,
    isDense: true,
    contentPadding: EdgeInsets.zero,
    border: InputBorder.none,
    constraints: BoxConstraints(maxHeight: 24),
    suffixIconConstraints: BoxConstraints(maxHeight: 24),
  );

  // ignore: long-method
  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _colorScheme,
    extensions: const [AppColors(success: Colors.lightGreen)],
    filledButtonTheme: FilledButtonThemeData(style: _buttonStyle),
    segmentedButtonTheme: const SegmentedButtonThemeData(
      style: ButtonStyle(
        iconSize: WidgetStatePropertyAll(24),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(height: 65),
    bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
    sliderTheme: SliderThemeData(
      overlayShape: SliderComponentShape.noOverlay,
      // ignore: deprecated_member_use
      year2023: false,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearMinHeight: 8,
      stopIndicatorRadius: 0,
      // ignore: deprecated_member_use
      year2023: false,
    ),
    // input decoration for InputDecorator, TextField, and TextFormField
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      border: InputBorder.none,
      iconColor: _colorScheme.onSurfaceVariant,
      labelStyle: TextStyle(color: _colorScheme.onSurfaceVariant),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? _colorScheme.primary
              : _colorScheme.onSurfaceVariant,
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
