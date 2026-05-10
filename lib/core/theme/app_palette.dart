import 'package:flutter/material.dart';

class NihPalette {
  const NihPalette._();

  static const Color primary = Color(0xFF111111);
  static const Color primaryDarker = Color(0xFF090909);
  static const Color primaryDarkest = Color(0xFF050505);
  static const Color base = Color(0xFF111111);
  static const Color grayDark = Color(0xFF6E6E73);
  static const Color grayLight = Color(0xFFE7E4DE);
  static const Color white = Color(0xFFFFFFFF);

  static const Color primaryAlt = Color(0xFF84B9FF);
  static const Color primaryAltDarkest = Color(0xFF2A5791);
  static const Color primaryAltDark = Color(0xFF568FD5);
  static const Color primaryAltLight = Color(0xFFD9E9FF);
  static const Color primaryAltLightest = Color(0xFFF4F8FF);

  static const Color secondary = Color(0xFF8BC34A);
  static const Color secondaryDarkest = Color(0xFF4B6F22);
  static const Color secondaryDark = Color(0xFF70A13A);
  static const Color secondaryLight = Color(0xFFDDEEC4);
  static const Color secondaryLightest = Color(0xFFF5FAEE);

  static const Color success = Color(0xFF2FA37F);
  static const Color warning = Color(0xFFE5B45C);
  static const Color mist = Color(0xFFF7F5F0);

  static const LinearGradient lightBackground = LinearGradient(
    colors: [Color(0xFFF8F6F1), Color(0xFFF6F4EF), Color(0xFFF3F1EC)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightContentBackground = LinearGradient(
    colors: [Color(0xFFF8F6F1), Color(0xFFF7F5F0), Color(0xFFF5F3EE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkBackground = LinearGradient(
    colors: [Color(0xFF0D1423), Color(0xFF15233B), Color(0xFF243756)],
    stops: [0.0, 0.48, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
