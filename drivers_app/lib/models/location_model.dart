import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationData {
  final GeoPoint location;
  final DateTime lastUpdated;
  final String driverId;
  final String driverName;
  final String routeId;
  final String status;

  LocationData({
    required this.location,
    required this.lastUpdated,
    required this.driverId,
    required this.driverName,
    required this.routeId,
    required this.status,
  });

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      location: map['location'] as GeoPoint,
      lastUpdated: _parseTimestamp(map['last_updated']) ?? DateTime.now(),
      driverId: map['driver_id'] ?? '',
      driverName: map['driver_name'] ?? '',
      routeId: map['route_id'] ?? '',
      status: map['status'] ?? 'Unknown',
    );
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        print('Error parsing timestamp string: $e');
        return null;
      }
    } else if (timestamp is DateTime) {
      return timestamp;
    }
    
    return null;
  }

  factory LocationData.fromPosition(Position position, {
    required String driverId,
    required String driverName,
    required String routeId,
    required String status,
  }) {
    return LocationData(
      location: GeoPoint(position.latitude, position.longitude),
      lastUpdated: position.timestamp ?? DateTime.now(),
      driverId: driverId,
      driverName: driverName,
      routeId: routeId,
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'last_updated': Timestamp.fromDate(lastUpdated),
      'driver_id': driverId,
      'driver_name': driverName,
      'route_id': routeId,
      'status': status,
    };
  }

  LocationData copyWith({
    GeoPoint? location,
    DateTime? lastUpdated,
    String? driverId,
    String? driverName,
    String? routeId,
    String? status,
  }) {
    return LocationData(
      location: location ?? this.location,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      routeId: routeId ?? this.routeId,
      status: status ?? this.status,
    );
  }
}
