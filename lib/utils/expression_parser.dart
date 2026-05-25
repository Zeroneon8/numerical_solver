import 'expression_evaluator.dart';

class ExpressionParser {
  static String toLatex(String input) {
    var output = input.trim();
    if (output.isEmpty) {
      return '';
    }

    output = _insertImplicitMultiplication(output);
    ExpressionEvaluator.evaluate(output);

    output = output.replaceAll('π', r'\pi');
    output = output.replaceAll('*', r'\cdot');

    output = output.replaceAllMapped(RegExp(r'root\(([^)]*)\)\{([^}]*)\}'), (
      match,
    ) {
      final index = match.group(1)?.trim() ?? '';
      final radicand = match.group(2) ?? '';
      if (index.isEmpty || index == '2') {
        return '\\sqrt{$radicand}';
      }
      return '\\sqrt[$index]{$radicand}';
    });

    output = output.replaceAllMapped(
      RegExp(r'\^\(([^)]*)\)'),
      (match) => '^{${match.group(1) ?? ''}}',
    );

    return output;
  }

  static String _insertImplicitMultiplication(String input) {
    var output = input;
    output = output.replaceAllMapped(
      RegExp(r'(\d)([A-Za-zπ])'),
      (m) => '${m.group(1)}*${m.group(2)}',
    );
    output = output.replaceAllMapped(
      RegExp(r'(\d)\('),
      (m) => '${m.group(1)}*(',
    );
    output = output.replaceAll(')(', ')*(');
    output = output.replaceAllMapped(
      RegExp(r'([A-Za-zπ])\('),
      (m) => '${m.group(1)}*(',
    );
    output = output.replaceAll('root*(', 'root(');
    return output;
  }
}
