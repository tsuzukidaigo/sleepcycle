import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_tracking_provider.dart';
import '../models/sleep_data.dart';
import '../utils/app_theme.dart';
import 'sleep_analysis_screen.dart';

class SleepHistoryScreen extends StatelessWidget {
  const SleepHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('睡眠履歴'),
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<SleepTrackingProvider>(
        builder: (context, provider, child) {
          final history = provider.sleepHistory.reversed.toList();
          if (history.isEmpty) {
            return const Center(
              child: Text(
                '履歴がありません',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final session = history[index];
              return _buildSessionTile(context, session);
            },
          );
        },
      ),
    );
  }

  Widget _buildSessionTile(BuildContext context, SleepSession session) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: AppTheme.cardBackground,
      title: Text(
        _formatDate(session.bedTime),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        _buildSubtitle(session),
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.white.withOpacity(0.7),
      ),
      onTap: () {
        final provider =
            Provider.of<SleepTrackingProvider>(context, listen: false);
        provider.setCurrentSession(session);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SleepAnalysisScreen()),
        );
      },
    );
  }

  String _buildSubtitle(SleepSession session) {
    final bed = _formatTime(session.bedTime);
    final wake = session.wakeUpTime != null ? _formatTime(session.wakeUpTime!) : '--:--';
    final quality = session.quality?.displayName ?? '分析中';
    return '$bed - $wake  $quality';
  }

  String _formatDate(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
