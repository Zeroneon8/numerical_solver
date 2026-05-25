import 'package:fraction/fraction.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums/numerical_method.dart';
import '../../domain/models/solver_result.dart';
import '../../domain/models/solution_step.dart';
import '../../utils/latex_formatter.dart';
import '../providers/system_input_provider.dart';
import '../providers/solver_provider.dart';
import '../widgets/math_keyboard.dart';
import '../widgets/matrix_input_grid.dart';
import '../widgets/step_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<MatrixInputGridState> _gridKey =
      GlobalKey<MatrixInputGridState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _desiredErrorController = TextEditingController();
  late final ProviderSubscription<AsyncValue<SolverViewState>> _solverSub;
  bool _hasActiveCell = false;
  bool _desiredErrorActive = false;

  @override
  void initState() {
    super.initState();
    _desiredErrorController.addListener(_onDesiredErrorChanged);
    _solverSub = ref.listenManual<AsyncValue<SolverViewState>>(solverProvider, (
      previous,
      next,
    ) {
      final finished = previous?.isLoading == true && !next.isLoading;
      if (!finished) {
        return;
      }
      _scrollToResults();
    });
  }

  @override
  void dispose() {
    _solverSub.close();
    _scrollController.dispose();
    _desiredErrorController.removeListener(_onDesiredErrorChanged);
    _desiredErrorController.dispose();
    super.dispose();
  }

  void _onDesiredErrorChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _onSizeSelected(int size) {
    ref.read(systemInputProvider.notifier).resize(size);
  }

  void _onCellChanged(int row, int col, String value) {
    ref.read(systemInputProvider.notifier).updateCell(row, col, value);
  }

  void _onActiveChanged(MatrixCellPosition? position) {
    final hasActiveCell = position != null;
    if (_hasActiveCell == hasActiveCell) {
      return;
    }
    setState(() {
      _hasActiveCell = hasActiveCell;
      if (hasActiveCell) {
        _desiredErrorActive = false;
      }
    });
  }

  void _activateDesiredErrorField() {
    _gridKey.currentState?.clearActiveCell();
    setState(() {
      _desiredErrorActive = true;
    });
  }

  void _deactivateDesiredErrorField() {
    if (!_desiredErrorActive) {
      return;
    }
    setState(() {
      _desiredErrorActive = false;
    });
  }

  void _insertKey(MathKey key) {
    if (_desiredErrorActive) {
      if (!_isAllowedDesiredErrorKey(key.text)) {
        return;
      }
      _insertTextInDesiredError(key.text);
      return;
    }
    _gridKey.currentState?.insertText(key.text, cursorOffset: key.cursorOffset);
  }

  void _backspace() {
    if (_desiredErrorActive) {
      _backspaceDesiredError();
      return;
    }
    _gridKey.currentState?.backspace();
  }

  void _confirm() {
    if (_desiredErrorActive) {
      _deactivateDesiredErrorField();
      return;
    }
    _gridKey.currentState?.moveToNextCell();
  }

  void _moveCursorLeft() {
    if (_desiredErrorActive) {
      _moveDesiredErrorCursor(-1);
      return;
    }
    _gridKey.currentState?.moveCursorLeft();
  }

  void _moveCursorRight() {
    if (_desiredErrorActive) {
      _moveDesiredErrorCursor(1);
      return;
    }
    _gridKey.currentState?.moveCursorRight();
  }

  void _clear() {
    ref.read(systemInputProvider.notifier).clear();
    _gridKey.currentState?.clearAll();
    _desiredErrorController.clear();
    _deactivateDesiredErrorField();
  }

  void _solve(NumericalMethod method) {
    _gridKey.currentState?.validateActiveCell();
    if (_gridKey.currentState?.hasInvalidNonEmptyCells() ?? false) {
      ref.read(solverProvider.notifier).solve(method, const <List<String>>[
        <String>[''],
      ]);
      return;
    }
    final matrix = ref.read(systemInputProvider).matrix;
    ref
        .read(solverProvider.notifier)
        .solve(method, matrix, desiredError: _desiredErrorController.text);
  }

  void _scrollToResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildSolveButton(
    NumericalMethod method,
    String label,
    bool hasResult,
    NumericalMethod? activeMethod,
  ) {
    final isActive = activeMethod == null || activeMethod == method;
    if (!hasResult || isActive) {
      return FilledButton(onPressed: () => _solve(method), child: Text(label));
    }
    return OutlinedButton(onPressed: () => _solve(method), child: Text(label));
  }

  @override
  Widget build(BuildContext context) {
    final inputState = ref.watch(systemInputProvider);
    final size = inputState.size;
    final solverState = ref.watch(solverProvider);
    final solverView = solverState.asData?.value;
    final hasResult = solverView?.result != null;
    final activeMethod = solverView?.activeMethod;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Numerical Solver')),
      body: SafeArea(
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) {
              return KeyEventResult.ignored;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _moveCursorLeft();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _moveCursorRight();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Column(
            children: <Widget>[
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _gridKey.currentState?.clearActiveCell();
                    _deactivateDesiredErrorField();
                  },
                  behavior: HitTestBehavior.deferToChild,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Tamaño del sistema',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: <Widget>[
                              for (final n in <int>[2, 3, 4, 5, 6])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text('${n}x$n'),
                                    selected: size == n,
                                    onSelected: (selected) {
                                      if (selected) {
                                        _onSizeSelected(n);
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        MatrixInputGrid(
                          key: _gridKey,
                          size: size,
                          onCellChanged: _onCellChanged,
                          onActiveChanged: _onActiveChanged,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _desiredErrorController,
                          readOnly: true,
                          showCursor: true,
                          onTap: _activateDesiredErrorField,
                          decoration: InputDecoration(
                            labelText: 'Error deseado (opcional)',
                            hintText: 'Ejemplo: 0.000001',
                            border: const OutlineInputBorder(),
                            errorText: _desiredErrorErrorText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            _buildSolveButton(
                              NumericalMethod.lu,
                              'Resolver con LU',
                              hasResult,
                              activeMethod,
                            ),
                            _buildSolveButton(
                              NumericalMethod.jacobi,
                              'Resolver con Jacobi',
                              hasResult,
                              activeMethod,
                            ),
                            _buildSolveButton(
                              NumericalMethod.gaussSeidel,
                              'Resolver con Gauss-Seidel',
                              hasResult,
                              activeMethod,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _clear,
                          child: const Text('Limpiar'),
                        ),
                        const SizedBox(height: 16),
                        _ResultsSection(solverState: solverState),
                      ],
                    ),
                  ),
                ),
              ),
              MathKeyboard(
                visible: _hasActiveCell || _desiredErrorActive,
                onKeyPressed: _insertKey,
                onBackspace: _backspace,
                onConfirm: _confirm,
                onMoveLeft: _moveCursorLeft,
                onMoveRight: _moveCursorRight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on _HomeScreenState {
  String? get _desiredErrorErrorText {
    final text = _desiredErrorController.text.trim();
    if (text.isEmpty) {
      return null;
    }
    if (!_isAllowedDesiredErrorSyntax(text)) {
      return 'Hay una o más expresiones matemáticas inválidas';
    }
    return null;
  }

  bool _isAllowedDesiredErrorSyntax(String input) {
    return RegExp(r'^\d+(\.\d*)?$').hasMatch(input);
  }

  bool _isAllowedDesiredErrorKey(String text) {
    return RegExp(r'^[0-9.]$').hasMatch(text);
  }

  void _insertTextInDesiredError(String text) {
    final value = _desiredErrorController.value;
    final selection = value.selection;
    final start = selection.start < 0 ? value.text.length : selection.start;
    final end = selection.end < 0 ? start : selection.end;
    final newText = value.text.replaceRange(start, end, text);
    final newOffset = start + text.length;
    _desiredErrorController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  void _backspaceDesiredError() {
    final value = _desiredErrorController.value;
    final selection = value.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final newText = value.text.replaceRange(
        selection.start,
        selection.end,
        '',
      );
      _desiredErrorController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
      return;
    }
    final cursor = selection.start < 0 ? value.text.length : selection.start;
    if (cursor <= 0) {
      return;
    }
    final newText = value.text.replaceRange(cursor - 1, cursor, '');
    _desiredErrorController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor - 1),
    );
  }

  void _moveDesiredErrorCursor(int delta) {
    final value = _desiredErrorController.value;
    final cursor = value.selection.baseOffset < 0
        ? value.text.length
        : value.selection.baseOffset;
    final nextOffset = (cursor + delta).clamp(0, value.text.length);
    _desiredErrorController.value = value.copyWith(
      selection: TextSelection.collapsed(offset: nextOffset),
    );
  }
}

class _ResultsSection extends StatelessWidget {
  const _ResultsSection({required this.solverState});

  final AsyncValue<SolverViewState> solverState;

  static const List<String> _variables = <String>['x', 'y', 'z', 'a', 'b', 'c'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return solverState.when(
      data: (viewState) {
        final result = viewState.result;
        if (result == null) {
          return const SizedBox.shrink();
        }
        if (result is SolverFailure) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              result.message,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
          );
        }
        final success = result as SolverSuccess;
        final solution = _extractSolution(success.steps);
        final steps = success.steps;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (solution != null) ...<Widget>[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Math.tex(
                    LatexFormatter.vectorToLatexWithApproximation(
                      solution,
                      _variables.take(solution.length).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: steps.length,
              itemBuilder: (context, index) {
                return StepCard(
                  key: ValueKey<String>('${steps[index].title}-$index'),
                  step: steps[index],
                  initiallyExpanded: index == 0,
                  showApproximation: index == steps.length - 1,
                );
              },
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          error.toString(),
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
        ),
      ),
    );
  }

  List<Fraction>? _extractSolution(List<SolutionStep> steps) {
    for (final step in steps.reversed) {
      if (step.solutionVector != null) {
        return step.solutionVector;
      }
    }
    return null;
  }
}
