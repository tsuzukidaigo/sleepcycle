import '../models/sleep_data.dart';

class SleepQualityAnalyzer {
  static final SleepQualityAnalyzer _instance =
      SleepQualityAnalyzer._internal();
  factory SleepQualityAnalyzer() => _instance;
  SleepQualityAnalyzer._internal();

  SleepSession analyzeSleepSession(SleepSession session) {
    // 睡眠効率を計算
    final sleepEfficiency = _calculateSleepEfficiency(session);

    // 睡眠の質を判定
    final quality = _determineSleepQuality(session, sleepEfficiency);

    // 実際の睡眠時間を推定
    final actualSleepTime = _estimateActualSleepTime(session);

    // 睡眠開始時間を推定
    final sleepStartTime = _estimateSleepStartTime(session);

    return SleepSession(
      id: session.id,
      bedTime: session.bedTime,
      wakeUpTime: session.wakeUpTime,
      sleepStartTime: sleepStartTime,
      timeInBed: session.timeInBed,
      actualSleepTime: actualSleepTime,
      sleepEfficiency: sleepEfficiency,
      soundEvents: session.soundEvents,
      audioFilePath: session.audioFilePath,
      quality: quality,
    );
  }

  double _calculateSleepEfficiency(SleepSession session) {
    if (session.timeInBed == null || session.timeInBed!.inMinutes == 0) {
      return 0.0;
    }

    // 実際の睡眠時間を推定
    final actualSleepTime = _estimateActualSleepTime(session);
    if (actualSleepTime == null) {
      return 0.0;
    }

    // 睡眠効率 = (実際の睡眠時間 / ベッドにいた時間) × 100
    return (actualSleepTime.inMinutes / session.timeInBed!.inMinutes) * 100;
  }

  Duration? _estimateActualSleepTime(SleepSession session) {
    if (session.timeInBed == null) return null;

    // 音響イベントから睡眠の中断を分析
    final disruptiveEvents = session.soundEvents.where((event) {
      return event.type == SoundType.snoring ||
          event.type == SoundType.cough ||
          event.type == SoundType.apnea ||
          event.type == SoundType.sleepTalk;
    }).toList();

    // 中断時間を計算
    final totalDisruptiveTime = disruptiveEvents.fold<Duration>(
      Duration.zero,
      (total, event) => total + event.duration,
    );

    // いびきや無呼吸の頻度による睡眠の質の低下を考慮
    final snoringEvents = session.soundEvents
        .where((e) => e.type == SoundType.snoring)
        .length;
    final apneaEvents = session.soundEvents
        .where((e) => e.type == SoundType.apnea)
        .length;

    // 睡眠の質の低下係数
    double qualityFactor = 1.0;
    if (snoringEvents > 10) qualityFactor -= 0.1;
    if (snoringEvents > 20) qualityFactor -= 0.1;
    if (apneaEvents > 5) qualityFactor -= 0.15;
    if (apneaEvents > 10) qualityFactor -= 0.2;

    // 基本的な睡眠時間から中断時間を引き、質の低下を考慮
    final baseSleepTime =
        session.timeInBed!.inMinutes - totalDisruptiveTime.inMinutes;
    final adjustedSleepTime = (baseSleepTime * qualityFactor).round();

    return Duration(
      minutes: adjustedSleepTime.clamp(0, session.timeInBed!.inMinutes),
    );
  }

  DateTime? _estimateSleepStartTime(SleepSession session) {
    if (session.soundEvents.isEmpty) {
      // 音響イベントがない場合は、ベッドに入ってから15分後と仮定
      return session.bedTime.add(const Duration(minutes: 15));
    }

    // 呼吸音が安定してくる時間を睡眠開始とみなす
    final breathingEvents = session.soundEvents.where((event) {
      return event.type == SoundType.inhale || event.type == SoundType.exhale;
    }).toList();

    if (breathingEvents.isNotEmpty) {
      breathingEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // 最初の安定した呼吸パターンが現れる時間
      for (int i = 0; i < breathingEvents.length - 5; i++) {
        final windowEvents = breathingEvents.skip(i).take(6).toList();
        final avgInterval = _calculateAverageInterval(windowEvents);

        // 呼吸間隔が安定している（3-6秒）場合、睡眠開始とみなす
        if (avgInterval >= 3 && avgInterval <= 6) {
          return windowEvents.first.timestamp;
        }
      }
    }

    // デフォルトはベッドに入ってから20分後
    return session.bedTime.add(const Duration(minutes: 20));
  }

