import 'package:flutter/foundation.dart';
import '../models/sleep_data.dart';
import '../services/audio_recording_service.dart';
import '../services/ai_audio_analysis_service.dart';
import '../services/sleep_quality_analyzer.dart';

class SleepTrackingProvider extends ChangeNotifier {
  final AudioRecordingService _recordingService = AudioRecordingService();
  final AIAudioAnalysisService _analysisService = AIAudioAnalysisService();
  final SleepQualityAnalyzer _qualityAnalyzer = SleepQualityAnalyzer();

  SleepSession? _currentSession;
  List<SleepSession> _sleepHistory = [];
  bool _isRecording = false;
  bool _isAnalyzing = false;
  String? _analysisProgress;
  String? _errorMessage;

  // Getters
  SleepSession? get currentSession => _currentSession;
  List<SleepSession> get sleepHistory => _sleepHistory;
  bool get isRecording => _isRecording;
  bool get isAnalyzing => _isAnalyzing;
  String? get analysisProgress => _analysisProgress;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> initialize() async {
    try {
      await _recordingService.initialize();
    } catch (e) {
      _errorMessage = 'Failed to initialize audio recording: $e';
      notifyListeners();
    }
  }

  Future<bool> startSleepTracking() async {
    try {
      _errorMessage = null;
      _isRecording = true;
      notifyListeners();

      print('Starting sleep tracking...');
      final success = await _recordingService.startRecording();
      print('Recording service start result: $success');

      if (success) {
        _currentSession = SleepSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          bedTime: DateTime.now(),
          audioFilePath: _recordingService.currentRecordingPath!,
        );
        print('Sleep session created successfully');
      } else {
        _isRecording = false;
        _errorMessage = '録音の開始に失敗しました。マイクロフォンの権限を確認してください。';
        print('Failed to start recording - no success from recording service');
      }

      notifyListeners();
      return success;
    } catch (e) {
      _isRecording = false;
      _errorMessage = '睡眠トラッキングの開始中にエラーが発生しました: $e';
      notifyListeners();
      print('Error starting sleep tracking: $e');
      return false;
    }
  }

  Future<void> stopSleepTracking() async {
    try {
      if (!_isRecording || _currentSession == null) return;

      final recordingPath = await _recordingService.stopRecording();
      if (recordingPath != null) {
        final wakeUpTime = DateTime.now();
        final timeInBed = wakeUpTime.difference(_currentSession!.bedTime);

        _currentSession = SleepSession(
          id: _currentSession!.id,
          bedTime: _currentSession!.bedTime,
          wakeUpTime: wakeUpTime,
          timeInBed: timeInBed,
          audioFilePath: recordingPath,
        );

        _isRecording = false;
        notifyListeners();

        // 音声分析を開始
        await _analyzeRecordedAudio();
      }
    } catch (e) {
      print('Error stopping sleep tracking: $e');
      _isRecording = false;
      notifyListeners();
    }
  }

  Future<void> _analyzeRecordedAudio() async {
    if (_currentSession == null) return;

    try {
      _isAnalyzing = true;
      _analysisProgress = '音声を分析中...';
      notifyListeners();

      // AI音声分析を実行（プログレス付き）
      final soundEvents = await _analysisService.analyzeAudioFileWithProgress(
        _currentSession!.audioFilePath,
        onProgress: (progress) {
          _analysisProgress = progress;
          notifyListeners();
        },
      );

      _analysisProgress = '睡眠の質を分析中...';
      notifyListeners();

      // 音響イベントを含むセッションを作成
      final sessionWithEvents = SleepSession(
        id: _currentSession!.id,
        bedTime: _currentSession!.bedTime,
        wakeUpTime: _currentSession!.wakeUpTime,
        timeInBed: _currentSession!.timeInBed,
        soundEvents: soundEvents,
        audioFilePath: _currentSession!.audioFilePath,
      );

      // 睡眠の質を分析
      final analyzedSession = _qualityAnalyzer.analyzeSleepSession(
        sessionWithEvents,
      );

      _currentSession = analyzedSession;
      _sleepHistory.add(analyzedSession);

      _isAnalyzing = false;
      _analysisProgress = null;
      notifyListeners();
    } catch (e) {
      print('Error analyzing audio: $e');
      _isAnalyzing = false;
      _analysisProgress = null;
      notifyListeners();
    }
  }

  List<SoundEvent> getSoundEventsByType(SoundType type) {
    if (_currentSession == null) return [];
    return _currentSession!.soundEvents
        .where((event) => event.type == type)
        .toList();
  }

  Map<SoundType, int> getSoundEventCounts() {
    if (_currentSession == null) return {};

    final counts = <SoundType, int>{};
    for (final type in SoundType.values) {
      counts[type] = _currentSession!.soundEvents
          .where((event) => event.type == type)
          .length;
    }
    return counts;
  }

  Map<String, dynamic>? getCurrentSleepAnalytics() {
    if (_currentSession == null) return null;
    return _qualityAnalyzer.getSleepAnalytics(_currentSession!);
  }

  void clearCurrentSession() {
    _currentSession = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _recordingService.dispose();
    super.dispose();
  }
}
