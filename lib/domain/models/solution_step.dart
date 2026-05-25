import 'package:fraction/fraction.dart';

import 'matrix.dart';

class SolutionStep {
  const SolutionStep({
    required this.title,
    required this.description,
    required this.matrixState,
    this.solutionVector,
    this.secondMatrixLatex,
    this.secondMatrixLabel,
  });

  final String title;
  final String description;
  final Matrix matrixState;
  final List<Fraction>? solutionVector;
  final String? secondMatrixLatex;
  final String? secondMatrixLabel;
}
