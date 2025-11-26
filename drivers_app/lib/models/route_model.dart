import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryRoute {
  final String id;
  final String name;
  final bool isCompleted;
  final DateTime? createdAt;

  DeliveryRoute({
    required this.id,
    required this.name,
    required this.isCompleted,
    this.createdAt,
  });

  factory DeliveryRoute.fromMap(Map<String, dynamic> map, String id) {
    return DeliveryRoute(
      id: id,
      name: map['name'] ?? '',
      isCompleted: map['is_completed'] ?? false,
      createdAt: _parseTimestamp(map['created_at']),
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
      'name': name,
      'is_completed': isCompleted,
    };
    
    if (createdAt != null) {
      map['created_at'] = Timestamp.fromDate(createdAt!);
    }
    
    return map;
  }

  DeliveryRoute copyWith({
    String? id,
    String? name,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return DeliveryRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
