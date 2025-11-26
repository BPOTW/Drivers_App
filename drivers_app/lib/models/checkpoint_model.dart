import 'package:cloud_firestore/cloud_firestore.dart';

class Checkpoint {
  final String id;
  final String routeId;
  final String name;
  final int order;
  final double expectedTime; // in minutes
  final bool hasReached;
  final String status;
  final DateTime? timeReached;

  Checkpoint({
    required this.id,
    required this.routeId,
    required this.name,
    required this.order,
    required this.expectedTime,
    required this.hasReached,
    required this.status,
    this.timeReached,
  });

  factory Checkpoint.fromMap(Map<String, dynamic> map, String id) {
    return Checkpoint(
      id: id,
      routeId: map['route_id'] ?? '',
      name: map['name'] ?? 'Unnamed',
      order: map['order'] ?? 0,
      expectedTime: (map['expected_time'] ?? 0).toDouble(),
      hasReached: map['has_reached'] ?? false,
      status: map['status'] ?? 'Pending',
      timeReached: _parseTimestamp(map['time_reached']),
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

  Map<String, dynamic> toMap() {
    final map = {
      'route_id': routeId,
      'name': name,
      'order': order,
      'expected_time': expectedTime,
      'has_reached': hasReached,
      'status': status,
    };
    
    if (timeReached != null) {
      map['time_reached'] = Timestamp.fromDate(timeReached!);
    }
    
    return map;
  }

  Checkpoint copyWith({
    String? id,
    String? routeId,
    String? name,
    int? order,
    double? expectedTime,
    bool? hasReached,
    String? status,
    DateTime? timeReached,
  }) {
    return Checkpoint(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      name: name ?? this.name,
      order: order ?? this.order,
      expectedTime: expectedTime ?? this.expectedTime,
      hasReached: hasReached ?? this.hasReached,
      status: status ?? this.status,
      timeReached: timeReached ?? this.timeReached,
    );
  }
}
