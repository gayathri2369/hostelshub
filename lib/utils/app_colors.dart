import 'package:flutter/material.dart';

class AppColors {
  // Primary brand color - deep teal/indigo for hostel theme
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF52B788);
  static const Color primaryDark = Color(0xFF1B4332);

  // Secondary - warm orange for CTAs
  static const Color secondary = Color(0xFFFF8C42);
  static const Color secondaryLight = Color(0xFFFFB380);

  // Backgrounds
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFB0B7C3);

  // Status
  static const Color success = Color(0xFF40916C);
  static const Color error = Color(0xFFE63946);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF3A86FF);

  // Chat bubbles
  static const Color senderBubble = Color(0xFF2D6A4F);
  static const Color receiverBubble = Color(0xFFF0F4F8);

  // Divider / Border
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF52B788)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
