/// デザインドキュメント
/// 睡眠記録を保持するためのデータモデル群。
/// - SoundType は音声分類結果の種別を列挙
/// - SoundEvent は検出時刻・継続時間・信頼度などのメタ情報を持つ
/// - SleepSession は就寝から起床までの統計値と WAV ファイルへのパスを保持
/// - toMap/fromMap で永続化やネットワーク送信を想定した変換を提供
enum SoundType {
  snoring, // いびき
  sleepTalk, // 寝言
  cough, // 咳
  apnea, // 無呼吸
  inhale, // 息を吸い込む
  exhale, // 息を吐き出す
  unknown, // 不明
}

/// 睡眠段階を表す列挙体
enum SleepStage {
  wake, // 覚醒
  rem, // レム睡眠
  nrem, // ノンレム睡眠
}

/// 音声データから推定された睡眠段階の時間区間
class SleepStageSegment {
  final DateTime start;
  final DateTime end;
  final SleepStage stage;

  SleepStageSegment({
    required this.start,
    required this.end,
    required this.stage,
  });

  Map<String, dynamic> toMap() {
    return {
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
      'stage': stage.index,
    };
  }

  factory SleepStageSegment.fromMap(Map<String, dynamic> map) {
    return SleepStageSegment(
      start: DateTime.fromMillisecondsSinceEpoch(map['start']),
      end: DateTime.fromMillisecondsSinceEpoch(map['end']),
      stage: SleepStage.values[map['stage']],
    );
  }
}

class SoundEvent {
  final String id;
  final SoundType type;
  final DateTime timestamp;
  final Duration duration;
  final String audioFilePath;
  final double confidence;
  final String? description;

  SoundEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.duration,
    required this.audioFilePath,
    required this.confidence,
    this.description,
  });

  /// データモデルを Map に変換して保存・送信に使用する
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration': duration.inMilliseconds,
      'audioFilePath': audioFilePath,
      'confidence': confidence,
      'description': description,
    };
  }

  /// Map から SoundEvent を生成
  factory SoundEvent.fromMap(Map<String, dynamic> map) {
    return SoundEvent(
      id: map['id'],
      type: SoundType.values[map['type']],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      duration: Duration(milliseconds: map['duration']),
      audioFilePath: map['audioFilePath'],
      confidence: map['confidence'].toDouble(),
      description: map['description'],
    );
  }
}

class SleepSession {
  final String id;
  final DateTime bedTime;
  final DateTime? wakeUpTime;
  final DateTime? sleepStartTime;
  final Duration? timeInBed;
  final Duration? actualSleepTime;
  final double? sleepEfficiency;
  final List<SoundEvent> soundEvents;
  final String audioFilePath;
  final SleepQuality? quality;
  final List<SleepStageSegment> sleepStages;
  final double? osaRisk;

  SleepSession({
    required this.id,
    required this.bedTime,
    this.wakeUpTime,
    this.sleepStartTime,
    this.timeInBed,
    this.actualSleepTime,
    this.sleepEfficiency,
    this.soundEvents = const [],
    required this.audioFilePath,
    this.quality,
    this.sleepStages = const [],
    this.osaRisk,
  });

  /// SleepSession を Map へ変換し永続化に利用
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bedTime': bedTime.millisecondsSinceEpoch,
      'wakeUpTime': wakeUpTime?.millisecondsSinceEpoch,
      'sleepStartTime': sleepStartTime?.millisecondsSinceEpoch,
      'timeInBed': timeInBed?.inMilliseconds,
      'actualSleepTime': actualSleepTime?.inMilliseconds,
      'sleepEfficiency': sleepEfficiency,
      'audioFilePath': audioFilePath,
      'quality': quality?.index,
      'sleepStages': sleepStages.map((e) => e.toMap()).toList(),
      'osaRisk': osaRisk,
    };
  }

  /// Map から SleepSession インスタンスを生成
  factory SleepSession.fromMap(Map<String, dynamic> map) {
    return SleepSession(
      id: map['id'],
      bedTime: DateTime.fromMillisecondsSinceEpoch(map['bedTime']),
      wakeUpTime: map['wakeUpTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['wakeUpTime'])
          : null,
      sleepStartTime: map['sleepStartTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['sleepStartTime'])
          : null,
      timeInBed: map['timeInBed'] != null
          ? Duration(milliseconds: map['timeInBed'])
          : null,
      actualSleepTime: map['actualSleepTime'] != null
          ? Duration(milliseconds: map['actualSleepTime'])
          : null,
      sleepEfficiency: map['sleepEfficiency']?.toDouble(),
      audioFilePath: map['audioFilePath'],
      quality: map['quality'] != null
          ? SleepQuality.values[map['quality']]
          : null,
      sleepStages: map['sleepStages'] != null
          ? (map['sleepStages'] as List)
              .map((e) => SleepStageSegment.fromMap(e))
              .toList()
          : [],
      osaRisk: map['osaRisk']?.toDouble(),
    );
  }
}

enum SleepQuality {
  excellent, // 優秀
  good, // 良い
  fair, // 普通
  poor, // 悪い
}

extension SleepQualityExtension on SleepQuality {
  /// 表示用の日本語文字列を返す
  String get displayName {
    switch (this) {
      case SleepQuality.excellent:
        return '優秀';
      case SleepQuality.good:
        return '良い';
      case SleepQuality.fair:
        return '普通';
      case SleepQuality.poor:
        return '悪い';
    }
  }
}

extension SleepStageExtension on SleepStage {
  /// 表示用の日本語文字列
  String get displayName {
    switch (this) {
      case SleepStage.wake:
        return '覚醒';
      case SleepStage.rem:
        return 'レム睡眠';
      case SleepStage.nrem:
        return 'ノンレム睡眠';
    }
  }
}

extension SoundTypeExtension on SoundType {
  /// 表示用の日本語文字列を返す
  String get displayName {
    switch (this) {
      case SoundType.snoring:
        return 'いびき';
      case SoundType.sleepTalk:
        return '寝言';
      case SoundType.cough:
        return '咳';
      case SoundType.apnea:
        return '無呼吸';
      case SoundType.inhale:
        return '息を吸い込む';
      case SoundType.exhale:
        return '息を吐き出す';
      case SoundType.unknown:
        return '不明';
    }
  }
}
