import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Tiny line sparkline with a gradient stroke and subtle highlight overlay.
enum HiFiSparkTone { income, teal }

class HiFiSpark extends StatelessWidget {
  const HiFiSpark({
    required this.values,
    this.tone = HiFiSparkTone.income,
    this.height = 36,
    this.width = 74,
    super.key,
  });

  final List<double> values;
  final HiFiSparkTone tone;
  final double height;
  final double width;

  LinearGradient get _gradient {
    switch (tone) {
      case HiFiSparkTone.income:
        return const LinearGradient(
          colors: <Color>[Color(0xFF2F8F6B), Color(0xFF3FBF8F)],
        );
      case HiFiSparkTone.teal:
        return const LinearGradient(
          colors: <Color>[Color(0xFF0E6B6F), Color(0xFF2AA79B)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _HiFiSparkPainter(values: values, gradient: _gradient),
      ),
    );
  }
}

class _HiFiSparkPainter extends CustomPainter {
  const _HiFiSparkPainter({required this.values, required this.gradient});

  final List<double> values;
  final LinearGradient gradient;

  static const double _strokeWidth = 3;
  static const double _highlightWidth = 1.2;
  static const double _verticalInset = 3;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.isEmpty) {
      return;
    }

    final Rect rect = Offset.zero & size;
    final Path path = _buildPath(size);

    final Paint linePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = _highlightWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
    canvas.drawPath(path, highlightPaint);
  }

  Path _buildPath(Size size) {
    final List<Offset> points = _buildPoints(size);
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);

    if (points.length == 1) {
      path.lineTo(points.first.dx, points.first.dy);
      return path;
    }

    for (int i = 0; i < points.length - 1; i++) {
      final Offset current = points[i];
      final Offset next = points[i + 1];
      final double midX = (current.dx + next.dx) / 2;

      path.quadraticBezierTo(
        current.dx,
        current.dy,
        midX,
        (current.dy + next.dy) / 2,
      );
    }

    path.quadraticBezierTo(
      points.last.dx,
      points.last.dy,
      points.last.dx,
      points.last.dy,
    );

    return path;
  }

  List<Offset> _buildPoints(Size size) {
    final double safeHeight = size.height - (_verticalInset * 2);
    final double stepX = values.length == 1
        ? 0
        : size.width / (values.length - 1);

    return List<Offset>.generate(values.length, (int index) {
      final double value = values[index].clamp(0.0, 1.0);
      final double dx = stepX * index;
      final double dy = _verticalInset + (safeHeight * (1 - value));
      return Offset(dx, dy);
    });
  }

  @override
  bool shouldRepaint(covariant _HiFiSparkPainter oldDelegate) {
    return !listEquals(values, oldDelegate.values) ||
        gradient != oldDelegate.gradient;
  }
}
