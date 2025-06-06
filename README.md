# flutter_sleepcycle

Sleep Cycle Tracker は、睡眠中の音声を録音し、端末上だけで解析を行う Flutter 製アプリケーションです。セッション開始時にマイクへのアクセス許可を求め、録音を WAV ファイルとして保存します。クラシファイアはデータをクラウドに送信することなく、いびき、咳、寝言、長時間の無音を検出します。

## 睡眠音声の分類

解析モジュールは小規模なロジスティック回帰モデルによって動作します。短い音声ウィンドウを処理し、いびき、咳、寝言、呼吸を分類します。長時間の無音は睡眠時無呼吸の可能性としてフラグ付けされます。すべての処理はローカルで行われ、録音は `*.wav` ファイルとして保存されるため、ネットワーク接続なしでも確認できます。

最新バージョンでは軽量な睡眠段階モデル (HomeSleepNet) も実行され、**Wake**、**REM**、**NREM** の各期間を推定します。同じ音声は SST モデル (Snore Shifted-window Transformer) にも渡され、閉塞性睡眠時無呼吸のリスクスコアを出力します。

## 開発者向けAI解説

AI処理は `lib/services` ディレクトリにまとめられており、主に次のコンポーネントで構成されています。

- `AIAudioAnalysisService`\
  録音した WAV ファイルから特徴量を抽出し `LightweightSoundClassifier` に渡します。現在は簡易実装ですが、OpenAI Whisper などの外部 API に置き換える想定です。
- `LightweightSoundClassifier`\
  3 つの特徴量を入力とするロジスティック回帰モデルで、いびき・咳・寝言・不明を分類します。
- `HomeSleepNetService`\
  睡眠段階を推定する軽量モデルを呼び出します。サンプルではランダム値を返しますが、TensorFlow Lite 版モデルに差し替え可能です。
- `SSTService`\
  Snore Shifted-window Transformer に基づき閉塞性睡眠時無呼吸のリスク値を算出します。こちらもデモ用にランダム値を返します。
- `SleepQualityAnalyzer`\
  検出したイベントの統計から睡眠効率や質を計算します。いびきや無呼吸の頻度に応じてスコアを調整します。

これらのサービスは疎結合となっており、より高度なAIモデルへの置き換えや外部APIとの連携が容易に行える設計です。

### 各サービスの詳細

`AIAudioAnalysisService`
: `analyzeAudioFile` で WAV ファイルを読み込み、平均振幅・分散・ゼロ交差率といった特徴量を生成します。`analyzeAudioFileWithProgress` を利用すると、解析工程をUI側に通知しながら処理できます。返り値は `List<SoundEvent>` で、後続の品質解析に利用されます。

`LightweightSoundClassifier`
: 静的に定義した重みを用いたロジスティック回帰モデルです。`classify` メソッドに3次元ベクトルを与えると `SoundType` 列挙体を返します。学習済みモデルに置き換える場合はこのメソッドを差し替えるだけで済みます。

`HomeSleepNetService`
: 音声全体を解析し、30分毎に `SleepStageSegment` を生成する想定です。サンプル実装では乱数を返していますが、TensorFlow Lite のモデルをロードして `classifyStages` の内部処理を置き換えることで実運用に耐えます。

`SSTService`
: Snore Shifted-window Transformer に基づき、OSA危険度スコア(0.0〜1.0)を返します。推論結果は `SleepSession.osaRisk` として保存され、ダッシュボード画面に表示されます。

`SleepQualityAnalyzer`
: `analyzeSleepSession` は検出済みイベントを元に睡眠効率や睡眠の質を算定し、`getSleepAnalytics` ではグラフ表示用データを取得できます。評価基準はコード内の重みを調整するだけで変更可能です。

## はじめに

1. [Flutter SDK](https://docs.flutter.dev/get-started/install) をインストールします。
2. 依存パッケージを取得します:

   ```bash
   flutter pub get
   ```

3. エミュレーターを起動するかデバイスを接続して実行します:

   ```bash
   flutter run
   ```

セッションを開始すると最初にマイクのアクセス許可が求められます。誤って拒否した場合は、後からシステム設定で許可を付与できます。
