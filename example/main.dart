import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:api_error_monitor/api_error_monitor.dart';

// Example model for testing
class UserModel {
  final String name;
  final String email;
  final int age;

  UserModel({required this.name, required this.email, required this.age});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] as String,
      email: json['email'] as String,
      age: json['age'] as int,
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Logger Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'API Logger Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Initialize API error monitor
  late final ApiErrorMonitor errorMonitor;
  late final Dio dio;

  String _status = 'Ready';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();

    // Initialize error monitor
    // Replace with your Discord webhook URL
    errorMonitor = ApiErrorMonitor(
      appName: "API Logger Example",
      discordWebhookUrl: null, // Add your webhook URL here
      enableInDebugMode: true, // Enable in debug mode for testing
      enableLocalLogging: true,
    );

    // Initialize Dio with error monitoring
    dio = Dio();
    dio.addApiErrorMonitoring(errorMonitor: errorMonitor);

    _addLog('Error monitor initialized');
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
  }

  // Test 1: Type mismatch error
  Future<void> _testTypeMismatch() async {
    setState(() {
      _status = 'Testing type mismatch...';
    });
    _addLog('Testing type mismatch error');

    try {
      // Simulate API response with wrong type
      final response = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'age': '25', // Should be int, but is String
      };

      final user = UserModel.fromJson(response);
      _addLog('User created: ${user.name}');
    } catch (e, s) {
      _addLog('Error caught: ${e.toString()}');
      // Get response from the try block scope
      final response = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'age': '25',
      };
      await errorMonitor.capture(
        e,
        stackTrace: s,
        endpoint: '/api/users',
        responseData: response,
      );
      _addLog('Error reported to monitor');
    }

    setState(() {
      _status = 'Type mismatch test completed';
    });
  }

  // Test 2: Missing key error
  Future<void> _testMissingKey() async {
    setState(() {
      _status = 'Testing missing key...';
    });
    _addLog('Testing missing key error');

    try {
      // Simulate API response with missing key
      final response = {
        'name': 'John Doe',
        // 'email' is missing
        'age': 25,
      };

      final user = UserModel.fromJson(response);
      _addLog('User created: ${user.name}');
    } catch (e, s) {
      _addLog('Error caught: ${e.toString()}');
      // Get response from the try block scope
      final response = {'name': 'John Doe', 'age': 25};
      await errorMonitor.capture(
        e,
        stackTrace: s,
        endpoint: '/api/users',
        responseData: response,
      );
      _addLog('Error reported to monitor');
    }

    setState(() {
      _status = 'Missing key test completed';
    });
  }

  // Test 3: Null value error
  Future<void> _testNullValue() async {
    setState(() {
      _status = 'Testing null value...';
    });
    _addLog('Testing null value error');

    try {
      // Simulate API response with null value
      final response = {
        'name': 'John Doe',
        'email': null, // Should be String, but is null
        'age': 25,
      };

      final user = UserModel.fromJson(response);
      _addLog('User created: ${user.name}');
    } catch (e, s) {
      _addLog('Error caught: ${e.toString()}');
      // Get response from the try block scope
      final response = {'name': 'John Doe', 'email': null, 'age': 25};
      await errorMonitor.capture(
        e,
        stackTrace: s,
        endpoint: '/api/users',
        responseData: response,
      );
      _addLog('Error reported to monitor');
    }

    setState(() {
      _status = 'Null value test completed';
    });
  }

  // Test 4: View local reports
  Future<void> _viewLocalReports() async {
    setState(() {
      _status = 'Loading local reports...';
    });
    _addLog('Loading local reports');

    final reports = await errorMonitor.getLocalReports();
    _addLog('Found ${reports.length} local reports');

    for (final report in reports) {
      _addLog('Report: ${report.endpoint} - ${report.errorMessage}');
    }

    setState(() {
      _status = 'Loaded ${reports.length} reports';
    });
  }

  // Test 5: Process queue
  Future<void> _processQueue() async {
    setState(() {
      _status = 'Processing queue...';
    });
    _addLog('Processing queue');

    final queueSize = errorMonitor.queueSize;
    _addLog('Queue size: $queueSize');

    if (queueSize > 0) {
      await errorMonitor.processQueue();
      _addLog('Queue processed');
    } else {
      _addLog('Queue is empty');
    }

    setState(() {
      _status = 'Queue processed';
    });
  }

  // Test 6: Clear local reports
  Future<void> _clearLocalReports() async {
    setState(() {
      _status = 'Clearing local reports...';
    });
    _addLog('Clearing local reports');

    final success = await errorMonitor.clearLocalReports();
    if (success) {
      _addLog('Local reports cleared');
    } else {
      _addLog('Failed to clear local reports');
    }

    setState(() {
      _status = 'Local reports cleared';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Status: $_status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ElevatedButton(
                  onPressed: _testTypeMismatch,
                  child: const Text('Test Type Mismatch'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _testMissingKey,
                  child: const Text('Test Missing Key'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _testNullValue,
                  child: const Text('Test Null Value'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _viewLocalReports,
                  child: const Text('View Local Reports'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _processQueue,
                  child: const Text('Process Queue'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _clearLocalReports,
                  child: const Text('Clear Local Reports'),
                ),
                const SizedBox(height: 24),
                Text('Logs:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
