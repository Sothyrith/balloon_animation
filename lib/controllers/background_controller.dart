import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bg_item.dart';

/// Manages the background clouds and birds that drift across the scene.
/// Call [tick] every frame to advance positions, and read [items] for rendering.
class BackgroundController {
  final List<BgItem> items = [];

  double _spawnTimer  = 0.0;
  double _nextSpawnIn = 1.0;
  final Random _rng = Random();

  double screenWidth  = 0;
  double screenHeight = 0;

  /// Seed a few items at startup so the background isn't empty.
  void prePopulate() {
    for (int i = 0; i < 2; i++) {
      final BgItem item = _makeItem();
      // Place at a random x so they spread across the screen immediately
      item.x = _rng.nextDouble() * screenWidth;
      items.add(item);
    }
  }

  /// Advance all item positions and spawn new ones on a timer.
  /// [dt] is delta time in seconds since the last tick.
  void tick(double dt) {
    // Move every item to the left
    for (final BgItem item in items) {
      item.x -= item.speed * dt;
    }

    // Remove items that have fully exited left edge
    items.removeWhere((BgItem item) => item.x < -item.width);

    // Spawn a new item every 3–6 seconds, capped at 3 on screen at once
    _spawnTimer += dt;
    if (_spawnTimer >= _nextSpawnIn && items.length < 3) {
      items.add(_makeItem());
      _spawnTimer  = 0;
      _nextSpawnIn = 3.0 + _rng.nextDouble() * 3.0;
    }
  }

  BgItem _makeItem() {
    final bool isCloud = _rng.nextBool();

    if (isCloud) {
      final double w = 260 + _rng.nextDouble() * 120;
      return BgItem(
        type:    BgItemType.cloud,
        x:       screenWidth + w,
        y:       _rng.nextDouble() * screenHeight * 0.35,
        width:   w,
        height:  w * 0.38,
        speed:   25 + _rng.nextDouble() * 20,
        opacity: 0.85 + _rng.nextDouble() * 0.15,
        color:   Color.lerp(Colors.white, const Color(0xFFDDEEFF), _rng.nextDouble())!,
      );
    } else {
      final double w = 220 + _rng.nextDouble() * 80;
      return BgItem(
        type:    BgItemType.bird,
        x:       screenWidth + w,
        y:       _rng.nextDouble() * screenHeight * 0.4,
        width:   w,
        height:  w * 0.28,
        speed:   35 + _rng.nextDouble() * 25,
        opacity: 0.6 + _rng.nextDouble() * 0.4,
        color:   Color.lerp(
            const Color(0xFF222222), const Color(0xFF666666), _rng.nextDouble())!,
      );
    }
  }
}