import 'package:flutter/material.dart';

const Color navy = Color(0xFF171329); // Professional Dark Charcoal background (#171717)
const Color surface = Color(0xFF27213D); // Card & Sheet Surface (#262626)
const Color surfaceLight = Color(0xFF322A4E); // Elevated component surface
const Color lime = Color(0xFFB8A1FF); // Professional Vibrant Accent (#FF6B6B)
const Color coral = Color(0xFFB8A1FF); // Accent Red/Coral (#FF6B6B)
const Color greenAccent = Color(0xFF10B981);
const Color muted = Color(0xFFC4BDD6); // Secondary Text & Border Muted (#D4D4D4)
const Color textWhite = Color(0xFFFFFFFF);

final ThemeData roomWalaTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: navy,
  colorScheme: ColorScheme.fromSeed(
    seedColor: lime,
    brightness: Brightness.dark,
    surface: surface,
    primary: lime,
    secondary: coral,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: navy,
    elevation: 0,
    centerTitle: false,
    iconTheme: IconThemeData(color: textWhite),
    titleTextStyle: TextStyle(
      color: textWhite,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
);

class AppTheme {
  static const Color navyDark = navy;
  static const Color surfaceNavy = surface;
  static const Color surfaceLightNavy = surfaceLight;
  static const Color accentLime = lime;
  static const Color accentCoral = coral;
  static const Color accentGreen = greenAccent;
  static const Color textSecondary = muted;
  static const Color textPrimary = textWhite;

  static ThemeData get darkTheme => roomWalaTheme;
}
