import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_error_report.dart';

/// Reporter that sends error reports to Discord webhook
class DiscordReporter {
  final String webhookUrl;
  final bool enabled;

  DiscordReporter({required this.webhookUrl, this.enabled = true});

  /// Send error report to Discord webhook
  Future<bool> report(ApiErrorReport report) async {
    if (!enabled) return false;

    try {
      final content = _createContentMessage(report);
      final embed = _createEmbed(report);

      final payload = jsonEncode({
        'content': content,
        'embeds': [embed],
      });

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      // Silently fail - we don't want to throw errors from error reporting
      return false;
    }
  }

  /// Create a simple text message for Discord content field
  /// Focuses on type mismatch errors - clean and simple format
  String _createContentMessage(ApiErrorReport report) {
    final buffer = StringBuffer();

    // Mention everyone for important errors (ALWAYS at the top)
    buffer.writeln('@everyone');
    buffer.writeln('');

    // Check if this is a type mismatch error
    final isTypeError =
        report.expectedType != null && report.receivedType != null;

    if (isTypeError) {
      // Simple type mismatch message
      buffer.writeln('🚨 **Type Mismatch Error**');
      buffer.writeln('');
      buffer.writeln('**App:** ${report.appName}');
      buffer.writeln('**Endpoint:** `${report.endpoint}`');

      // Show key if available and it's not a type name
      if (report.key != null &&
          report.key!.isNotEmpty &&
          report.key != report.receivedType &&
          report.key != report.expectedType &&
          report.key != 'double' &&
          report.key != 'int' &&
          report.key != 'String' &&
          report.key != 'bool') {
        buffer.writeln('**🔑 Field Name:** `${report.key}`');
        buffer.writeln('');
      }

      buffer.writeln('**Data Type Error:**');
      buffer.writeln('❌ **Current Type:** `${report.receivedType}`');
      buffer.writeln('✅ **Expected Type:** `${report.expectedType}`');
    } else {
      // Other types of errors
      buffer.writeln('🚨 **API Parsing Error**');
      buffer.writeln('');
      buffer.writeln('**App:** ${report.appName}');
      buffer.writeln('**Endpoint:** `${report.endpoint}`');

      if (report.key != null &&
          report.key!.isNotEmpty &&
          report.key != 'double' &&
          report.key != 'int' &&
          report.key != 'String' &&
          report.key != 'bool') {
        buffer.writeln('**🔑 Key:** `${report.key}`');
        buffer.writeln('');
      }

      buffer.writeln('**Error:**');
      buffer.writeln('```');
      // Error message is already cleaned (no stack trace)
      final cleanError = _removeStackTrace(report.errorMessage);
      buffer.writeln(cleanError);
      buffer.writeln('```');
    }

    return buffer.toString();
  }

  /// Remove stack trace from error message completely
  String _removeStackTrace(String errorMessage) {
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

  /// Create Discord embed (without stack trace)
  Map<String, dynamic> _createEmbed(ApiErrorReport report) {
    final fields = <Map<String, dynamic>>[];
    final isTypeError =
        report.expectedType != null && report.receivedType != null;

    fields.add({'name': 'App Name', 'value': report.appName, 'inline': true});
    fields.add({
      'name': 'Endpoint',
      'value': '`${report.endpoint}`',
      'inline': false,
    });

    if (isTypeError) {
      if (report.key != null &&
          report.key!.isNotEmpty &&
          report.key != report.receivedType &&
          report.key != report.expectedType &&
          report.key != 'double' &&
          report.key != 'int' &&
          report.key != 'String' &&
          report.key != 'bool') {
        fields.add({
          'name': '🔑 Field Name',
          'value': '`${report.key}`',
          'inline': true,
        });
      }
      if (report.receivedType != null) {
        fields.add({
          'name': '❌ Current Type',
          'value': '`${report.receivedType}`',
          'inline': true,
        });
      }
      if (report.expectedType != null) {
        fields.add({
          'name': '✅ Expected Type',
          'value': '`${report.expectedType}`',
          'inline': true,
        });
      }
    } else {
      if (report.key != null &&
          report.key!.isNotEmpty &&
          report.key != 'double' &&
          report.key != 'int' &&
          report.key != 'String' &&
          report.key != 'bool') {
        fields.add({'name': 'Key', 'value': '`${report.key}`', 'inline': true});
      }
      if (report.expectedType != null) {
        fields.add({
          'name': 'Expected Type',
          'value': '`${report.expectedType}`',
          'inline': true,
        });
      }
      if (report.receivedType != null) {
        fields.add({
          'name': 'Received Type',
          'value': '`${report.receivedType}`',
          'inline': true,
        });
      }
    }

    // Add error details (cleaned, no stack trace)
    if (isTypeError) {
      final cleanError = _removeStackTrace(report.errorMessage);
      final errorSummary = cleanError.length > 200
          ? '${cleanError.substring(0, 200)}...'
          : cleanError;
      if (errorSummary.isNotEmpty && errorSummary.length > 10) {
        fields.add({
          'name': 'Error Details',
          'value': '```$errorSummary```',
          'inline': false,
        });
      }
    } else {
      final cleanError = _removeStackTrace(report.errorMessage);
      if (cleanError.isNotEmpty && cleanError.length > 10) {
        fields.add({
          'name': 'Error Message',
          'value': '```$cleanError```',
          'inline': false,
        });
      }
    }

    fields.add({
      'name': 'Timestamp',
      'value': report.timestamp.toIso8601String(),
      'inline': false,
    });

    int color = 0xFF0000; // Red
    String title = '🚨 API Parsing Error';

    if (isTypeError) {
      color = 0xFF6B6B; // Orange/Red for type errors
      title = '🔴 Type Mismatch Error';
    } else if (report.receivedType == 'null') {
      color = 0xFFFF00; // Yellow for null errors
      title = '⚠️ Null Value Error';
    }

    return {
      'title': title,
      'color': color,
      'fields': fields,
      'timestamp': report.timestamp.toIso8601String(),
    };
  }
}
