import 'package:fraction/fraction.dart';

import '../models/linear_system.dart';
import '../models/solver_result.dart';

abstract class ISolverRepository {
  SolverResult solve(LinearSystem system, {Fraction? tolerance});
}
