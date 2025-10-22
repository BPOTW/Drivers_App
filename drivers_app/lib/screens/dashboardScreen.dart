import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationLogScreen extends StatefulWidget {
  const LocationLogScreen({super.key});

  @override
  State<LocationLogScreen> createState() => _LocationLogScreenState();
}

class _LocationLogScreenState extends State<LocationLogScreen> {
  final ValueNotifier<double> _progress = ValueNotifier<double>(0.0);
  final ValueNotifier<String> _serverStatus = ValueNotifier<String>('Idle');
  final ValueNotifier<Duration> _remainingTime = ValueNotifier<Duration>(
    Duration.zero,
  );

  final List<Map<String, dynamic>> _checkpoints = [];

  int _currentStep = 0;
  Timer? _timeoutTimer;
  Timer? _countdownTimer;
  Timer? _timer;
  Map appData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    getDataFromDatabase();
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      updateLoationOnDatabase();
    });
  }

  Future getDriverLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      _serverStatus.value = "Enable Location Service";
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        _serverStatus.value = "Location Permision Denied";
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _serverStatus.value = "Permision Denied Forever";
      print(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(accuracy: LocationAccuracy.best),
    );
    return position;
  }

  Position? previousLocation;
  bool checkIfMoving(Position currentPosition, double speed) {
    bool isMoving = false;
    if (previousLocation != null) {
      double distance = Geolocator.distanceBetween(
        previousLocation!.latitude,
        previousLocation!.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );

      if (distance > 5 || speed >= 0.0) {
        isMoving = true;
        previousLocation = currentPosition;
      } else {
        isMoving = false;
      }
    } else {
      isMoving = false;
    }
    return isMoving;
  }

  void updateLoationOnDatabase() async {
    _serverStatus.value = "Updating Location...";
    Position locationData = await getDriverLocation();
    String userId = appData['userId'];
    bool isMoving = checkIfMoving(locationData, locationData.speed);
    try {
      await FirebaseFirestore.instance
          .collection('live_locations')
          .doc(userId)
          .update({
            'location': GeoPoint(locationData.latitude, locationData.longitude),
            'last_updated': locationData.timestamp,
            'driver_id': userId,
            'driver_name': appData['userName'],
            'route_id': appData['routeId'],
            'status': isMoving ? 'Moving' : 'Not Moving',
          });
      _serverStatus.value = "Location Updated Successfully";
    } catch (e) {
      _serverStatus.value = "Failed to Update Location";
    }
  }

  Future<void> getDataFromDatabase() async {
    _serverStatus.value = "Loading User Data...";
    try {
      String userId = await getStoredUserId();
      if (userId.isEmpty) {
        _serverStatus.value = "No user found.";
        return;
      }
      appData['userId'] = userId;

      Map<String, dynamic>? userData = await getUserDataFromDatabase(userId);
      if (userData == null || !userData.containsKey('route_id')) {
        _serverStatus.value = "User data missing route_id.";
        return;
      }

      String routeId = userData['route_id'];
      appData['routeId'] = routeId;
      appData['userName'] = userData['name'];

      Map<String, dynamic>? routeData = await getRoutesDataFromDatabase(
        routeId,
      );
      if (routeData == null) {
        _serverStatus.value = "Route not found.";
        return;
      }

      List<QueryDocumentSnapshot<Map<String, dynamic>>> checkpointsDocs =
          await getCheckpointsDataFromDatabase(routeId);

      List<Map<String, dynamic>> loadedCheckpoints = checkpointsDocs.map((doc) {
        final data = doc.data();
        return {
          'checkpointId': doc.id,
          'routeId': routeId,
          'name': data['name'] ?? 'Unnamed',
          'expected_time': data['expected_time'] ?? '',
          'icon': Icons.location_on,
        };
      }).toList();

      appData['checkpointData'] = loadedCheckpoints;

      setState(() {
        _checkpoints.clear();
        _checkpoints.addAll(loadedCheckpoints);
        _progress.value = 0.0;
        _currentStep = 0;
        _serverStatus.value = "Route '${routeData['name']}' loaded.";
      });

      _serverStatus.value = "Data Loaded Sussessfully";
      setState(() {
        _isLoading = false;
      });

      if (_checkpoints.isNotEmpty) {
        _startTimeout();
      }
    } catch (e) {
      print("Error loading data: $e");
      _serverStatus.value = "Failed to Load User Data.";
    }
  }

  Future<String> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? "";
  }

  Future<Map<String, dynamic>?> getUserDataFromDatabase(String userId) async {
    print("Fetching userData for userId=$userId");
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    return query.data();
  }

  Future<Map<String, dynamic>?> getRoutesDataFromDatabase(
    String routeId,
  ) async {
    print("Fetching routeData for routeId=$routeId");
    final query = await FirebaseFirestore.instance
        .collection('routes')
        .doc(routeId)
        .get();
    return query.data();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  getCheckpointsDataFromDatabase(String routeId) async {
    print("Fetching checkpoints for routeId=$routeId");
    final query = await FirebaseFirestore.instance
        .collection('routes')
        .doc(routeId)
        .collection('checkpoints')
        .orderBy(
          'order',
          descending: false,
        ) // Optional if you have checkpoint order
        .get();
    return query.docs;
  }

  void saveCheckpointToDatabase(
    String routeId,
    String checkpointId,
    int step,
  ) async {
    _serverStatus.value = "Saving checkpoint";
    try {
      await FirebaseFirestore.instance
          .collection('routes')
          .doc(routeId)
          .collection('checkpoints')
          .doc(checkpointId)
          .update({
            'has_reached': true,
            'status': 'Reached',
            'time_reached': Timestamp.now(),
          });
      _serverStatus.value = "Checkpoint Saved Successfully";
      _updateProgress(step);
    } catch (e) {
      _serverStatus.value = "Failed to Save Checkpoint";
      print(e);
    }
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();

    // Get expected time for the current checkpoint
    final currentCheckpoint = _checkpoints[_currentStep];
    final expectedSeconds =
        currentCheckpoint['expected_time'] * 60; // Example: 10800 for 3 hours

    // Convert to Duration
    final expectedDuration = Duration(seconds: expectedSeconds);

    _remainingTime.value = expectedDuration;

    _timeoutTimer = Timer(expectedDuration, _onTimeout);

    // Countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.value.inSeconds <= 1) {
        timer.cancel();
        _onTimeout();
      } else {
        _remainingTime.value = Duration(
          seconds: _remainingTime.value.inSeconds - 1,
        );
      }
    });
  }

  void _onTimeout() {
    _serverStatus.value = "Timeout: Alerting Admin";
    _countdownTimer?.cancel();
    sendEmailToAdmin();
  }

  Future<void> sendEmailToAdmin() async {
     
    const serviceId = 'service_yrz397m';
    const templateId = 'template_kqobk0r';
    const publicKey = 'nIdsDTNhRs67zApkj';
    Position location = await getDriverLocation();

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'name': appData['userName'],
          'driverId': appData['userId'],
          'locationUrl': 'https://www.google.com/maps?q=${location.latitude},${location.longitude}',
          'email': 'muhammadarslanm011@gmail.com',
        },
      }),
    );

    if (response.statusCode == 200) {
      print('Email sent!');
      _serverStatus.value = "Timeout: Email Send";
    } else {
      print('Failed to send: ${response.body}');
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void _updateProgress(int step) {
    if (step == _currentStep) {
      _startTimeout();
      setState(() {
        _currentStep++;
        _progress.value = _currentStep / _checkpoints.length;
      });

      if (_currentStep == _checkpoints.length) {
        _timeoutTimer?.cancel();
        _countdownTimer?.cancel();
        _remainingTime.value = Duration.zero;
        _serverStatus.value = "All locations logged successfully!";
      }
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _serverStatus.dispose();
    _remainingTime.dispose();
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildCheckpointButton(int index) {
    bool isEnabled = index == _currentStep;
    bool isCompleted = index < _currentStep;
    String checkpointId = _checkpoints[index]['checkpointId'];
    String routeId = _checkpoints[index]['routeId'];
    return ElevatedButton.icon(
      onPressed: isEnabled
          ? () => saveCheckpointToDatabase(routeId, checkpointId, index)
          : null,
      icon: Icon(
        _checkpoints[index]['icon'],
        color: isCompleted ? Colors.greenAccent : Colors.white,
      ),
      label: Text(_checkpoints[index]['name']),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCompleted
            ? Colors.green.withAlpha(8)
            : isEnabled
            ? Colors.blueAccent
            : Colors.grey[800],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            // sendEmailToAdmin();
          },
          child: const Text('Driver Location Log')),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.tealAccent,
                strokeWidth: 4,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  // Progress section
                  ValueListenableBuilder<double>(
                    valueListenable: _progress,
                    builder: (context, value, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 12,
                            backgroundColor: Colors.grey[800],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.tealAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Progress: ${(value * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Countdown timer
                  ValueListenableBuilder<Duration>(
                    valueListenable: _remainingTime,
                    builder: (context, remaining, _) {
                      if (_currentStep >= _checkpoints.length) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.tealAccent.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "⏰ Remaining Time",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _formatDuration(remaining),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.tealAccent,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Dynamic buttons
                  Expanded(
                    child: GridView.builder(
                      itemCount: _checkpoints.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.3,
                          ),
                      itemBuilder: (context, index) =>
                          _buildCheckpointButton(index),
                    ),
                  ),

                  // Server status section
                  ValueListenableBuilder<String>(
                    valueListenable: _serverStatus,
                    builder: (context, status, _) => Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 0),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud, color: Colors.tealAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              status,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
