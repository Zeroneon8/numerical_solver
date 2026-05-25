import 'package:fraction/fraction.dart';

import '../../domain/models/linear_system.dart';
import '../../domain/models/matrix.dart';
import '../../domain/models/solution_step.dart';
import '../../domain/models/solver_result.dart';
import '../../domain/repositories/i_solver_repository.dart';
import '../../utils/fraction_math.dart';

class JacobiSolver implements ISolverRepository {
  const JacobiSolver();

  @override
  SolverResult solve(LinearSystem system, {Fraction? tolerance}) {
    final a = _coefficientsAsDouble(system.coefficients.copy());
    final b = system.constants.map(fractionToDouble).toList(growable: false);
    final n = system.size;
    final maxIterations = 100;
    final errorTolerance = fractionToDouble(tolerance ?? Fraction(1, 1000000));
    final steps = <SolutionStep>[];
    final variableNames = _variableNames(n);

    steps.add(
      SolutionStep(
        title: 'Sistema original',
        description:
            'Matriz aumentada [A|b] antes de cualquier transformación.',
        matrixState: _buildAugmented(a, b),
      ),
    );

    final swappedAny = _reorderRowsForDiagonalDominance(a, b, steps);
    if (!swappedAny) {
      steps.add(
        SolutionStep(
          title: 'Reordenamiento previo',
          description:
              'Las filas ya están en el orden óptimo para la diagonal.',
          matrixState: _buildAugmented(a, b),
        ),
      );
    }

    if (!_isDiagonallyDominant(a)) {
      steps.add(
        SolutionStep(
          title: '⚠️ Advertencia de convergencia',
          description:
              'La matriz no es diagonalmente dominante. La convergencia del método no está garantizada. Los resultados pueden ser incorrectos.',
          matrixState: _buildAugmented(a, b),
        ),
      );
    }

    for (var i = 0; i < n; i++) {
      if (a[i][i].abs() <= _epsilon) {
        return const SolverFailure(
          'No se puede aplicar Jacobi: existe un cero en la diagonal principal.',
        );
      }
    }

    steps.add(
      SolutionStep(
        title: 'Fórmulas iterativas de Jacobi',
        description: _jacobiFormulasDescription(a, b, variableNames),
        matrixState: _buildAugmented(a, b),
      ),
    );

    var current = List<double>.filled(n, 0);
    steps.add(
      SolutionStep(
        title: 'Vector inicial',
        description: '',
        matrixState: _vectorAsColumn(current),
        solutionVector: doubleVectorToFractions(current),
      ),
    );

    for (var iter = 1; iter <= maxIterations; iter++) {
      final next = List<double>.filled(n, 0);

      for (var i = 0; i < n; i++) {
        var sum = 0.0;
        for (var j = 0; j < n; j++) {
          if (j == i) {
            continue;
          }
          sum += a[i][j] * current[j];
        }
        next[i] = (b[i] - sum) / a[i][i];

        if (!next[i].isFinite) {
          return const SolverFailure(
            'El sistema no converge con el método de Jacobi',
          );
        }
      }

      final error = _maxError(current, next);
      if (!error.isFinite) {
        return const SolverFailure(
          'El sistema no converge con el método de Jacobi',
        );
      }

      steps.add(
        SolutionStep(
          title: 'Iteración $iter',
          description: '',
          matrixState: _vectorAsColumn(next),
          solutionVector: doubleVectorToFractions(next),
          secondMatrixLatex: '\\text{error} = ${_numberText(error)}',
        ),
      );

      if (error <= errorTolerance) {
        steps.add(
          SolutionStep(
            title: 'Convergencia en $iter iteraciones',
            description: '',
            matrixState: _vectorAsColumn(next),
            solutionVector: doubleVectorToFractions(next),
            secondMatrixLatex: '\\text{error} = ${_numberText(error)}',
          ),
        );
        return SolverSuccess(steps);
      }
      current = next;
    }

    return const SolverFailure(
      'El sistema no converge con el método de Jacobi',
    );
  }

