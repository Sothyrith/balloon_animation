import 'package:flutter/material.dart';

class BalloonPainter extends CustomPainter {
  final Color color;
  final bool  shadowMode;

  const BalloonPainter(this.color, {this.shadowMode = false});

  @override
  void paint(Canvas canvas, Size size) {
    final double w  = size.width;
    final double h  = size.height;
    final double cx = w / 2;

    // Body is more circular — nearly equal width and height
    // Center of the circle sits at 40% height
    final double radius     = w * 0.46;
    final double centerX    = cx;
    final double centerY    = h * 0.40;
    final double bodyBottom = centerY + radius; // bottom of circle

    // Use oval (slightly taller than wide) for that classic balloon look
    final Rect bodyRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width:  radius * 2.0,
      height: radius * 2.2,
    );

    final Path bodyPath = Path()..addOval(bodyRect);

    if (shadowMode) {
      canvas.drawPath(bodyPath, Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill);
      return;
    }

    // Base fill
    canvas.drawPath(bodyPath, Paint()
      ..color = color
      ..style = PaintingStyle.fill);

    // Glossy highlight
    canvas.drawPath(bodyPath, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        radius: 0.55,
        colors: [
          Colors.white.withOpacity(0.45),
          Colors.transparent,
        ],
      ).createShader(bodyRect)
      ..style = PaintingStyle.fill);

    // Knot — small oval at the bottom tip of the balloon
    final double knotTop = bodyBottom;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, knotTop + 5),
        width: 8, height: 10,
      ),
      Paint()
        ..color = color.withOpacity(0.85)
        ..style = PaintingStyle.fill,
    );

    // Wire — longer S-curve from knot to bottom of canvas
    final Path wirePath = Path()
      ..moveTo(cx, knotTop + 10)
      ..cubicTo(
        cx + 10, h * 0.82,
        cx - 10, h * 0.90,
        cx + 5,  h * 1.0,
      );

    canvas.drawPath(wirePath, Paint()
      ..color       = Colors.black.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round);
  }

  @override
  bool shouldRepaint(BalloonPainter old) =>
      old.color != color || old.shadowMode != shadowMode;
}