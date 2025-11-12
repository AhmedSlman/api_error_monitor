import 'package:dio/dio.dart';
import '../api_error_monitor.dart';

/// Dio interceptor for automatically capturing API parsing errors
class ApiErrorDioInterceptor extends Interceptor {
  final ApiErrorMonitor errorMonitor;
  final Function(dynamic data)? fromJsonCallback;

  ApiErrorDioInterceptor({
    required this.errorMonitor,
    this.fromJsonCallback,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Capture parsing errors
    if (err.type == DioExceptionType.badResponse) {
      final endpoint = err.requestOptions.uri.toString();
      final requestData = err.requestOptions.data;
      final responseData = err.response?.data;

      errorMonitor.capture(
        err,
        stackTrace: err.stackTrace,
        endpoint: endpoint,
        requestData: requestData is Map ? Map<String, dynamic>.from(requestData) : null,
        responseData: responseData,
      );
    }

    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // If fromJsonCallback is provided, try to parse the response
    if (fromJsonCallback != null) {
      try {
        fromJsonCallback!(response.data);
      } catch (e, stackTrace) {
        final endpoint = response.requestOptions.uri.toString();
        final requestData = response.requestOptions.data;
        final responseData = response.data;

        errorMonitor.capture(
          e,
          stackTrace: stackTrace,
          endpoint: endpoint,
          requestData: requestData is Map ? Map<String, dynamic>.from(requestData) : null,
          responseData: responseData,
        );
      }
    }

    super.onResponse(response, handler);
  }
}

/// Helper extension for Dio to easily add error monitoring
extension DioApiErrorMonitoring on Dio {
  /// Add API error monitoring to this Dio instance
  void addApiErrorMonitoring({
    required ApiErrorMonitor errorMonitor,
    Function(dynamic data)? fromJsonCallback,
  }) {
    interceptors.add(
      ApiErrorDioInterceptor(
        errorMonitor: errorMonitor,
        fromJsonCallback: fromJsonCallback,
      ),
    );
  }
}

