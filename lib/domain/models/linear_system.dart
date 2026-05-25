import 'package:fraction/fraction.dart';

import 'matrix.dart';

class LinearSystem {
  const LinearSystem({required this.matrix});

  final Matrix matrix;

  int get size => matrix.rows;

  Matrix get coefficients {
    final data = matrix
        .toList()
        .map((row) => row.take(matrix.cols - 1).toList(growable: false))
        .toList(growable: false);
    return Matrix.fromList(data);
  }

  List<Fraction> get constants {
    return matrix.toList().map((row) => row.last).toList(growable: false);
  }
}
