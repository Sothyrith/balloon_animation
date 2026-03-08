import 'package:flutter/material.dart';
import 'particle.dart';

/// Mutable runtime state for one balloon.
/// Holds animation controllers and all in-flight state changes.
class BalloonState {
  // Animation controllers — created by BalloonController.init()
  AnimationController? ctrlFloat;
  AnimationController? ctrlGrow;
  AnimationController? ctrlDrift;
  AnimationController? ctrlPulse;

  // Driven animations
  Animation<double>? animFloat;
  Animation<double>? animGrow;
  Animation<double>? animDrift;
  Animation<double>? animPulse;

  // Drag state
  Offset drag = Offset.zero;

  // Visibility + behavior flags
  bool visible        = true;
  bool isBursting     = false;
  bool isFloatingAway = false;
  bool waitForShrink  = false;

  // Burst particle data
  List<Particle> particles  = [];
  Offset         burstOrigin = Offset.zero;

  // Which step in the behavior sequence we're on
  int seqIndex = 0;

  /// True once all animations have been wired up and are ready to render.
  bool get isReady =>
      animFloat != null &&
          animGrow  != null &&
          animDrift != null &&
          animPulse != null;

  /// Clean up all controllers.
  void disposeControllers() {
    ctrlFloat?.dispose();
    ctrlGrow?.dispose();
    ctrlDrift?.dispose();
    ctrlPulse?.dispose();
  }
}