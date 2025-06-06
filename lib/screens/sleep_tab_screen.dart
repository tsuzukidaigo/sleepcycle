import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/sleep_tracking_provider.dart';
import '../utils/app_theme.dart';

class SleepTabScreen extends StatefulWidget {
  const SleepTabScreen({super.key});

  @override
  State<SleepTabScreen> createState() => _SleepTabScreenState();
}

class _SleepTabScreenState extends State<SleepTabScreen> {
  DateTime _wakeUpTime = DateTime.now().add(const Duration(hours: 8));
  late final List<Offset> _stars;

  /// Round [time] up so that its minutes are divisible by [interval].
  DateTime _roundToMinuteInterval(DateTime time, int interval) {
    final remainder = time.minute % interval;
    if (remainder != 0) {
      time = time.add(Duration(minutes: interval - remainder));
    }
    return DateTime(time.year, time.month, time.day, time.hour, time.minute);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    final rand = Random();
    _stars = List.generate(80, (_) => Offset(rand.nextDouble(), rand.nextDouble()));
    _wakeUpTime = _roundToMinuteInterval(_wakeUpTime, 5);
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
                    : [const Color(0xFF000814), const Color(0xFF1C3036)],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  if (!isSleeping)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _StarFieldPainter(_stars),
                      ),
                    ),
                  Center(
                    child: isSleeping
                        ? _buildSleepMode(context, provider, rangeText)
                        : _buildSetup(context, provider, rangeText),
                  ),
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
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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

class _StarFieldPainter extends CustomPainter {
  final List<Offset> stars;

  _StarFieldPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.6);
    for (final offset in stars) {
      final pos = Offset(offset.dx * size.width, offset.dy * size.height);
      canvas.drawCircle(pos, 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
