import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────
  static const primary      = Color(0xFF00897B);
  static const primaryDark  = Color(0xFF00695C);
  static const primaryLight = Color(0xFF4DB6AC);
  static const accent       = Color(0xFFE91E8C);

  // ── Light surface ──────────────────────────────────────────────────────
  static const bgLight      = Color(0xFFF5F6FA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const cardLight    = Color(0xFFFFFFFF);

  // ── Dark surface ───────────────────────────────────────────────────────
  static const bgDark       = Color(0xFF0F1117);
  static const surfaceDark  = Color(0xFF1C1F26);
  static const cardDark     = Color(0xFF252830);

  // ── Text ───────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textOnDark    = Color(0xFFF1F5F9);

  // ── Borders & dividers ─────────────────────────────────────────────────
  static const divider      = Color(0xFFE5E7EB);
  static const dividerDark  = Color(0xFF2D3139);

  // ── Status colours ─────────────────────────────────────────────────────
  static const success    = Color(0xFF22C55E);
  static const warning    = Color(0xFFF59E0B);
  static const error      = Color(0xFFEF4444);
  static const info       = Color(0xFF3B82F6);

  // ── Order status ───────────────────────────────────────────────────────
  static const pending    = Color(0xFFF59E0B);
  static const accepted   = Color(0xFF3B82F6);
  static const processing = Color(0xFF8B5CF6);
  static const dispatched = Color(0xFFEC4899);
  static const delivered  = Color(0xFF22C55E);
  static const cancelled  = Color(0xFFEF4444);

  // ── Category palette (index-based gradient pairs) ──────────────────────
  static const categoryGradients = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    [Color(0xFF10B981), Color(0xFF34D399)],
    [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    [Color(0xFFEF4444), Color(0xFFF87171)],
    [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    [Color(0xFF06B6D4), Color(0xFF22D3EE)],
    [Color(0xFFEC4899), Color(0xFFF472B6)],
    [Color(0xFF84CC16), Color(0xFFA3E635)],
  ];

  static Color statusColor(String s) => switch (s) {
    'pending'    => pending,
    'accepted'   => accepted,
    'processing' => processing,
    'dispatched' => dispatched,
    'delivered'  => delivered,
    _            => cancelled,
  };
}
