import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static bool soundEnabled = true;
  static bool isTesting = false;

  /// Play an audio file from assets/audio/ relative path
  static Future<void> play(String assetName) async {
    if (isTesting || !soundEnabled) return;
    try {
      final player = AudioPlayer();
      // AssetSource automatically points inside the 'assets/' folder.
      // So 'audio/filename.mp3' maps to 'assets/audio/filename.mp3'.
      await player.play(AssetSource('audio/$assetName'));
      
      // Auto-dispose of the player instance once playback completes
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      debugPrint('AudioService: error playing $assetName: $e');
    }
  }

  static Future<void> playMove() => play('click.mp3');
  static Future<void> playClick() => play('click.mp3');
  static Future<void> playWin() => play('winner.mp3');
  static Future<void> playLose() => play('loser.mp3');
  static Future<void> playDraw() => play('wrong.mp3');
  static Future<void> playSuccess() => play('right.mp3');
  static Future<void> playUndo() => play('wrong.mp3');
}
