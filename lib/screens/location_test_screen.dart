import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/api_connect.dart';
import 'package:flutter_application_1/services/carwash_service.dart';
import 'package:flutter_application_1/models/cars.dart';

class LocationTestScreen extends StatefulWidget {
  const LocationTestScreen({super.key});

  @override
  State<LocationTestScreen> createState() => _LocationTestScreenState();
}

class _LocationTestScreenState extends State<LocationTestScreen> {
  bool _isLoading = false;
  String _status = '';
  List<CarWash>? _locations;

  Future<void> _testDirectAPI() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing direct API call...';
      _locations = null;
    });

    try {
      print('[TEST] Testing ApiConnect.getLocations()...');
      final response = await ApiConnect.getLocations();

      if (response != null) {
        setState(() {
          _status = '✅ API Response: ${response.statusCode}\n${response.body}';
        });
      } else {
        setState(() {
          _status = '❌ API returned null response';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ API Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCarWashService() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing CarWash service...';
      _locations = null;
    });

    try {
      print('[TEST] Testing CarWashService.fetchCarWashes()...');
      final locations = await CarWashService.fetchCarWashes();

      setState(() {
        _locations = locations;
        _status =
            '✅ Successfully fetched ${locations.length} locations from service';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Service Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkLogin() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking login status...';
    });

    try {
      final isLoggedIn = await ApiConnect.isLoggedIn();
      final token = await ApiConnect.getAccessToken();

      setState(() {
        _status =
            'Login Status: ${isLoggedIn ? "✅ Logged In" : "❌ Not Logged In"}\n'
            'Token: ${token?.substring(0, 20) ?? "None"}...';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Login Check Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location API Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Backend Location Testing',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isLoading ? null : _checkLogin,
              child: const Text('Check Login Status'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _isLoading ? null : _testDirectAPI,
              child: const Text('Test Direct API Call'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _isLoading ? null : _testCarWashService,
              child: const Text('Test CarWash Service'),
            ),
            const SizedBox(height: 20),

            if (_isLoading) const Center(child: CircularProgressIndicator()),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _status.isEmpty ? 'Ready to test' : _status,
                        style: TextStyle(
                          color:
                              _status.contains('✅')
                                  ? Colors.green
                                  : _status.contains('❌')
                                  ? Colors.red
                                  : Colors.black,
                        ),
                      ),
                      if (_locations != null) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Fetched Locations:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._locations!.map(
                          (location) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(location.name),
                              subtitle: Text(location.location),
                              trailing: Text(
                                '${location.services.length} services',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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
