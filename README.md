# flutter_sleepcycle

Sleep Cycle Tracker is a Flutter application that records your sleep sounds and
analyses them entirely on device. When you start a session the app asks for
microphone permission and stores recordings as WAV files. The classifier
detects snoring, coughing, sleep talking and prolonged silence without sending
any data to the cloud.

## Sleep audio classification

The analysis module is powered by a small logistic regression model. It
processes short audio windows and classifies snoring, coughing, sleep talking or
breathing. Long periods of silence are flagged as potential apnea events.
Everything happens locally and recordings are stored as `*.wav` files so that
you can review them without network access.

## Getting Started

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Fetch dependencies:

   ```bash
   flutter pub get
   ```

3. Launch an emulator or connect a device and run:

   ```bash
   flutter run
   ```

The first time you start a session the app will request access to the
microphone. If you accidentally deny the permission you can enable it later from
the system settings.
