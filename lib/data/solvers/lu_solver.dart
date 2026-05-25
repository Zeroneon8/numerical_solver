import 'package:fraction/fraction.dart';

import '../../domain/models/linear_system.dart';
import '../../domain/models/matrix.dart';
import '../../domain/models/solution_step.dart';
import '../../domain/models/solver_result.dart';
import '../../domain/repositories/i_solver_repository.dart';
import '../../utils/latex_formatter.dart';
import '../../utils/fraction_math.dart';

class LuSolver implements ISolverRepository {
  const LuSolver();

  @override
  SolverResult solve(LinearSystem system, {Fraction? tolerance}) {
    final size = system.size;
    final originalA = normalizeMatrix(system.coefficients.copy());
    final originalB = normalizeVector(system.constants);
    final u = originalA.copy();
    final l = _identity(size);
    final pb = normalizeVector(system.constants);
    final steps = <SolutionStep>[];
    final epsilon = Fraction(1, 10000000000);

    steps.add(
      SolutionStep(
        title: 'Sistema original',
        description:
            'Matriz aumentada [A|b] ingresada por el usuario. Se resolverá mediante factorización LU con pivoteo parcial.',
        matrixState: _buildAugmented(originalA, originalB),
      ),
    );

    for (var k = 0; k < size; k++) {
      var pivotRow = k;
      for (var i = k + 1; i < size; i++) {
        if (fractionAbs(
              u.get(i, k),
            ).compareTo(fractionAbs(u.get(pivotRow, k))) >
            0) {
          pivotRow = i;
        }
      }

      if (fractionAbs(u.get(pivotRow, k)).compareTo(epsilon) <= 0) {
        return const SolverFailure(
          'El sistema no tiene solución única (matriz singular)',
        );
      }

      final pivotValue = u.get(pivotRow, k);
      if (pivotRow != k) {
        u.swapRows(k, pivotRow);
        _swap(pb, k, pivotRow);
        _swapLower(l, k, pivotRow, k);
      }

      final pivotEntry = u.get(k, k);
      if (fractionIsZero(pivotEntry)) {
        return const SolverFailure(
          'No se puede aplicar LU: el pivote es cero después del pivoteo parcial.',
        );
      }

      steps.add(
        SolutionStep(
          title: 'Pivoteo parcial: columna ${k + 1}',
          description: pivotRow != k
              ? 'Pivote mayor ${_fractionText(pivotValue)} encontrado en fila ${pivotRow + 1}; se intercambia con fila ${k + 1}.'
              : 'El pivote actual ya es el mayor en la columna ${k + 1}.',
          matrixState: _buildAugmented(u, pb),
        ),
      );

      for (var i = k + 1; i < size; i++) {
        final originalEntry = u.get(i, k);
        final factor = fractionDiv(originalEntry, pivotEntry);
        l.set(i, k, factor);

        for (var j = k; j < size; j++) {
          u.set(
            i,
            j,
            fractionSub(u.get(i, j), fractionMul(factor, u.get(k, j))),
          );
        }

        steps.add(
          SolutionStep(
            title:
                'Eliminación fila ${i + 1}, columna ${k + 1}: m = ${_fractionText(factor)}',
            description:
                'F_${i + 1} = F_${i + 1} - (${_fractionText(factor)})·F_${k + 1}.',
            matrixState: u.copy(),
          ),
        );
      }
    }

    steps.add(
      SolutionStep(
        title: 'Descomposición LU completa',
        description:
            'La matriz A ha sido descompuesta en A = L × U donde L es triangular inferior con unos en la diagonal y U es triangular superior.',
        matrixState: l.copy(),
        secondMatrixLabel: 'Matriz U',
        secondMatrixLatex: LatexFormatter.matrixToLatex(u),
      ),
    );

    final y = List<Fraction>.filled(size, Fraction(0, 1));
    for (var i = 0; i < size; i++) {
      var sum = Fraction(0, 1);
      final sumParts = <String>[];
      for (var j = 0; j < i; j++) {
        final product = fractionMul(l.get(i, j), y[j]);
        sum = fractionAdd(sum, product);
        sumParts.add('${_fractionText(l.get(i, j))}×${_fractionText(y[j])}');
      }
      y[i] = fractionSub(pb[i], sum);
      final rhs = sumParts.isEmpty ? '0' : sumParts.join(' + ');

      steps.add(
        SolutionStep(
          title: 'Sustitución hacia adelante: y_${i + 1}',
          description:
              'y_${i + 1} = ${_fractionText(pb[i])} - ($rhs) = ${_fractionText(y[i])}.',
          matrixState: _vectorAsColumn(y),
        ),
      );
    }

    final x = List<Fraction>.filled(size, Fraction(0, 1));
    for (var i = size - 1; i >= 0; i--) {
      var sum = Fraction(0, 1);
      final sumParts = <String>[];
      for (var j = i + 1; j < size; j++) {
        final product = fractionMul(u.get(i, j), x[j]);
        sum = fractionAdd(sum, product);
        sumParts.add('${_fractionText(u.get(i, j))}×${_fractionText(x[j])}');
      }
      final diagonal = u.get(i, i);
      if (fractionIsZero(diagonal)) {
        return const SolverFailure(
          'No se puede completar la sustitución hacia atrás: un pivote diagonal es cero.',
        );
      }
      x[i] = fractionDiv(fractionSub(y[i], sum), diagonal);
      final rhs = sumParts.isEmpty ? '0' : sumParts.join(' + ');

      steps.add(
        SolutionStep(
          title: 'Sustitución hacia atrás: x_${i + 1}',
          description:
              'x_${i + 1} = (${_fractionText(y[i])} - ($rhs)) / ${_fractionText(u.get(i, i))} = ${_fractionText(x[i])}.',
          matrixState: _vectorAsColumn(x),
          solutionVector: List<Fraction>.from(x),
        ),
      );
    }

    final verificationLines = <String>[];
    for (var i = 0; i < size; i++) {
      var dot = Fraction(0, 1);
      final parts = <String>[];
      for (var j = 0; j < size; j++) {
        final product = fractionMul(originalA.get(i, j), x[j]);
        dot = fractionAdd(dot, product);
        parts.add(
          '${_fractionText(originalA.get(i, j))}×${_fractionText(x[j])}',
        );
      }
      verificationLines.add(
        'Ecuación ${i + 1}: (${parts.join(' + ')}) = ${_fractionText(dot)} y b_${i + 1} = ${_fractionText(originalB[i])}.',
      );
    }

    steps.add(
      SolutionStep(
        title: 'Verificación: A × x = b',
        description: verificationLines.join(' | '),
        matrixState: _appendVectorToMatrix(originalA, x),
        solutionVector: x,
      ),
    );

    return SolverSuccess(steps);
  }

