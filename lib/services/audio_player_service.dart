/// デザインドキュメント
/// 端末上の音声ファイルを再生するためのラッパーサービス。
/// - just_audio パッケージを利用し再生、停止、シークを管理
/// - Singleton パターンでインスタンスを共有しストリームで状態更新を通知
/// - 波形表示や速度変更機能など拡張の余地を残している
import 'dart:io';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  String? _currentAudioPath;
  bool _isPlaying = false;
  Duration? _currentPosition;
  Duration? _totalDuration;

  bool get isPlaying => _isPlaying;
  Duration? get currentPosition => _currentPosition;
  Duration? get totalDuration => _totalDuration;
  String? get currentAudioPath => _currentAudioPath;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> initialize() async {
    // プレイヤーの状態変更を監視
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
    });

    _player.positionStream.listen((position) {
      _currentPosition = position;
    });

    _player.durationStream.listen((duration) {
      _totalDuration = duration;
    });
  }

  Future<bool> loadAudio(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: $audioPath');
      }

      await _player.setFilePath(audioPath);
      _currentAudioPath = audioPath;
      return true;
    } catch (e) {
      print('Error loading audio: $e');
      return false;
    }
  }

  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      await _player.seek(Duration.zero);
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print('Error seeking audio: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  Future<void> playSegment(
    String audioPath,
    Duration start,
    Duration duration,
  ) async {
    try {
      await loadAudio(audioPath);
      await seek(start);
      await play();

      // 指定された時間後に停止
      Future.delayed(duration, () {
        pause();
      });
    } catch (e) {
      print('Error playing audio segment: $e');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
