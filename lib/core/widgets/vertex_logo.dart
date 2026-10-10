import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';

/// Marca gráfica de Tienda Vertex: logo PNG + wordmark.
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo_vertex.png',
          height: markSize * 1.4,
          fit: BoxFit.contain,
        ),
        if (showWordmark) ...[
          SizedBox(width: markSize * 0.5),
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: wordmarkSize * 0.62,
                fontWeight: FontWeight.w600,
                letterSpacing: wordmarkSize * 0.14,
                color: textColor,
              ),
              children: [
                const TextSpan(text: 'TIENDA '),
                TextSpan(
                  text: 'VERTEX',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: wordmarkSize * 0.62,
                    fontWeight: FontWeight.w800,
                    letterSpacing: wordmarkSize * 0.14,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}