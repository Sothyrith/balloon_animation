import 'package:flutter/material.dart';

enum BgItemType { cloud, bird }

/// A single cloud or bird that drifts across the background.
class BgItem {
  final BgItemType type;
  double           x;         // mutable — moves left each tick
  final double     y;
  final double     width;
  final double     height;
  final double     speed;     // px per second
  final double     opacity;
  final Color      color;

  BgItem({
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.speed,
    required this.opacity,
    required this.color,
  });
}