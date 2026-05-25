import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../utils/expression_parser.dart';

typedef MatrixCellChanged = void Function(int row, int col, String value);
typedef ActiveCellChanged = void Function(MatrixCellPosition? position);

enum _CellValidationState { empty, valid, invalid }

class MatrixCellPosition {
  const MatrixCellPosition(this.row, this.col);

  final int row;
  final int col;
}

class MatrixInputGrid extends StatefulWidget {
  const MatrixInputGrid({
    super.key,
    required this.size,
    this.onCellChanged,
    this.onActiveChanged,
  });

  final int size;
  final MatrixCellChanged? onCellChanged;
  final ActiveCellChanged? onActiveChanged;

  @override
  State<MatrixInputGrid> createState() => MatrixInputGridState();
}

class MatrixInputGridState extends State<MatrixInputGrid> {
  static const List<String> _variables = <String>['x', 'y', 'z', 'a', 'b', 'c'];
  static const double _cellWidth = 64;
  static const double _cellHeight = 46;

  final List<List<TextEditingController>> _controllers =
      <List<TextEditingController>>[];
  final List<List<FocusNode>> _focusNodes = <List<FocusNode>>[];
  final List<List<TextSelection>> _selections = <List<TextSelection>>[];
  final List<List<ScrollController>> _scrollControllers =
      <List<ScrollController>>[];
  final List<List<_CellValidationState>> _cellStates =
      <List<_CellValidationState>>[];
  final List<List<String?>> _latexCache = <List<String?>>[];
  final Set<int> _dirtyWidthColumns = <int>{};
  List<double> _columnWidths = <double>[];
  TextStyle? _lastWidthTextStyle;
  double? _lastWidthScale;
  MatrixCellPosition? _active;
  bool _lastPointerInside = false;
  bool _suppressSelectionFix = false;

  @override
  void initState() {
    super.initState();
    _initGrid();
  }

