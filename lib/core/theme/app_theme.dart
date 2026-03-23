import 'package:flutter/material.dart';

import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_theme.dart' as ui;

class AppTheme {
  static const Color brandPrimary = AppColors.primary;
  static const Color brandPrimarySoft = AppColors.primaryContainer;
  static const Color brandAccent = AppColors.secondary;
  static const Color appBackground = AppColors.background;

  static ThemeData light() {
    return ui.AppTheme.light();
  }

  static ThemeData dark() {
    return ui.AppTheme.light();
  }
}
