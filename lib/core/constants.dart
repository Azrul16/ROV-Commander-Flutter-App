import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0F172A);
  static const backgroundDeep = Color(0xFF020617);
  static const card = Color(0xFF1E293B);
  static const cardElevated = Color(0xFF111827);
  static const border = Color(0xFF334155);
  static const primary = Color(0xFF38BDF8);
  static const cyan = Color(0xFF22D3EE);
  static const violet = Color(0xFFA78BFA);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF94A3B8);
}

class ApiConstants {
  static const defaultPort = '8000';
  static const baseUrlStorageKey = 'rov_base_url';
  static const pollInterval = Duration(milliseconds: 800);
}
