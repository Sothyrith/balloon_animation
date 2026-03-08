import 'dart:math';
import 'package:flutter/material.dart';
import '../models/balloon_behavior.dart';
import '../models/balloon_config.dart';
import '../models/balloon_state.dart';
import '../models/particle.dart';

/// Controls all animation and behavior logic for a single balloon.
///
/// Depends on [onStateChanged] (calls setState in the parent widget) and
/// [onPlayInflate] (triggers inflate sound) injected as callbacks so this
/// class has zero dependency on the widget tree.
class BalloonController {
  final BalloonConfig config;
  final BalloonState  state;
  final TickerProvider vsync;
  final VoidCallback onStateChanged;
  final VoidCallback onPlayInflate;

  double _screenWidth  = 0;
  double _screenHeight = 0;

  final Random _rng = Random();

  BalloonController({
    required this.config,
    required this.state,
    required this.vsync,
    required this.onStateChanged,
    required this.onPlayInflate,
  });

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Wire up all animation controllers and start the balloon.
  /// Must be called after screen dimensions are known.
  void init(double screenWidth, double screenHeight) {
    _screenWidth  = screenWidth;
    _screenHeight = screenHeight;

    final double maxWidth  = _screenHeight * config.maxWidthRatio;
    final double startLeft = _screenWidth  * config.startLeftRatio;
    final double bottom    = _screenHeight * 0.65;

    // Drift — constant side-to-side sway, starts immediately
    state.ctrlDrift = AnimationController(
        duration: config.driftDuration, vsync: vsync);
    state.animDrift = Tween<double>(
        begin: -config.driftRange, end: config.driftRange)
        .animate(CurvedAnimation(
        parent: state.ctrlDrift!, curve: Curves.easeInOut));
    state.ctrlDrift!.repeat(reverse: true);

    // Pulse — subtle scale breathing, starts immediately
    state.ctrlPulse = AnimationController(
        duration: config.pulseDuration, vsync: vsync);
    state.animPulse = Tween<double>(begin: 1.0, end: config.pulseMax)
        .animate(CurvedAnimation(
        parent: state.ctrlPulse!, curve: Curves.easeInOut));
    state.ctrlPulse!.repeat(reverse: true);

    // Float up — moves balloon from bottom to top
    state.ctrlFloat = AnimationController(
        duration: config.floatDuration, vsync: vsync);
    state.animFloat = Tween<double>(begin: bottom, end: 60.0)
        .animate(CurvedAnimation(
        parent: state.ctrlFloat!, curve: config.floatCurve));

    // Grow size — balloon inflates as it rises
    state.ctrlGrow = AnimationController(
        duration: config.growDuration, vsync: vsync);
    state.animGrow = Tween<double>(begin: 50.0, end: maxWidth)
        .animate(CurvedAnimation(
        parent: state.ctrlGrow!, curve: config.growCurve));

    // Listen for when balloon reaches the top
    state.ctrlFloat!.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed &&
          !state.waitForShrink &&
          !state.isFloatingAway) {
        _onReachedTop();
      }
    });

    // Set starting horizontal position via drag offset
    state.drag = Offset(startLeft, 0);

    state.ctrlFloat!.forward();
    state.ctrlGrow!.forward();
  }

  // ── Sequence dispatcher ────────────────────────────────────────────────────

  void _onReachedTop() {
    final BalloonBehavior behavior =
    config.sequence[state.seqIndex % config.sequence.length];
    state.seqIndex++;

    switch (behavior) {
      case BalloonBehavior.explode:
        _triggerExplode();
        break;
      case BalloonBehavior.floatAway:
        _triggerFloatAway();
        break;
      case BalloonBehavior.waitForShrink:
        _triggerWaitForShrink();
        break;
    }
  }

  // ── Behavior 0: Explode ────────────────────────────────────────────────────

  void _triggerExplode() {
    if (state.isBursting) return;

    final double aw = state.animGrow!.value;
    final double ah = aw * 1.5;

    // Mix generic burst colors with the balloon's own color
    final List<Color> burstColors = [
      Colors.orange, Colors.red, Colors.yellow,
      Colors.deepOrange, Colors.white,
      config.color, config.color, // weighted toward the balloon color
    ];

    state.isBursting  = true;
    state.visible     = false;
    state.burstOrigin = Offset(
      state.drag.dx + aw / 2,
      state.animFloat!.value + state.drag.dy + ah / 2,
    );
    state.particles = List.generate(16, (int i) => Particle(
      angle:  (i / 16) * 2 * pi,
      speed:  150 + _rng.nextDouble() * 150,
      radius: 6   + _rng.nextDouble() * 10,
      color:  burstColors[_rng.nextInt(burstColors.length)],
    ));
    onStateChanged();

    Future.delayed(const Duration(milliseconds: 1200), () {
      state.isBursting = false;
      state.particles  = [];
      onStateChanged();
      respawn();
    });
  }

  // ── Behavior 1: Float away ─────────────────────────────────────────────────

  void _triggerFloatAway() {
    state.isFloatingAway = true;

    final double currentTop    = state.animFloat!.value;
    final double balloonHeight = state.animGrow!.value * 1.5;

    // Use a dedicated short-duration controller so the balloon zips off quickly
    // without being slowed by the 6–8s main float controller duration
    final AnimationController floatAwayCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: vsync,
    );

    state.animFloat = Tween<double>(
      begin: currentTop,
      end:   -(balloonHeight + 20), // just past the top screen edge
    ).animate(CurvedAnimation(parent: floatAwayCtrl, curve: Curves.easeIn));

    floatAwayCtrl.forward();
    onStateChanged();

    // 800ms to exit screen + 500ms pause before respawn
    Future.delayed(const Duration(milliseconds: 1300), () {
      state.isFloatingAway = false;
      floatAwayCtrl.dispose();
      respawn();
    });
  }

  // ── Behavior 2: Wait for shrink ────────────────────────────────────────────

  void _triggerWaitForShrink() {
    state.waitForShrink = true;
    onStateChanged();
    // No auto-respawn — user must tap the balloon to bring it back down
  }

  // ── Tap handler ────────────────────────────────────────────────────────────

  /// Called when the user taps the balloon.
  void onTap() {
    // If waiting at top — tap shrinks balloon back down
    if (state.waitForShrink) {
      state.waitForShrink = false;
      state.ctrlFloat!.reverse();
      state.ctrlGrow!.reverse();
      onStateChanged();
      return;
    }

    // Normal toggle: float up or back down
    if (state.ctrlFloat!.isCompleted) {
      state.ctrlFloat!.reverse();
      state.ctrlGrow!.reverse();
    } else {
      onPlayInflate();
      state.ctrlFloat!.forward();
      state.ctrlGrow!.forward();
    }
  }

  // ── Respawn ────────────────────────────────────────────────────────────────

  /// Reset balloon to starting position and replay the launch animation.
  void respawn() {
    final double bottom    = _screenHeight * 0.65;
    final double startLeft = _screenWidth  * config.startLeftRatio;

    // Restore the normal float animation range
    // (may have been replaced by the floatAway temporary animation)
    state.animFloat = Tween<double>(begin: bottom, end: 60.0)
        .animate(CurvedAnimation(
        parent: state.ctrlFloat!, curve: config.floatCurve));

    state.drag           = Offset(startLeft, 0);
    state.visible        = true;
    state.isBursting     = false;
    state.isFloatingAway = false;
    state.waitForShrink  = false;
    state.particles      = [];

    state.ctrlFloat!.reset();
    state.ctrlGrow!.reset();
    state.ctrlFloat!.forward();
    state.ctrlGrow!.forward();

    onStateChanged();
    onPlayInflate();
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  void dispose() {
    state.disposeControllers();
  }
}