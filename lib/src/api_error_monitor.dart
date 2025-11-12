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
    if (!_config.enabled) return;

    // Check debug mode
    if (kDebugMode && !_config.enableInDebugMode) {
      return;
    }

    try {
      final errorMessage = error.toString();
      final errorInfo = ErrorParser.parseError(error, errorMessage);

      // Use provided values or parsed values
      final finalKey = key ?? errorInfo.key;
      final finalExpectedType = expectedType ?? errorInfo.expectedType;
      final finalReceivedType = receivedType ?? errorInfo.receivedType;

      final report = ApiErrorReport(
        appName: _config.appName,
        endpoint: endpoint,
        key: finalKey,
        expectedType: finalExpectedType,
        receivedType: finalReceivedType,
        errorMessage: errorMessage,
        stackTrace: stackTrace?.toString(),
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
}
