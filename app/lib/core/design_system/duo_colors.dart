import 'package:flutter/material.dart';

class DuoColors {
  DuoColors._();

  // Orbit V3.2
  static const orbitBackground = Color(0xFF080B12);
  static const orbitSurface = Color(0xFF111622);
  static const orbitCardSurface = Color(0xE8111622);
  static const orbitBorder = Color(0xFF20283A);
  static const orbitTextPrimary = Color(0xFFF6F8FB);
  static const orbitTextSecondary = Color(0xFF98A2B3);
  static const orbitAccent = Color(0xFFA782FF);

  static const orbitCardShadow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  // Backgrounds
  static const background = Color(0xFF0D0F14);
  static const surface = Color(0xFF171A22);
  static const surfaceLight = Color(0xFF1F2430);

  // Primary
  static const primary = Color(0xFF7C5CFF);
  static const primaryLight = Color(0xFFA78BFA);

  // Success
  static const success = Color(0xFF3DDC97);

  // Status
  static const warning = Color(0xFFFFC857);
  static const error = Color(0xFFFF6B6B);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB2B8C6);
  static const textHint = Color(0xFF7B8294);

  // Borders
  static const border = Color(0x22FFFFFF);

  // Glass
  static const glass = Color(0x14FFFFFF);

  // Dividers
  static const divider = Color(0x12FFFFFF);

  // Overlay
  static const overlay = Color(0x66000000);

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B6BFF),
      Color(0xFF6A4CFF),
    ],
  );

  static const successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4BE7A6),
      Color(0xFF2ECF86),
    ],
  );

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1C2030),
      Color(0xFF141821),
    ],
  );

  // Hero card (balance) — deeper, more saturated purple than
  // the neutral cardGradient used by list/summary cards below it.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2E2358),
      Color(0xFF15111F),
    ],
  );

  // Shadows
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.28),
          blurRadius: 26,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> get successGlow => [
        BoxShadow(
          color: success.withValues(alpha: 0.28),
          blurRadius: 24,
          spreadRadius: 1,
        ),
      ];
}
