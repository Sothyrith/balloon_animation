import 'package:flutter/material.dart';

/// A single burst particle that flies outward from the balloon's center.
class Particle {
  final double angle;   // direction in radians
  final double speed;   // pixels per second
  final double radius;  // circle radius in px
  final Color  color;

  double distance = 0;    // how far it has traveled so far
  double opacity  = 1.0;  // fades out as it travels

  Particle({
    required this.angle,
    required this.speed,
    required this.radius,
    required this.color,
  });
}