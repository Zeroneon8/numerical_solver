import 'package:fraction/fraction.dart';

import 'invalid_expression_exception.dart';

class ExpressionEvaluator {
  static Fraction evaluate(String input) {
    final prepared = _insertImplicitMultiplication(input.trim());
    final tokenizer = _Tokenizer(prepared);
    final parser = _Parser(tokenizer);
    final result = parser.parseExpression();
    if (!tokenizer.isAtEnd) {
      throw InvalidExpressionException('Expresion invalida');
    }
    return _normalizeResult(result);
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

  static Fraction _normalizeResult(Fraction value) {
    final normalized = Fraction(
      _toInt(value.numerator),
      _toInt(value.denominator),
    );
    final reduced = normalized.reduce();
    if (_isOne(reduced.denominator)) {
      return Fraction(_toInt(reduced.numerator), 1);
    }
    return reduced;
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is BigInt) {
      return value.toInt();
    }
    return (value as dynamic).toInt();
  }

  static bool _isOne(Object? value) {
    return value == 1 || value == BigInt.one;
  }
}

enum _TokenType {
  number,
  identifier,
  plus,
  minus,
  star,
  slash,
  caret,
  lParen,
  rParen,
  lBrace,
  rBrace,
  eof,
}

class _Token {
  const _Token(this.type, this.lexeme);

  final _TokenType type;
  final String lexeme;
}

class _Tokenizer {
  _Tokenizer(this.source);

  final String source;
  int _index = 0;
  _Token? _cached;

  bool get isAtEnd {
    final token = peek();
    return token.type == _TokenType.eof;
  }

  _Token peek() {
    _cached ??= _nextToken();
    return _cached!;
  }

  _Token advance() {
    final token = peek();
    _cached = null;
    return token;
  }

  _Token _nextToken() {
    _skipWhitespace();
    if (_index >= source.length) {
      return const _Token(_TokenType.eof, '');
    }
    final char = source[_index];
    if (_isDigit(char) || char == '.') {
      return _numberToken();
    }
    if (_isLetter(char) || char == 'π') {
      return _identifierToken();
    }
    _index++;
    switch (char) {
      case '+':
        return const _Token(_TokenType.plus, '+');
      case '-':
        return const _Token(_TokenType.minus, '-');
      case '*':
        return const _Token(_TokenType.star, '*');
      case '/':
        return const _Token(_TokenType.slash, '/');
      case '^':
        return const _Token(_TokenType.caret, '^');
      case '(':
        return const _Token(_TokenType.lParen, '(');
      case ')':
        return const _Token(_TokenType.rParen, ')');
      case '{':
        return const _Token(_TokenType.lBrace, '{');
      case '}':
        return const _Token(_TokenType.rBrace, '}');
      default:
        throw InvalidExpressionException('Expresion invalida');
    }
  }

  void _skipWhitespace() {
    while (_index < source.length) {
      final char = source[_index];
      if (char == ' ' || char == '\t' || char == '\n' || char == '\r') {
        _index++;
      } else {
        break;
      }
    }
  }

  _Token _numberToken() {
    final start = _index;
    var hasDot = false;
    while (_index < source.length) {
      final char = source[_index];
      if (char == '.') {
        if (hasDot) {
          break;
        }
        hasDot = true;
        _index++;
        continue;
      }
      if (!_isDigit(char)) {
        break;
      }
      _index++;
    }
    return _Token(_TokenType.number, source.substring(start, _index));
  }

  _Token _identifierToken() {
    final start = _index;
    while (_index < source.length) {
      final char = source[_index];
      if (_isLetter(char) || char == 'π') {
        _index++;
      } else {
        break;
      }
    }
    return _Token(_TokenType.identifier, source.substring(start, _index));
  }

  bool _isDigit(String char) =>
      char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;

  bool _isLetter(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }
}

class _Parser {
  _Parser(this._tokenizer);

  final _Tokenizer _tokenizer;

  Fraction parseExpression() {
    var value = _parseTerm();
    while (true) {
      final token = _tokenizer.peek();
      if (token.type == _TokenType.plus) {
        _tokenizer.advance();
        value = value + _parseTerm();
      } else if (token.type == _TokenType.minus) {
        _tokenizer.advance();
        value = value - _parseTerm();
      } else {
        break;
      }
    }
    return value;
  }

  Fraction _parseTerm() {
    var value = _parsePower();
    while (true) {
      final token = _tokenizer.peek();
      if (token.type == _TokenType.star) {
        _tokenizer.advance();
        value = value * _parsePower();
      } else if (token.type == _TokenType.slash) {
        _tokenizer.advance();
        value = value / _parsePower();
      } else {
        break;
      }
    }
    return value;
  }

