import 'package:flutter/material.dart';

class NihPalette {
  const NihPalette._();

  static const Color primary = Color(0xFF2F6B49);
  static const Color primaryDarker = Color(0xFF25553A);
  static const Color primaryDarkest = Color(0xFF183728);
  static const Color base = Color(0xFF253328);
  static const Color grayDark = Color(0xFF667062);
  static const Color grayLight = Color(0xFFE7E1D4);
  static const Color white = Color(0xFFFFFFFF);
  static const Color sand = Color(0xFFF8F3E8);
  static const Color sandDark = Color(0xFFECE2CC);
  static const Color warmSurface = Color(0xFFFEFBF5);
  static const Color warmSurfaceAlt = Color(0xFFF4EEDC);
  static const Color borderSoft = Color(0xFFE4DAC4);

  static const Color primaryAlt = Color(0xFF84B9FF);
  static const Color primaryAltDarkest = Color(0xFF2A5791);
  static const Color primaryAltDark = Color(0xFF568FD5);
  static const Color primaryAltLight = Color(0xFFD9E9FF);
  static const Color primaryAltLightest = Color(0xFFF4F8FF);

  static const Color secondary = Color(0xFF8FB868);
  static const Color secondaryDarkest = Color(0xFF4E6C34);
  static const Color secondaryDark = Color(0xFF6F9450);
  static const Color secondaryLight = Color(0xFFDDE9C9);
  static const Color secondaryLightest = Color(0xFFF5F8EE);

  static const Color success = Color(0xFF2F8F63);
  static const Color warning = Color(0xFFE5B45C);
  static const Color mist = Color(0xFFF7F2E8);
  static const Color macroProtein = Color(0xFF3F7BE0);
  static const Color macroCarbs = Color(0xFFF0A34A);
  static const Color macroFat = Color(0xFFD96A5E);

  static const LinearGradient lightBackground = LinearGradient(
    colors: [Color(0xFFF6F3E8), Color(0xFFF4EFDF), Color(0xFFEFF4E8)],
    stops: [0.0, 0.58, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightContentBackground = LinearGradient(
    colors: [Color(0xFFF9F5EB), Color(0xFFF5F1E5), Color(0xFFF0F5EA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBackground = LinearGradient(
    colors: [Color(0xFF0D1423), Color(0xFF15233B), Color(0xFF243756)],
    stops: [0.0, 0.48, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
