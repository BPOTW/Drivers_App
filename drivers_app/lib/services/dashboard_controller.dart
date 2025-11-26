import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/route_model.dart';
import '../models/checkpoint_model.dart';
import '../models/location_model.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/email_service.dart';
import '../constants/app_constants.dart';

class DashboardController extends ChangeNotifier {
  // State variables
  double _progress = 0.0;
  String _serverStatus = AppConstants.statusIdle;
  Duration _remainingTime = Duration.zero;
  List<Checkpoint> _checkpoints = [];
  int _currentStep = 0;
  bool _isLoading = true;

  // User and route data
  User? _user;
  DeliveryRoute? _route;

  // Timers
  Timer? _timeoutTimer;
  Timer? _countdownTimer;
  Timer? _locationUpdateTimer;

  // Getters
  double get progress => _progress;
  String get serverStatus => _serverStatus;
  Duration get remainingTime => _remainingTime;
  List<Checkpoint> get checkpoints => _checkpoints;
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  User? get user => _user;
  DeliveryRoute? get route => _route;
  bool get isRouteCompleted => _route?.isCompleted ?? false;

  // Initialize the dashboard
  // If routeId is provided we load and use that route (instead of the user's assigned route).
  Future<void> initialize({String? routeId}) async {
    _setLoading(true);
    _setStatus(AppConstants.statusLoadingUserData);

    try {
      await _loadUserData();
      await _loadSystemData();

      if (routeId != null && routeId.isNotEmpty) {
        // Load the specified route (display/update only this route)
        await _loadRouteData(routeId: routeId);
        // Only load checkpoints if route is not completed
        if (_route != null && !_route!.isCompleted) {
          await _loadCheckpoints();
          if (_checkpoints.isNotEmpty) {
            _startTimeout();
          } else {
            _setStatus(AppConstants.statusNoCheckpoints);
          }
        }
      } else if (_user != null && _user!.routeId.isNotEmpty) {
        await _loadRouteData();
        // Only load checkpoints if route is not completed
        if (_route != null && !_route!.isCompleted) {
          await _loadCheckpoints();
          if (_checkpoints.isNotEmpty) {
            _startTimeout();
          }else{
            _setStatus(AppConstants.statusNoCheckpoints);
          }
        }
      } else {
        _setLoading(false);
        _setStatus(AppConstants.statusNoRouteAssigned);
      }
    } catch (e) {
      _setStatus(AppConstants.statusFailedToLoadUserData);
      print('Error initializing dashboard: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadSystemData() async{
    final systemData = await FirebaseFirestore.instance.collection('system_data')
          .doc('global_data')
          .get();
    if (systemData.data()!.isEmpty) {
      _setStatus(AppConstants.statusSystemDataNotFound);
      return;
    }else{
      _setStatus(AppConstants.statusSystemDataFound);
      final adminEmail = systemData.data()!['email'] != '' ? systemData.data()!['email'] : AppConstants.defaultAdminEmail;
      AppConstants.adminEmail = adminEmail;
      print(AppConstants.adminEmail);
    }
  }
 
  // Load user data
  Future<void> _loadUserData() async {
    final userId = await StorageService.getUserId();
    if (userId.isEmpty) {
      _setStatus(AppConstants.statusNoUserFound);
      return;
    }
    final user = await FirebaseService.getUserById(userId);
    if (user == null) {
      _setStatus(AppConstants.statusUserDataMissing);
      return;
    }

    _user = user;
  }

  // Load route data
  // Load route data. If routeId is provided it will be used, otherwise we
  // fall back to the user's assigned route id.
  Future<void> _loadRouteData({String? routeId}) async {
    final rid = routeId ?? _user?.routeId;
    if (rid == null || rid.isEmpty) {
      _setStatus(AppConstants.statusNoRouteAssigned);
      return;
    }

    final route = await FirebaseService.getRouteById(rid);
    if (route == null) {
      print("error");
      _setStatus(AppConstants.statusUserDataMissing);
      return;
    }

    _route = route;

    if (route.isCompleted) {
      _setStatus('${AppConstants.statusRouteCompleted} ${route.name}');
      return;
    }

    _setStatus('${AppConstants.statusRouteLoaded} ${route.name}');
  }

  // Load checkpoints for the current _route (or exit if we don't have a route)
  Future<void> _loadCheckpoints() async {
    final rid = _route?.id;
    if (rid == null || rid.isEmpty) return;

    final checkpoints = await FirebaseService.getCheckpointsByRouteId(rid);
    _checkpoints = checkpoints;
    _progress = 0.0;
    _currentStep = 0;
  }

  // Start location update timer
  void startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(
      AppConstants.locationUpdateInterval,
      (_) => updateLocation(),
    );
  }

  // Update location
  Future<void> updateLocation() async {
    // We require a route id (either from the opened _route or from the user's assigned route)
    final routeId = _route?.id ?? _user?.routeId;
    if (_user == null || routeId == null || routeId.isEmpty) {
      return;
    }

    try {
      _setStatus(AppConstants.statusUpdatingLocation);
      final position = await LocationService.getCurrentLocation();
      final isMoving = LocationService.isMoving(position);
        final locationData = LocationData.fromPosition(
          position,
          driverId: _user!.id,
          driverName: _user!.name,
          routeId: routeId,
          status: isMoving ? 'Moving' : 'Not Moving',
        );

        await FirebaseService.updateLocation(locationData);
        _setStatus(AppConstants.statusLocationUpdated);
    } catch (e) {
      _setStatus(AppConstants.statusFailedToUpdateLocation);
      print('Error updating location: $e');
    }
  }

  // Save checkpoint
  Future<void> saveCheckpoint(int step) async {
    if (step != _currentStep || step >= _checkpoints.length) return;

    _setStatus(AppConstants.statusSavingCheckpoint);

    try {
      final checkpoint = _checkpoints[step];
      final routeId = _route?.id ?? '';
      await FirebaseService.updateCheckpointStatus(routeId, checkpoint.id);

      _setStatus(AppConstants.statusCheckpointSaved);
      _updateProgress(step);
    } catch (e) {
      _setStatus(AppConstants.statusFailedToSaveCheckpoint);
      print('Error saving checkpoint: $e');
    }
  }

  // Update progress
  void _updateProgress(int step) {
    if (step == _currentStep) {
      _currentStep++;
      _progress = _currentStep / _checkpoints.length;
      notifyListeners();

      if (_currentStep == _checkpoints.length) {
        _timeoutTimer?.cancel();
        _countdownTimer?.cancel();
        _remainingTime = Duration.zero;
        
        _markRouteAsCompleted();
        _setStatus(AppConstants.statusAllLocationsLogged);
      } else {
        _startTimeout();
      }
    }
  }

  // Mark route as completed
  Future<void> _markRouteAsCompleted() async {
    try {
      print("completed");
      final rid = _route?.id ?? _user?.routeId ?? '';
      if (rid.isNotEmpty) await FirebaseService.markRouteAsCompleted(rid);
    } catch (e) {
      print('Error marking route as completed: $e');
    }
  }

  // Start timeout timer
  void _startTimeout() {
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();

    if (_currentStep >= _checkpoints.length) return;

    final currentCheckpoint = _checkpoints[_currentStep];
    final expectedDuration = Duration(
      hours: currentCheckpoint.expectedTime.toInt(),
    );

    _remainingTime = expectedDuration;
    notifyListeners();

    _timeoutTimer = Timer(expectedDuration, _onTimeout);

    _countdownTimer = Timer.periodic(AppConstants.countdownInterval, (timer) {
      if (_remainingTime.inSeconds <= 1) {
        timer.cancel();
        _onTimeout();
      } else {
        _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        notifyListeners();
      }
    });
  }

  // Handle timeout
  void _onTimeout() async {
    _setStatus(AppConstants.statusTimeoutAlertingAdmin);
    _countdownTimer?.cancel();

    try {
      final position = await LocationService.getCurrentLocation();
      await EmailService.sendTimeoutAlert(
        driverName: _user!.name,
        driverId: _user!.id,
        location: position,
      );
      _setStatus(AppConstants.statusTimeoutEmailSent);
    } catch (e) {
      print('Error sending timeout alert: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setStatus(String status) {
    _serverStatus = status;
    notifyListeners();
  }

  // Dispose resources
  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
}
