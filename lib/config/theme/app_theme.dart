import 'package:flutter/material.dart';

import '../../features/conversation/colors.dart';
import '../../features/conversation/utils/colors.dart';

class AppTheme {
  ThemeData getTheme() {
    return ThemeData(
      primaryColor: appColorPrimary,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: ColorScheme.dark(
        primary: appColorPrimary,
        secondary: chatGPT_textField_bgColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appColorPrimary,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: appColorPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.grey[400]),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: replyMsgBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: replyMsgBgColor,
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.grey[400]),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}