  Matrix _identity(int size) {
    final matrix = Matrix.zeros(size, size);
    for (var i = 0; i < size; i++) {
      matrix.set(i, i, Fraction(1, 1));
    }
    return matrix;
  }

  void _swap(List<Fraction> list, int a, int b) {
    final tmp = list[a];
    list[a] = list[b];
    list[b] = tmp;
  }

  void _swapLower(Matrix l, int a, int b, int upTo) {
    for (var col = 0; col < upTo; col++) {
      final tmp = l.get(a, col);
      l.set(a, col, l.get(b, col));
      l.set(b, col, tmp);
    }
  }

  Matrix _buildAugmented(Matrix a, List<Fraction> b) {
    final data = List<List<Fraction>>.generate(a.rows, (row) {
      return List<Fraction>.generate(a.cols + 1, (col) {
        if (col < a.cols) {
          return a.get(row, col);
        }
        return b[row];
      });
    });
    return Matrix.fromList(data);
  }

  Matrix _vectorAsColumn(List<Fraction> vector) {
    final data = vector.map((value) => <Fraction>[value]).toList();
    return Matrix.fromList(data);
  }

  Matrix _appendVectorToMatrix(Matrix matrix, List<Fraction> vector) {
    final data = List<List<Fraction>>.generate(matrix.rows, (row) {
      return List<Fraction>.generate(matrix.cols + 1, (col) {
        if (col < matrix.cols) {
          return matrix.get(row, col);
        }
        return vector[row];
      });
    });
    return Matrix.fromList(data);
  }

  String _fractionText(Fraction value) {
    final reduced = normalizeFraction(value);
    if (_isOne(reduced.denominator)) {
      return '${reduced.numerator}';
    }
    return '${reduced.numerator}/${reduced.denominator}';
  }

  bool _isOne(Object? value) {
    if (value is int) {
      return value == 1;
    }
    if (value is BigInt) {
      return value == BigInt.one;
    }
    return value == 1;
  }
}
