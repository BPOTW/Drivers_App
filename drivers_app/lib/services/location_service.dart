import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';

class LocationService {
  static Position? _previousLocation;

  static Future<Position> getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException('Location services are disabled.');
    }

    // Check and request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );

    return position;
  }

  static bool isMoving(Position currentPosition) {
    if (_previousLocation == null) {
      _previousLocation = currentPosition;
      return false;
    }

    double distance = Geolocator.distanceBetween(
      _previousLocation!.latitude,
      _previousLocation!.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    // bool isMoving = distance > AppConstants.minDistanceThreshold ||
    //     currentPosition.speed >= AppConstants.minSpeedThreshold;
    bool isMoving = distance > AppConstants.minDistanceThreshold;

    if (isMoving) {
      _previousLocation = currentPosition;
    }

    return isMoving;
  }

  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      return permission == LocationPermission.whileInUse ||
             permission == LocationPermission.always;
    }
    
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }

  static String getLocationStatusMessage(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return AppConstants.statusLocationPermissionDenied;
      case LocationPermission.deniedForever:
        return AppConstants.statusPermissionDeniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return AppConstants.statusIdle;
      case LocationPermission.unableToDetermine:
        return 'Unable to determine location permission';
    }
  }
}

class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}
