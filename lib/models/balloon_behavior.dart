/// The three possible behaviors when a balloon reaches the top of the screen.
enum BalloonBehavior {
  explode,        // burst into particles then auto-respawn
  floatAway,      // drift off screen top then auto-respawn
  waitForShrink,  // stay at top until user taps to shrink back down
}