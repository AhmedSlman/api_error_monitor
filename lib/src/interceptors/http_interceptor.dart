import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_error_monitor.dart';

/// Helper class for monitoring HTTP package requests
class ApiErrorHttpClient {
  final http.Client _client;
  final ApiErrorMonitor errorMonitor;

  ApiErrorHttpClient({http.Client? client, required this.errorMonitor})
    : _client = client ?? http.Client();

  /// Get request with error monitoring
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Function(dynamic data)? fromJsonCallback,
  }) async {
    try {
      final response = await _client.get(url, headers: headers);

      if (fromJsonCallback != null) {
        try {
          final jsonData = jsonDecode(response.body);
          fromJsonCallback(jsonData);
        } catch (e, stackTrace) {
          errorMonitor.capture(
            e,
            stackTrace: stackTrace,
            endpoint: url.toString(),
            requestData: null,
            responseData: response.body,
          );
          rethrow;
        }
      }

      return response;
    } catch (e, stackTrace) {
      if (e is! FormatException) {
        errorMonitor.capture(
          e,
          stackTrace: stackTrace,
          endpoint: url.toString(),
          requestData: null,
          responseData: null,
        );
      }
      rethrow;
    }
  }

  /// Post request with error monitoring
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Function(dynamic data)? fromJsonCallback,
  }) async {
    try {
      final response = await _client.post(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      );

      if (fromJsonCallback != null) {
        try {
          final jsonData = jsonDecode(response.body);
          fromJsonCallback(jsonData);
        } catch (e, stackTrace) {
          errorMonitor.capture(
            e,
            stackTrace: stackTrace,
            endpoint: url.toString(),
            requestData: body is Map ? Map<String, dynamic>.from(body) : null,
            responseData: response.body,
          );
          rethrow;
        }
      }

      return response;
    } catch (e, stackTrace) {
      if (e is! FormatException) {
        errorMonitor.capture(
          e,
          stackTrace: stackTrace,
          endpoint: url.toString(),
          requestData: body is Map ? Map<String, dynamic>.from(body) : null,
          responseData: null,
        );
      }
      rethrow;
    }
  }

  /// Put request with error monitoring
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Function(dynamic data)? fromJsonCallback,
  }) async {
    try {
      final response = await _client.put(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      );

      if (fromJsonCallback != null) {
        try {
          final jsonData = jsonDecode(response.body);
          fromJsonCallback(jsonData);
        } catch (e, stackTrace) {
          errorMonitor.capture(
            e,
            stackTrace: stackTrace,
            endpoint: url.toString(),
            requestData: body is Map ? Map<String, dynamic>.from(body) : null,
            responseData: response.body,
          );
          rethrow;
        }
      }

      return response;
    } catch (e, stackTrace) {
      if (e is! FormatException) {
        errorMonitor.capture(
          e,
          stackTrace: stackTrace,
          endpoint: url.toString(),
          requestData: body is Map ? Map<String, dynamic>.from(body) : null,
          responseData: null,
        );
      }
      rethrow;
    }
  }

  /// Delete request with error monitoring
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Function(dynamic data)? fromJsonCallback,
  }) async {
    try {
      final response = await _client.delete(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      );

      if (fromJsonCallback != null) {
        try {
          final jsonData = jsonDecode(response.body);
          fromJsonCallback(jsonData);
        } catch (e, stackTrace) {
          errorMonitor.capture(
            e,
            stackTrace: stackTrace,
            endpoint: url.toString(),
            requestData: body is Map ? Map<String, dynamic>.from(body) : null,
            responseData: response.body,
          );
          rethrow;
        }
      }

      return response;
    } catch (e, stackTrace) {
      if (e is! FormatException) {
        errorMonitor.capture(
          e,
          stackTrace: stackTrace,
          endpoint: url.toString(),
          requestData: body is Map ? Map<String, dynamic>.from(body) : null,
          responseData: null,
        );
      }
      rethrow;
    }
  }

  /// Close the underlying HTTP client
  void close() {
    _client.close();
  }
}