  double _calculateAverageInterval(List<SoundEvent> events) {
    if (events.length < 2) return 0;

    double totalInterval = 0;
    for (int i = 1; i < events.length; i++) {
      totalInterval += events[i].timestamp
          .difference(events[i - 1].timestamp)
          .inSeconds;
    }

    return totalInterval / (events.length - 1);
  }

  SleepQuality _determineSleepQuality(
    SleepSession session,
    double sleepEfficiency,
  ) {
    int score = 100;

    // 睡眠効率による評価
    if (sleepEfficiency < 70)
      score -= 30;
    else if (sleepEfficiency < 80)
      score -= 20;
    else if (sleepEfficiency < 90)
      score -= 10;

    // 音響イベントによる評価
    final snoringCount = session.soundEvents
        .where((e) => e.type == SoundType.snoring)
        .length;
    final apneaCount = session.soundEvents
        .where((e) => e.type == SoundType.apnea)
        .length;
    final coughCount = session.soundEvents
        .where((e) => e.type == SoundType.cough)
        .length;
    final sleepTalkCount = session.soundEvents
        .where((e) => e.type == SoundType.sleepTalk)
        .length;

    // いびきの影響
    if (snoringCount > 20)
      score -= 20;
    else if (snoringCount > 10)
      score -= 15;
    else if (snoringCount > 5)
      score -= 10;

    // 無呼吸の影響
    if (apneaCount > 10)
      score -= 25;
    else if (apneaCount > 5)
      score -= 20;
    else if (apneaCount > 2)
      score -= 15;

    // 咳の影響
    if (coughCount > 10)
      score -= 15;
    else if (coughCount > 5)
      score -= 10;

    // 寝言の影響
    if (sleepTalkCount > 5) score -= 10;

    // 睡眠時間による評価
    if (session.timeInBed != null) {
      final hoursInBed = session.timeInBed!.inHours;
      if (hoursInBed < 6)
        score -= 20;
      else if (hoursInBed < 7)
        score -= 10;
      else if (hoursInBed > 10)
        score -= 10;
    }

    // スコアに基づいて睡眠の質を判定
    if (score >= 85) return SleepQuality.excellent;
    if (score >= 70) return SleepQuality.good;
    if (score >= 55) return SleepQuality.fair;
    return SleepQuality.poor;
  }

  Map<String, dynamic> getSleepAnalytics(SleepSession session) {
    final snoringEvents = session.soundEvents
        .where((e) => e.type == SoundType.snoring)
        .toList();
    final apneaEvents = session.soundEvents
        .where((e) => e.type == SoundType.apnea)
        .toList();
    final coughEvents = session.soundEvents
        .where((e) => e.type == SoundType.cough)
        .toList();
    final sleepTalkEvents = session.soundEvents
        .where((e) => e.type == SoundType.sleepTalk)
        .toList();

    final totalSnoringDuration = snoringEvents.fold<Duration>(
      Duration.zero,
      (total, event) => total + event.duration,
    );

    final totalApneaDuration = apneaEvents.fold<Duration>(
      Duration.zero,
      (total, event) => total + event.duration,
    );

    return {
      'snoringCount': snoringEvents.length,
      'snoringDuration': totalSnoringDuration,
      'apneaCount': apneaEvents.length,
      'apneaDuration': totalApneaDuration,
      'coughCount': coughEvents.length,
      'sleepTalkCount': sleepTalkEvents.length,
      'sleepEfficiency': session.sleepEfficiency,
      'timeInBed': session.timeInBed,
      'actualSleepTime': session.actualSleepTime,
      'quality': session.quality,
    };
  }
}
