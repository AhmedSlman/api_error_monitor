import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/api_error_report.dart';

/// Reporter that saves error reports to local file
class LocalFileReporter {
  final bool enabled;
  final String? customLogDirectory;
  late final Directory _logDirectory;

  LocalFileReporter({
    this.enabled = true,
    this.customLogDirectory,
  });

  /// Initialize the log directory
  Future<void> initialize() async {
    if (!enabled) return;

    if (customLogDirectory != null) {
      _logDirectory = Directory(customLogDirectory!);
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      _logDirectory = Directory(path.join(appDocDir.path, 'api_error_monitor', 'logs'));
    }

    if (!await _logDirectory.exists()) {
      await _logDirectory.create(recursive: true);
    }
  }

  /// Save error report to local file
  Future<bool> report(ApiErrorReport report) async {
    if (!enabled) return false;

    try {
      await initialize();

      final timestamp = report.timestamp.toIso8601String().replaceAll(':', '-');
      final fileName = 'error_$timestamp.json';
      final file = File(path.join(_logDirectory.path, fileName));

      await file.writeAsString(
        jsonEncode(report.toJson()),
        mode: FileMode.write,
      );

      return true;
    } catch (e) {
      // Silently fail - we don't want to throw errors from error reporting
      return false;
    }
  }

  /// Get all error reports from local storage
  Future<List<ApiErrorReport>> getAllReports() async {
    if (!enabled) return [];

    try {
      await initialize();

      final files = _logDirectory.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path)); // Sort by name (timestamp)

      final reports = <ApiErrorReport>[];
      for (final file in files) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          reports.add(ApiErrorReport(
            appName: json['appName'] as String,
            endpoint: json['endpoint'] as String,
            key: json['key'] as String?,
            expectedType: json['expectedType'] as String?,
            receivedType: json['receivedType'] as String?,
            timestamp: DateTime.parse(json['timestamp'] as String),
            errorMessage: json['errorMessage'] as String,
            stackTrace: json['stackTrace'] as String?,
            requestData: json['requestData'] as Map<String, dynamic>?,
            responseData: json['responseData'],
          ));
        } catch (e) {
          // Skip invalid files
          continue;
        }
      }

      return reports;
    } catch (e) {
      return [];
    }
  }

  /// Clear all error reports
  Future<bool> clearReports() async {
    if (!enabled) return false;

    try {
      await initialize();

      final files = _logDirectory.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      for (final file in files) {
        await file.delete();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get log directory path
  /// Note: This may throw an error if initialize() hasn't been called yet
  String getLogDirectoryPath() {
    try {
      return _logDirectory.path;
    } catch (e) {
      // If _logDirectory hasn't been initialized, return default path
      if (customLogDirectory != null) {
        return customLogDirectory!;
      }
      return 'api_error_monitor/logs';
    }
  }
}

