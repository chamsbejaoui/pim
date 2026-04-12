import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';

enum CommentaryEvent { intro, sprint, collision, intensity, injury, end }

class CommentaryService {
  CommentaryService({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;
  final AudioPlayer stadiumPlayer = AudioPlayer();
  final AudioPlayer commentaryPlayer = AudioPlayer();
  final AudioPlayer introPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _shouldLoopStadium = false;
  StreamSubscription<void>? _introCompleteSub;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await stadiumPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    await commentaryPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    await introPlayer.setPlayerMode(PlayerMode.mediaPlayer);

    final context = AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: [AVAudioSessionOptions.mixWithOthers],
      ),
    );

    await stadiumPlayer.setAudioContext(context);
    await commentaryPlayer.setAudioContext(context);
    await introPlayer.setAudioContext(context);

    await stadiumPlayer.setReleaseMode(ReleaseMode.loop);
    await commentaryPlayer.setReleaseMode(ReleaseMode.stop);
    await introPlayer.setReleaseMode(ReleaseMode.stop);
    _isInitialized = true;
  }

  Future<void> ensureInitialized() async {
    await initialize();
  }

  Future<void> startStadiumLoop() async {
    await ensureInitialized();
    _shouldLoopStadium = true;
    await stadiumPlayer.stop();
    await introPlayer.stop();
    _introCompleteSub?.cancel();

    final introPlayed = await _safePlayWithResult(
      introPlayer,
      AssetSource('audio/intro_hafid_derraji.mp3'),
      volume: 1.0,
    );

    if (!introPlayed) {
      await _safePlay(
        stadiumPlayer,
        AssetSource('audio/simulation_bg.mp3'),
        volume: 0.8,
      );
      return;
    }

    _introCompleteSub = introPlayer.onPlayerComplete.listen((_) async {
      _introCompleteSub?.cancel();
      if (!_shouldLoopStadium) {
        return;
      }
      await _safePlay(
        stadiumPlayer,
        AssetSource('audio/simulation_bg.mp3'),
        volume: 0.8,
      );
    });
  }

  Future<void> playWhistle() async {
    await ensureInitialized();
    await commentaryPlayer.stop();
    await _safePlay(
      commentaryPlayer,
      AssetSource(
        'audio/freesound_community-referee-whistle-blow-gymnasium-6320.mp3',
      ),
      volume: 1.0,
    );
  }

  Future<void> stopStadiumLoop() async {
    _shouldLoopStadium = false;
    _introCompleteSub?.cancel();
    await introPlayer.stop();
    await stadiumPlayer.stop();
  }

  Future<void> playEvent(CommentaryEvent event) async {
    await ensureInitialized();
    final clip = _pickClip(event);
    if (clip == null) {
      return;
    }
    await commentaryPlayer.stop();
    await _safePlay(commentaryPlayer, AssetSource(clip), volume: 1.0);
  }

  String randomLine(CommentaryEvent event) {
    final options = _commentaryLines[event] ?? const [];
    if (options.isEmpty) {
      return '';
    }
    return options[_random.nextInt(options.length)];
  }

  void dispose() {
    _introCompleteSub?.cancel();
    stadiumPlayer.dispose();
    commentaryPlayer.dispose();
    introPlayer.dispose();
  }

  String? _pickClip(CommentaryEvent event) {
    switch (event) {
      case CommentaryEvent.intro:
        return null;
      case CommentaryEvent.sprint:
        return null;
      case CommentaryEvent.collision:
        return null;
      case CommentaryEvent.intensity:
        return null;
      case CommentaryEvent.injury:
        return null;
      case CommentaryEvent.end:
        return null;
    }
  }

  Future<void> _safePlay(
    AudioPlayer player,
    Source source, {
    required double volume,
  }) async {
    try {
      await player.setSource(source);
      await player.setVolume(volume);
      await player.resume();
    } catch (_) {
      // Ignore audio errors so simulation keeps running.
    }
  }

  Future<bool> _safePlayWithResult(
    AudioPlayer player,
    Source source, {
    required double volume,
  }) async {
    try {
      await player.setSource(source);
      await player.setVolume(volume);
      await player.resume();
      return true;
    } catch (_) {
      return false;
    }
  }
}

const Map<CommentaryEvent, List<String>> _commentaryLines = {
  CommentaryEvent.intro: [
    'Welcome to the match! The energy is electric tonight!',
  ],
  CommentaryEvent.sprint: [
    'What an explosive sprint from the Odin winger!',
    'He is flying down the flank with serious speed!',
    'Lightning pace on display from Odin Club!',
  ],
  CommentaryEvent.collision: [
    'Oh that is a heavy challenge in midfield!',
    'Crunching contact there, both sides feeling it!',
    'A hard collision, and the crowd reacts instantly!',
  ],
  CommentaryEvent.intensity: [
    'The tempo is rising, fatigue levels are climbing!',
    'High intensity phase now, the pace is relentless!',
    'Odin are pushing hard, this is a fierce spell!',
  ],
  CommentaryEvent.injury: [
    'This does not look good for Odin Club!',
    'Trouble here, an Odin player is down!',
    'Injury concern, the medical team is on alert!',
  ],
  CommentaryEvent.end: [
    'And that is the final whistle in this intense simulation match!',
  ],
};
