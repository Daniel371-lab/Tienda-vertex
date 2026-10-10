import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Marca gráfica de Tienda Vertex.
class VertexLogo extends StatelessWidget {
  const VertexLogo({
    super.key,
    this.markSize = 28,
    this.showWordmark = true,
    this.wordmarkSize = 17,
    this.color = AppColors.primary,
    this.textColor = AppColors.textPrimary,
  });

  final double markSize;
  final bool showWordmark;
  final double wordmarkSize;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_vertex.png',
      height: markSize * 1.4,
      fit: BoxFit.contain,
    );
  }
}