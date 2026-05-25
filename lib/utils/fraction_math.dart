import 'package:fraction/fraction.dart';

import '../domain/models/matrix.dart';

Fraction normalizeFraction(Fraction value) => value.reduce();

double fractionToDouble(Fraction value) => value.toDouble();

Fraction doubleToFraction(double value, {double precision = 1.0e-10}) {
  return Fraction.fromDouble(value, precision: precision);
}

Matrix normalizeMatrix(Matrix matrix) {
  final data = matrix
      .toList()
      .map(
        (row) => row
            .map((value) => normalizeFraction(value))
            .toList(growable: false),
      )
      .toList(growable: false);
  return Matrix.fromList(data);
}

List<Fraction> normalizeVector(List<Fraction> values) {
  return values.map(normalizeFraction).toList(growable: false);
}

Matrix doubleMatrixToFractionMatrix(
  List<List<double>> data, {
  double precision = 1.0e-10,
}) {
  final converted = data
      .map(
        (row) => row
            .map((value) => doubleToFraction(value, precision: precision))
            .toList(growable: false),
      )
      .toList(growable: false);
  return Matrix.fromList(converted);
}

Matrix doubleVectorToColumnMatrix(
  List<double> values, {
  double precision = 1.0e-10,
}) {
  final converted = values
      .map((value) => <Fraction>[doubleToFraction(value, precision: precision)])
      .toList(growable: false);
  return Matrix.fromList(converted);
}

List<Fraction> doubleVectorToFractions(
  List<double> values, {
  double precision = 1.0e-10,
}) {
  return values
      .map((value) => doubleToFraction(value, precision: precision))
      .toList(growable: false);
}

Fraction fractionAdd(Fraction left, Fraction right) => (left + right).reduce();

Fraction fractionSub(Fraction left, Fraction right) => (left - right).reduce();

Fraction fractionMul(Fraction left, Fraction right) => (left * right).reduce();

Fraction fractionDiv(Fraction left, Fraction right) => (left / right).reduce();

Fraction fractionAbs(Fraction value) {
  final zero = Fraction(0, 1);
  return value.compareTo(zero) < 0 ? (zero - value).reduce() : value.reduce();
}

bool fractionIsZero(Fraction value) => value.compareTo(Fraction(0, 1)) == 0;
