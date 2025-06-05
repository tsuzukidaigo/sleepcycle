/// デザインドキュメント
/// アプリのメインとなるホーム画面。
/// - 録音の開始・停止ボタンを表示し SleepTrackingProvider と連携
/// - マイク権限がない場合は PermissionHelper でユーザーに要求
/// - 分析完了後はグラフ画面やイベント一覧画面への遷移入口を提供
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/sleep_tracking_provider.dart';
import '../models/sleep_data.dart';
import '../utils/permission_helper.dart';
import 'sleep_analysis_screen.dart';
import 'sound_events_screen.dart';
import 'sleep_history_screen.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check permission status when app resumes (e.g., after coming back from settings)
      _checkPermissionStatus();
    }
  }

  /// アプリが再度フォーカスを得た際にマイク権限を確認する
  Future<void> _checkPermissionStatus() async {
    final status = await Permission.microphone.status;
    print('App resumed, microphone permission status: $status');

    if (status.isGranted) {
      // Clear any error messages if permission is now granted
      final provider = Provider.of<SleepTrackingProvider>(
        context,
        listen: false,
      );
      if (provider.errorMessage != null) {
        provider.clearError();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('マイクロフォンの許可が有効になりました！'),
            backgroundColor: Color(0xFF27AE60),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  /// ホーム画面全体のUIを構築する
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Consumer<SleepTrackingProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  Expanded(
                    child: provider.currentSession != null
                        ? _buildSessionView(context, provider)
                        : _buildTrackingView(context, provider),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 画面上部のタイトルと説明を描画
  Widget _buildHeader() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        children: [
          StreamBuilder<DateTime>(
            stream: Stream.periodic(
              const Duration(seconds: 1),
              (_) => DateTime.now(),
            ),
            builder: (context, snapshot) {
              final now = snapshot.data ?? DateTime.now();
              final time =
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
              return Text(
                time,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Sleep Tracker',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  /// 録音中/待機中のUIを返す
  Widget _buildTrackingView(
    BuildContext context,
    SleepTrackingProvider provider,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Error message display
        if (provider.errorMessage != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE74C3C).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFE74C3C)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFE74C3C),
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: provider.clearError,
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFFE74C3C),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],

        if (provider.isAnalyzing) ...[
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
          ),
          const SizedBox(height: 24),
          Text(
            provider.analysisProgress ?? '分析中...',
            style: const TextStyle(fontSize: 18, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: provider.isRecording
                  ? const Color(0xFFE74C3C).withOpacity(0.2)
                  : AppTheme.accent.withOpacity(0.2),
              border: Border.all(
                color: provider.isRecording
                    ? const Color(0xFFE74C3C)
                    : AppTheme.accent,
                width: 3,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () => _handleTrackingButton(context, provider),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        provider.isRecording ? Icons.stop : Icons.bedtime,
                        size: 64,
                        color: provider.isRecording
                            ? const Color(0xFFE74C3C)
                            : AppTheme.accent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.isRecording ? '起床' : '就寝',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: provider.isRecording
                              ? const Color(0xFFE74C3C)
                              : AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            provider.isRecording
                ? '睡眠を記録中...\nタップして起床時刻を記録'
                : 'タップして睡眠トラッキングを開始',
            style: const TextStyle(fontSize: 18, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          if (provider.isRecording) ...[
            const SizedBox(height: 24),
            _buildRecordingTimer(),
          ],
        ],
        const SizedBox(height: 48),
        if (provider.sleepHistory.isNotEmpty) _buildHistoryButton(context),
      ],
    );
  }

  /// 記録終了後のセッション詳細を表示
  Widget _buildSessionView(
    BuildContext context,
    SleepTrackingProvider provider,
  ) {
    final session = provider.currentSession!;
    final analytics = provider.getCurrentSleepAnalytics();

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSleepQualityCard(session, analytics),
          const SizedBox(height: 24),
          _buildSleepStatsGrid(session, analytics),
          const SizedBox(height: 24),
          _buildSoundEventsPreview(context, provider),
          const SizedBox(height: 24),
          _buildActionButtons(context, provider),
        ],
      ),
    );
  }

  /// 睡眠の質を表示するカードウィジェット
  Widget _buildSleepQualityCard(
    SleepSession session,
    Map<String, dynamic>? analytics,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '睡眠の質',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            session.quality?.displayName ?? '分析中',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _getQualityColor(session.quality),
            ),
          ),
          if (session.sleepEfficiency != null) ...[
            const SizedBox(height: 16),
            Text(
              '睡眠効率: ${session.sleepEfficiency!.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  /// 就寝・起床時間などの統計をグリッド表示
  Widget _buildSleepStatsGrid(
    SleepSession session,
    Map<String, dynamic>? analytics,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard('就寝時刻', _formatTime(session.bedTime), Icons.bedtime),
        _buildStatCard(
          '起床時刻',
          session.wakeUpTime != null
              ? _formatTime(session.wakeUpTime!)
              : '--:--',
          Icons.wb_sunny,
        ),
        _buildStatCard(
          'ベッド時間',
          session.timeInBed != null
              ? _formatDuration(session.timeInBed!)
              : '--',
          Icons.access_time,
        ),
        _buildStatCard(
          '実睡眠時間',
          session.actualSleepTime != null
              ? _formatDuration(session.actualSleepTime!)
              : '--',
          Icons.hotel,
        ),
      ],
    );
  }

  /// タイトル・値・アイコンを持つ統計カード
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: AppTheme.accent),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 音響イベントの概要をチップ形式で表示
  Widget _buildSoundEventsPreview(
    BuildContext context,
    SleepTrackingProvider provider,
  ) {
    final eventCounts = provider.getSoundEventCounts();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '音響イベント',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SoundEventsScreen(),
                    ),
                  );
                },
                child: const Text('詳細を見る'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildEventChip('いびき', eventCounts[SoundType.snoring] ?? 0),
              _buildEventChip('寝言', eventCounts[SoundType.sleepTalk] ?? 0),
              _buildEventChip('咳', eventCounts[SoundType.cough] ?? 0),
              _buildEventChip('無呼吸', eventCounts[SoundType.apnea] ?? 0),
            ],
          ),
        ],
      ),
    );
  }

  /// イベント件数を表示する小さなチップ
  Widget _buildEventChip(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        '$label: $count回',
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  /// 分析画面遷移や新規記録開始ボタン群
  Widget _buildActionButtons(
    BuildContext context,
    SleepTrackingProvider provider,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SleepAnalysisScreen(),
                ),
              );
            },
            icon: const Icon(Icons.analytics),
            label: const Text('詳細分析を見る'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => provider.clearCurrentSession(),
            icon: const Icon(Icons.refresh),
            label: const Text('新しい記録を開始'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.accent),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 録音経過時間を表示するタイマー
  Widget _buildRecordingTimer() {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      builder: (context, snapshot) {
        final provider = Provider.of<SleepTrackingProvider>(
          context,
          listen: false,
        );
        if (provider.currentSession?.bedTime == null) {
          return const SizedBox.shrink();
        }

        final elapsed = DateTime.now().difference(
          provider.currentSession!.bedTime,
        );
        return Text(
          '記録時間: ${_formatDuration(elapsed)}',
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
        );
      },
    );
  }

  /// 睡眠履歴画面への遷移ボタン
  Widget _buildHistoryButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SleepHistoryScreen()),
        );
      },
      icon: const Icon(Icons.history),
      label: const Text('睡眠履歴を見る'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: AppTheme.accent),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// 録音開始・停止ボタンの押下処理
  void _handleTrackingButton(
    BuildContext context,
    SleepTrackingProvider provider,
  ) async {
    if (provider.isRecording) {
      await provider.stopSleepTracking();
    } else {
      print('Requesting microphone permission...');
      // Request microphone permission with user-friendly dialog
      final hasPermission = await PermissionHelper.requestMicrophonePermission(
        context,
      );
      print('Permission result: $hasPermission');

      if (!hasPermission) {
        print('Permission denied, showing snackbar');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('マイクロフォンの許可が必要です。設定から許可してください。'),
            backgroundColor: Color(0xFFE74C3C),
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      print('Permission granted, starting sleep tracking...');
      final success = await provider.startSleepTracking();
      if (!success) {
        print('Failed to start sleep tracking');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('録音の開始に失敗しました。しばらくしてから再度お試しください。'),
            backgroundColor: Color(0xFFE74C3C),
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        print('Sleep tracking started successfully');
      }
    }
  }

  /// 睡眠の質に応じた色を取得
  Color _getQualityColor(SleepQuality? quality) {
    switch (quality) {
      case SleepQuality.excellent:
        return const Color(0xFF27AE60);
      case SleepQuality.good:
        return AppTheme.accent;
      case SleepQuality.fair:
        return const Color(0xFFF39C12);
      case SleepQuality.poor:
        return const Color(0xFFE74C3C);
      default:
        return Colors.white;
    }
  }

  /// HH:mm 形式で時刻を整形
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Duration を「X時間Y分」に変換
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}時間${minutes}分';
  }
}
