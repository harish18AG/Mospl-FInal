import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MOSPL Premium Leather Brand Palette
/// Inspired by Bellroy, Fossil, Coach — clean, warm, and luxurious.
class AppColors {
  // Primary brand
  static const leatherBrown = Color(0xff7A4E2D);
  static const espressoBrown = Color(0xff4B2E1E);
  static const leatherBrownLight = Color(0xff9E6645);

  // Accent
  static const luxuryGold = Color(0xffC8A96A);
  static const goldLight = Color(0xffF7E7C3);

  // Backgrounds
  static const warmCream = Color(0xffF8F5F1);
  static const ivoryWhite = Color(0xffFFFCF8);
  static const softBeige = Color(0xffE6DDD5);
  static const creamInputFill = Color(0xffF3EFEA);
  static const wishlistBg = Color(0xffFFF4E3);

  // Text
  static const darkCharcoal = Color(0xff222222);
  static const secondaryText = Color(0xff6B7280);

  // Semantic
  static const successGreen = Color(0xff2E7D32);
  static const errorRed = Color(0xffD32F2F);

  // Dark mode surfaces
  static const darkBg = Color(0xff1A1410);
  static const darkSurface = Color(0xff241C16);
  static const darkCard = Color(0xff2E2318);
  static const darkBorder = Color(0xff3D2E22);
  static const darkInputFill = Color(0xff1F170F);
}

