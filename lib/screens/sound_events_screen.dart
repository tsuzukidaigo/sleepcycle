/// デザインドキュメント
/// 検出された音声イベントを種別ごとのタブで管理し再生を行う画面。
/// - AudioPlayerService と連携して WAV ファイルのロード・再生・停止を制御
/// - イベント毎に信頼度や説明文を表示しユーザー体験を向上
/// - 将来的にはフィルタリングや共有機能の追加を計画
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_tracking_provider.dart';
import '../models/sleep_data.dart';
import '../services/audio_player_service.dart';

class SoundEventsScreen extends StatefulWidget {
  const SoundEventsScreen({super.key});

  @override
  State<SoundEventsScreen> createState() => _SoundEventsScreenState();
}

class _SoundEventsScreenState extends State<SoundEventsScreen>
    with TickerProviderStateMixin {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  late TabController _tabController;
  String? _playingEventId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: SoundType.values.length - 1,
      vsync: this,
    ); // unknownを除く
    _audioPlayer.initialize();

    // プレイヤーの状態監視
    _audioPlayer.playerStateStream.listen((state) {
      if (!state.playing && _playingEventId != null) {
        setState(() {
          _playingEventId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  /// 音響イベント画面のUIを構築
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('音響イベント'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF4A90E2),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          onTap: (index) {
            // タブの選択処理（必要に応じて）
          },
          tabs: _buildTabs(),
        ),
      ),
      body: Consumer<SleepTrackingProvider>(
        builder: (context, provider, child) {
          final session = provider.currentSession;
          if (session == null) {
            return const Center(
              child: Text(
                '音響イベントがありません',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: _buildTabViews(session),
          );
        },
      ),
    );
  }

  /// タブバーに表示する種別ラベル一覧
  List<Tab> _buildTabs() {
    final types = SoundType.values
        .where((type) => type != SoundType.unknown)
        .toList();
    return types.map((type) => Tab(text: type.displayName)).toList();
  }

  /// 種別ごとのイベントリストビューを生成
  List<Widget> _buildTabViews(SleepSession session) {
    final types = SoundType.values
        .where((type) => type != SoundType.unknown)
        .toList();
    return types.map((type) => _buildEventList(session, type)).toList();
  }

  /// 指定タイプのイベント一覧を表示
  Widget _buildEventList(SleepSession session, SoundType type) {
    final events = session.soundEvents
        .where((event) => event.type == type)
        .toList();
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getTypeIcon(type), size: 64, color: Colors.white30),
            const SizedBox(height: 16),
            Text(
              '${type.displayName}は検出されませんでした',
              style: const TextStyle(color: Colors.white60, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF16213E),
          child: Row(
            children: [
              Icon(_getTypeIcon(type), size: 24, color: _getTypeColor(type)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${type.displayName} - ${events.length}回検出',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '総時間: ${_formatTotalDuration(events)}',
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
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(event, session.bedTime);
            },
          ),
        ),
      ],
    );
  }

  /// 個々のイベントカードウィジェット
  Widget _buildEventCard(SoundEvent event, DateTime bedTime) {
    final isPlaying = _playingEventId == event.id;
    final relativeTime = event.timestamp.difference(bedTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlaying ? const Color(0xFF4A90E2) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getTypeColor(event.type),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_formatRelativeTime(relativeTime)} - ${event.type.displayName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildPlayButton(event),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '時刻: ${_formatTime(event.timestamp)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '時間: ${_formatDuration(event.duration)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '信頼度: ${(event.confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          if (event.description != null) ...[
            const SizedBox(height: 8),
            Text(
              event.description!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (isPlaying) ...[
            const SizedBox(height: 12),
            _buildPlaybackProgress(),
          ],
        ],
      ),
    );
  }

  /// 再生・一時停止ボタン
  Widget _buildPlayButton(SoundEvent event) {
    final isPlaying = _playingEventId == event.id;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4A90E2).withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () => _handlePlayButton(event),
        icon: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: const Color(0xFF4A90E2),
        ),
        iconSize: 20,
      ),
    );
  }

  /// 再生位置を表示するプログレスバー
  Widget _buildPlaybackProgress() {
    return StreamBuilder<Duration>(
      stream: _audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = _audioPlayer.totalDuration ?? Duration.zero;

        return Column(
          children: [
            LinearProgressIndicator(
              value: duration.inMilliseconds > 0
                  ? position.inMilliseconds / duration.inMilliseconds
                  : 0,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// イベントをタップした際の再生/停止処理
  void _handlePlayButton(SoundEvent event) async {
    if (_playingEventId == event.id) {
      // 現在再生中の場合は停止
      await _audioPlayer.pause();
      setState(() {
        _playingEventId = null;
      });
    } else {
      // 新しい音声を再生
      try {
        await _audioPlayer.loadAudio(event.audioFilePath);

        // イベントの開始時間を計算（これは簡略化されたもので、実際には音声ファイル内の特定の位置を指定する必要があります）
        final startTime = Duration.zero; // 実際の実装では event.timestamp から計算

        await _audioPlayer.playSegment(
          event.audioFilePath,
          startTime,
          event.duration,
        );

        setState(() {
          _playingEventId = event.id;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('音声の再生に失敗しました: $e'),
            backgroundColor: const Color(0xFFE74C3C),
          ),
        );
      }
    }
  }

  /// 種別に応じたアイコンを取得
  IconData _getTypeIcon(SoundType type) {
    switch (type) {
      case SoundType.snoring:
        return Icons.volume_up;
      case SoundType.sleepTalk:
        return Icons.chat_bubble_outline;
      case SoundType.cough:
        return Icons.sick;
      case SoundType.apnea:
        return Icons.air;
      case SoundType.inhale:
        return Icons.arrow_downward;
      case SoundType.exhale:
        return Icons.arrow_upward;
      case SoundType.unknown:
        return Icons.help_outline;
    }
  }

  /// 種別に応じたテーマカラーを返す
  Color _getTypeColor(SoundType type) {
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

  /// 時刻をHH:mm形式で整形
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Durationをmm:ssまたはhh:mm:ss形式に変換
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }

  /// 就寝からの経過時間を表現
  String _formatRelativeTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '就寝から${hours}時間${minutes}分後';
    } else {
      return '就寝から${minutes}分後';
    }
  }

  /// イベントリストの総継続時間を算出
  String _formatTotalDuration(List<SoundEvent> events) {
    final totalDuration = events.fold<Duration>(
      Duration.zero,
      (total, event) => total + event.duration,
    );
    return _formatDuration(totalDuration);
  }
}
