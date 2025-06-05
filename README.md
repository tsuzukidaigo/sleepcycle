# flutter_sleepcycle

A new Flutter project.

## Sleep audio classification

This project now includes a lightweight on-device model based on logistic
regression. The classifier extracts simple acoustic features from each recorded
segment and predicts snoring, coughs, sleep talking and breathing sounds without
requiring any cloud services. Prolonged silence is additionally detected as a
possible apnea event. Recordings are saved as `*.wav` files so that they can be
analyzed completely offline.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
