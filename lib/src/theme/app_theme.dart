import 'package:flutter/material.dart';

class AppTheme {
  static const _blue = Color(0xff1976d2);
  static const _orange = Color(0xffff9800);
  static const _green = Color(0xff4caf50);
  static const _lightBackground = Color(0xffffffff);
  static const _lightSurface = Color(0xfff5f5f5);
  static const _lightInput = Color(0xfff5f5f5);
  static const _lightBorder = Color(0xffe0e0e0);
  static const _text = Color(0xff212121);
  static const _secondaryText = Color(0xff757575);

  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: _blue,
      brightness: brightness,
      primary: _blue,
      secondary: _orange,
      tertiary: _green,
      surface: isDark ? const Color(0xff1f1f1f) : _lightSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? const Color(0xff121212) : _lightBackground,
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: isDark ? Colors.white : _text,
            displayColor: isDark ? Colors.white : _text,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xff1f1f1f) : Colors.white,
        foregroundColor: isDark ? Colors.white : _text,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xff1f1f1f) : _lightSurface,
        elevation: 0.5,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isDark ? const Color(0xff263244) : _lightBorder,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xff2a2a2a) : _lightInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _blue, width: 1.3),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size.fromHeight(46),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xff2a2a2a) : _lightSurface,
        selectedColor: _blue.withValues(alpha: 0.14),
        checkmarkColor: _blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _blue,
        unselectedItemColor: isDark ? Colors.grey.shade500 : Colors.grey.shade700,
        backgroundColor: isDark ? const Color(0xff111827) : Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xff1f1f1f) : _lightSurface,
        indicatorColor: isDark ? const Color(0xff2a2a2a) : const Color(0xffe3f2fd),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? _blue
                : isDark
                    ? Colors.grey.shade400
                    : _secondaryText,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? _blue
                : isDark
                    ? Colors.grey.shade400
                    : _secondaryText,
          ),
        ),
      ),
    );
  }
}
