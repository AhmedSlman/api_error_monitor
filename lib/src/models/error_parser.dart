/// Utility class to parse error messages and extract information
class ErrorParser {
  /// Parse exception to extract key, expected type, and received type
  static ApiErrorInfo parseError(dynamic error, String errorMessage) {
    String? key;
    String? expectedType;
    String? receivedType;

    // Try to extract information from common error patterns
    // Pattern 1: Type 'X' is not a subtype of type 'Y' in type cast
    final typeCastPattern = RegExp(
      r"type '([^']+)' is not a subtype of type '([^']+)'",
      caseSensitive: false,
    );
    final typeCastMatch = typeCastPattern.firstMatch(errorMessage);
    if (typeCastMatch != null) {
      receivedType = _cleanType(typeCastMatch.group(1));
      expectedType = _cleanType(typeCastMatch.group(2));
    }

    // Pattern 2: Invalid argument(s): key not found: "keyName"
    final keyNotFoundPattern = RegExp(
      'key not found[:\\s]+["\']?([^"\']+)["\']?',
      caseSensitive: false,
    );
    final keyNotFoundMatch = keyNotFoundPattern.firstMatch(errorMessage);
    if (keyNotFoundMatch != null && keyNotFoundMatch.groupCount > 0) {
      key = keyNotFoundMatch.group(1);
    }

    // Pattern 3: type 'Null' is not a subtype of type 'String' (or other types)
    final nullPattern = RegExp(
      r"type 'null' is not a subtype of type '([^']+)'",
      caseSensitive: false,
    );
    final nullMatch = nullPattern.firstMatch(errorMessage);
    if (nullMatch != null) {
      receivedType = 'null';
      expectedType = _cleanType(nullMatch.group(1));
    }

    // Pattern 4: CastError - type 'X' is not a subtype of type 'Y' in type cast
    final castErrorPattern = RegExp(
      r"type '([^']+)' is not a subtype of type '([^']+)' in type cast",
      caseSensitive: false,
    );
    final castErrorMatch = castErrorPattern.firstMatch(errorMessage);
    if (castErrorMatch != null && key == null) {
      receivedType = _cleanType(castErrorMatch.group(1));
      expectedType = _cleanType(castErrorMatch.group(2));
    }

    // Pattern 5: FormatException or similar - try to extract key from JSON path
    final jsonPathPattern = RegExp(
      '["\']([^"\']+)["\'][:\\s]',
      caseSensitive: false,
    );
    if (key == null) {
      final jsonPathMatch = jsonPathPattern.firstMatch(errorMessage);
      if (jsonPathMatch != null && jsonPathMatch.groupCount > 0) {
        key = jsonPathMatch.group(1);
      }
    }

    // Try to get type information from the error object itself
    if (error is TypeError) {
      final typeErrorString = error.toString();
      if (receivedType == null || expectedType == null) {
        final errorMatch = typeCastPattern.firstMatch(typeErrorString);
        if (errorMatch != null) {
          receivedType ??= _cleanType(errorMatch.group(1));
          expectedType ??= _cleanType(errorMatch.group(2));
        }
      }
    }

    return ApiErrorInfo(
      key: key,
      expectedType: expectedType,
      receivedType: receivedType,
    );
  }

  /// Clean type string to make it more readable
  static String _cleanType(String? type) {
    if (type == null) return 'Unknown';
    return type
        .replaceAll('dart.core.', '')
        .replaceAll('dart.collection.', '')
        .replaceAll('<dynamic>', '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .trim();
  }
}

/// Information extracted from an error
class ApiErrorInfo {
  final String? key;
  final String? expectedType;
  final String? receivedType;

  ApiErrorInfo({this.key, this.expectedType, this.receivedType});
}
