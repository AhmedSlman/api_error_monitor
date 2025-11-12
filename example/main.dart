import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:api_error_monitor/api_error_monitor.dart';

const _baseUrl = 'https://jsonplaceholder.typicode.com';
const _userEndpoint = '/users/1';
const _discordWebhookUrl =
    String.fromEnvironment('DISCORD_WEBHOOK', defaultValue: '');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Error Monitor Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'API Error Monitor Example'),
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
  late final ApiErrorMonitor errorMonitor;
  late final Dio dio;

  String _status = 'Ready';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();

    errorMonitor = ApiErrorMonitor(
      appName: 'API Error Monitor Example',
      discordWebhookUrl:
          _discordWebhookUrl.isEmpty ? null : _discordWebhookUrl,
      enableInDebugMode: true,
      enableLocalLogging: true,
    );

    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.addApiErrorMonitoring(errorMonitor: errorMonitor);

    _addLog('Error monitor initialized');
    if (_discordWebhookUrl.isEmpty) {
      _addLog(
        'TIP: Define DISCORD_WEBHOOK env var to send reports to Discord.',
      );
    }
  }

  void _addLog(String message) {
    if (!mounted) return;
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
  }

  void _updateStatus(String message) {
    if (!mounted) return;
    setState(() => _status = message);
  }

  Future<void> _runScenario({
    required String description,
    required void Function(Map<String, dynamic>) action,
  }) async {
    final endpoint = '$_baseUrl$_userEndpoint';
    _updateStatus('Running $description scenario...');
    _addLog('GET $endpoint');

    Response<dynamic>? response;
    try {
      response = await dio.get(_userEndpoint);
      final data = Map<String, dynamic>.from(response.data as Map);
      action(data);
      _addLog('$description completed without errors.');
    } catch (e, s) {
      _addLog('$description captured error: $e');
      await errorMonitor.capture(
        e,
        stackTrace: s,
        endpoint: endpoint,
        responseData: response?.data,
      );
    } finally {
      _updateStatus('$description scenario finished');
    }
  }

  Future<void> _fetchUserWithTypeMismatch() async {
    await _runScenario(
      description: 'Type mismatch',
      action: (data) {
        // jsonplaceholder returns id as int -> expect String to trigger error
        final id = data['id'] as String;
        final email = data['email'] as String;
        _addLog('Parsed id=$id email=$email (unexpected)');
      },
    );
  }

  Future<void> _fetchUserWithMissingKey() async {
    await _runScenario(
      description: 'Missing key',
      action: (data) {
        // The API does not return an "age" field -> expect int to trigger error
        final age = data['age'] as int;
        _addLog('Parsed age=$age (unexpected)');
      },
    );
  }

  Future<void> _fetchUserSuccessfully() async {
    await _runScenario(
      description: 'Successful parse',
      action: (data) {
        final user = UserModel.fromJson(data);
        _addLog(
          'Parsed user: ${user.name} (${user.email}) from ${user.city}.',
        );
      },
    );
  }

  Future<void> _viewLocalReports() async {
    _updateStatus('Loading local reports...');
    _addLog('Loading local reports');

    final reports = await errorMonitor.getLocalReports();
    _addLog('Found ${reports.length} local reports');

    for (final report in reports) {
      _addLog('Report: ${report.endpoint} - ${report.errorMessage}');
    }

    _updateStatus('Loaded ${reports.length} reports');
  }

  Future<void> _processQueue() async {
    _updateStatus('Processing queue...');
    _addLog('Processing queue');

    final queueSize = errorMonitor.queueSize;
    _addLog('Queue size: $queueSize');

    if (queueSize > 0) {
      await errorMonitor.processQueue();
      _addLog('Queue processed');
    } else {
      _addLog('Queue is empty');
    }

    _updateStatus('Queue processed');
  }

  Future<void> _clearLocalReports() async {
    _updateStatus('Clearing local reports...');
    _addLog('Clearing local reports');

    final success = await errorMonitor.clearLocalReports();
    if (success) {
      _addLog('Local reports cleared');
    } else {
      _addLog('Failed to clear local reports');
    }

    _updateStatus('Local reports cleared');
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
                  onPressed: _fetchUserWithTypeMismatch,
                  child: const Text('Fetch user (type mismatch)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _fetchUserWithMissingKey,
                  child: const Text('Fetch user (missing key)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _fetchUserSuccessfully,
                  child: const Text('Fetch user (success)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _viewLocalReports,
                  child: const Text('View local reports'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _processQueue,
                  child: const Text('Process webhook retry queue'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _clearLocalReports,
                  child: const Text('Clear local reports'),
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

class UserModel {
  final int id;
  final String name;
  final String email;
  final String city;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.city,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>;
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      city: address['city'] as String,
    );
  }
}
