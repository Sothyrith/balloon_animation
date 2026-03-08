import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class BalloonAudio {
  AudioPlayer? _inflatePlayer;
  AudioPlayer? _windPlayer;

  Future<void> init() async {
    try {
      _windPlayer    = AudioPlayer();
      _inflatePlayer = AudioPlayer();

      await AudioPlayer.global.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake:        false,
          contentType:      AndroidContentType.music,
          usageType:        AndroidUsageType.media,
          audioFocus:       AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options:  [AVAudioSessionOptions.mixWithOthers],
        ),
      ));

      await _windPlayer!.setVolume(0.7);
      await _windPlayer!.setReleaseMode(ReleaseMode.loop);
      await _windPlayer!.play(AssetSource('sounds/wind.mp3'));

      await _inflatePlayer!.setVolume(0.9);
      await _inflatePlayer!.play(AssetSource('sounds/inflate.mp3'));
    } catch (e) {
      debugPrint('BalloonAudio init error: $e');
    }
  }

  void playInflate() {
    _inflatePlayer
        ?.stop()
        .then((_) => _inflatePlayer?.play(AssetSource('sounds/inflate.mp3')));
  }

  void dispose() {
    _windPlayer?.stop();
    _inflatePlayer?.stop();
    _windPlayer?.dispose();
    _inflatePlayer?.dispose();
    _windPlayer    = null;
    _inflatePlayer = null;
  }
}