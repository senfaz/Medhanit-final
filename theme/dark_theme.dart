import 'package:flutter/material.dart';
import 'package:flutter_grocery/utill/app_constants.dart';

ThemeData dark = ThemeData(
  fontFamily: AppConstants.fontFamily,
  primaryColor: const Color(0xFF2DA95C), // Enhanced Green
  secondaryHeaderColor: const Color(0xFF1F4A3C), // Dark green background
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF2C2C2C),
  cardColor: const Color(0xFF121212),
  hintColor: const Color(0xFFE7F6F8),
  focusColor: const Color(0xFF17A2B8), // Teal for focus
  canvasColor: const Color(0xFF4d5054),
  shadowColor: Colors.black.withValues(alpha: 0.4),
  textTheme: TextTheme(titleLarge: TextStyle(color: const Color(0xFFE0E0E0).withValues(alpha: 0.3))),
  pageTransitionsTheme: const PageTransitionsTheme(builders: {
    TargetPlatform.android: ZoomPageTransitionsBuilder(),
    TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
    TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
  }),
  popupMenuTheme: const PopupMenuThemeData(color: Color(0xFF29292D), surfaceTintColor: Color(0xFF29292D)),
  dialogTheme: const DialogThemeData(surfaceTintColor: Colors.white10),
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFF2DA95C), // Enhanced Green
    onPrimary: Colors.white,
    secondary: const Color(0xFF17A2B8), // Teal
    onSecondary: Colors.white,
    tertiary: const Color(0xFF28A745), // Accent Green
    onTertiary: Colors.white,
    error: Colors.redAccent,
    onError: Colors.white,
    surface: Colors.white10,
    onSurface: Colors.white70,
    shadow: Colors.black.withValues(alpha: 0.4),
  ),
);
