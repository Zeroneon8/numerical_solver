import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final systemInputProvider =
    NotifierProvider<SystemInputNotifier, SystemInputState>(
      SystemInputNotifier.new,
    );

@immutable
class SystemInputState {
  const SystemInputState({required this.size, required this.matrix});

  final int size;
  final List<List<String>> matrix;

  factory SystemInputState.empty(int size) {
    return SystemInputState(size: size, matrix: _emptyMatrix(size));
  }

  SystemInputState copyWith({int? size, List<List<String>>? matrix}) {
    return SystemInputState(
      size: size ?? this.size,
      matrix: matrix ?? this.matrix,
    );
  }
}

class SystemInputNotifier extends Notifier<SystemInputState> {
  @override
  SystemInputState build() {
    return SystemInputState.empty(2);
  }

  void updateCell(int row, int col, String value) {
    final matrix = List<List<String>>.from(state.matrix, growable: false);
    if (row < 0 || row >= matrix.length) {
      return;
    }
    if (col < 0 || col >= matrix[row].length) {
      return;
    }
    final updatedRow = List<String>.from(matrix[row], growable: false);
    updatedRow[col] = value;
    matrix[row] = updatedRow;
    state = state.copyWith(matrix: matrix);
  }

  void resize(int size) {
    state = SystemInputState.empty(size);
  }

  void clear() {
    state = state.copyWith(matrix: _emptyMatrix(state.size));
  }
}

List<List<String>> _emptyMatrix(int size) {
  return List.generate(size, (_) => List<String>.filled(size + 1, ''));
}
