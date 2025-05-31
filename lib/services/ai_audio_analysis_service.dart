/// デザインドキュメント
/// 音声ファイルから睡眠関連イベントを抽出する AI 解析サービス。
/// - 本リポジトリでは外部 API を呼び出さず乱数で擬似的な結果を生成
/// - analyzeAudioFileWithProgress は進捗コールバックを提供し UI との連携を容易にする
/// - 実運用では OpenAI Whisper 等のクラウド API との置き換えを想定
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import '../models/sleep_data.dart';

class AIAudioAnalysisService {
  static final AIAudioAnalysisService _instance =
      AIAudioAnalysisService._internal();
  factory AIAudioAnalysisService() => _instance;
  AIAudioAnalysisService._internal();

  // 実際の実装では、OpenAI Whisper API やGoogle Cloud Speech-to-Text APIなどを使用します
  // ここでは簡単なモックAPIを示しています

  /// 音声ファイルを解析してイベント一覧を返す
  Future<List<SoundEvent>> analyzeAudioFile(String audioFilePath) async {
    try {
      // ファイルが存在するかチェック
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: $audioFilePath');
      }

      return await _analyzeWavFile(audioFilePath);

      // 実際のAPI実装例（コメントアウト）:
      /*
      final request = http.MultipartRequest('POST', Uri.parse(_apiEndpoint));
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.files.add(await http.MultipartFile.fromPath('audio', audioFilePath));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final result = json.decode(responseData);
        return _parseAnalysisResult(result, audioFilePath);
      } else {
        throw Exception('AI analysis failed: ${response.statusCode}');
      }
      */
    } catch (e) {
      print('Error analyzing audio: $e');
      rethrow;
    }
  }

  // プログレス付きの分析関数
  /// 解析処理の進行状況をコールバックで通知
  Future<List<SoundEvent>> analyzeAudioFileWithProgress(
    String audioFilePath, {
    Function(String)? onProgress,
  }) async {
    try {
      // ファイルが存在するかチェック
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: $audioFilePath');
      }

      onProgress?.call('音声ファイルを読み込み中...');
      await Future.delayed(const Duration(seconds: 1));

      onProgress?.call('AI分析を開始中...');
      await Future.delayed(const Duration(seconds: 1));

      onProgress?.call('音声パターンを解析中...');
      await Future.delayed(const Duration(seconds: 2));

      onProgress?.call('睡眠イベントを分類中...');
      final events = await _analyzeWavFile(audioFilePath);

      onProgress?.call('分析結果を処理中...');
      await Future.delayed(const Duration(milliseconds: 500));

      onProgress?.call('分析完了！');
      return events;
    } catch (e) {
      onProgress?.call('分析エラー: $e');
      print('Error analyzing audio with progress: $e');
      rethrow;
    }
  }

  /// ダミーの分析結果を生成するモック実装
  Future<List<SoundEvent>> _mockAnalyzeAudio(String audioFilePath) async {
    // モック分析 - 実際の実装では本物のAI分析を行います
    await Future.delayed(const Duration(seconds: 2)); // 分析時間をシミュレート

    final events = <SoundEvent>[];
    final baseTime = DateTime.now().subtract(const Duration(hours: 8));

    // いびきのイベント
    events.add(
      SoundEvent(
        id: '1',
        type: SoundType.snoring,
        timestamp: baseTime.add(const Duration(minutes: 30)),
        duration: const Duration(seconds: 15),
        audioFilePath: audioFilePath,
        confidence: 0.85,
        description: '軽いいびき',
      ),
    );

    events.add(
      SoundEvent(
        id: '2',
        type: SoundType.snoring,
        timestamp: baseTime.add(const Duration(hours: 2)),
        duration: const Duration(seconds: 25),
        audioFilePath: audioFilePath,
        confidence: 0.92,
        description: '強いいびき',
      ),
    );

    // 寝言のイベント
    events.add(
      SoundEvent(
        id: '3',
        type: SoundType.sleepTalk,
        timestamp: baseTime.add(const Duration(hours: 3, minutes: 15)),
        duration: const Duration(seconds: 8),
        audioFilePath: audioFilePath,
        confidence: 0.78,
        description: '小声での寝言',
      ),
    );

    // 咳のイベント
    events.add(
      SoundEvent(
        id: '4',
        type: SoundType.cough,
        timestamp: baseTime.add(const Duration(hours: 5)),
        duration: const Duration(seconds: 3),
        audioFilePath: audioFilePath,
        confidence: 0.95,
        description: '軽い咳',
      ),
    );

    // 無呼吸のイベント
    events.add(
      SoundEvent(
        id: '5',
        type: SoundType.apnea,
        timestamp: baseTime.add(const Duration(hours: 4, minutes: 30)),
        duration: const Duration(seconds: 12),
        audioFilePath: audioFilePath,
        confidence: 0.73,
        description: '軽度の無呼吸',
      ),
    );

    // 呼吸音のイベント
    for (int i = 0; i < 20; i++) {
      events.add(
        SoundEvent(
          id: 'inhale_$i',
          type: SoundType.inhale,
          timestamp: baseTime.add(Duration(minutes: i * 20)),
          duration: const Duration(seconds: 2),
          audioFilePath: audioFilePath,
          confidence: 0.60 + (i % 3) * 0.1,
          description: '通常の吸気音',
        ),
      );

      events.add(
        SoundEvent(
          id: 'exhale_$i',
          type: SoundType.exhale,
          timestamp: baseTime.add(Duration(minutes: i * 20 + 2)),
          duration: const Duration(seconds: 2),
          audioFilePath: audioFilePath,
          confidence: 0.65 + (i % 3) * 0.1,
          description: '通常の呼気音',
        ),
      );
    }

    return events;
  }

  /// WAV ファイルを読み込み簡易的な特徴量でイベント抽出
  Future<List<SoundEvent>> _analyzeWavFile(String audioFilePath) async {
    final file = File(audioFilePath);
    final bytes = await file.readAsBytes();
    if (bytes.length < 44) {
      throw Exception('Invalid WAV file');
    }

    final header = bytes.buffer.asByteData();
    final sampleRate = header.getUint32(24, Endian.little);
    final bitsPerSample = header.getUint16(34, Endian.little);
    final dataSize = header.getUint32(40, Endian.little);
    final bytesPerSample = bitsPerSample ~/ 8;
    final totalSamples = dataSize ~/ bytesPerSample;

    final samples = List<int>.generate(totalSamples, (i) {
      final index = 44 + i * bytesPerSample;
      return header.getInt16(index, Endian.little);
    });

    // 開始時間をファイル名から推定
    final baseName = p.basenameWithoutExtension(audioFilePath);
    DateTime baseTime;
    try {
      final ts = int.parse(baseName.split('_').last);
      baseTime = DateTime.fromMillisecondsSinceEpoch(ts);
    } catch (_) {
      baseTime = DateTime.now();
    }

    final events = <SoundEvent>[];
    final windowSize = sampleRate; // 1秒
    int silentSamples = 0;

    for (int i = 0; i < samples.length; i += windowSize) {
      final end = min(i + windowSize, samples.length);
      final segment = samples.sublist(i, end);
      final avgAmplitude =
          segment.fold<int>(0, (p, s) => p + s.abs()) / segment.length;

      final timestamp = baseTime.add(Duration(seconds: i ~/ sampleRate));

      if (avgAmplitude > 12000) {
        events.add(
          SoundEvent(
            id: 'cough_$i',
            type: SoundType.cough,
            timestamp: timestamp,
            duration: Duration(seconds: (end - i) ~/ sampleRate),
            audioFilePath: audioFilePath,
            confidence: 0.8,
            description: '咳音',
          ),
        );
        silentSamples = 0;
      } else if (avgAmplitude > 6000) {
        events.add(
          SoundEvent(
            id: 'snore_$i',
            type: SoundType.snoring,
            timestamp: timestamp,
            duration: Duration(seconds: (end - i) ~/ sampleRate),
            audioFilePath: audioFilePath,
            confidence: 0.7,
            description: 'いびき音',
          ),
        );
        silentSamples = 0;
      } else if (avgAmplitude < 500) {
        silentSamples += segment.length;
        if (silentSamples >= sampleRate * 10) {
          final apneaStart = timestamp.subtract(Duration(seconds: 10));
          events.add(
            SoundEvent(
              id: 'apnea_$i',
              type: SoundType.apnea,
              timestamp: apneaStart,
              duration: const Duration(seconds: 10),
              audioFilePath: audioFilePath,
              confidence: 0.6,
              description: '無呼吸疑い',
            ),
          );
          silentSamples = 0;
        }
      } else if (avgAmplitude > 3000) {
        events.add(
          SoundEvent(
            id: 'talk_$i',
            type: SoundType.sleepTalk,
            timestamp: timestamp,
            duration: Duration(seconds: (end - i) ~/ sampleRate),
            audioFilePath: audioFilePath,
            confidence: 0.5,
            description: '寝言音',
          ),
        );
        silentSamples = 0;
      } else {
        events.add(
          SoundEvent(
            id: 'breath_$i',
            type: i % 2 == 0 ? SoundType.inhale : SoundType.exhale,
            timestamp: timestamp,
            duration: Duration(seconds: (end - i) ~/ sampleRate),
            audioFilePath: audioFilePath,
            confidence: 0.4,
            description: '呼吸音',
          ),
        );
        silentSamples = 0;
      }
    }

    return events;
  }
}
