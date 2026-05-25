import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../domain/models/solution_step.dart';
import '../../utils/latex_formatter.dart';

class StepCard extends StatefulWidget {
  const StepCard({
    super.key,
    required this.step,
    required this.initiallyExpanded,
    this.showApproximation = false,
  });

  final SolutionStep step;
  final bool initiallyExpanded;
  final bool showApproximation;

  @override
  State<StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<StepCard> {
  late String _matrixLatex;
  late List<String> _variableNames;

  @override
  void initState() {
    super.initState();
    _computeCaches();
  }

  @override
  void didUpdateWidget(covariant StepCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      _computeCaches();
    }
  }

  void _computeCaches() {
    _matrixLatex = LatexFormatter.matrixToLatex(widget.step.matrixState);
    _variableNames = _variableNamesFor(widget.step.solutionVector?.length ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final isIterationStep =
        widget.step.title.startsWith('Iteración') ||
        widget.step.title.startsWith('Convergencia');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: widget.initiallyExpanded,
        title: _MathText(text: widget.step.title, style: titleStyle),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (!isIterationStep && widget.step.description.isNotEmpty)
                  _MathText(text: widget.step.description, style: bodyStyle),
                if (!isIterationStep) ...<Widget>[
                  const SizedBox(height: 12),
                  if (widget.step.secondMatrixLatex != null) ...<Widget>[
                    const Text(
                      'Matriz L',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                  ],
                  _MathScroll(child: Math.tex(_matrixLatex)),
                  if (widget.step.secondMatrixLatex != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      widget.step.secondMatrixLabel ?? 'Segunda matriz',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    _MathScroll(
                      child: Math.tex(widget.step.secondMatrixLatex!),
                    ),
                  ],
                ] else ...<Widget>[
                  if (widget.step.solutionVector != null) ...<Widget>[
                    _MathScroll(
                      child: Math.tex(
                        widget.showApproximation
                            ? LatexFormatter.vectorToLatexWithApproximation(
                                widget.step.solutionVector!,
                                _variableNames,
                              )
                            : LatexFormatter.vectorToLatex(
                                widget.step.solutionVector!,
                                _variableNames,
                              ),
                      ),
                    ),
                  ],
                  if (widget.step.secondMatrixLatex != null) ...<Widget>[
                    const SizedBox(height: 8),
                    _MathScroll(
                      child: Math.tex(widget.step.secondMatrixLatex!),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _variableNamesFor(int size) {
    const base = <String>['x', 'y', 'z'];
    return List<String>.generate(size, (index) {
      if (index < base.length) {
        return base[index];
      }
      return 'x_{${index + 1}}';
    });
  }
}

class _MathScroll extends StatelessWidget {
  const _MathScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(padding: const EdgeInsets.only(top: 8), child: child),
    );
  }
}

class _MathText extends StatelessWidget {
  const _MathText({required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    return Text.rich(
      TextSpan(
        style: effectiveStyle,
        children: _buildSpans(text, effectiveStyle),
      ),
      softWrap: true,
    );
  }

  List<InlineSpan> _buildSpans(String text, TextStyle style) {
    final spans = <InlineSpan>[];
    var index = 0;
    for (final match in _mathFragmentPattern.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      final fragment = match.group(0)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Math.tex(_fragmentToLatex(fragment), textStyle: style),
        ),
      );
      index = match.end;
    }
    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index)));
    }
    return spans;
  }

  String _fragmentToLatex(String fragment) {
    if (_fractionPattern.hasMatch(fragment)) {
      final parts = fragment.split('/');
      return '\\frac{${parts[0]}}{${parts[1]}}';
    }
    if (_simpleSubscriptPattern.hasMatch(fragment)) {
      final parts = fragment.split('_');
      return '${parts[0]}_{${parts[1]}}';
    }
    return fragment;
  }

  static final RegExp _mathFragmentPattern = RegExp(
    r'(?:[A-Za-z]+_[A-Za-z0-9]+|[A-Za-z]+_\{[^}]+\}|[A-Za-z]+\^\{[^}]+\}|\d+/\d+)',
  );
  static final RegExp _fractionPattern = RegExp(r'^\d+/\d+$');
  static final RegExp _simpleSubscriptPattern = RegExp(
    r'^[A-Za-z]+_[A-Za-z0-9]+$',
  );
}
