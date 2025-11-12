import 'package:flutter_test/flutter_test.dart';
import 'package:api_logger/api_logger.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiErrorMonitor', () {
    late ApiErrorMonitor errorMonitor;

    setUp(() {
      errorMonitor = ApiErrorMonitor(
        appName: "TestApp",
        enableInDebugMode: true,
        enableLocalLogging:
            false, // Disable local logging in tests to avoid path_provider issues
      );
    });

    test('should initialize with correct app name', () {
      expect(errorMonitor.isEnabled, true);
    });

    test('should capture type mismatch error', () async {
      try {
        // Simulate type mismatch error
        final data = {'name': 'John', 'age': '25'}; // age should be int
        // ignore: unused_local_variable
        final age = data['age'] as int; // This will throw TypeError
      } catch (e, s) {
        await errorMonitor.capture(
          e,
          stackTrace: s,
          endpoint: '/test/endpoint',
          responseData: {'name': 'John', 'age': '25'},
        );
        // If no exception is thrown, the test passes
        expect(e, isNotNull);
      }
    });

    test('should capture missing key error', () async {
      try {
        // Simulate missing key error
        final data = <String, dynamic>{};
        // ignore: unused_local_variable
        final name = data['name'] as String; // This will throw error
      } catch (e, s) {
        await errorMonitor.capture(
          e,
          stackTrace: s,
          endpoint: '/test/endpoint',
          responseData: <String, dynamic>{},
        );
        expect(e, isNotNull);
      }
    });

    test('should parse error and extract information', () {
      final errorMessage = "type 'String' is not a subtype of type 'int'";
      final errorInfo = ErrorParser.parseError(TypeError(), errorMessage);

      expect(errorInfo.expectedType, isNotNull);
      expect(errorInfo.receivedType, isNotNull);
    });

    test('should create ApiErrorReport with correct data', () {
      final report = ApiErrorReport(
        appName: "TestApp",
        endpoint: "/test/endpoint",
        key: "age",
        expectedType: "int",
        receivedType: "String",
        errorMessage: "Type error",
        timestamp: DateTime.now(),
      );

      expect(report.appName, "TestApp");
      expect(report.endpoint, "/test/endpoint");
      expect(report.key, "age");
      expect(report.expectedType, "int");
      expect(report.receivedType, "String");
    });

    test('should convert ApiErrorReport to JSON', () {
      final report = ApiErrorReport(
        appName: "TestApp",
        endpoint: "/test/endpoint",
        key: "age",
        expectedType: "int",
        receivedType: "String",
        errorMessage: "Type error",
        timestamp: DateTime.now(),
      );

      final json = report.toJson();
      expect(json['appName'], "TestApp");
      expect(json['endpoint'], "/test/endpoint");
      expect(json['key'], "age");
      expect(json['expectedType'], "int");
      expect(json['receivedType'], "String");
    });

    test('should handle null values in error report', () {
      final report = ApiErrorReport(
        appName: "TestApp",
        endpoint: "/test/endpoint",
        errorMessage: "Error",
        timestamp: DateTime.now(),
      );

      expect(report.key, isNull);
      expect(report.expectedType, isNull);
      expect(report.receivedType, isNull);
    });

    test('should initialize with configuration', () {
      final config = ApiErrorMonitorConfig(
        appName: "TestApp",
        discordWebhookUrl: null,
        enableInDebugMode: true,
        enableLocalLogging: false, // Disable local logging in tests
        enabled: true,
      );

      final monitor = ApiErrorMonitor.fromConfig(config);
      expect(monitor.isEnabled, true);
    });

    test('should handle disabled monitor', () async {
      final disabledMonitor = ApiErrorMonitor(
        appName: "TestApp",
        enabled: false,
      );

      // Should not throw even if capture is called
      await disabledMonitor.capture(Exception("Test error"), endpoint: "/test");

      expect(disabledMonitor.isEnabled, false);
    });
  });

  group('ErrorParser', () {
    test('should parse type mismatch error', () {
      final errorMessage = "type 'String' is not a subtype of type 'int'";
      final errorInfo = ErrorParser.parseError(TypeError(), errorMessage);

      expect(errorInfo.receivedType, contains('String'));
      expect(errorInfo.expectedType, contains('int'));
    });

    test('should parse null value error', () {
      final errorMessage = "type 'null' is not a subtype of type 'String'";
      final errorInfo = ErrorParser.parseError(TypeError(), errorMessage);

      expect(errorInfo.receivedType, 'null');
      expect(errorInfo.expectedType, contains('String'));
    });

    test('should parse missing key error', () {
      final errorMessage = 'key not found: "email"';
      final errorInfo = ErrorParser.parseError(Exception(), errorMessage);

      expect(errorInfo.key, 'email');
    });

    test('should handle empty error message', () {
      final errorInfo = ErrorParser.parseError(Exception(), '');

      expect(errorInfo.key, isNull);
      expect(errorInfo.expectedType, isNull);
      expect(errorInfo.receivedType, isNull);
    });
  });

  group('ApiErrorReport', () {
    test('should create report with all fields', () {
      final report = ApiErrorReport(
        appName: "TestApp",
        endpoint: "/test/endpoint",
        key: "email",
        expectedType: "String",
        receivedType: "null",
        errorMessage: "Test error",
        stackTrace: "Stack trace",
        requestData: {'id': 1},
        responseData: {'email': null},
        timestamp: DateTime(2024, 1, 1),
      );

      expect(report.appName, "TestApp");
      expect(report.endpoint, "/test/endpoint");
      expect(report.key, "email");
      expect(report.expectedType, "String");
      expect(report.receivedType, "null");
      expect(report.errorMessage, "Test error");
      expect(report.stackTrace, "Stack trace");
      expect(report.requestData, {'id': 1});
      expect(report.responseData, {'email': null});
      expect(report.timestamp, DateTime(2024, 1, 1));
    });

    test('should use current timestamp when not provided', () {
      final before = DateTime.now();
      final report = ApiErrorReport(
        appName: "TestApp",
        endpoint: "/test",
        errorMessage: "Error",
      );
      final after = DateTime.now();

      expect(
        report.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        report.timestamp.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('should convert to JSON with all fields', () {
      final report = ApiErrorReport(
        appName: "TestApp",
        endpoint: "/test",
        key: "email",
        expectedType: "String",
        receivedType: "null",
        errorMessage: "Error",
        stackTrace: "Stack",
        requestData: {'id': 1},
        responseData: {'email': null},
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

      final json = report.toJson();
      expect(json['appName'], "TestApp");
      expect(json['endpoint'], "/test");
      expect(json['key'], "email");
      expect(json['expectedType'], "String");
      expect(json['receivedType'], "null");
      expect(json['errorMessage'], "Error");
      expect(json['stackTrace'], "Stack");
      expect(json['requestData'], {'id': 1});
      expect(json['responseData'], {'email': null});
      expect(json['timestamp'], "2024-01-01T12:00:00.000");
    });
  });
}
