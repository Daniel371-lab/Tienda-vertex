import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';

/// Marca gráfica de Tienda Vertex.
/// El símbolo es un "vértice" geométrico: dos trazos que convergen
/// en un nodo circular, representando el punto de encuentro central.
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
        SizedBox(
          width: markSize,
          height: markSize,
          child: CustomPaint(painter: _VertexMarkPainter(color)),
        ),
        if (showWordmark) ...[
          SizedBox(width: markSize * 0.35),
          _Wordmark(
            size: wordmarkSize,
            textColor: textColor,
            accentColor: color,
          ),
        ],
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({
    required this.size,
    required this.textColor,
    required this.accentColor,
  });

  final double size;
  final Color textColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: size * 0.62,
          fontWeight: FontWeight.w600,
          letterSpacing: size * 0.14,
          color: textColor,
        ),
        children: [
          const TextSpan(text: 'TIENDA '),
          TextSpan(
            text: 'VERTEX',
            style: GoogleFonts.plusJakartaSans(
              fontSize: size * 0.62,
              fontWeight: FontWeight.w800,
              letterSpacing: size * 0.14,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _VertexMarkPainter extends CustomPainter {
  _VertexMarkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.085;
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.14)
      ..lineTo(size.width * 0.50, size.height * 0.80)
      ..lineTo(size.width * 0.85, size.height * 0.14);

    canvas.drawPath(path, paint);

    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.80),
      size.width * 0.10,
      nodePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _VertexMarkPainter old) => old.color != color;
}