import 'dart:collection';
import '../models/api_error_report.dart';
import 'discord_reporter.dart';

/// Queue for storing failed reports to retry later
class ReporterQueue {
  final Queue<ApiErrorReport> _queue = Queue();
  final DiscordReporter discordReporter;
  final int maxRetries;
  final Duration retryDelay;

  ReporterQueue({
    required this.discordReporter,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 5),
  });

  /// Add report to queue for retry
  void enqueue(ApiErrorReport report) {
    _queue.add(report);
  }

  /// Process all queued reports
  Future<void> processQueue() async {
    while (_queue.isNotEmpty) {
      final report = _queue.removeFirst();
      var retries = 0;
      var success = false;

      while (retries < maxRetries && !success) {
        success = await discordReporter.report(report);
        if (!success) {
          retries++;
          if (retries < maxRetries) {
            await Future.delayed(retryDelay * retries); // Exponential backoff
          }
        }
      }

      // If still failed after max retries, we can optionally log it locally
      // or just drop it to avoid infinite queue growth
    }
  }

  /// Get queue size
  int get queueSize => _queue.length;

  /// Clear queue
  void clear() {
    _queue.clear();
  }
}
