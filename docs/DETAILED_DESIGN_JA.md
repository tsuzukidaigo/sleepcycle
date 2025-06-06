# Sleep Cycle Tracker 詳細設計書

## 1. 目的

Sleep Cycle Tracker は睡眠中の音声を録音し、簡易的な AI 解析によりいびき・寝言・咳・無呼吸などのイベントを検出して睡眠の質を評価するアプリです。本ドキュメントではソースコードを基にアーキテクチャと主要コンポーネントの設計をまとめます。

## 2. システム構成

```
lib/
  models/        ドメインモデル (SleepSession, SoundEvent)
  providers/     状態管理 (SleepTrackingProvider)
  services/      録音・解析などの業務ロジック
  screens/       画面ウィジェット群
  utils/         共通ユーティリティ
```

- **models**: `SoundType` や `SleepSession` のようなデータモデルを提供します。
- **providers**: `ChangeNotifier` を用いた状態管理クラスを置き、画面間でデータを共有します。
- **services**: マイク録音、AI 解析、睡眠スコア算出などアプリの中核処理を担当します。
- **screens**: ホーム画面、分析画面、履歴画面などの UI を構築します。
- **utils**: パーミッション要求など共通機能をヘルパとしてまとめます。

## 3. データモデル

`sleep_data.dart` では睡眠に関する主要データを定義しています。`SoundEvent` は録音から検出された音声イベントを表し、`SleepSession` が一晩の睡眠セッション全体を管理します。

```dart
enum SoundType {
  snoring, // いびき
  sleepTalk, // 寝言
  cough, // 咳
  apnea, // 無呼吸
  inhale, // 息を吸い込む
  exhale, // 息を吐き出す
  unknown, // 不明
}
```
【F:lib/models/sleep_data.dart†L7-L15】

各モデルは `toMap` / `fromMap` を実装しており、`SharedPreferences` 経由で永続化可能です。

```dart
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'type': type.index,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'duration': duration.inMilliseconds,
    'audioFilePath': audioFilePath,
    'confidence': confidence,
    'description': description,
  };
}
```
【F:lib/models/sleep_data.dart†L36-L46】

睡眠の質は `SleepQuality` 列挙体で段階評価され、`displayName` 拡張で日本語表示が得られます。

```dart
enum SleepQuality {
  excellent, // 優秀
  good, // 良い
  fair, // 普通
  poor, // 悪い
}
```
【F:lib/models/sleep_data.dart†L129-L134】

## 4. 状態管理 (Provider)

`SleepTrackingProvider` がアプリ全体の状態を管理します。録音・解析の開始停止を行い、進捗やエラーを UI へ通知します。

```dart
class SleepTrackingProvider extends ChangeNotifier {
  final AudioRecordingService _recordingService = AudioRecordingService();
  final AIAudioAnalysisService _analysisService = AIAudioAnalysisService();
  final SleepQualityAnalyzer _qualityAnalyzer = SleepQualityAnalyzer();
  // ...
}
```
【F:lib/providers/sleep_tracking_provider.dart†L15-L23】

録音開始時には `AudioRecordingService` を起動して `SleepSession` を生成します。

```dart
_currentSession = SleepSession(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  bedTime: DateTime.now(),
  audioFilePath: _recordingService.currentRecordingPath!,
);
```
【F:lib/providers/sleep_tracking_provider.dart†L81-L87】

録音停止後は `_analyzeRecordedAudio()` を呼び出して AI 解析を実行し、結果を履歴へ保存します。

## 5. サービス層

### 5.1 AudioRecordingService

`flutter_sound` を利用して WAV 形式で録音します。シングルトン構成でアプリ内から共通して使用されます。

```dart
Future<bool> startRecording() async {
  if (_isRecording) return false;
  _currentRecordingPath = await _getRecordingPath();
  _recordingStartTime = DateTime.now();
  await _recorder!.startRecorder(
    toFile: _currentRecordingPath,
    codec: Codec.pcm16WAV,
    bitRate: 128000,
    sampleRate: 44100,
  );
  _isRecording = true;
  return true;
}
```
【F:lib/services/audio_recording_service.dart†L47-L66】

