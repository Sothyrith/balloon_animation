import 'package:flutter/material.dart';

/// Draws a flock of 5 birds as M-shaped quadratic bezier strokes.
class BirdPainter extends CustomPainter {
  final Color color;

  const BirdPainter({this.color = const Color(0xFF333333)});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color      = color
      ..strokeWidth = 3.0
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    // Each offset is the starting point of one bird
    const List<Offset> offsets = [
      Offset(0,  0),
      Offset(18, -6),
      Offset(36, -2),
      Offset(54, -8),
      Offset(72, -3),
    ];

    for (final Offset o in offsets) {
      final path = Path();
      path.moveTo(o.dx,      o.dy);
      path.quadraticBezierTo(o.dx + 5,  o.dy - 5, o.dx + 10, o.dy);
      path.quadraticBezierTo(o.dx + 15, o.dy - 5, o.dx + 20, o.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(BirdPainter old) => old.color != color;
}