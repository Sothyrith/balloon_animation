import 'package:flutter/material.dart';
import 'balloon_behavior.dart';

/// Immutable configuration for one balloon.
/// Created once and never mutated — all runtime state lives in BalloonState.
class BalloonConfig {
  final bool   isImage;         // true = image asset, false = custom painter
  final Color  color;
  final double maxWidthRatio;   // max balloon width as fraction of screen height
  final double startLeftRatio;  // initial left position as fraction of screen width
  final List<BalloonBehavior> sequence; // cycled through each time balloon reaches top

  final Duration floatDuration;
  final Duration growDuration;
  final Duration driftDuration;
  final Duration pulseDuration;

  final double driftRange; // ± radians for left/right sway
  final double pulseMax;   // max scale for pulse animation

  final Curve floatCurve;
  final Curve growCurve;

  const BalloonConfig({
    required this.isImage,
    required this.color,
    required this.maxWidthRatio,
    required this.startLeftRatio,
    required this.sequence,
    required this.floatDuration,
    required this.growDuration,
    required this.driftDuration,
    required this.pulseDuration,
    required this.driftRange,
    required this.pulseMax,
    required this.floatCurve,
    required this.growCurve,
  });
}