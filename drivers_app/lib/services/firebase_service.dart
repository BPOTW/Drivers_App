import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/route_model.dart';
import '../models/checkpoint_model.dart';
import '../models/location_model.dart';
import '../constants/app_constants.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  static Future<User?> getUserByLoginKey(String loginKey) async {
    try {
      final query = await _firestore
          .collection(AppConstants.usersCollection)
          .where('login_key', isEqualTo: loginKey)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final doc = query.docs.first;
      return User.fromMap(doc.data(), doc.id);
    } catch (e) {
      print('Error getting user by login key: $e');
      return null;
    }
  }

  static Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }
      return User.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Route operations
  static Future<DeliveryRoute?> getRouteById(String routeId) async {
    try {
      print(routeId);
      final doc = await _firestore
          .collection(AppConstants.routesCollection)
          .doc(routeId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return DeliveryRoute.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting route by ID: $e');
      return null;
    }
  }

  /// Fetch all routes that have been assigned to a particular driver
  /// (driver id stored inside the nested `driver_info.driver_id` field).
  static Future<List<DeliveryRoute>> getRoutesAssignedToDriver(
      String driverId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.routesCollection)
          .where('driver_info.driver_id', isEqualTo: driverId)
          .get();

        return query.docs
          .map((doc) => DeliveryRoute.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting routes for driver: $e');
      return [];
    }
  }

  static Future<List<Checkpoint>> getCheckpointsByRouteId(
    String routeId,
  ) async {
    try {
      final query = await _firestore
          .collection(AppConstants.routesCollection)
          .doc(routeId)
          .collection(AppConstants.checkpointsCollection)
          .orderBy('order', descending: false)
          .get();

      return query.docs
          .map((doc) => Checkpoint.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting checkpoints: $e');
      return [];
    }
  }

  // Location operations
  static Future<void> updateLocation(LocationData locationData) async {
    try {
      await _firestore
          .collection(AppConstants.liveLocationsCollection)
          .doc(locationData.driverId)
          .update(locationData.toMap());
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }

  static Future<void> updateCheckpointStatus(
    String routeId,
    String checkpointId,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.routesCollection)
          .doc(routeId)
          .collection(AppConstants.checkpointsCollection)
          .doc(checkpointId)
          .update({
            'has_reached': true,
            'status': 'Reached',
            'time_reached': Timestamp.now(),
          });
    } catch (e) {
      print('Error updating checkpoint status: $e');
      rethrow;
    }
  }

  static Future<void> markRouteAsCompleted(String routeId) async {
    try {
      await _firestore
          .collection(AppConstants.routesCollection)
          .doc(routeId)
          .update({'status': 'Completed', 'is_completed': true});
    } catch (e) {
      print('Error marking route as completed: $e');
      rethrow;
    }
  }
}

class StorageService {
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userIdKey, userId);
  }

  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userIdKey) ?? '';
  }

  static Future<void> saveLoginKey(String loginKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.loginKey, loginKey);
  }

  static Future<String> getLoginKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.loginKey) ?? '';
  }

  static Future<bool> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.loginKey);
      print('object');
      return true;
    } catch (e) {
      print("Error occored");
      print(e);
      return false;
    }
  }
}
