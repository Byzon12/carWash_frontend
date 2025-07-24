import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/api_connect.dart';
import 'package:flutter_application_1/services/carwash_service.dart';
import 'package:flutter_application_1/widgets/login_status_widget.dart';

class QuickBackendTest extends StatefulWidget {
  const QuickBackendTest({super.key});

  @override
  State<QuickBackendTest> createState() => _QuickBackendTestState();
}

class _QuickBackendTestState extends State<QuickBackendTest> {
  String _testResult = '';
  bool _isLoading = false;

  Future<void> _runQuickTest() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing backend connectivity...\n';
    });

    try {
      // 1. Check login status
      _updateResult('1. Checking login status...');
      final isLoggedIn = await ApiConnect.isLoggedIn();
      _updateResult(
        '   Login status: ${isLoggedIn ? "✅ Logged In" : "❌ Not Logged In"}',
      );

      if (!isLoggedIn) {
        _updateResult('   ⚠️  Need to login first to access locations API');
        setState(() => _isLoading = false);
        return;
      }

      // 2. Test direct API call
      _updateResult('2. Testing direct API call...');
      final response = await ApiConnect.getLocations();

      if (response != null) {
        _updateResult('   API Response Status: ${response.statusCode}');
        _updateResult(
          '   API Response Body: ${response.body.substring(0, 200)}...',
        );
      } else {
        _updateResult('   ❌ API returned null response');
      }

      // 3. Test CarWash service
      _updateResult('3. Testing CarWash service...');
      final locations = await CarWashService.fetchCarWashes();
      _updateResult('   Service returned ${locations.length} locations');

      if (locations.isNotEmpty) {
        _updateResult('   First location: ${locations.first.name}');
      }
    } catch (e) {
      _updateResult('❌ Error: $e');
    }

    setState(() => _isLoading = false);
  }

  void _updateResult(String message) {
    setState(() {
      _testResult += '$message\n';
    });
    print('[QUICK_TEST] $message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Backend Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LoginStatusWidget(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _runQuickTest,
              child:
                  _isLoading
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          ),
                          SizedBox(width: 10),
                          Text('Testing...'),
                        ],
                      )
                      : const Text('Run Backend Test'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResult.isEmpty
                        ? 'Click "Run Backend Test" to test location fetching'
                        : _testResult,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
