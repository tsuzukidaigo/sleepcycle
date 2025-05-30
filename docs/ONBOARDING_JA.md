# コードベース概要

このドキュメントは、新しく参加する開発者がリポジトリの構成を素早く把握するためのガイドです。プロジェクトは Flutter 製アプリ「Sleep Cycle Tracker」で、睡眠中の音声を記録し AI 解析を行い、睡眠の質を表示する機能を提供します。

## ディレクトリ構成

- **lib/**: アプリの主要なソースコードを格納しています。
  - `main.dart` / `main_new.dart`: アプリのエントリーポイント。
  - `models/`: `sleep_data.dart` など、ドメインモデルを定義します。
  - `providers/`: `SleepTrackingProvider` などの状態管理クラス。
  - `services/`: 録音や解析を行うサービス層。
  - `screens/`: 画面ウィジェット群。
  - `utils/`: 権限要求処理などのユーティリティ。
- **android/**、**ios/** など: 各プラットフォーム用のネイティブ設定。
- **test/**: Flutter のテストコード。現在はサンプルテストのみ。
- **pubspec.yaml**: 依存パッケージと Flutter 設定を管理するファイル。

## 主なコンポーネント

- **SleepTrackingProvider** (`lib/providers/sleep_tracking_provider.dart`)
  - 録音開始・停止や解析進行状況を管理します。
  - `AudioRecordingService` と `AIAudioAnalysisService` を利用し、録音データから `SoundEvent` を生成して `SleepQualityAnalyzer` で睡眠指標を計算します。
- **SleepSession** (`lib/models/sleep_data.dart`)
  - 一回の睡眠セッションを表し、検出イベントや睡眠効率を保持します。
- **services/**
  - `audio_recording_service.dart`: `flutter_sound` で WAV 形式の録音を行います。
  - `ai_audio_analysis_service.dart`: WAV ファイルを解析していびきや咳などのイベントを抽出します（現状はモック実装）。
  - `sleep_quality_analyzer.dart`: 音響イベントから睡眠効率や質を計算します。
  - `audio_player_service.dart`: `just_audio` を利用した再生機能。

## 開発の進め方

1. Flutter SDK セットアップ後、依存パッケージを取得します。
   ```bash
   flutter pub get
   ```
2. エミュレータまたは実機でアプリを起動します。
   ```bash
   flutter run
   ```
3. 変更点を確認する場合はテストを実行します。
   ```bash
   flutter test
   ```
   現在はテンプレートのウィジェットテストのみ含まれています。

## 参考

詳しい実装例や API 利用箇所は各ソースファイルのコメントを参照してください。あわせて README を確認すると全体像を把握しやすくなります。
