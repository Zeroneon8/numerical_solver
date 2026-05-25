import 'package:fraction/fraction.dart';

import '../domain/models/matrix.dart';

class LatexFormatter {
  static String matrixToLatex(Matrix matrix) {
    final rows = matrix
        .toList()
        .map((row) {
          return row
              .map((f) {
                return _fractionToLatex(f);
              })
              .join(' & ');
        })
        .join(r' \\ ');
    return '\\begin{pmatrix}$rows\\end{pmatrix}';
  }

  static String vectorToLatex(List<Fraction> v, List<String> variableNames) {
    return _vectorToLatex(v, variableNames, includeApproximation: false);
  }

  static String vectorToLatexWithApproximation(
    List<Fraction> v,
    List<String> variableNames,
  ) {
    return _vectorToLatex(v, variableNames, includeApproximation: true);
  }

  static String _vectorToLatex(
    List<Fraction> v,
    List<String> variableNames, {
    required bool includeApproximation,
  }) {
    final entries = <String>[];
    for (var i = 0; i < v.length; i++) {
      final variable = i < variableNames.length
          ? variableNames[i]
          : 'x_{${i + 1}}';
      final exact = _fractionToLatex(v[i]);
      if (includeApproximation && !_isInteger(v[i])) {
        entries.add(
          '$variable = $exact \\approx ${_fractionApproximation(v[i])}',
        );
      } else {
        entries.add('$variable = $exact');
      }
    }
    return entries.join(r' \quad ');
  }

  static String _fractionToLatex(Fraction value) {
    final normalized = _normalize(value);
    final numerator = _toInt(normalized.numerator);
    final denominator = _toInt(normalized.denominator);

    if (denominator == 1) {
      return '$numerator';
    }

    if (numerator % denominator == 0) {
      return '${numerator ~/ denominator}';
    }

    return '\\frac{$numerator}{$denominator}';
  }

  static String _fractionApproximation(Fraction value) {
    return _toDouble(value).toStringAsFixed(9);
  }

  static bool _isInteger(Fraction value) {
    return _toInt(value.denominator) == 1;
  }

  static Fraction _normalize(Fraction value) {
    return Fraction(_toInt(value.numerator), _toInt(value.denominator));
  }

  static double _toDouble(Fraction value) {
    final normalized = _normalize(value);
    return _toInt(normalized.numerator) / _toInt(normalized.denominator);
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is BigInt) {
      return value.toInt();
    }
    return (value as dynamic).toInt();
  }
}
