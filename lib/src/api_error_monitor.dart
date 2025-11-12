import 'package:flutter/foundation.dart';
import 'models/api_error_report.dart';
import 'models/error_parser.dart';
import 'reporters/discord_reporter.dart';
import 'reporters/local_file_reporter.dart';
import 'reporters/reporter_queue.dart';

/// Configuration for ApiErrorMonitor
class ApiErrorMonitorConfig {
  /// Name of the app using the package
  final String appName;

  /// Discord webhook URL for reporting errors
  final String? discordWebhookUrl;

  /// Enable/disable sending reports in debug mode
  final bool enableInDebugMode;

  /// Enable/disable local file logging
  final bool enableLocalLogging;

  /// Custom directory for local logs
  final String? customLogDirectory;

  /// Maximum number of retries for failed webhook requests
  final int maxRetries;

  /// Delay between retries
  final Duration retryDelay;

  /// Enable/disable reporting
  final bool enabled;

  ApiErrorMonitorConfig({
    required this.appName,
    this.discordWebhookUrl,
    this.enableInDebugMode = false,
    this.enableLocalLogging = true,
    this.customLogDirectory,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 5),
    this.enabled = true,
  });
}

/// Main class for monitoring and reporting API errors
class ApiErrorMonitor {
  final ApiErrorMonitorConfig _config;
  final DiscordReporter? _discordReporter;
  final LocalFileReporter? _localFileReporter;
  late final ReporterQueue? _reporterQueue;

