import 'solution_step.dart';

sealed class SolverResult {
  const SolverResult();
}

class SolverSuccess extends SolverResult {
  const SolverSuccess(this.steps);

  final List<SolutionStep> steps;
}

class SolverFailure extends SolverResult {
  const SolverFailure(this.message);

  final String message;
}
