/// デザインドキュメント
/// 睡眠効率などの統計値を可視化する画面。
/// - SleepTrackingProvider から取得した SleepSession をもとに描画
/// - fl_chart を利用し時間推移やイベント頻度をグラフ表示
/// - 週次・月次の比較分析機能を追加できるよう拡張性を確保
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/sleep_tracking_provider.dart';
import '../models/sleep_data.dart';

class SleepAnalysisScreen extends StatelessWidget {
  const SleepAnalysisScreen({super.key});

  @override
  /// 分析画面のメインUIを構築
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('睡眠分析'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<SleepTrackingProvider>(
        builder: (context, provider, child) {
          final session = provider.currentSession;
          if (session == null) {
            return const Center(
              child: Text(
                '分析する睡眠データがありません',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }

          final analytics = provider.getCurrentSleepAnalytics();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(session, analytics),
                const SizedBox(height: 24),
                _buildSoundEventsChart(session),
                const SizedBox(height: 24),
                _buildSleepTimelineChart(session),
                const SizedBox(height: 24),
                _buildRecommendations(session, analytics),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 睡眠の質サマリーカード
  Widget _buildSummaryCard(
    SleepSession session,
    Map<String, dynamic>? analytics,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4A90E2).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getQualityIcon(session.quality),
                size: 32,
                color: _getQualityColor(session.quality),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '睡眠の質: ${session.quality?.displayName ?? "分析中"}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (session.sleepEfficiency != null)
                      Text(
                        '睡眠効率: ${session.sleepEfficiency!.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAnalyticsSummary(analytics),
        ],
      ),
    );
  }

  /// グラフ下部に表示する分析値のまとめ
  Widget _buildAnalyticsSummary(Map<String, dynamic>? analytics) {
    if (analytics == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsItem(
                'いびき',
                '${analytics['snoringCount']}回',
                Icons.volume_up,
              ),
            ),
            Expanded(
              child: _buildAnalyticsItem(
                '無呼吸',
                '${analytics['apneaCount']}回',
                Icons.air,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsItem(
                '咳',
                '${analytics['coughCount']}回',
                Icons.sick,
              ),
            ),
            Expanded(
              child: _buildAnalyticsItem(
                '寝言',
                '${analytics['sleepTalkCount']}回',
                Icons.chat_bubble_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ラベルと値を表示する小さなカード
  Widget _buildAnalyticsItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90E2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4A90E2)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 音響イベントの割合を円グラフで表示
  Widget _buildSoundEventsChart(SleepSession session) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4A90E2).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '音響イベント分布',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: _buildSoundEventsPieChart(session)),
        ],
      ),
    );
  }

  /// 音響イベントの種類別パイチャート
  Widget _buildSoundEventsPieChart(SleepSession session) {
    final eventCounts = <SoundType, int>{};
    for (final event in session.soundEvents) {
      eventCounts[event.type] = (eventCounts[event.type] ?? 0) + 1;
    }

    if (eventCounts.isEmpty) {
      return const Center(
        child: Text(
          '音響イベントが検出されませんでした',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final sections = eventCounts.entries.map((entry) {
      final percentage = (entry.value / session.soundEvents.length) * 100;
      return PieChartSectionData(
        color: _getSoundTypeColor(entry.key),
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: eventCounts.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getSoundTypeColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.key.displayName}\n${entry.value}回',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// タイムライングラフを包むコンテナ
  Widget _buildSleepTimelineChart(SleepSession session) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4A90E2).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '睡眠タイムライン',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: _buildTimelineChart(session)),
        ],
      ),
    );
  }

  /// イベント発生時刻を折れ線で描画
  Widget _buildTimelineChart(SleepSession session) {
    if (session.soundEvents.isEmpty) {
      return const Center(
        child: Text('タイムラインデータがありません', style: TextStyle(color: Colors.white70)),
      );
    }

    // 時間軸に沿ってイベントをプロット
    final sortedEvents = session.soundEvents.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final spots = <FlSpot>[];
    final startTime = session.bedTime.millisecondsSinceEpoch.toDouble();

    for (int i = 0; i < sortedEvents.length; i++) {
      final event = sortedEvents[i];
      final x =
          (event.timestamp.millisecondsSinceEpoch - startTime) /
          (1000 * 60 * 60); // 時間単位
      spots.add(FlSpot(x, _getSoundTypeValue(event.type)));
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: session.timeInBed?.inHours.toDouble() ?? 8,
        minY: 0,
        maxY: 6,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final type = _getValueSoundType(value.toInt());
                return Text(
                  type.displayName,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                );
              },
              reservedSize: 60,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white24),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.white24, strokeWidth: 0.5);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.white24, strokeWidth: 0.5);
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: const Color(0xFF4A90E2),
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final event = sortedEvents[index];
                return FlDotCirclePainter(
                  radius: 4,
                  color: _getSoundTypeColor(event.type),
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 睡眠改善のヒントを表示するウィジェット
  Widget _buildRecommendations(
    SleepSession session,
    Map<String, dynamic>? analytics,
  ) {
    final recommendations = _generateRecommendations(session, analytics);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4A90E2).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '改善のアドバイス',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...recommendations.map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Color(0xFFF39C12),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 分析結果からユーザーへのアドバイス文を生成
  List<String> _generateRecommendations(
    SleepSession session,
    Map<String, dynamic>? analytics,
  ) {
    final recommendations = <String>[];

    if (analytics != null) {
      final snoringCount = analytics['snoringCount'] as int;
      final apneaCount = analytics['apneaCount'] as int;
      final sleepEfficiency = analytics['sleepEfficiency'] as double?;

      if (snoringCount > 10) {
        recommendations.add('いびきが多く検出されました。横向きで寝る、減量、アルコールを控えることを試してみてください。');
      }

      if (apneaCount > 5) {
        recommendations.add('無呼吸イベントが多く発生しています。医師に相談することを強くお勧めします。');
      }

      if (sleepEfficiency != null && sleepEfficiency < 85) {
        recommendations.add('睡眠効率が低下しています。就寝前のスクリーン時間を減らし、リラックスできる環境を作りましょう。');
      }
    }

    if (session.timeInBed != null) {
      if (session.timeInBed!.inHours < 7) {
        recommendations.add('睡眠時間が不足しています。7-9時間の睡眠を心がけましょう。');
      } else if (session.timeInBed!.inHours > 9) {
        recommendations.add('睡眠時間が長すぎる可能性があります。規則正しい睡眠スケジュールを維持しましょう。');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('良い睡眠が取れています！この調子で規則正しい睡眠習慣を続けましょう。');
    }

    return recommendations;
  }

  /// 評価に応じた色を返す
  Color _getQualityColor(SleepQuality? quality) {
    switch (quality) {
      case SleepQuality.excellent:
        return const Color(0xFF27AE60);
      case SleepQuality.good:
        return const Color(0xFF4A90E2);
      case SleepQuality.fair:
        return const Color(0xFFF39C12);
      case SleepQuality.poor:
        return const Color(0xFFE74C3C);
      default:
        return Colors.white;
    }
  }

  /// 評価に応じたアイコンを返す
  IconData _getQualityIcon(SleepQuality? quality) {
    switch (quality) {
      case SleepQuality.excellent:
        return Icons.star;
      case SleepQuality.good:
        return Icons.thumb_up;
      case SleepQuality.fair:
        return Icons.trending_flat;
      case SleepQuality.poor:
        return Icons.thumb_down;
      default:
        return Icons.help_outline;
    }
  }

  /// サウンド種別ごとの表示色
  Color _getSoundTypeColor(SoundType type) {
    switch (type) {
      case SoundType.snoring:
        return const Color(0xFFE74C3C);
      case SoundType.sleepTalk:
        return const Color(0xFF9B59B6);
      case SoundType.cough:
        return const Color(0xFFF39C12);
      case SoundType.apnea:
        return const Color(0xFF34495E);
      case SoundType.inhale:
        return const Color(0xFF3498DB);
      case SoundType.exhale:
        return const Color(0xFF2ECC71);
      case SoundType.unknown:
        return const Color(0xFF95A5A6);
    }
  }

  /// 折れ線グラフ用にサウンド種別を数値化
  double _getSoundTypeValue(SoundType type) {
    switch (type) {
      case SoundType.snoring:
        return 5;
      case SoundType.sleepTalk:
        return 4;
      case SoundType.cough:
        return 3;
      case SoundType.apnea:
        return 2;
      case SoundType.inhale:
        return 1;
      case SoundType.exhale:
        return 1;
      case SoundType.unknown:
        return 0;
    }
  }

  /// 数値からサウンド種別を逆変換
  SoundType _getValueSoundType(int value) {
    switch (value) {
      case 5:
        return SoundType.snoring;
      case 4:
        return SoundType.sleepTalk;
      case 3:
        return SoundType.cough;
      case 2:
        return SoundType.apnea;
      case 1:
        return SoundType.inhale;
      default:
        return SoundType.unknown;
    }
  }
}