class AppTheme {
  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBg : AppColors.warmCream;
    final surface = isDark ? AppColors.darkSurface : AppColors.ivoryWhite;
    final cardColor = isDark ? AppColors.darkCard : AppColors.ivoryWhite;
    final inputFill = isDark ? AppColors.darkInputFill : AppColors.creamInputFill;
    final border = isDark ? AppColors.darkBorder : AppColors.softBeige;
    final primaryText = isDark ? const Color(0xffF0EAE3) : AppColors.darkCharcoal;
    final secondaryText = isDark ? const Color(0xff9E8E7E) : AppColors.secondaryText;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.leatherBrown,
      onPrimary: Colors.white,
      primaryContainer: isDark ? const Color(0xff3D2218) : const Color(0xffF5E6D8),
      onPrimaryContainer: AppColors.espressoBrown,
      secondary: AppColors.luxuryGold,
      onSecondary: AppColors.espressoBrown,
      secondaryContainer: isDark ? const Color(0xff3A2D16) : AppColors.goldLight,
      onSecondaryContainer: AppColors.espressoBrown,
      tertiary: AppColors.successGreen,
      onTertiary: Colors.white,
      tertiaryContainer: isDark ? const Color(0xff1A3320) : const Color(0xffD4EDDA),
      onTertiaryContainer: const Color(0xff1B5E20),
      error: AppColors.errorRed,
      onError: Colors.white,
      errorContainer: const Color(0xffFFDAD6),
      onErrorContainer: const Color(0xff410002),
      surface: surface,
      onSurface: primaryText,
      onSurfaceVariant: secondaryText,
      outline: border,
      outlineVariant: isDark ? const Color(0xff2A1E14) : const Color(0xffEDE4DC),
      shadow: isDark ? Colors.black : AppColors.espressoBrown.withValues(alpha: 0.08),
      inverseSurface: isDark ? AppColors.warmCream : AppColors.espressoBrown,
      onInverseSurface: isDark ? AppColors.darkCharcoal : Colors.white,
      inversePrimary: AppColors.leatherBrownLight,
      surfaceTint: AppColors.leatherBrown.withValues(alpha: 0.04),
    );

    // Premium typography — Inter for readability, slight letter spacing
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w300, color: primaryText),
      displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w300, color: primaryText),
      displaySmall: GoogleFonts.inter(fontWeight: FontWeight.w400, color: primaryText),
      headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primaryText, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primaryText, letterSpacing: -0.3),
      headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primaryText),
      titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primaryText),
      titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: primaryText, letterSpacing: 0.1),
      titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w600, color: primaryText, letterSpacing: 0.1),
      bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400, color: primaryText),
      bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400, color: primaryText),
      bodySmall: GoogleFonts.inter(fontWeight: FontWeight.w400, color: secondaryText),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: primaryText),
      labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w500, color: secondaryText),
      labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w500, color: secondaryText, letterSpacing: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: baseTextTheme,

      // ── AppBar ──────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.espressoBrown.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: primaryText,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xffD4B896) : AppColors.leatherBrown,
        ),
        actionsIconTheme: IconThemeData(
          color: isDark ? const Color(0xffD4B896) : AppColors.leatherBrown,
        ),
      ),

      // ── Cards ────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: AppColors.espressoBrown.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border, width: 1),
        ),
      ),

      // ── Input fields ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: GoogleFonts.inter(
          color: secondaryText.withValues(alpha: 0.7),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.inter(color: secondaryText, fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(color: AppColors.leatherBrown, fontSize: 12, fontWeight: FontWeight.w600),
        prefixIconColor: isDark ? const Color(0xff9E7E5E) : AppColors.leatherBrown.withValues(alpha: 0.7),
        suffixIconColor: isDark ? const Color(0xff9E7E5E) : AppColors.leatherBrown.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.leatherBrown, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
        ),
      ),

      // ── Elevated Button ───────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.leatherBrown,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? const Color(0xff3D2E22) : AppColors.softBeige,
          disabledForegroundColor: secondaryText,
          elevation: 2,
          shadowColor: AppColors.espressoBrown.withValues(alpha: 0.25),
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.2),
        ),
      ),

      // ── Outlined Button ──────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.leatherBrown,
          side: const BorderSide(color: AppColors.leatherBrown, width: 1.5),
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.2),
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.leatherBrown,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // ── Chips ────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.ivoryWhite,
        selectedColor: AppColors.leatherBrown,
        disabledColor: isDark ? AppColors.darkSurface : AppColors.softBeige,
        checkmarkColor: Colors.white,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: primaryText),
        selectedShadowColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        pressElevation: 0,
        side: BorderSide(color: border, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.ivoryWhite,
        selectedItemColor: AppColors.leatherBrown,
        unselectedItemColor: secondaryText,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
      ),

      // ── Navigation Bar (Material 3 bottom nav) ───────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.ivoryWhite,
        indicatorColor: isDark
            ? AppColors.leatherBrown.withValues(alpha: 0.25)
            : const Color(0xffF5E6D8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.espressoBrown.withValues(alpha: 0.1),
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            fontSize: 11,
            color: states.contains(WidgetState.selected)
                ? AppColors.leatherBrown
                : secondaryText,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AppColors.leatherBrown
                : secondaryText,
          ),
        ),
      ),

      // ── Divider ──────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // ── List Tile ────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: cardColor,
        iconColor: isDark ? const Color(0xff9E7E5E) : AppColors.leatherBrown.withValues(alpha: 0.75),
        titleTextStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, color: primaryText, fontSize: 14),
        subtitleTextStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, color: secondaryText, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ── Checkbox ────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.leatherBrown;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── Switch ───────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return secondaryText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.leatherBrown;
          return border;
        }),
      ),

      // ── Badge (notification dots) ─────────────────────────────────────
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.luxuryGold,
        textColor: AppColors.espressoBrown,
        smallSize: 8,
        largeSize: 16,
      ),

      // ── Icon ────────────────────────────────────────────────────────
      iconTheme: IconThemeData(
        color: isDark ? const Color(0xff9E7E5E) : AppColors.leatherBrown.withValues(alpha: 0.85),
        size: 22,
      ),

      // ── Dialog ──────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.ivoryWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: 1),
        ),
        titleTextStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: primaryText),
        contentTextStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14, color: secondaryText),
      ),

      // ── Bottom Sheet ─────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.ivoryWhite,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 0,
        dragHandleColor: border,
      ),

      // ── Snack Bar ────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.espressoBrown,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
        actionTextColor: AppColors.luxuryGold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── Progress Indicator ───────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.leatherBrown,
        circularTrackColor: Color(0xffF5E6D8),
        linearTrackColor: Color(0xffF5E6D8),
      ),

      // ── Floating Action Button ────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.leatherBrown,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // ── Tab Bar ──────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.leatherBrown,
        unselectedLabelColor: AppColors.secondaryText,
        indicatorColor: AppColors.leatherBrown,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        dividerColor: AppColors.softBeige,
      ),

      // ── PopupMenu ────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.ivoryWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: AppColors.espressoBrown.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: 1),
        ),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
