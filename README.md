# API Error Monitor

A Dart/Flutter package that automatically detects and reports API response parsing errors, including type mismatches and missing keys, with Discord webhook integration.

## Features

- 🔍 **Automatic Error Detection**: Intercepts API requests and automatically detects parsing errors
- 🎯 **Type Mismatch Detection**: Identifies when JSON values don't match expected data types
- 🔑 **Missing Key Detection**: Detects when required JSON keys are missing
- 📱 **Discord Integration**: Sends error reports to Discord webhooks
- 💾 **Local Logging**: Saves error reports to local files for offline scenarios
- 🔄 **Retry Mechanism**: Automatically retries failed webhook requests
- 🛠️ **Dio Support**: Built-in interceptor for Dio HTTP client
- 🌐 **HTTP Support**: Wrapper class for the `http` package
- 🐛 **Debug Mode Control**: Configurable behavior in debug mode
- 📊 **Error Analytics**: Retrieve and analyze local error reports

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  api_error_monitor: ^0.0.2
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Usage

```dart
import 'package:api_error_monitor/api_error_monitor.dart';

// Initialize the error monitor
final errorMonitor = ApiErrorMonitor(
  appName: "MyApp",
  discordWebhookUrl: "https://discord.com/api/webhooks/xxxx",
);

// Capture an error manually
try {
  final model = MyModel.fromJson(response.data);
} catch (e, s) {
  errorMonitor.capture(
    e,
    stackTrace: s,
    endpoint: "/user/profile",
    responseData: response.data,
  );
}
```

### Using with Dio

```dart
import 'package:dio/dio.dart';
import 'package:api_error_monitor/api_error_monitor.dart';

final dio = Dio();

// Add the error monitoring interceptor
dio.addApiErrorMonitoring(
  errorMonitor: ApiErrorMonitor(
    appName: "MyApp",
    discordWebhookUrl: "https://discord.com/api/webhooks/xxxx",
  ),
);

// Make requests as usual
final response = await dio.get('/user/profile');
final user = UserModel.fromJson(response.data); // Errors will be automatically captured
```

### Using with HTTP Package

```dart
import 'package:api_error_monitor/api_error_monitor.dart';
import 'package:http/http.dart' as http;

final errorMonitor = ApiErrorMonitor(
  appName: "MyApp",
  discordWebhookUrl: "https://discord.com/api/webhooks/xxxx",
);

final httpClient = ApiErrorHttpClient(
  errorMonitor: errorMonitor,
);

// Make requests with automatic error monitoring
final response = await httpClient.get(
  Uri.parse('https://api.example.com/user/profile'),
  fromJsonCallback: (data) {
    return UserModel.fromJson(data);
  },
);
```

## Configuration

### ApiErrorMonitor Options

```dart
final errorMonitor = ApiErrorMonitor(
  appName: "MyApp",                    // Required: App name
  discordWebhookUrl: "https://...",     // Optional: Discord webhook URL
  enableInDebugMode: false,             // Default: false (disabled in debug)
  enableLocalLogging: true,             // Default: true
  customLogDirectory: "/path/to/logs",  // Optional: Custom log directory
  maxRetries: 3,                        // Default: 3
  retryDelay: Duration(seconds: 5),     // Default: 5 seconds
  enabled: true,                        // Default: true
);
```

### Configuration Object

```dart
final config = ApiErrorMonitorConfig(
  appName: "MyApp",
  discordWebhookUrl: "https://discord.com/api/webhooks/xxxx",
  enableInDebugMode: false,
  enableLocalLogging: true,
  maxRetries: 3,
  retryDelay: Duration(seconds: 5),
  enabled: true,
);

final errorMonitor = ApiErrorMonitor.fromConfig(config);
```

## Error Report Format

Each error report contains the following information:

