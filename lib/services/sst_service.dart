import 'dart:io';
import 'dart:math';

/// Snore Shifted-window Transformer を利用してOSA危険度を算出するサービス
/// ここでは疑似的なスコアを返すのみ
class SSTService {
  static final SSTService _instance = SSTService._internal();
  factory SSTService() => _instance;
  SSTService._internal();

  Future<double> estimateRisk(String audioPath) async {
    final file = File(audioPath);
    if (!await file.exists()) {
      throw Exception('Audio file not found: $audioPath');
    }
    final rand = Random();
    return rand.nextDouble(); // 0.0 - 1.0 のリスク値
  }
}
