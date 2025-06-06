/// デザインドキュメント
/// マイク入力の録音を担当するサービス。
/// - flutter_sound を用いて 16bit WAV 形式で保存
/// - startRecording/stopRecording で録音ファイルのパスと開始時刻を管理
/// - アプリ内で単一のインスタンスを共有する Singleton 構成
/// - 将来的にはバックグラウンド録音や圧縮フォーマット対応を検討
import 'dart:async';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AudioRecordingService {
  static final AudioRecordingService _instance =
      AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  FlutterSoundRecorder? _recorder;
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;
  DateTime? get recordingStartTime => _recordingStartTime;

  /// レコーダーのインスタンスを生成します
  /// 実際の openRecorder は権限取得後に行うため
  /// ここではインスタンス生成のみを行います
  Future<void> initialize() async {
    _recorder = FlutterSoundRecorder();
  }

  /// 録音用セッションを初期化します
  Future<bool> _ensureRecorderInitialized() async {
    if (_isRecorderInitialized) return true;
    try {
      _recorder ??= FlutterSoundRecorder();
      await _recorder!.openRecorder();
      _isRecorderInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing recorder: $e');
      return false;
    }
  }

  /// 録音ファイルを保存するパスを生成
  Future<String> _getRecordingPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory(path.join(directory.path, 'recordings'));

    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(recordingsDir.path, 'sleep_session_$timestamp.wav');
  }

  /// マイク録音を開始し成功可否を返します
  Future<bool> startRecording() async {
    if (_isRecording) return false;

    try {
      // Permission check is now handled by the caller (PermissionHelper)
      // to avoid duplicate permission requests

      // Ensure recorder is ready now that permission is granted
      final ready = await _ensureRecorderInitialized();
      if (!ready) return false;

      _currentRecordingPath = await _getRecordingPath();
      _recordingStartTime = DateTime.now();

      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.pcm16WAV,
        bitRate: 128000,
        sampleRate: 44100,
      );

      _isRecording = true;
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  /// 録音を停止してファイルパスを返します
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      await _recorder!.stopRecorder();
      _isRecording = false;

      final recordingPath = _currentRecordingPath;
      _currentRecordingPath = null;
      _recordingStartTime = null;

      return recordingPath;
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  /// 後始末としてレコーダーを解放
  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
    await _recorder?.closeRecorder();
    _recorder = null;
  }
}
