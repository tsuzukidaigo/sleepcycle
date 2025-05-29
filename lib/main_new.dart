import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sleep_tracking_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SleepCycleApp());
}

class SleepCycleApp extends StatelessWidget {
  const SleepCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SleepTrackingProvider()..initialize(),
      child: MaterialApp(
        title: 'Sleep Cycle Tracker',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A90E2),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
