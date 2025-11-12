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
      final embed = _createEmbed(report);
      final payload = jsonEncode({
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

  /// Create Discord embed from error report
  Map<String, dynamic> _createEmbed(ApiErrorReport report) {
    final fields = <Map<String, dynamic>>[];

    fields.add({'name': 'App Name', 'value': report.appName, 'inline': true});

    fields.add({
      'name': 'Endpoint',
      'value': '`${report.endpoint}`',
      'inline': false,
    });

    if (report.key != null) {
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

    fields.add({
      'name': 'Timestamp',
      'value': report.timestamp.toIso8601String(),
      'inline': false,
    });

    fields.add({
      'name': 'Error Message',
      'value': '```${report.errorMessage}```',
      'inline': false,
    });

    if (report.stackTrace != null && report.stackTrace!.isNotEmpty) {
      // Discord has a limit on field value length, so truncate if needed
      final stackTrace = report.stackTrace!;
      final maxLength = 1000;
      fields.add({
        'name': 'Stack Trace',
        'value': stackTrace.length > maxLength
            ? '```${stackTrace.substring(0, maxLength)}...```'
            : '```$stackTrace```',
        'inline': false,
      });
    }

    // Determine color based on error type
    int color = 0xFF0000; // Red
    if (report.receivedType == 'null') {
      color = 0xFFFF00; // Yellow
    }

    return {
      'title': '🚨 API Parsing Error',
      'color': color,
      'fields': fields,
      'timestamp': report.timestamp.toIso8601String(),
    };
  }
}