  @override
  void didUpdateWidget(covariant MatrixInputGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size != widget.size) {
      _resetGrid();
    }
  }

  @override
  void dispose() {
    _disposeGrid();
    super.dispose();
  }

  void _initGrid() {
    for (var row = 0; row < widget.size; row++) {
      final rowControllers = <TextEditingController>[];
      final rowFocusNodes = <FocusNode>[];
      final rowSelections = <TextSelection>[];
      final rowScrollControllers = <ScrollController>[];
      final rowStates = <_CellValidationState>[];
      final rowLatex = <String?>[];
      for (var col = 0; col < widget.size + 1; col++) {
        final controller = TextEditingController();
        final focusNode = FocusNode();
        final scrollController = ScrollController();
        final rowIndex = row;
        final colIndex = col;
        controller.addListener(() {
          _handleSelectionChange(rowIndex, colIndex, controller);
        });
        rowControllers.add(controller);
        rowFocusNodes.add(focusNode);
        rowSelections.add(const TextSelection.collapsed(offset: 0));
        rowScrollControllers.add(scrollController);
        rowStates.add(_CellValidationState.empty);
        rowLatex.add(null);
      }
      _controllers.add(rowControllers);
      _focusNodes.add(rowFocusNodes);
      _selections.add(rowSelections);
      _scrollControllers.add(rowScrollControllers);
      _cellStates.add(rowStates);
      _latexCache.add(rowLatex);
    }
    _columnWidths = List<double>.filled(widget.size + 1, _cellWidth);
    _dirtyWidthColumns
      ..clear()
      ..addAll(List<int>.generate(widget.size + 1, (index) => index));
  }

  void _disposeGrid() {
    for (final rowControllers in _controllers) {
      for (final controller in rowControllers) {
        controller.dispose();
      }
    }
    for (final rowFocusNodes in _focusNodes) {
      for (final focusNode in rowFocusNodes) {
        focusNode.dispose();
      }
    }
    for (final rowScrolls in _scrollControllers) {
      for (final scrollController in rowScrolls) {
        scrollController.dispose();
      }
    }
    _controllers.clear();
    _focusNodes.clear();
    _selections.clear();
    _scrollControllers.clear();
    _cellStates.clear();
    _latexCache.clear();
    _dirtyWidthColumns.clear();
    _columnWidths = <double>[];
    _lastWidthTextStyle = null;
    _lastWidthScale = null;
  }

  void _resetGrid() {
    _disposeGrid();
    _initGrid();
    _active = null;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      FocusScope.of(context).unfocus();
      widget.onActiveChanged?.call(null);
    });
  }

  void _setActiveCell(MatrixCellPosition? position) {
    final previous = _active;
    if (previous != null &&
        (position == null ||
            previous.row != position.row ||
            previous.col != position.col)) {
      _validateCell(previous.row, previous.col);
    }

    setState(() {
      _active = position;
    });
    widget.onActiveChanged?.call(position);
    if (position == null) {
      FocusScope.of(context).unfocus();
      return;
    }
    final focusNode = _focusNodes[position.row][position.col];
    final controller = _controllers[position.row][position.col];
    focusNode.requestFocus();
    final selection = TextSelection.collapsed(offset: controller.text.length);
    controller.selection = selection;
    _selections[position.row][position.col] = selection;
    _scrollToEnd(position.row, position.col);
  }

  void clearActiveCell() {
    if (_active == null) {
      return;
    }
    _setActiveCell(null);
  }

  void validateActiveCell() {
    final active = _active;
    if (active == null) {
      return;
    }
    _validateCell(active.row, active.col);
    setState(() {});
  }

  bool hasInvalidNonEmptyCells() {
    for (var row = 0; row < widget.size; row++) {
      for (var col = 0; col < widget.size + 1; col++) {
        if (_controllers[row][col].text.trim().isEmpty) {
          continue;
        }
        if (_cellStates[row][col] == _CellValidationState.invalid) {
          return true;
        }
      }
    }
    return false;
  }

  void _updateCellValue(int row, int col, String value) {
    widget.onCellChanged?.call(row, col, value);
  }

  bool _isActive(int row, int col) {
    return _active?.row == row && _active?.col == col;
  }

  void _ensureActiveFocus() {
    final position = _active;
    if (position == null) {
      return;
    }
    final focusNode = _focusNodes[position.row][position.col];
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }
  }

  void _scrollToEnd(int row, int col) {
    final scrollController = _scrollControllers[row][col];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) {
        return;
      }
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  void _handleSelectionChange(
    int row,
    int col,
    TextEditingController controller,
  ) {
    if (!_isActive(row, col)) {
      return;
    }
    if (_suppressSelectionFix) {
      return;
    }
    final selection = controller.selection;
    if (!selection.isValid) {
      return;
    }
    if (!_lastPointerInside &&
        controller.text.isNotEmpty &&
        selection.start == 0 &&
        selection.end == controller.text.length) {
      final fallback = _fallbackSelection(row, col, controller);
      if (fallback != selection) {
        _suppressSelectionFix = true;
        controller.selection = fallback;
        _suppressSelectionFix = false;
        _selections[row][col] = fallback;
      }
      return;
    }
    _selections[row][col] = selection;
  }

  TextSelection _effectiveSelection(
    int row,
    int col,
    TextEditingController controller,
  ) {
    final selection = controller.selection;
    if (!selection.isValid) {
      return _fallbackSelection(row, col, controller);
    }
    if (!_lastPointerInside &&
        controller.text.isNotEmpty &&
        selection.start == 0 &&
        selection.end == controller.text.length) {
      return _fallbackSelection(row, col, controller);
    }
    return selection;
  }

  TextSelection _fallbackSelection(
    int row,
    int col,
    TextEditingController controller,
  ) {
    final stored = _selections[row][col];
    if (stored.isValid && stored.end <= controller.text.length) {
      return stored;
    }
    return TextSelection.collapsed(offset: controller.text.length);
  }

  Widget _buildCell(
    int row,
    int col, {
    required double width,
    required Color activeColor,
    required Color bColumnColor,
    required Color borderColor,
    required TextStyle textStyle,
  }) {
    final isBColumn = col == widget.size;
    final isActive = _isActive(row, col);
    final cellState = _cellStates[row][col];
    final isInvalid = !isActive && cellState == _CellValidationState.invalid;
    return Container(
      width: width,
      height: _cellHeight,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: isInvalid
            ? Colors.red.withValues(alpha: 0.15)
            : isActive
            ? activeColor
            : (isBColumn ? bColumnColor : null),
        border: Border.all(color: isInvalid ? Colors.red : borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isActive
          ? Listener(
              onPointerDown: (_) {
                _lastPointerInside = true;
              },
              child: TextField(
                controller: _controllers[row][col],
                focusNode: _focusNodes[row][col],
                scrollController: _scrollControllers[row][col],
                readOnly: true,
                showCursor: true,
                enableInteractiveSelection: true,
                keyboardType: TextInputType.none,
                textInputAction: TextInputAction.none,
                enableSuggestions: false,
                autocorrect: false,
                textAlign: TextAlign.center,
                style: textStyle,
                scrollPhysics: const ClampingScrollPhysics(),
                maxLines: 1,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 6,
                  ),
                ),
                onTap: () {
                  if (_isActive(row, col)) {
                    return;
                  }
                  _setActiveCell(MatrixCellPosition(row, col));
                },
              ),
            )
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _setActiveCell(MatrixCellPosition(row, col)),
              child: _buildDisplayContent(row, col, textStyle),
            ),
    );
  }

  Widget _buildDisplayContent(int row, int col, TextStyle textStyle) {
    final raw = _controllers[row][col].text;
    if (raw.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (_cellStates[row][col] == _CellValidationState.invalid) {
      return Center(
        child: Text(raw, textAlign: TextAlign.center, style: textStyle),
      );
    }

    final cachedLatex = _latexCache[row][col];
    if (cachedLatex != null) {
      return Center(child: Math.tex(cachedLatex, textStyle: textStyle));
    }

    try {
      final latex = ExpressionParser.toLatex(raw);
      _latexCache[row][col] = latex;
      return Center(child: Math.tex(latex, textStyle: textStyle));
    } catch (_) {
      return Center(
        child: Text(raw, textAlign: TextAlign.center, style: textStyle),
      );
    }
  }

  void _updateColumnWidthsIfNeeded(TextStyle textStyle, TextScaler textScaler) {
    final widthScale = textScaler.scale(1);
    final styleChanged = _lastWidthTextStyle != textStyle;
    final scaleChanged = _lastWidthScale != widthScale;

    if (styleChanged ||
        scaleChanged ||
        _columnWidths.length != widget.size + 1) {
      _columnWidths = List<double>.filled(widget.size + 1, _cellWidth);
      _dirtyWidthColumns
        ..clear()
        ..addAll(List<int>.generate(widget.size + 1, (index) => index));
      _lastWidthTextStyle = textStyle;
      _lastWidthScale = widthScale;
    }

    if (_dirtyWidthColumns.isEmpty) {
      return;
    }

    for (final col in _dirtyWidthColumns) {
      var maxWidth = 0.0;
      for (var row = 0; row < widget.size; row++) {
        final value = _controllers[row][col].text;
        final displayText = value.isEmpty ? '0' : value;
        final painter = TextPainter(
          text: TextSpan(text: displayText, style: textStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          textScaler: textScaler,
        )..layout();
        if (painter.width > maxWidth) {
          maxWidth = painter.width;
        }
      }
      _columnWidths[col] = (maxWidth + 24).clamp(_cellWidth, 100.0).toDouble();
    }
    _dirtyWidthColumns.clear();
  }

  void _updateCellDerivedState(int row, int col, String newText) {
    if (newText.trim().isEmpty) {
      _cellStates[row][col] = _CellValidationState.empty;
      _latexCache[row][col] = null;
    } else {
      _cellStates[row][col] = _CellValidationState.valid;
      try {
        _latexCache[row][col] = ExpressionParser.toLatex(newText);
      } catch (_) {
        _latexCache[row][col] = null;
      }
    }
    _dirtyWidthColumns.add(col);
  }

  void insertText(String text, {int? cursorOffset}) {
    final position = _active;
    if (position == null) {
      return;
    }
    _lastPointerInside = false;
    _ensureActiveFocus();
    final controller = _controllers[position.row][position.col];
    final currentText = controller.text;
    final selection = _effectiveSelection(
      position.row,
      position.col,
      controller,
    );
    final start = selection.start < 0 ? currentText.length : selection.start;
    final end = selection.end < 0 ? currentText.length : selection.end;
    final newText = currentText.replaceRange(start, end, text);
    final offset = cursorOffset ?? text.length;
    final caret = (start + offset).clamp(0, newText.length).toInt();
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: caret),
    );
    _selections[position.row][position.col] = TextSelection.collapsed(
      offset: caret,
    );
    _updateCellValue(position.row, position.col, newText);
    _updateCellDerivedState(position.row, position.col, newText);
    setState(() {});
  }

  void backspace() {
    final position = _active;
    if (position == null) {
      return;
    }
    _lastPointerInside = false;
    _ensureActiveFocus();
    final controller = _controllers[position.row][position.col];
    final currentText = controller.text;
    if (currentText.isEmpty) {
      return;
    }
    final selection = _effectiveSelection(
      position.row,
      position.col,
      controller,
    );
    var start = selection.start < 0 ? currentText.length : selection.start;
    var end = selection.end < 0 ? currentText.length : selection.end;
    if (start != end) {
      final newText = currentText.replaceRange(start, end, '');
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
      _selections[position.row][position.col] = TextSelection.collapsed(
        offset: start,
      );
      _updateCellValue(position.row, position.col, newText);
      _updateCellDerivedState(position.row, position.col, newText);
      setState(() {});
      return;
    }
    if (start == 0) {
      return;
    }
    final newText = currentText.replaceRange(start - 1, start, '');
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start - 1),
    );
    _selections[position.row][position.col] = TextSelection.collapsed(
      offset: start - 1,
    );
    _updateCellValue(position.row, position.col, newText);
    _updateCellDerivedState(position.row, position.col, newText);
    setState(() {});
  }

  void moveCursorLeft() {
    final position = _active;
    if (position == null) {
      return;
    }
    _lastPointerInside = false;
    _ensureActiveFocus();
    final controller = _controllers[position.row][position.col];
    final selection = _effectiveSelection(
      position.row,
      position.col,
      controller,
    );
    if (selection.start != selection.end) {
      controller.selection = TextSelection.collapsed(offset: selection.start);
      _selections[position.row][position.col] = TextSelection.collapsed(
        offset: selection.start,
      );
      return;
    }
    final current = selection.start < 0
        ? controller.text.length
        : selection.start;
    final next = (current - 1).clamp(0, controller.text.length).toInt();
    controller.selection = TextSelection.collapsed(offset: next);
    _selections[position.row][position.col] = TextSelection.collapsed(
      offset: next,
    );
  }

  void moveCursorRight() {
    final position = _active;
    if (position == null) {
      return;
    }
    _lastPointerInside = false;
    _ensureActiveFocus();
    final controller = _controllers[position.row][position.col];
    final selection = _effectiveSelection(
      position.row,
      position.col,
      controller,
    );
    if (selection.start != selection.end) {
      controller.selection = TextSelection.collapsed(offset: selection.end);
      _selections[position.row][position.col] = TextSelection.collapsed(
        offset: selection.end,
      );
      return;
    }
    final current = selection.start < 0
        ? controller.text.length
        : selection.start;
    final next = (current + 1).clamp(0, controller.text.length).toInt();
    controller.selection = TextSelection.collapsed(offset: next);
    _selections[position.row][position.col] = TextSelection.collapsed(
      offset: next,
    );
  }

  void moveToNextCell() {
    final position = _active;
    if (position == null) {
      return;
    }
    final lastColumn = widget.size;
    final isLastCell =
        position.row == widget.size - 1 && position.col == lastColumn;
    if (isLastCell) {
      _setActiveCell(null);
      return;
    }
    var nextRow = position.row;
    var nextCol = position.col + 1;
    if (nextCol > lastColumn) {
      nextCol = 0;
      nextRow = position.row + 1;
    }
    if (nextRow >= widget.size) {
      return;
    }
    _setActiveCell(MatrixCellPosition(nextRow, nextCol));
  }

  void clearAll() {
    for (var row = 0; row < _controllers.length; row++) {
      for (var col = 0; col < _controllers[row].length; col++) {
        _controllers[row][col].clear();
        _cellStates[row][col] = _CellValidationState.empty;
        _latexCache[row][col] = null;
        _dirtyWidthColumns.add(col);
      }
    }
    setState(() {});
  }

  void _validateCell(int row, int col) {
    final content = _controllers[row][col].text.trim();
    if (content.isEmpty) {
      _cellStates[row][col] = _CellValidationState.empty;
      return;
    }

    try {
      final latex = _latexCache[row][col] ?? ExpressionParser.toLatex(content);
      _latexCache[row][col] = latex;
      try {
        Math.tex(latex);
        _cellStates[row][col] = _CellValidationState.valid;
      } catch (_) {
        _cellStates[row][col] = _CellValidationState.invalid;
      }
    } catch (_) {
      _cellStates[row][col] = _CellValidationState.invalid;
    }
  }

  List<List<String>> getValues() {
    return _controllers
        .map(
          (rowControllers) =>
              rowControllers.map((controller) => controller.text).toList(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primaryContainer.withValues(
      alpha: 0.6,
    );
    final bColumnColor = theme.colorScheme.secondaryContainer.withValues(
      alpha: 0.35,
    );
    final borderColor = theme.dividerColor;
    final variableStyle = theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );
    final textStyle =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final textScaler = MediaQuery.textScalerOf(context);
    _updateColumnWidthsIfNeeded(textStyle, textScaler);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: <Widget>[
          for (var row = 0; row < widget.size; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  for (var col = 0; col < widget.size; col++) ...<Widget>[
                    _buildCell(
                      row,
                      col,
                      width: _columnWidths[col],
                      activeColor: activeColor,
                      bColumnColor: bColumnColor,
                      borderColor: borderColor,
                      textStyle: textStyle,
                    ),
                    Text(
                      _variables[col],
                      style: variableStyle ?? theme.textTheme.titleMedium,
                    ),
                    if (col < widget.size - 1) ...<Widget>[
                      const SizedBox(width: 6),
                      Text('+', style: theme.textTheme.titleMedium),
                      const SizedBox(width: 6),
                    ] else
                      const SizedBox(width: 8),
                  ],
                  Text('=', style: theme.textTheme.titleMedium),
                  const SizedBox(width: 8),
                  _buildCell(
                    row,
                    widget.size,
                    width: _columnWidths[widget.size],
                    activeColor: activeColor,
                    bColumnColor: bColumnColor,
                    borderColor: borderColor,
                    textStyle: textStyle,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
