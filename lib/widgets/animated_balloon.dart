import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui';
import 'dart:math';

import '../audio/balloon_audio.dart';
import '../controllers/background_controller.dart';
import '../controllers/balloon_controller.dart';
import '../models/balloon_behavior.dart';
import '../models/balloon_config.dart';
import '../models/balloon_state.dart';
import '../models/bg_item.dart';
import '../models/particle.dart';
import '../painters/balloon_painter.dart';
import '../painters/bird_painter.dart';
import '../painters/cloud_painter.dart';

class AnimatedBalloonWidget extends StatefulWidget {
  const AnimatedBalloonWidget({super.key});

  @override
  State<AnimatedBalloonWidget> createState() => _AnimatedBalloonWidgetState();
}

class _AnimatedBalloonWidgetState extends State<AnimatedBalloonWidget>
    with TickerProviderStateMixin {

  // ── Balloon definitions (immutable config) ─────────────────────────────────
  //
  // Orange — image asset, left side, largest
  //   Sequence: explode → float away → tap to shrink
  //
  // Green — custom painter, right side, medium
  //   Sequence: float away → explode → tap to shrink
  //
  // Blue — custom painter, middle, smallest
  //   Sequence: tap to shrink → explode → float away

  static const List<BalloonConfig> _configs = [

    BalloonConfig(
      isImage:         true,
      color:           Colors.orange,
      maxWidthRatio:   1 / 3,
      startLeftRatio:  0.05,
      sequence:        [
        BalloonBehavior.explode,
        BalloonBehavior.floatAway,
        BalloonBehavior.waitForShrink,
      ],
      floatDuration:   Duration(seconds: 8),
      growDuration:    Duration(seconds: 4),
      driftDuration:   Duration(milliseconds: 2200),
      pulseDuration:   Duration(milliseconds: 1600),
      driftRange:      0.08,
      pulseMax:        1.06,
      floatCurve:      Curves.decelerate,
      growCurve:       Curves.easeInOutBack,
    ),

    BalloonConfig(
      isImage:         false,
      color:           Color(0xFF43A047), // green
      maxWidthRatio:   1 / 4,
      startLeftRatio:  0.5,
      sequence:        [
        BalloonBehavior.floatAway,
        BalloonBehavior.explode,
        BalloonBehavior.waitForShrink,
      ],
      floatDuration:   Duration(seconds: 7),
      growDuration:    Duration(milliseconds: 3500),
      driftDuration:   Duration(milliseconds: 1800),
      pulseDuration:   Duration(milliseconds: 1400),
      driftRange:      0.06,
      pulseMax:        1.04,
      floatCurve:      Curves.easeInOut,
      growCurve:       Curves.easeInOut,
    ),

    BalloonConfig(
      isImage:         false,
      color:           Color(0xFF1E88E5), // blue
      maxWidthRatio:   1 / 5,
      startLeftRatio:  0.3,
      sequence:        [
        BalloonBehavior.waitForShrink,
        BalloonBehavior.explode,
        BalloonBehavior.floatAway,
      ],
      floatDuration:   Duration(seconds: 6),
      growDuration:    Duration(seconds: 3),
      driftDuration:   Duration(milliseconds: 2500),
      pulseDuration:   Duration(milliseconds: 1200),
      driftRange:      0.10,
      pulseMax:        1.08,
      floatCurve:      Curves.easeIn,
      growCurve:       Curves.elasticOut,
    ),

  ];

  // ── Runtime objects ────────────────────────────────────────────────────────

  late final List<BalloonState>      _states;
  late final List<BalloonController> _controllers;
  late final BackgroundController    _bgCtrl;
  late final BalloonAudio            _audio;

  Ticker?  _ticker;
  Duration _lastTick    = Duration.zero;
  bool     _initialized = false;
  bool     _isReady     = false; // true only after first frame + balloon init done

  double _screenWidth  = 0;
  double _screenHeight = 0;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _states  = List.generate(_configs.length, (_) => BalloonState());
    _bgCtrl  = BackgroundController();
    _audio   = BalloonAudio();

    _controllers = List.generate(_configs.length, (int i) => BalloonController(
      config:         _configs[i],
      state:          _states[i],
      vsync:          this,
      onStateChanged: () { if (mounted) setState(() {}); },
      onPlayInflate:  _audio.playInflate,
    ));

    // Wait for first frame before starting ticker and audio
    // prevents freeze on hot restart caused by early setState calls
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _isReady = true);
      _ticker = createTicker(_onTick)..start();
      _audio.init();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _screenWidth  = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;

    if (_initialized) return;
    _initialized = true;

    _bgCtrl.screenWidth  = _screenWidth;
    _bgCtrl.screenHeight = _screenHeight;
    _bgCtrl.prePopulate();

    for (final BalloonController ctrl in _controllers) {
      ctrl.init(_screenWidth, _screenHeight);
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    for (final BalloonController ctrl in _controllers) ctrl.dispose();
    _audio.dispose();
    super.dispose();
  }

  // ── Per-frame tick ─────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    if (!_isReady || _screenWidth == 0) return;

    final double dt = _lastTick == Duration.zero
        ? 0.0
        : (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    setState(() {
      _bgCtrl.tick(dt);

      // Advance burst particles for each balloon
      for (final BalloonState s in _states) {
        if (s.isBursting) {
          for (final Particle p in s.particles) {
            p.distance += p.speed * dt;
            p.opacity   = (1.0 - p.distance / 200).clamp(0.0, 1.0);
          }
        }
      }
    });
  }

  // ── Build helpers ──────────────────────────────────────────────────────────

  /// Shadow layer — blurred grey copy offset slightly right and down.
  Widget _buildShadow(
      BalloonConfig config,
      double aw, double ah,
      double offsetX, double offsetY,
      double opacity,
      ) {
    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: config.isImage
            ? Image.asset(
          'assets/images/BeginningGoogleFlutter-Balloon.png',
          height: ah, width: aw,
          // Use a fixed grey opacity for image shadow — independent of
          // the float animation so it's always visible at consistent strength
          color: Colors.black.withOpacity(0.5),
          colorBlendMode: BlendMode.srcIn,
        )
            : SizedBox(
          width: aw, height: ah,
          child: CustomPaint(
            painter: BalloonPainter(
              Colors.grey.withOpacity(opacity),
              shadowMode: true,
            ),
          ),
        ),
      ),
    );
  }

  /// Balloon body — image with gloss overlay, or custom painted shape.
  Widget _buildBody(BalloonConfig config, double aw, double ah) {
    if (config.isImage) {
      return ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (Rect bounds) => RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.6,
          colors: [Colors.white.withOpacity(0.35), Colors.transparent],
        ).createShader(bounds),
        child: Image.asset(
          'assets/images/BeginningGoogleFlutter-Balloon.png',
          height: ah, width: aw,
          errorBuilder: (_, __, ___) => Container(
            height: ah, width: aw, color: Colors.orange,
            child: const Center(child: Icon(Icons.error, color: Colors.white)),
          ),
        ),
      );
    }

    return CustomPaint(
      size: Size(aw, ah),
      painter: BalloonPainter(config.color),
    );
  }

  /// Full balloon widget: shadow + body wrapped in drift, pulse, and gestures.
  Widget _buildBalloon(
      BalloonConfig config,
      BalloonState  state,
      BalloonController ctrl,
      double aw, double ah,
      ) {
    final double ratio         = aw / (_screenHeight * config.maxWidthRatio);
    final double shadowOpacity = 0.015 * state.ctrlFloat!.value.clamp(0.0, 1.0);

    return RepaintBoundary(
      child: GestureDetector(
        onPanUpdate: (DragUpdateDetails d) =>
            setState(() => state.drag += d.delta),
        onDoubleTap: () {}, // absorb so it doesn't bubble to the respawn-all handler
        onTap:       ctrl.onTap,
        child: Transform.rotate(
          angle:     state.animDrift!.value,
          alignment: Alignment.bottomCenter,
          child: Transform.scale(
            scale: state.animPulse!.value,
            child: Stack(
              alignment: Alignment.topLeft,
              clipBehavior: Clip.none,
              children: [
                _buildShadow(config, aw, ah, 8 * ratio, 10 * ratio, shadowOpacity),
                _buildBody(config, aw, ah),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Main build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool allReady = _isReady &&
        _states.every((BalloonState s) => s.isReady);
    if (!allReady) return const SizedBox.shrink();

    return SizedBox(
      width:  _screenWidth,
      height: _screenHeight,
      child: GestureDetector(
        // Double tap anywhere to respawn all three balloons
        onDoubleTap: () {
          for (final BalloonController ctrl in _controllers) {
            ctrl.respawn();
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [

            // ── Background clouds + birds ─────────────────────────────────
            RepaintBoundary(
              child: Stack(
                children: _bgCtrl.items.map((BgItem item) => Positioned(
                  left: item.x,
                  top:  item.y,
                  child: Opacity(
                    opacity: item.opacity,
                    child: item.type == BgItemType.cloud
                        ? CustomPaint(
                      size: Size(item.width, item.height),
                      painter: CloudPainter(color: item.color),
                    )
                        : CustomPaint(
                      size: Size(item.width, item.height),
                      painter: BirdPainter(color: item.color),
                    ),
                  ),
                )).toList(),
              ),
            ),

            // ── Balloons + burst particles ────────────────────────────────
            ..._configs.asMap().entries.expand((entry) {
              final int             i      = entry.key;
              final BalloonConfig   config = entry.value;
              final BalloonState    state  = _states[i];
              final BalloonController ctrl = _controllers[i];

              final double aw = state.animGrow!.value;
              final double ah = aw * 1.5;

              return [

                // Burst particles
                if (state.isBursting)
                  ...state.particles.map((Particle p) {
                    final double px = state.burstOrigin.dx + cos(p.angle) * p.distance;
                    final double py = state.burstOrigin.dy + sin(p.angle) * p.distance;
                    return Positioned(
                      left: px - p.radius,
                      top:  py - p.radius,
                      child: Opacity(
                        opacity: p.opacity,
                        child: Container(
                          width:  p.radius * 2,
                          height: p.radius * 2,
                          decoration: BoxDecoration(
                            color: p.color, shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),

                // Balloon body
                if (state.visible)
                  Positioned(
                    top:  state.animFloat!.value + state.drag.dy - aw * 0.2,
                    left: state.drag.dx - aw * 0.2,
                    child: Padding(
                      padding: EdgeInsets.all(aw * 0.2),
                      child: SizedBox(
                        width: aw, height: ah,
                        child: _buildBalloon(config, state, ctrl, aw, ah),
                      ),
                    ),
                  ),

              ];
            }),

          ],
        ),
      ),
    );
  }
}