import 'dart:io';
import 'dart:math';

import '../models/sleep_data.dart';

/// HomeSleepNet を用いて睡眠段階を推定するサービス
/// 現状はダミー実装でランダムな段階を返す。
class HomeSleepNetService {
  static final HomeSleepNetService _instance = HomeSleepNetService._internal();
  factory HomeSleepNetService() => _instance;
  HomeSleepNetService._internal();

  Future<List<SleepStageSegment>> classifyStages(String audioPath) async {
    final file = File(audioPath);
    if (!await file.exists()) {
      throw Exception('Audio file not found: $audioPath');
    }

    final rand = Random();
    final startTime = DateTime.now();
    // 30分単位で6時間分のダミーデータを生成
    final segments = <SleepStageSegment>[];
    DateTime current = startTime;
    for (int i = 0; i < 12; i++) {
      final stage = SleepStage.values[rand.nextInt(SleepStage.values.length)];
      final end = current.add(const Duration(minutes: 30));
      segments.add(SleepStageSegment(start: current, end: end, stage: stage));
      current = end;
    }
    return segments;
  }
}
