import 'package:fraction/fraction.dart';

class Matrix {
  Matrix._(this.rows, this.cols, this._data);

  final int rows;
  final int cols;
  final List<List<Fraction>> _data;

  factory Matrix.fromList(List<List<Fraction>> data) {
    if (data.isEmpty) {
      return Matrix._(0, 0, <List<Fraction>>[]);
    }
    final rows = data.length;
    final cols = data.first.length;
    for (final row in data) {
      if (row.length != cols) {
        throw ArgumentError('Matrix rows must have equal length.');
      }
    }
    final copy = data
        .map((row) => row.map((value) => value).toList(growable: false))
        .toList(growable: false);
    return Matrix._(rows, cols, copy);
  }

  factory Matrix.zeros(int rows, int cols) {
    final data = List<List<Fraction>>.generate(
      rows,
      (_) => List<Fraction>.filled(cols, Fraction(0, 1)),
    );
    return Matrix._(rows, cols, data);
  }

  Fraction get(int row, int col) => _data[row][col];

  void set(int row, int col, Fraction value) {
    _data[row][col] = value;
  }

  void rowOperation(int i, int j, Fraction factor) {
    for (var col = 0; col < cols; col++) {
      _data[i][col] = _data[i][col] - factor * _data[j][col];
    }
  }

  void swapRows(int i, int j) {
    final tmp = _data[i];
    _data[i] = _data[j];
    _data[j] = tmp;
  }

  Matrix copy() => Matrix.fromList(toList());

  List<List<Fraction>> toList() {
    return _data
        .map((row) => row.map((value) => value).toList(growable: false))
        .toList(growable: false);
  }
}
