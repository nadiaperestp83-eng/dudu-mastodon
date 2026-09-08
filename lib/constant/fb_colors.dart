import 'package:flutter/material.dart';

/// Design tokens que replicam a identidade visual do Facebook.
/// Usados pelo ThemeUtil (lib/utils/themes.dart) e por widgets que
/// precisam de uma cor "hard-coded" (ex: botão Seguir, cards).
class FbColors {
  FbColors._();

  /// Azul clássico do Facebook.
  static const Color primaryBlue = Color(0xFF1877F2);

  /// Fundo geral das telas (cinza-gelo).
  static const Color background = Color(0xFFF0F2F5);

  /// Fundo dos cards (posts, perfil, etc).
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// Texto principal (grafite quase preto).
  static const Color textPrimary = Color(0xFF050505);

  /// Texto secundário (cinza médio: timestamps, contadores, legendas).
  static const Color textSecondary = Color(0xFF65676B);

  /// Divisórias e bordas discretas.
  static const Color divider = Color(0xFFCED0D4);

  /// Fundo dos "chips" de ícone circulares na AppBar (pesquisa, notificações).
  static const Color iconChipBackground = Color(0xFFE4E6E9);
}
