import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'dart:developer' as developer;

enum _SoundAction { click, success, error, hint, toggle }

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final Map<_SoundAction, AudioPlayer> _players = {};
  final Map<_SoundAction, DateTime> _lastPlayedAt = {};
  int _playRequestId = 0;

  static const Map<_SoundAction, String> _assets = {
    _SoundAction.click: 'sounds/click.wav',
    _SoundAction.success: 'sounds/Success.mp3',
    _SoundAction.error: 'sounds/Error.ogg',
    _SoundAction.hint: 'sounds/Hint.wav',
    _SoundAction.toggle: 'sounds/Toggle.wav',
  };

  static const Map<_SoundAction, Duration> _minIntervals = {
    _SoundAction.click: Duration(milliseconds: 90),
    _SoundAction.success: Duration(milliseconds: 350),
    _SoundAction.error: Duration(milliseconds: 250),
    _SoundAction.hint: Duration(milliseconds: 200),
    _SoundAction.toggle: Duration(milliseconds: 180),
  };

  bool get _isMuted =>
      Hive.box('iqVaultBox').get('isSoundEnabled', defaultValue: true) == false;

  /// Initializes the global audio context to ensure sounds play correctly on mobile devices,
  /// even when the physical mute switch is on (for games).
  static Future<void> init() async {
    try {
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
      ));
      developer.log('SoundService: Audio Context Initialized');
    } catch (e) {
      developer.log('SoundService: Failed to initialize Audio Context: $e');
    }
  }

  Future<AudioPlayer> _playerFor(_SoundAction action) async {
    final existingPlayer = _players[action];
    if (existingPlayer != null) return existingPlayer;

    final player = _players.putIfAbsent(action, () {
      final player = AudioPlayer();
      return player;
    });
    await player.setPlayerMode(PlayerMode.lowLatency);
    return player;
  }

  bool _canPlay(_SoundAction action) {
    if (_isMuted) return false;

    final now = DateTime.now();
    final lastPlayed = _lastPlayedAt[action];
    final minInterval = _minIntervals[action] ?? Duration.zero;
    if (lastPlayed != null && now.difference(lastPlayed) < minInterval) {
      return false;
    }

    _lastPlayedAt[action] = now;
    return true;
  }

  Future<void> _play(_SoundAction action) async {
    if (!_canPlay(action)) return;

    final assetPath = _assets[action];
    if (assetPath == null) return;

    final requestId = ++_playRequestId;
    try {
      for (final player in _players.values) {
        await player.stop();
      }

      if (requestId != _playRequestId) return;

      final player = await _playerFor(action);
      await player.play(AssetSource(assetPath));
    } catch (e) {
      developer.log('SoundService: Error playing $assetPath: $e');
    }
  }

  Future<void> playClick() async {
    if (_isMuted) return;
    try {
      HapticFeedback.lightImpact();
      await _play(_SoundAction.click);
    } catch (e) {
      developer.log('SoundService: Error playing click.wav: $e');
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> playSuccess() async {
    if (_isMuted) return;
    HapticFeedback.mediumImpact();
    await _play(_SoundAction.success);
  }

  Future<void> playError() async {
    if (_isMuted) return;
    try {
      // Stronger feedback for errors: two heavy pulses
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.heavyImpact();
      
      await _play(_SoundAction.error);
    } catch (e) {
      developer.log('SoundService: Error.ogg missing or failed.');
    }
  }

  Future<void> playHint() async {
    if (_isMuted) return;
    try {
      HapticFeedback.selectionClick();
      await _play(_SoundAction.hint);
    } catch (e) {
      developer.log('SoundService: Hint.wav missing or failed.');
    }
  }

  Future<void> playToggle() async {
    // Respect the rule: no sound should be made if sound is OFF.
    // This means turning it ON will be silent, but turning it OFF will play once (since it was ON).
    if (_isMuted) return;
    try {
      HapticFeedback.lightImpact();
      await _play(_SoundAction.toggle);
    } catch (e) {
      developer.log('SoundService: Toggle.wav missing or failed.');
    }
  }
}