- **App Name**: Name of the app using the package
- **Endpoint**: Full API endpoint where the error occurred
- **Key**: The JSON key that caused the issue (if detected)
- **Expected Type**: The expected data type
- **Received Type**: The actual data type from the server
- **Timestamp**: When the error occurred
- **Error Message**: The error message
- **Stack Trace**: Stack trace for debugging (optional)
- **Request Data**: Request data (if available)
- **Response Data**: Response data (if available)

## Discord Webhook Setup

1. Go to your Discord server
2. Navigate to Server Settings > Integrations > Webhooks
3. Click "New Webhook"
4. Copy the webhook URL
5. Use it in your `ApiErrorMonitor` configuration

Example Discord webhook URL:

```
https://discord.com/api/webhooks/1234567890/abcdefghijklmnopqrstuvwxyz
```

## Local Logging

Error reports are automatically saved to local files when `enableLocalLogging` is enabled. By default, logs are stored in:

- **iOS/Android**: App documents directory (`api_error_monitor/logs/`)
- **Custom**: Use `customLogDirectory` to specify a custom path

### Retrieve Local Reports

```dart
final reports = await errorMonitor.getLocalReports();
for (final report in reports) {
  print('Error: ${report.errorMessage}');
  print('Endpoint: ${report.endpoint}');
  print('Key: ${report.key}');
}
```

### Clear Local Reports

```dart
await errorMonitor.clearLocalReports();
```

### Get Log Directory Path

```dart
final logPath = errorMonitor.getLocalLogDirectoryPath();
print('Logs stored at: $logPath');
```

## Retry Mechanism

Failed webhook requests are automatically queued and retried:

```dart
// Process queued reports (call when network is available)
await errorMonitor.processQueue();

// Check queue size
final queueSize = errorMonitor.queueSize;

// Clear queue
errorMonitor.clearQueue();
```

## Advanced Usage

### Manual Error Capture

```dart
errorMonitor.capture(
  error,
  stackTrace: stackTrace,
  endpoint: "/api/users",
  key: "email",                    // Optional: Specify the key
  expectedType: "String",          // Optional: Specify expected type
  receivedType: "int",             // Optional: Specify received type
  requestData: {"id": 123},        // Optional: Request data
  responseData: {"email": 123},    // Optional: Response data
);
```

### Dio Interceptor with Custom Parsing

```dart
dio.addApiErrorMonitoring(
  errorMonitor: errorMonitor,
  fromJsonCallback: (data) {
    // Custom parsing logic
    return MyModel.fromJson(data);
  },
);
```

### HTTP Client with Custom Parsing

```dart
final response = await httpClient.get(
  Uri.parse('https://api.example.com/user'),
  fromJsonCallback: (data) {
    return UserModel.fromJson(data);
  },
);
```

## Error Patterns Detected

The package automatically detects the following error patterns:

1. **Type Mismatch**: `type 'X' is not a subtype of type 'Y'`
2. **Missing Key**: `key not found: "keyName"`
3. **Null Value**: `type 'null' is not a subtype of type 'String'`
4. **Cast Error**: `type 'X' is not a subtype of type 'Y' in type cast`
5. **JSON Path**: Extracts keys from JSON path errors

## Debug Mode

By default, error reporting is disabled in debug mode. To enable it:

```dart
final errorMonitor = ApiErrorMonitor(
  appName: "MyApp",
  discordWebhookUrl: "https://discord.com/api/webhooks/xxxx",
  enableInDebugMode: true, // Enable in debug mode
);
```

## Best Practices

1. **Use in Production**: Disable error reporting in debug mode to avoid spam
2. **Monitor Queue Size**: Regularly check and process the retry queue
3. **Clear Old Logs**: Periodically clear old local logs to save storage
4. **Webhook Security**: Keep your Discord webhook URL secure
5. **Error Handling**: Always handle errors in your code, even with monitoring

## Example App

See the `/example` directory for a complete example application.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or contributions, please open an issue on GitHub.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.
