import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:water_tank_controller/core/app_colors.dart';

class OceanBackground extends StatelessWidget {
  const OceanBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.abyss,
            AppColors.deepSea,
            Color(0xFF075F72),
            Color(0xFF052A38),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _Glow(
            alignment: Alignment(-1.05, -0.86),
            color: Color(0xFF3DE9FF),
            size: 280,
            opacity: 0.24,
          ),
          const _Glow(
            alignment: Alignment(1.12, -0.28),
            color: Color(0xFF75FFF3),
            size: 220,
            opacity: 0.15,
          ),
          const _Glow(
            alignment: Alignment(-0.76, 1.04),
            color: Color(0xFF0CE0B8),
            size: 330,
            opacity: 0.13,
          ),
          CustomPaint(painter: _CurrentPainter()),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.alignment,
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Alignment alignment;
  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.045);

    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.12 + i * 0.13);
      final path = Path()..moveTo(-40, y);
      for (var x = -40.0; x <= size.width + 40; x += 44) {
        path.lineTo(x, y + math.sin((x / 62) + i) * (10 + i * 1.6));
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
