/// デザインドキュメント
/// アプリの起動処理と全体ナビゲーションを定義する。
/// - SleepTrackingProvider を ChangeNotifierProvider で初期化し状態管理を統一
/// - BottomNavigationBar でホーム、分析、音声イベントの各画面を切り替える
/// - アプリ全体のテーマやルート設定はここで一元管理する想定
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sleep_tracking_provider.dart';
import 'screens/sleep_tab_screen.dart';
import 'screens/sleep_history_screen.dart';
import 'screens/sleep_analysis_screen.dart';
import 'screens/profile_screen.dart';
import 'utils/app_theme.dart';

/// エントリポイント。アプリを起動する
void main() {
  runApp(const SleepCycleApp());
}

/// アプリ全体のProviderとテーマを設定するWidget
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
            seedColor: AppTheme.accent,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: AppTheme.background,
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// ボトムナビゲーションを持つメイン画面
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// ナビゲーションバーの選択状態を管理するステート
class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SleepTabScreen(),
    const SleepHistoryScreen(),
    const SleepAnalysisScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Provider.of<SleepTrackingProvider>(context).isRecording
          ? null
          : BottomNavigationBar(
              backgroundColor: AppTheme.background,
              selectedItemColor: AppTheme.accent,
              unselectedItemColor: Colors.grey,
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.nightlight_round), label: '睡眠'),
                BottomNavigationBarItem(icon: Icon(Icons.book), label: '日誌'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '統計'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'プロフィール'),
              ],
            ),
    );
  }
}
