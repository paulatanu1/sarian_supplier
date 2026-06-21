import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(Color primary, Color secondary) =>
      GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge:  GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold,  color: primary),
        headlineLarge: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold,  color: primary),
        headlineMedium:GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600,  color: primary),
        titleLarge:    GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600,  color: primary),
        titleMedium:   GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500,  color: primary),
        titleSmall:    GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500,  color: primary),
        bodyLarge:     GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.normal,color: primary),
        bodyMedium:    GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.normal,color: secondary),
        bodySmall:     GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.normal,color: secondary),
        labelLarge:    GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600,  color: Colors.white),
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        bg:         AppColors.bgLight,
        surface:    AppColors.surfaceLight,
        tPrimary:   AppColors.textPrimary,
        tSecondary: AppColors.textSecondary,
        divider:    AppColors.divider,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        bg:         AppColors.bgDark,
        surface:    AppColors.surfaceDark,
        tPrimary:   AppColors.textOnDark,
        tSecondary: const Color(0xFF9CA3AF),
        divider:    AppColors.dividerDark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color tPrimary,
    required Color tSecondary,
    required Color divider,
  }) =>
      ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
          primary:   AppColors.primary,
          secondary: AppColors.accent,
          surface:   surface,
          error:     AppColors.error,
        ),
        scaffoldBackgroundColor: bg,
        textTheme: _textTheme(tPrimary, tSecondary),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
          labelStyle: GoogleFonts.poppins(color: tSecondary, fontSize: 14),
          hintStyle:  GoogleFonts.poppins(color: tSecondary, fontSize: 14),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: divider),
          ),
          margin: EdgeInsets.zero,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor:   AppColors.primary,
          unselectedItemColor: tSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 12,
          selectedLabelStyle:   GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        ),
        dividerTheme: DividerThemeData(color: divider, thickness: 1),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
          labelStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.primaryDark),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
}
