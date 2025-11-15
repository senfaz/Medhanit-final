import 'package:flutter/material.dart';
import 'package:flutter_grocery/utill/app_constants.dart';

ThemeData light = ThemeData(
  fontFamily: AppConstants.fontFamily,
  primaryColor: const Color(0xFF2DA95C), // Enhanced Green
  secondaryHeaderColor: const Color(0xFFE8F5F0), // Light green background
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFE8F5F0), // Light green background
  cardColor: Colors.white,
  focusColor: const Color(0xFF17A2B8), // Teal for focus
  hintColor: const Color(0xFF52575C),
  canvasColor: const Color(0xFFFAFAFA),
  shadowColor: Colors.grey[300],

  textTheme: const TextTheme(titleLarge: TextStyle(color: Color(0xFFE0E0E0))),
  pageTransitionsTheme: const PageTransitionsTheme(builders: {
    TargetPlatform.android: ZoomPageTransitionsBuilder(),
    TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
    TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
  }),
  popupMenuTheme: const PopupMenuThemeData(color: Colors.white, surfaceTintColor: Colors.white),
  dialogTheme: const DialogThemeData(surfaceTintColor: Colors.white),
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: const Color(0xFF2DA95C), // Enhanced Green
    onPrimary: Colors.white,
    secondary: const Color(0xFF17A2B8), // Teal
    onSecondary: Colors.white,
    tertiary: const Color(0xFF28A745), // Accent Green
    onTertiary: Colors.white,
    error: Colors.redAccent,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: const Color(0xFF002349),
    shadow: Colors.grey[300],
  ),
);