### 5.2 AIAudioAnalysisService

録音ファイルを読み込み、簡易的な特徴量と軽量分類器 `LightweightSoundClassifier` でイベントを推定します。実環境ではクラウド API への置き換えも可能です。

```dart
final events = <SoundEvent>[];
for (int i = 0; i < samples.length; i += windowSize) {
  final features = _extractFeatures(segment);
  final classified = _classifier.classify(features);
  switch (classified) {
    case SoundType.snoring:
    case SoundType.cough:
    case SoundType.sleepTalk:
      events.add(
        SoundEvent(
          id: '${classified.name}_$i',
          type: classified,
          timestamp: timestamp,
          duration: Duration(seconds: (end - i) ~/ sampleRate),
          audioFilePath: audioFilePath,
          confidence: 0.7,
          description: classified.displayName,
        ),
      );
      break;
    default:
      // 呼吸音
      events.add(
        SoundEvent(
          id: 'breath_$i',
          type: i % 2 == 0 ? SoundType.inhale : SoundType.exhale,
          timestamp: timestamp,
          duration: Duration(seconds: (end - i) ~/ sampleRate),
          audioFilePath: audioFilePath,
          confidence: 0.4,
          description: '呼吸音',
        ),
      );
  }
}
```
【F:lib/services/ai_audio_analysis_service.dart†L240-L289】

### 5.3 SleepQualityAnalyzer

取得した `SoundEvent` の統計から睡眠効率や入眠時刻を計算し、総合スコアに応じた `SleepQuality` を決定します。

```dart
// 睡眠効率 = (実際の睡眠時間 / ベッドにいた時間) × 100
return (actualSleepTime.inMinutes / session.timeInBed!.inMinutes) * 100;
```
【F:lib/services/sleep_quality_analyzer.dart†L54-L55】

```dart
// スコアに基づいて睡眠の質を判定
if (score >= 85) return SleepQuality.excellent;
if (score >= 70) return SleepQuality.good;
if (score >= 55) return SleepQuality.fair;
return SleepQuality.poor;
```
【F:lib/services/sleep_quality_analyzer.dart†L211-L215】

## 6. 画面構成

- **HomeScreen**: 録音開始・停止ボタンを中心に、許可要求や進捗表示を行います。分析結果へのナビゲーションもここから行います。
- **SleepAnalysisScreen**: `fl_chart` を利用してイベント頻度や睡眠効率をグラフ表示します。
- **SleepHistoryScreen**: 過去の `SleepSession` 一覧を表示し、タップで分析画面へ遷移します。
- **SoundEventsScreen**: 検出イベントを種別ごとのタブで確認し、 `AudioPlayerService` で再生できます。

## 7. データフロー

1. **録音開始** – ホーム画面で録音開始ボタンを押すと `SleepTrackingProvider.startSleepTracking()` が呼ばれ、`AudioRecordingService` が WAV 録音を開始します。
2. **録音停止** – 停止時にファイルパスが `SleepSession` へ保存され、 `_analyzeRecordedAudio()` が解析を実行します。
3. **AI 解析** – `AIAudioAnalysisService` が音声を分類し `SoundEvent` を生成、`SleepQualityAnalyzer` がセッションに統計値を付与します。
4. **履歴保存** – 完了したセッションは `SharedPreferences` を通じて永続化され、履歴画面で閲覧できます。

## 8. 今後の拡張案

- OpenAI Whisper 等による高精度な音声認識の導入
- バックグラウンド録音や省電力化への対応
- イベント共有・CSV 出力などエクスポート機能の追加
- Apple HealthKit など外部サービスとの連携

## 9. まとめ

本アプリは録音・分類・評価の各フェーズを明確に分離し、Flutter で取り回しやすいアーキテクチャを採用しています。軽量なオフライン分類器を備えつつ、クラウド連携を見据えた拡張性を持つ点が特徴です。