  bool _reorderRowsForDiagonalDominance(
    List<List<double>> a,
    List<double> b,
    List<SolutionStep> steps,
  ) {
    var swappedAny = false;
    for (var i = 0; i < a.length; i++) {
      var pivot = i;
      for (var r = i + 1; r < a.length; r++) {
        if (a[r][i].abs() > a[pivot][i].abs()) {
          pivot = r;
        }
      }
      if (pivot != i) {
        final tempRow = a[i];
        a[i] = a[pivot];
        a[pivot] = tempRow;
        final temp = b[i];
        b[i] = b[pivot];
        b[pivot] = temp;
        swappedAny = true;
        steps.add(
          SolutionStep(
            title: 'Reordenamiento previo: columna ${i + 1}',
            description:
                'Reordenando filas para maximizar dominancia diagonal: intercambiando fila ${i + 1} y fila ${pivot + 1}.',
            matrixState: _buildAugmented(a, b),
          ),
        );
      }
    }
    return swappedAny;
  }

  double _maxError(List<double> prev, List<double> next) {
    var maxDiff = 0.0;
    for (var i = 0; i < prev.length; i++) {
      final diff = (next[i] - prev[i]).abs();
      if (diff > maxDiff) {
        maxDiff = diff;
      }
    }
    return maxDiff;
  }

  bool _isDiagonallyDominant(List<List<double>> matrix) {
    for (var i = 0; i < matrix.length; i++) {
      var sum = 0.0;
      for (var j = 0; j < matrix[i].length; j++) {
        if (j == i) {
          continue;
        }
        sum += matrix[i][j].abs();
      }
      final diag = matrix[i][i].abs();
      if (diag <= sum) {
        return false;
      }
    }
    return true;
  }

  List<List<double>> _coefficientsAsDouble(Matrix matrix) {
    return matrix
        .toList()
        .map((row) => row.map(fractionToDouble).toList(growable: false))
        .toList(growable: false);
  }

  Matrix _buildAugmented(List<List<double>> a, List<double> b) {
    final data = List<List<Fraction>>.generate(a.length, (row) {
      return List<Fraction>.generate(a[row].length + 1, (col) {
        if (col < a[row].length) {
          return a[row][col].toFraction();
        }
        return b[row].toFraction();
      });
    });
    return Matrix.fromList(data);
  }

  Matrix _vectorAsColumn(List<double> vector) {
    return doubleVectorToColumnMatrix(vector);
  }

  String _jacobiFormulasDescription(
    List<List<double>> a,
    List<double> b,
    List<String> variableNames,
  ) {
    final lines = <String>[
      'Despeje por variable usando valores de la iteración anterior.',
    ];
    for (var i = 0; i < a.length; i++) {
      final terms = <String>[];
      for (var j = 0; j < a[i].length; j++) {
        if (j == i) {
          continue;
        }
        terms.add('${_numberText(a[i][j])}${variableNames[j]}^{(k)}');
      }
      final rhs = terms.isEmpty
          ? _numberText(b[i])
          : '${_numberText(b[i])} - ${terms.join(' - ')}';
      lines.add(
        '${variableNames[i]}^{(k+1)} = ($rhs) / ${_numberText(a[i][i])}',
      );
    }
    return lines.join(' | ');
  }

  List<String> _variableNames(int size) {
    const base = <String>['x', 'y', 'z'];
    return List<String>.generate(size, (index) {
      if (index < base.length) {
        return base[index];
      }
      return 'x${index + 1}';
    });
  }

  String _numberText(double value) {
    if (value.abs() < _epsilon) {
      return '0';
    }
    final text = value.toStringAsPrecision(10);
    return text.contains('e') ? value.toStringAsFixed(10) : _trimZeros(text);
  }

  String _trimZeros(String text) {
    final trimmed = text.replaceFirst(RegExp(r'\.?(0+)$'), '');
    return trimmed.isEmpty || trimmed == '-' ? '0' : trimmed;
  }

  static const double _epsilon = 1e-12;
}