  ApiErrorMonitor({
    required String appName,
    String? discordWebhookUrl,
    bool enableInDebugMode = false,
    bool enableLocalLogging = true,
    String? customLogDirectory,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 5),
    bool enabled = true,
  }) : _config = ApiErrorMonitorConfig(
         appName: appName,
         discordWebhookUrl: discordWebhookUrl,
         enableInDebugMode: enableInDebugMode,
         enableLocalLogging: enableLocalLogging,
         customLogDirectory: customLogDirectory,
         maxRetries: maxRetries,
         retryDelay: retryDelay,
         enabled: enabled,
       ),
       _discordReporter = discordWebhookUrl != null
           ? DiscordReporter(
               webhookUrl: discordWebhookUrl,
               enabled: enabled && (enableInDebugMode || !kDebugMode),
             )
           : null,
       _localFileReporter = enableLocalLogging
           ? LocalFileReporter(
               enabled: enabled,
               customLogDirectory: customLogDirectory,
             )
           : null {
    // Initialize local file reporter
    _localFileReporter?.initialize();

    // Initialize reporter queue if discord reporter is available
    final discordReporter = _discordReporter;
    if (discordReporter != null) {
      _reporterQueue = ReporterQueue(
        discordReporter: discordReporter,
        maxRetries: maxRetries,
        retryDelay: retryDelay,
      );
    } else {
      _reporterQueue = null;
    }
  }

  /// Create from config
  ApiErrorMonitor.fromConfig(ApiErrorMonitorConfig config)
    : _config = config,
      _discordReporter = config.discordWebhookUrl != null
          ? DiscordReporter(
              webhookUrl: config.discordWebhookUrl!,
              enabled:
                  config.enabled && (config.enableInDebugMode || !kDebugMode),
            )
          : null,
      _localFileReporter = config.enableLocalLogging
          ? LocalFileReporter(
              enabled: config.enabled,
              customLogDirectory: config.customLogDirectory,
            )
          : null {
    _localFileReporter?.initialize();

    // Initialize reporter queue if discord reporter is available
    final discordReporter = _discordReporter;
    if (discordReporter != null) {
      _reporterQueue = ReporterQueue(
        discordReporter: discordReporter,
        maxRetries: config.maxRetries,
        retryDelay: config.retryDelay,
      );
    } else {
      _reporterQueue = null;
    }
  }

  /// Check if reporting is enabled
  bool get isEnabled => _config.enabled;

  /// Capture and report an API error
  /// Focuses on type mismatch and parsing errors, ignores network errors
  Future<void> capture(
    dynamic error, {
    StackTrace? stackTrace,
    required String endpoint,
    Map<String, dynamic>? requestData,
    dynamic responseData,
    String? key,
    String? expectedType,
    String? receivedType,
  }) async {
    print('🚀 ApiErrorMonitor.capture called');
    print('📝 Provided key: $key');
    print('📝 Provided expectedType: $expectedType');
    print('📝 Provided receivedType: $receivedType');
    print('📝 Error: ${error.toString()}');
    print('📝 Stack trace available: ${stackTrace != null}');

    if (!_config.enabled) {
      print('⚠️ ApiErrorMonitor is disabled');
      return;
    }

    // Check debug mode
    if (kDebugMode && !_config.enableInDebugMode) {
      print('⚠️ Debug mode is enabled but enableInDebugMode is false');
      return;
    }

    // Ignore network/HTTP errors (DioException, SocketException, etc.)
    // Focus only on parsing/type errors
    final errorMessage = error.toString();

    // Check if it's a DioException (network error) by checking the error message
    if (errorMessage.contains('DioException') &&
        !errorMessage.toLowerCase().contains('type') &&
        !errorMessage.toLowerCase().contains('subtype') &&
        !errorMessage.toLowerCase().contains('cast')) {
      // This is likely a network/HTTP error, not a parsing error
      // Skip it unless it contains type-related keywords
      return;
    }

    try {
      // Combine error message with stack trace for better key extraction
      final fullErrorContext = stackTrace != null
          ? '$errorMessage\n$stackTrace'
          : errorMessage;

      print('🔍 Calling ErrorParser.parseError...');
      print('📝 Error message: $errorMessage');
      print('📝 Stack trace available: ${stackTrace != null}');

      final errorInfo = ErrorParser.parseError(error, fullErrorContext);

      print(
        '📊 ErrorInfo received - Key: ${errorInfo.key}, Expected: ${errorInfo.expectedType}, Received: ${errorInfo.receivedType}',
      );

      // Use provided values or parsed values (provided values take priority)
      final finalKey = key ?? errorInfo.key;
      final finalExpectedType = expectedType ?? errorInfo.expectedType;
      final finalReceivedType = receivedType ?? errorInfo.receivedType;

      // Only report if it's a type error or parsing error
      // Skip if no type information is available (likely network error)
      if (finalExpectedType == null &&
          finalReceivedType == null &&
          finalKey == null &&
          !errorMessage.toLowerCase().contains('type') &&
          !errorMessage.toLowerCase().contains('subtype') &&
          !errorMessage.toLowerCase().contains('cast')) {
        // This doesn't look like a parsing/type error, skip it
        return;
      }

      // Clean error message - remove stack trace completely
      final cleanErrorMessage = _removeStackTraceFromMessage(errorMessage);

      final report = ApiErrorReport(
        appName: _config.appName,
        endpoint: endpoint,
        key: finalKey,
        expectedType: finalExpectedType,
        receivedType: finalReceivedType,
        errorMessage: cleanErrorMessage,
        stackTrace: null, // Never send stack trace to Discord
        requestData: requestData,
        responseData: responseData,
      );

      // Save to local file (always try, even if it fails)
      await _localFileReporter?.report(report);

      // Send to Discord webhook
      if (_discordReporter != null) {
        try {
          final success = await _discordReporter.report(report);
          if (!success && _reporterQueue != null) {
            // Queue for retry if failed
            _reporterQueue.enqueue(report);
          }
        } catch (e) {
          // If network error, queue for retry
          if (_reporterQueue != null) {
            _reporterQueue.enqueue(report);
          }
        }
      }

      // Log to console in debug mode
      if (kDebugMode) {
        debugPrint('ApiErrorMonitor: Error captured and reported');
        debugPrint(report.toString());
      }
    } catch (e) {
      // Silently fail - we don't want to throw errors from error reporting
      if (kDebugMode) {
        debugPrint('ApiErrorMonitor: Failed to capture error: $e');
      }
    }
  }

  /// Process queued reports (call this when network is available)
  Future<void> processQueue() async {
    await _reporterQueue?.processQueue();
  }

  /// Get all local error reports
  Future<List<ApiErrorReport>> getLocalReports() async {
    return await _localFileReporter?.getAllReports() ?? [];
  }

  /// Clear all local error reports
  Future<bool> clearLocalReports() async {
    return await _localFileReporter?.clearReports() ?? false;
  }

  /// Get local log directory path
  String? getLocalLogDirectoryPath() {
    return _localFileReporter?.getLogDirectoryPath();
  }

  /// Get queue size
  int get queueSize => _reporterQueue?.queueSize ?? 0;

  /// Clear queue
  void clearQueue() {
    _reporterQueue?.clear();
  }

  /// Remove stack trace from error message completely
  String _removeStackTraceFromMessage(String errorMessage) {
    if (errorMessage.isEmpty) return errorMessage;

    final lines = errorMessage.split('\n');
    final cleanLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();

      // Skip empty lines
      if (trimmed.isEmpty) continue;

      // Skip stack trace lines completely:
      // - Lines starting with #
      // - Lines containing package: or dart:
      // - Lines with file paths (.dart)
      // - Lines with function names and line numbers
      // - Lines with <anonymous closure> or <asynchronous suspension>
      if (trimmed.startsWith('#') ||
          trimmed.startsWith('at ') ||
          line.contains('package:') ||
          line.contains('dart:') ||
          line.contains('.dart:') ||
          line.contains('<anonymous closure>') ||
          line.contains('<asynchronous suspension>') ||
          line.contains('MappedListIterable') ||
          line.contains('ListIterator') ||
          line.contains('_GrowableList') ||
          line.contains('List.of') ||
          line.contains('ListIterable')) {
        continue;
      }

      cleanLines.add(line);
    }

    final result = cleanLines.join('\n').trim();

    // If result is empty or only contains error type, return a simple message
    if (result.isEmpty || result.length < 10) {
      return 'Type mismatch error occurred during JSON parsing';
    }

    return result;
  }
}
