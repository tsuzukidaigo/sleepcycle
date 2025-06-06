/// デザインドキュメント
/// テスト用に機能を絞ったエントリポイント。
/// - 開発時に SleepTabScreen のみを表示して動作確認を容易にする
/// - SleepTrackingProvider の初期化処理は本番と共通でロジックを共有
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sleep_tracking_provider.dart';
import 'screens/sleep_tab_screen.dart';
import 'utils/app_theme.dart';

/// テスト用エントリポイント
void main() {
  runApp(const SleepCycleApp());
}

/// SleepTabScreen だけを表示する簡易版アプリ
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
        home: const SleepTabScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
