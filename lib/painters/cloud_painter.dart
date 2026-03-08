import 'package:flutter/material.dart';

/// Draws a single cloud shape using cubic bezier curves.
/// One continuous path gives a clean outer outline with no internal circle edges.
class CloudPainter extends CustomPainter {
  final Color color;

  const CloudPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final path = Path();
    path.moveTo(w * 0.05, h * 0.75);
    path.cubicTo(w * 0.0,  h * 0.75, w * 0.0,  h * 0.45, w * 0.2,  h * 0.45);
    path.cubicTo(w * 0.2,  h * 0.1,  w * 0.5,  h * 0.05, w * 0.5,  h * 0.25);
    path.cubicTo(w * 0.5,  h * 0.0,  w * 0.8,  h * 0.0,  w * 0.8,  h * 0.3);
    path.cubicTo(w * 1.0,  h * 0.3,  w * 1.0,  h * 0.75, w * 0.95, h * 0.75);
    path.lineTo(w * 0.05, h * 0.75);
    path.close();

    // Fill
    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.fill);

    // Outline
    canvas.drawPath(path, Paint()
      ..color       = Colors.black.withOpacity(0.4)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin  = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(CloudPainter old) => old.color != color;
}