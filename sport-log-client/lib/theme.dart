import 'package:material_ui/material_ui.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';

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

  // ignore: long-method
  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _colorScheme,
    extensions: const [AppColors(success: Colors.lightGreen)],
    elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle),
    filledButtonTheme: FilledButtonThemeData(style: _buttonStyle),
    segmentedButtonTheme: const SegmentedButtonThemeData(
      style: ButtonStyle(
        iconSize: WidgetStatePropertyAll(24),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    iconTheme: IconThemeData(color: _colorScheme.primary),
    navigationBarTheme: const NavigationBarThemeData(height: 65),
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
