import 'dart:math';
import '../models/sleep_data.dart';

class LightweightSoundClassifier {
  static final LightweightSoundClassifier _instance =
      LightweightSoundClassifier._internal();
  factory LightweightSoundClassifier() => _instance;
  LightweightSoundClassifier._internal();

  final List<SoundType> classes = [
    SoundType.snoring,
    SoundType.cough,
    SoundType.sleepTalk,
    SoundType.unknown,
  ];

  // Predefined weights for a simple logistic regression model.
  final List<List<double>> _weights = [
    [2.0, 0.5, -1.0], // snoring
    [3.0, 1.0, 2.0],  // cough
    [1.5, 0.2, 3.0],  // sleep talk
    [0.0, 0.0, 0.0],  // unknown
  ];

  final List<double> _biases = [0.0, 0.0, 0.0, 0.0];

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(max);
    final expScores = logits.map((l) => exp(l - maxLogit)).toList();
    final sumExp = expScores.reduce((a, b) => a + b);
    return expScores.map((e) => e / sumExp).toList();
  }

  /// Classify a feature vector into a [SoundType].
  SoundType classify(List<double> features) {
    if (features.length != 3) return SoundType.unknown;

    final logits = List<double>.filled(_weights.length, 0.0);
    for (int i = 0; i < _weights.length; i++) {
      double score = _biases[i];
      for (int j = 0; j < features.length; j++) {
        score += _weights[i][j] * features[j];
      }
      logits[i] = score;
    }

    final probs = _softmax(logits);
    int bestIndex = 0;
    double bestProb = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > bestProb) {
        bestProb = probs[i];
        bestIndex = i;
      }
    }

    return classes[bestIndex];
  }
}
