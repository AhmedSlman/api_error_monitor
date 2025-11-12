/// A Dart/Flutter package that automatically detects and reports API response
/// parsing errors, including type mismatches and missing keys, with Discord
/// webhook integration.
///
/// This package provides:
/// - Automatic error detection during JSON parsing
/// - Discord webhook integration for error reporting
/// - Local file logging for offline scenarios
/// - Support for both Dio and http packages
/// - Retry mechanism for failed webhook requests
/// - Debug mode configuration
library api_error_monitor;

// Export main API
export 'src/api_error_monitor.dart';

// Export models
export 'src/models/api_error_report.dart';
export 'src/models/error_parser.dart';

// Export interceptors
export 'src/interceptors/dio_interceptor.dart';
export 'src/interceptors/http_interceptor.dart';

// Export reporters (internal use, but available for customization)
export 'src/reporters/discord_reporter.dart';
export 'src/reporters/local_file_reporter.dart';
export 'src/reporters/reporter_queue.dart';
