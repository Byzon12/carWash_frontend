import 'package:flutter/material.dart';
import '../api/api_connect.dart';

class ApiDebugScreen extends StatefulWidget {
  const ApiDebugScreen({super.key});

  @override
  _ApiDebugScreenState createState() => _ApiDebugScreenState();
}

class _ApiDebugScreenState extends State<ApiDebugScreen> {
  String _debugOutput = 'Ready to test API...\n';
  bool _isLoading = false;

  void _addOutput(String message) {
    setState(() {
      _debugOutput += '$message\n';
    });
  }

  Future<void> _testLogin() async {
    setState(() => _isLoading = true);
    _addOutput('🔐 Testing login...');

    try {
      final response = await ApiConnect.login(
        'test@example.com',
        'testpassword',
      );
      _addOutput('✅ Login response received: ${response.statusCode}');
      _addOutput('📝 Response body: ${response.body}');
    } catch (e) {
      _addOutput('❌ Login error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testLocations() async {
    setState(() => _isLoading = true);
    _addOutput('📍 Testing locations API...');

    try {
      final response = await ApiConnect.getLocations();
      if (response != null) {
        _addOutput('✅ Locations response received: ${response.statusCode}');
        _addOutput('📝 Response body: ${response.body}');
      } else {
        _addOutput('❌ Locations response is null');
      }
    } catch (e) {
      _addOutput('❌ Locations error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _checkAuthStatus() async {
    setState(() => _isLoading = true);
    _addOutput('🔍 Checking authentication status...');

    try {
      final isLoggedIn = await ApiConnect.isLoggedIn();
      _addOutput('📊 Is logged in: $isLoggedIn');

      final token = await ApiConnect.getAccessToken();
      if (token != null) {
        _addOutput('🎟️ Token available: ${token.substring(0, 20)}...');
      } else {
        _addOutput('❌ No token available');
      }
    } catch (e) {
      _addOutput('❌ Auth check error: $e');
    }

    setState(() => _isLoading = false);
  }

  void _clearOutput() {
    setState(() => _debugOutput = 'Output cleared...\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API Debug Console'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Button Row
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 8.0,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkAuthStatus,
                  child: Text('Check Auth'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testLogin,
                  child: Text('Test Login'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testLocations,
                  child: Text('Test Locations'),
                ),
                ElevatedButton(
                  onPressed: _clearOutput,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: Text('Clear'),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (_isLoading) LinearProgressIndicator(),

          // Debug output
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16.0),
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _debugOutput,
                  style: TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 12.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
