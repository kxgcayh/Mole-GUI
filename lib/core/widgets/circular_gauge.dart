import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CircularGauge extends StatelessWidget {
  final double value; // 0.0 to 100.0
  final double size;
  final double strokeWidth;
  final List<Color> gradientColors;
  final String label;
  final String? sublabel;
  final Widget? centerWidget;

  const CircularGauge({
    super.key,
    required this.value,
    this.size = 130,
    this.strokeWidth = 10,
    this.gradientColors = AppColors.cpuGradient,
    required this.label,
    this.sublabel,
    this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 100.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _GaugePainter(
                  percent: clampedValue / 100.0,
                  strokeWidth: strokeWidth,
                  gradientColors: gradientColors,
                  trackColor: AppColors.darkCardBorder.withValues(alpha: 0.6),
                ),
              ),
              centerWidget ??
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${clampedValue.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: size * 0.22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (sublabel != null)
                        Text(
                          sublabel!,
                          style: TextStyle(
                            fontSize: size * 0.1,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percent;
  final double strokeWidth;
  final List<Color> gradientColors;
  final Color trackColor;

  _GaugePainter({
    required this.percent,
    required this.strokeWidth,
    required this.gradientColors,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 1.25,
      pi * 1.5,
      false,
      trackPaint,
    );

    if (percent > 0) {
      final sweepAngle = pi * 1.5 * percent;
      final gradient = SweepGradient(
        startAngle: -pi * 1.25,
        endAngle: -pi * 1.25 + (pi * 1.5),
        colors: gradientColors,
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi * 1.25,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gradientColors != gradientColors;
  }
}
