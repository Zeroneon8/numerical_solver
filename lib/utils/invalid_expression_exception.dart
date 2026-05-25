class InvalidExpressionException implements Exception {
  InvalidExpressionException(this.message);

  final String message;

  @override
  String toString() => message;
}
