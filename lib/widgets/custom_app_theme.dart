import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single source of truth for the app's look. Change a token here and every
/// screen follows — screens must not hardcode colors, radii, spacing or sizes.

/// Color palette.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF16B4D0); // Fire Message cyan
  static const Color onPrimary = Color(0xFF04191E);
  static const Color secondary = Color(0xFF3B82F6); // Blue
  static const Color tertiary = Color(0xFF7C3AED); // Purple

  // Surfaces (darkest → lightest)
  static const Color background = Color(0xFF0B0D10);
  static const Color surface = Color(0xFF13161B);
  static const Color surfaceElevated = Color(0xFF1A1E24);
  static const Color border = Color(0xFF262B33);

  // Text
  static const Color textPrimary = Color(0xFFECEEF1);
  static const Color textSecondary = Color(0xFFA1A7B0);
  static const Color textMuted = Color(0xFF6B7280);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color onStatus = Colors.white;

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, secondary, tertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Translucent tint of [color] for chips, badges and icon backgrounds.
  static Color tint(Color color) => color.withValues(alpha: 0.14);
}

/// Spacing scale.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets screen = EdgeInsets.all(lg);
  static const EdgeInsets card = EdgeInsets.all(lg);
  static const double listGap = sm;
}

/// Corner radii.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;

  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(md));
  static const BorderRadius large = BorderRadius.all(Radius.circular(lg));
}

/// Icon and avatar sizes.
class AppSizes {
  AppSizes._();

  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 56; // empty states
  static const double avatar = 44;
  static const double logoPreview = 140;
  static const double buttonHeight = 52;
  static const double borderWidth = 1;
}

class CustomAppTheme {
  CustomAppTheme._();

  static TextTheme get _textTheme {
    final base = ThemeData.dark().textTheme.apply(fontFamily: GoogleFonts.poppins().fontFamily);
    return base
        .copyWith(
          headlineMedium: base.headlineMedium?.copyWith(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2),
          headlineSmall: base.headlineSmall?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, height: 1.25),
          titleLarge: base.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: base.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall: base.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: base.bodyLarge?.copyWith(fontSize: 15, height: 1.45),
          bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
          bodySmall: base.bodySmall?.copyWith(fontSize: 12, height: 1.4, color: AppColors.textSecondary),
          labelLarge: base.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
          labelMedium: base.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
          labelSmall: base.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4),
        )
        .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary);
  }

  static OutlineInputBorder _inputBorder(Color color, [double width = AppSizes.borderWidth]) =>
      OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: color, width: width),
      );

  static const _buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.medium);
  static const _buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md);
  static const _buttonMinSize = Size(64, AppSizes.buttonHeight);

  static ThemeData get darkTheme {
    final textTheme = _textTheme;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.tint(AppColors.primary),
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceElevated,
      surfaceContainerHighest: AppColors.surfaceElevated,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      error: AppColors.error,
      onError: AppColors.onStatus,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: GoogleFonts.poppins().fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: AppSizes.iconLg),
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimary, size: AppSizes.iconLg),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: textTheme.labelMedium,
        unselectedLabelStyle: textTheme.labelMedium,
        selectedIconTheme: const IconThemeData(size: AppSizes.iconLg),
        unselectedIconTheme: const IconThemeData(size: AppSizes.iconLg),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.border,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w400),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.primary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        helperStyle: textTheme.bodySmall,
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.primary, 1.5),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, 1.5),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        iconColor: AppColors.textSecondary,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.surfaceElevated,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          minimumSize: _buttonMinSize,
          padding: _buttonPadding,
          textStyle: textTheme.labelLarge,
          shape: _buttonShape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: _buttonMinSize,
          padding: _buttonPadding,
          textStyle: textTheme.labelLarge,
          shape: _buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
          elevation: 0,
          minimumSize: _buttonMinSize,
          padding: _buttonPadding,
          textStyle: textTheme.labelLarge,
          shape: _buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          textStyle: textTheme.labelLarge,
          shape: _buttonShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.textPrimary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        extendedTextStyle: textTheme.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.tint(AppColors.primary),
        side: const BorderSide(color: AppColors.border),
        labelStyle: textTheme.labelMedium,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.small),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.onPrimary : AppColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.surfaceElevated,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.border),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
        side: const BorderSide(color: AppColors.textMuted, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceElevated,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyMedium,
        menuStyle: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surfaceElevated),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      iconTheme: const IconThemeData(size: AppSizes.iconMd, color: AppColors.textPrimary),
      expansionTileTheme: const ExpansionTileThemeData(
        backgroundColor: AppColors.surface,
        collapsedBackgroundColor: AppColors.surface,
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        tilePadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        childrenPadding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(color: AppColors.border),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
        elevation: 0,
        contentTextStyle: textTheme.bodyMedium,
        actionTextColor: AppColors.primary,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
          side: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