  Fraction _parsePower() {
    var value = _parseUnary();
    final token = _tokenizer.peek();
    if (token.type == _TokenType.caret) {
      _tokenizer.advance();
      final exponent = _parsePower();
      return _pow(value, exponent);
    }
    return value;
  }

  Fraction _parseUnary() {
    final token = _tokenizer.peek();
    if (token.type == _TokenType.minus) {
      _tokenizer.advance();
      return _negate(_parseUnary());
    }
    return _parsePrimary();
  }

  Fraction _parsePrimary() {
    final token = _tokenizer.peek();
    if (token.type == _TokenType.number) {
      _tokenizer.advance();
      return _fractionFromNumber(token.lexeme);
    }
    if (token.type == _TokenType.identifier) {
      _tokenizer.advance();
      final name = token.lexeme;
      if (name == 'root') {
        return _parseRoot();
      }
      if (name == 'pi' || name == 'π') {
        return Fraction(355, 113);
      }
      if (name == 'e') {
        return Fraction(2718, 1000);
      }
      throw InvalidExpressionException('Expresion invalida');
    }
    if (token.type == _TokenType.lParen) {
      _tokenizer.advance();
      final value = parseExpression();
      _consume(_TokenType.rParen);
      return value;
    }
    throw InvalidExpressionException('Expresion invalida');
  }

  Fraction _parseRoot() {
    _consume(_TokenType.lParen);
    Fraction index;
    if (_tokenizer.peek().type == _TokenType.rParen) {
      _tokenizer.advance();
      index = Fraction(2, 1);
    } else {
      index = parseExpression();
      _consume(_TokenType.rParen);
    }
    _consume(_TokenType.lBrace);
    final radicand = parseExpression();
    _consume(_TokenType.rBrace);
    return _root(index, radicand);
  }

  void _consume(_TokenType type) {
    final token = _tokenizer.advance();
    if (token.type != type) {
      throw InvalidExpressionException('Expresion invalida');
    }
  }

  Fraction _fractionFromNumber(String text) {
    if (text.isEmpty || text == '.') {
      throw InvalidExpressionException('Expresion invalida');
    }
    if (!text.contains('.')) {
      return Fraction(int.parse(text), 1);
    }
    final parts = text.split('.');
    if (parts.length != 2 || parts[1].isEmpty) {
      throw InvalidExpressionException('Expresion invalida');
    }
    final whole = parts[0].isEmpty ? '0' : parts[0];
    final frac = parts[1];
    final numerator = int.parse('$whole$frac');
    var denominator = 1;
    for (var i = 0; i < frac.length; i++) {
      denominator *= 10;
    }
    return Fraction(numerator, denominator);
  }

  Fraction _pow(Fraction base, Fraction exponent) {
    if (!_isOne(exponent.denominator)) {
      throw InvalidExpressionException('Expresion invalida');
    }
    final exp = _toInt(exponent.numerator);
    if (exp < 0) {
      throw InvalidExpressionException('Expresion invalida');
    }
    var result = Fraction(1, 1);
    for (var i = 0; i < exp; i++) {
      result = result * base;
    }
    return result;
  }

  Fraction _root(Fraction index, Fraction radicand) {
    if (!_isOne(index.denominator) || !_isOne(radicand.denominator)) {
      throw InvalidExpressionException('Expresion invalida');
    }
    final indexValue = _toInt(index.numerator);
    if (indexValue <= 0) {
      throw InvalidExpressionException('Expresion invalida');
    }
    final radValue = _toInt(radicand.numerator);
    if (radValue == 0) {
      return Fraction(0, 1);
    }
    if (radValue < 0 && indexValue % 2 == 0) {
      throw InvalidExpressionException('Expresion invalida');
    }
    final absRad = radValue.abs();
    final root = _intNthRoot(absRad, indexValue);
    if (_intPow(root, indexValue) != absRad) {
      throw InvalidExpressionException('Expresion invalida');
    }
    final signedRoot = radValue < 0 ? -root : root;
    return Fraction(signedRoot, 1);
  }

  int _intNthRoot(int value, int n) {
    var low = 0;
    var high = value;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final pow = _intPow(mid, n);
      if (pow == value) {
        return mid;
      }
      if (pow < value) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return high;
  }

  int _intPow(int base, int exp) {
    var result = 1;
    for (var i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  bool _isOne(Object? value) {
    return value == 1 || value == BigInt.one;
  }

  Fraction _negate(Fraction value) {
    return Fraction(0, 1) - value;
  }

  int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is BigInt) {
      return value.toInt();
    }
    return (value as dynamic).toInt();
  }
}
