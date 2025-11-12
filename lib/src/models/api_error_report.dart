/// Model representing an API error report
class ApiErrorReport {
  /// Name of the app using the package
  final String appName;

  /// Full API endpoint where the error occurred
  final String endpoint;

  /// The JSON key that caused the issue
  final String? key;

  /// The expected data type
  final String? expectedType;

  /// The actual data type from the server
  final String? receivedType;

  /// When the error occurred
  final DateTime timestamp;

  /// Error message
  final String errorMessage;

  /// Stack trace for debugging
  final String? stackTrace;

  /// Request data (if available)
  final Map<String, dynamic>? requestData;

  /// Response data (if available)
  final dynamic responseData;

  ApiErrorReport({
    required this.appName,
    required this.endpoint,
    this.key,
    this.expectedType,
    this.receivedType,
    DateTime? timestamp,
    required this.errorMessage,
    this.stackTrace,
    this.requestData,
    this.responseData,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON for sending to webhook
  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'endpoint': endpoint,
      'key': key,
      'expectedType': expectedType,
      'receivedType': receivedType,
      'timestamp': timestamp.toIso8601String(),
      'errorMessage': errorMessage,
      'stackTrace': stackTrace,
      'requestData': requestData,
      'responseData': responseData,
    };
  }

  /// Format as a string for logging
  @override
  String toString() {
    return '''
ApiErrorReport:
  App Name: $appName
  Endpoint: $endpoint
  Key: ${key ?? 'N/A'}
  Expected Type: ${expectedType ?? 'N/A'}
  Received Type: ${receivedType ?? 'N/A'}
  Timestamp: ${timestamp.toIso8601String()}
  Error: $errorMessage
  Stack Trace: ${stackTrace ?? 'N/A'}
''';
  }
}
