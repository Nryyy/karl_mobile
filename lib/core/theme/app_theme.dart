import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material Design 3 theme configuration with dynamic color support.
abstract final class AppTheme {
  static const _primarySeed = Color(0xFF0066CC);
  static const _secondarySeed = Color(0xFF5C5C95);
  static const _tertiarySeed = Color(0xFF8B5CF6);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeed,
      secondary: _secondarySeed,
      tertiary: _tertiarySeed,
      brightness: Brightness.light,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: _buildAppBarTheme(colorScheme),
      cardTheme: _buildCardThemeData(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      navigationBarTheme: _buildNavigationBarTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      dialogTheme: _buildDialogThemeData(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
      dividerTheme: _buildDividerTheme(colorScheme),
      listTileTheme: _buildListTileTheme(colorScheme),
      floatingActionButtonTheme: _buildFABTheme(colorScheme),
      pageTransitionsTheme: _buildPageTransitions(),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeed,
      secondary: _secondarySeed,
      tertiary: _tertiarySeed,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
      surfaceContainerLowest: const Color(0xFF0F1419),
      surfaceContainerLow: const Color(0xFF1A1F2E),
      surfaceContainer: const Color(0xFF252B3D),
      surfaceContainerHigh: const Color(0xFF30364A),
      surfaceContainerHighest: const Color(0xFF3B4256),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: _buildAppBarTheme(colorScheme, isDark: true),
      cardTheme: _buildCardThemeData(colorScheme, isDark: true),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(
        colorScheme,
        isDark: true,
      ),
      navigationBarTheme: _buildNavigationBarTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      dialogTheme: _buildDialogThemeData(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
      dividerTheme: _buildDividerTheme(colorScheme),
      listTileTheme: _buildListTileTheme(colorScheme),
      floatingActionButtonTheme: _buildFABTheme(colorScheme),
      pageTransitionsTheme: _buildPageTransitions(),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        color: colorScheme.onSurface,
        letterSpacing: -0.25,
      ),
      displayMedium: base.displayMedium?.copyWith(color: colorScheme.onSurface),
      displaySmall: base.displaySmall?.copyWith(color: colorScheme.onSurface),
      headlineLarge: base.headlineLarge?.copyWith(
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(color: colorScheme.onSurface),
      titleLarge: base.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.43,
      ),
      bodySmall: base.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      labelLarge: base.labelLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(
    ColorScheme colorScheme, {
    bool isDark = false,
  }) => AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 3,
    backgroundColor: colorScheme.surfaceContainerLowest,
    foregroundColor: colorScheme.onSurface,
    centerTitle: true,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    ),
    iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    ),
  );

  static CardThemeData _buildCardThemeData(
    ColorScheme colorScheme, {
    bool isDark = false,
  }) => CardThemeData(
    elevation: 0,
    color: colorScheme.surfaceContainerLowest,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        width: 1,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.zero,
  );

  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    ColorScheme colorScheme,
  ) => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: colorScheme.surfaceContainerLow,
      foregroundColor: colorScheme.primary,
      elevation: 1,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
  );

  static FilledButtonThemeData _buildFilledButtonTheme(
    ColorScheme colorScheme,
  ) => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
  );

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
    ColorScheme colorScheme,
  ) => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: colorScheme.primary,
      side: BorderSide(color: colorScheme.outline),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
  );

  static TextButtonThemeData _buildTextButtonTheme(ColorScheme colorScheme) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      );

  static InputDecorationTheme _buildInputDecorationTheme(
    ColorScheme colorScheme, {
    bool isDark = false,
  }) => InputDecorationTheme(
    filled: true,
    fillColor: isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.error, width: 2),
    ),
    labelStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurfaceVariant,
    ),
    hintStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    ),
  );

  static NavigationBarThemeData _buildNavigationBarTheme(
    ColorScheme colorScheme,
  ) => NavigationBarThemeData(
    backgroundColor: colorScheme.surfaceContainer,
    indicatorColor: colorScheme.secondaryContainer,
    indicatorShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSecondaryContainer,
            )
          : GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
    ),
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? IconThemeData(color: colorScheme.onSecondaryContainer, size: 24)
          : IconThemeData(color: colorScheme.onSurfaceVariant, size: 24),
    ),
    elevation: 3,
    height: 80,
  );

  static ChipThemeData _buildChipTheme(ColorScheme colorScheme) =>
      ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.secondaryContainer,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSecondaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      );

  static DialogThemeData _buildDialogThemeData(ColorScheme colorScheme) =>
      DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
        ),
      );

  static SnackBarThemeData _buildSnackBarTheme(ColorScheme colorScheme) =>
      SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      );

  static DividerThemeData _buildDividerTheme(ColorScheme colorScheme) =>
      DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      );

  static ListTileThemeData _buildListTileTheme(ColorScheme colorScheme) =>
      ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.secondaryContainer.withValues(
          alpha: 0.3,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );

  static FloatingActionButtonThemeData _buildFABTheme(
    ColorScheme colorScheme,
  ) => FloatingActionButtonThemeData(
    backgroundColor: colorScheme.primaryContainer,
    foregroundColor: colorScheme.onPrimaryContainer,
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    extendedTextStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
  );

  static PageTransitionsTheme _buildPageTransitions() => PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
    },
  );
}
