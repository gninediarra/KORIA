import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF080E1A);
  static const surface = Color(0xFF0F1B2D);
  static const card = Color(0xFF152030);
  static const cardLight = Color(0xFF1A2C42);
  static const cardBorder = Color(0xFF1E3354);

  static const cyan = Color(0xFF00D4FF);
  static const cyanDim = Color(0xFF0096BB);
  static const cyanGlow = Color(0x3300D4FF);

  static const green = Color(0xFF00E676);
  static const greenDim = Color(0xFF00C853);
  static const greenZone = Color(0x5500E676);

  static const orange = Color(0xFFFFAB00);
  static const orangeDim = Color(0xFFFF8F00);
  static const orangeZone = Color(0x55FFAB00);

  static const red = Color(0xFFFF3D57);
  static const redDim = Color(0xFFDD2C3F);
  static const redZone = Color(0x55FF3D57);

  static const soil = Color(0xFFBC8A5F);
  static const water = Color(0xFF1E88E5);
  static const air = Color(0xFF8E24AA);

  static const textPrimary = Color(0xFFE8EDF5);
  static const textSecondary = Color(0xFF7B94B5);
  static const textHint = Color(0xFF3D5475);

  static const divider = Color(0xFF1A2E48);

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [cyan, Color(0xFF0066FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get bgGradient => const LinearGradient(
        colors: [bg, Color(0xFF0D1A2E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static Color statusColor(String status) {
    switch (status) {
      case 'rouge':
        return red;
      case 'orange':
        return orange;
      default:
        return green;
    }
  }

  static Color statusZoneColor(String status) {
    switch (status) {
      case 'rouge':
        return redZone;
      case 'orange':
        return orangeZone;
      default:
        return greenZone;
    }
  }
}

/// Theme-aware colors. Use [AdaptiveColors.of(context)] inside build methods.
class AdaptiveColors {
  final bool _dark;
  AdaptiveColors._(this._dark);

  static AdaptiveColors of(BuildContext context) =>
      AdaptiveColors._(Theme.of(context).brightness == Brightness.dark);

  Color get bg => _dark ? AppColors.bg : const Color(0xFFF0F4F8);
  Color get surface => _dark ? AppColors.surface : Colors.white;
  Color get card => _dark ? AppColors.card : Colors.white;
  Color get cardBorder => _dark ? AppColors.cardBorder : const Color(0xFFDDE5EF);
  Color get textPrimary => _dark ? AppColors.textPrimary : const Color(0xFF0A1929);
  Color get textSecondary => _dark ? AppColors.textSecondary : const Color(0xFF546E8A);
  Color get textHint => _dark ? AppColors.textHint : const Color(0xFF8BA4BC);
  Color get divider => _dark ? AppColors.divider : const Color(0xFFDDE5EF);
}

class AppTheme {
  static ThemeData get lightTheme {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF0F4F8),
      colorScheme: const ColorScheme.light(
        primary: AppColors.cyan,
        secondary: AppColors.green,
        surface: Colors.white,
        error: AppColors.red,
      ),
      textTheme: GoogleFonts.exo2TextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.exo2(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF0A1929)),
        headlineLarge: GoogleFonts.exo2(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFF0A1929)),
        headlineMedium: GoogleFonts.exo2(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF0A1929)),
        headlineSmall: GoogleFonts.exo2(fontSize: 17, fontWeight: FontWeight.w600, color: const Color(0xFF0A1929)),
        titleLarge: GoogleFonts.exo2(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0A1929)),
        titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0A1929)),
        titleSmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF546E8A)),
        bodyLarge: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF0A1929)),
        bodyMedium: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF546E8A)),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8BA4BC)),
        labelLarge: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0A1929), letterSpacing: 0.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.exo2(fontSize: 17, fontWeight: FontWeight.w600, color: const Color(0xFF0A1929), letterSpacing: 0.3),
        iconTheme: const IconThemeData(color: AppColors.cyan),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.cyan,
        unselectedItemColor: Color(0xFF8BA4BC),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFDDE5EF), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDE5EF))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDE5EF))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cyan, width: 1.5)),
        labelStyle: GoogleFonts.inter(color: const Color(0xFF546E8A), fontSize: 14),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF8BA4BC), fontSize: 14),
        prefixIconColor: const Color(0xFF8BA4BC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.exo2(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFDDE5EF), thickness: 1, space: 0),
    );
  }

  static ThemeData get theme {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        secondary: AppColors.green,
        surface: AppColors.surface,
        error: AppColors.red,
      ),
      textTheme: GoogleFonts.exo2TextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.exo2(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.exo2(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.exo2(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.exo2(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.exo2(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.textHint,
        ),
        labelLarge: GoogleFonts.exo2(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.exo2(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.cyan),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.cyan,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textHint,
          fontSize: 14,
        ),
        prefixIconColor: AppColors.textHint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: AppColors.bg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.exo2(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),
    );
  }
}

class AppShadows {
  static List<BoxShadow> cyan = [
    BoxShadow(
      color: AppColors.cyan.withValues(alpha: 0.15),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
