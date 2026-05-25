import 'dart:async';
import 'dart:isolate';

import 'package:fraction/fraction.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/solvers/gauss_seidel_solver.dart';
import '../../data/solvers/jacobi_solver.dart';
import '../../data/solvers/lu_solver.dart';
import '../../domain/enums/numerical_method.dart';
import '../../domain/models/linear_system.dart';
import '../../domain/models/matrix.dart';
import '../../domain/models/solver_result.dart';
import '../../domain/repositories/i_solver_repository.dart';
import '../../utils/expression_evaluator.dart';
import '../../utils/invalid_expression_exception.dart';

final solverProvider = AsyncNotifierProvider<SolverNotifier, SolverViewState>(
  SolverNotifier.new,
);

class SolverViewState {
  const SolverViewState({this.result, this.activeMethod});

  final SolverResult? result;
  final NumericalMethod? activeMethod;
}

class SolverNotifier extends AsyncNotifier<SolverViewState> {
  @override
  FutureOr<SolverViewState> build() {
    return const SolverViewState();
  }

  Future<void> solve(
    NumericalMethod method,
    List<List<String>> rawMatrix, {
    String? desiredError,
  }) async {
    state = const AsyncValue.loading();
    try {
      final request = _SolveRequest(
        methodIndex: method.index,
        rawMatrix: rawMatrix
            .map((row) => List<String>.from(row, growable: false))
            .toList(growable: false),
        desiredError: desiredError,
      );
      final result = kIsWeb
          ? _solveInBackground(request)
          : await Isolate.run<SolverResult>(() {
              return _solveInBackground(request);
            });
      state = AsyncValue.data(
        SolverViewState(result: result, activeMethod: method),
      );
    } on InvalidExpressionException {
      state = AsyncValue.data(
        SolverViewState(
          result: const SolverFailure(
            'Hay una o más expresiones matemáticas inválidas',
          ),
          activeMethod: method,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class _SolveRequest {
  const _SolveRequest({
    required this.methodIndex,
    required this.rawMatrix,
    required this.desiredError,
  });

  final int methodIndex;
  final List<List<String>> rawMatrix;
  final String? desiredError;
}

SolverResult _solveInBackground(_SolveRequest request) {
  final method = NumericalMethod.values[request.methodIndex];
  final matrix = _evaluateMatrixBackground(request.rawMatrix);
  final tolerance = _evaluateToleranceBackground(request.desiredError);
  final system = LinearSystem(matrix: matrix);
  final solver = _solverForBackground(method);
  return solver.solve(system, tolerance: tolerance);
}

Matrix _evaluateMatrixBackground(List<List<String>> rawMatrix) {
  final evaluated = rawMatrix
      .map((row) {
        return row
            .map((value) {
              if (value.trim().isEmpty) {
                throw InvalidExpressionException('Expresion invalida');
              }
              return ExpressionEvaluator.evaluate(value);
            })
            .toList(growable: false);
      })
      .toList(growable: false);
  return Matrix.fromList(evaluated);
}

Fraction? _evaluateToleranceBackground(String? desiredError) {
  final input = desiredError?.trim() ?? '';
  if (input.isEmpty) {
    return null;
  }
  final numericToleranceRegExp = RegExp(r'^\d+(\.\d*)?$');
  if (!numericToleranceRegExp.hasMatch(input)) {
    throw InvalidExpressionException('Expresion invalida');
  }
  final tolerance = _decimalToFractionBackground(input);
  if (tolerance.compareTo(Fraction(0, 1)) <= 0 ||
      tolerance.compareTo(Fraction(1, 1)) > 0) {
    throw InvalidExpressionException('Error deseado inválido');
  }
  return tolerance;
}

Fraction _decimalToFractionBackground(String input) {
  final parts = input.split('.');
  final wholePart = parts[0];
  final fractionalPart = parts.length > 1 ? parts[1] : '';
  final digits = '$wholePart$fractionalPart';
  final numerator = BigInt.parse(digits).toInt();
  final denominator = fractionalPart.isEmpty
      ? 1
      : BigInt.from(10).pow(fractionalPart.length).toInt();
  return Fraction(numerator, denominator).reduce();
}

ISolverRepository _solverForBackground(NumericalMethod method) {
  switch (method) {
    case NumericalMethod.lu:
      return const LuSolver();
    case NumericalMethod.jacobi:
      return const JacobiSolver();
    case NumericalMethod.gaussSeidel:
      return const GaussSeidelSolver();
  }
}
