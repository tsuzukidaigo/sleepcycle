import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_tracking_provider.dart';
import '../utils/app_theme.dart';

class SleepTabScreen extends StatefulWidget {
  const SleepTabScreen({super.key});

  @override
  State<SleepTabScreen> createState() => _SleepTabScreenState();
}

class _SleepTabScreenState extends State<SleepTabScreen> {
  DateTime _wakeUpTime = DateTime.now().add(const Duration(hours: 8));

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepTrackingProvider>(
      builder: (context, provider, child) {
        final isSleeping = provider.isRecording;
        final rangeStart = _wakeUpTime;
        final rangeEnd = _wakeUpTime.add(const Duration(minutes: 30));
        final rangeText = '${_formatTime(rangeStart)}-${_formatTime(rangeEnd)}';

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isSleeping
                    ? [Colors.black, const Color(0xFF0A0A23)]
                    : [const Color(0xFF001027), Colors.black],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  if (!isSleeping)
                    _buildSetup(context, provider, rangeText)
                  else
                    _buildSleepMode(context, provider, rangeText),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetup(
      BuildContext context, SleepTrackingProvider provider, String rangeText) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 200,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            use24hFormat: true,
            minuteInterval: 5,
            initialDateTime: _wakeUpTime,
            onDateTimeChanged: (value) {
              setState(() {
                _wakeUpTime = value;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '次の時間帯に簡単に起床 $rangeText',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: provider.startSleepTracking,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Colors.white24,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              '開始',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSleepMode(
      BuildContext context, SleepTrackingProvider provider, String rangeText) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
                color: Colors.white,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          '次の時間帯に簡単に起床 $rangeText',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const Spacer(),
        GestureDetector(
          onTap: provider.stopSleepTracking,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            margin: const EdgeInsets.only(bottom: 40),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Colors.white24,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              '停止',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }
}
