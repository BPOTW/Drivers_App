import 'package:admin_app/components/log_data_to_server.dart';
import 'package:admin_app/screens/create_new_route_screen.dart';
import 'package:admin_app/screens/route_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  List<bool> toggleButton = [];
  Future<List<Map<String, dynamic>>> fetchRoutes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('routes')
          .get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      await logEvent(
        event: 'App Error',
        message: 'Error fetching routes from server Page:routes_screen.',
        type: 'ERROR',
      );
      print('Error fetching routes: $e');
      return [];
    }
  }

  Future<void> updateRouteStatus(String id, bool isActive) async {
    try {
      await FirebaseFirestore.instance.collection('routes').doc(id).update({
        'is_active': isActive,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Route status updated to ${isActive ? 'Active' : 'Inactive'}',
          ),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {}); // refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await logEvent(
        event: 'App Error',
        message: 'Error updating route status Page:routes_screen.',
        type: 'ERROR',
      );
    }
  }

  Future<void> duplicateRoute(Map<String, dynamic> originalRoute) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    try {
      // Create new route document
      final newRouteRef = firestore.collection('routes').doc();
      final newRouteId = newRouteRef.id;

      // Prepare new route data (without driver assignment)
      final newRouteData = {
        'name': '${originalRoute['name']}',
        'dealer_name': originalRoute['dealer_name'],
        'dealer_phone': originalRoute['dealer_phone'],
        'distance_km': originalRoute['distance_km'],
        'end': originalRoute['end'],
        'expected_time': originalRoute['expected_time'],
        'is_active': true,
        'start': originalRoute['start'],
        'is_completed': false,
        'status': 'Pending',
        'checkpoints': originalRoute['checkpoints'],
        'created_at': DateTime.now().toIso8601String(),
        // No driver assignment fields
      };

      batch.set(newRouteRef, newRouteData);

      // Copy checkpoints from original route
      final originalCheckpointsSnapshot = await firestore
          .collection('routes')
          .doc(originalRoute['id'])
          .collection('checkpoints')
          .get();

      int order = 1;
      for (var checkpointDoc in originalCheckpointsSnapshot.docs) {
        final checkpointData = checkpointDoc.data();
        final newCheckpointRef = newRouteRef.collection('checkpoints').doc();
        
        batch.set(newCheckpointRef, {
          'name': checkpointData['name'],
          'expected_time': checkpointData['expected_time'],
          'location': checkpointData['location'],
          'time_reached': Timestamp.now(),
          'order': order,
          'has_reached': false,
          'status': "Pending",
        });
        order++;
      }

      await batch.commit();

      await logEvent(
        event: 'Route Duplicated',
        message: 'Successfully duplicated route: ${originalRoute['name']}',
        type: 'INFO',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Route '${originalRoute['name']}' duplicated successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {}); // Refresh the UI
    } catch (e) {
      await logEvent(
        event: 'App Error',
        message: 'Error duplicating route Page:routes_screen.',
        type: 'ERROR',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error duplicating route: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      print("Error duplicating route: $e");
    }
  }

  Future<void> deleteRoute(String routeId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final routeRef = firestore.collection('routes').doc(routeId);

      final driversRef = await routeRef.collection('assigned_drivers').get();
      final docIds = driversRef.docs.map((doc) => doc.id).toList();

      final checkpointsSnapshot = await routeRef
          .collection('checkpoints')
          .get();

      final assignedDriversSnapshot = await routeRef
          .collection('assigned_drivers')
          .get();
      

      WriteBatch batch = firestore.batch();
      for (var doc in checkpointsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      for (var doc in assignedDriversSnapshot.docs) {
        batch.delete(doc.reference);
      }

      for (var id in docIds) {
        final locationSnapshot = firestore
          .collection('live_locations')
          .doc(id);
        final usersSnapshot = firestore
          .collection('users')
          .doc(id);
        batch.update(locationSnapshot,{'route_id':''});
        batch.update(usersSnapshot,{'route_id':'','route_name':'','is_delivery_assigned':false});
      }

      await batch.commit();
      await routeRef.delete();

      print("Route and checkpoints deleted successfully!");
      await logEvent(
        event: 'Route Deleted',
        message: 'Successfully deleted route : ${routeId}',
        type: 'INFO',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Route deleted successfully")),
      );
      setState(() {});
    } catch (e) {
      await logEvent(
        event: 'App Error',
        message: 'Error deleting route Page:routes_screen.',
        type: 'ERROR',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong!")),
      );
      print("Error deleting route and checkpoints: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Button Row
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Routes",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateRouteScreen(),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  icon: const Icon(Icons.add_road),
                  label: const Text(
                    "Create New Route",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    iconColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Grid View for Routes
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchRoutes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final routes = snapshot.data ?? [];
                if (routes.isEmpty) {
                  return const Center(child: Text('No routes found'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    toggleButton.add(route['is_active']);
                    return Card(
                      color: Colors.teal.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.alt_route,
                                  color: Colors.teal.shade300,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      route['name'] ?? 'Unnamed Route',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Assigned by: ${route['dealer_name'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Checkpoints: ${route['checkpoints']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Status: ${route['status']}',
                              style: TextStyle(
                                color: route['status'] == 'Completed'
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // View Details Button
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RouteDetailsScreen(
                                          routeData: route,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.info_outline),
                                  label: const Text(
                                    "Details",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    iconColor: Colors.white,
                                    backgroundColor: Colors.teal.shade700,
                                  ),
                                ),

                                // Action buttons
                                Row(
                                  children: [
                                    // Duplicate Button
                                    IconButton(
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Duplicate Route'),
                                            content: Text(
                                              'Are you sure you want to duplicate "${route['name']}"? This will create a new route without assigning a driver.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                ),
                                                child: const Text('Duplicate',style: TextStyle(color: Colors.white),),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          duplicateRoute(route);
                                        }
                                      },
                                      icon: const Icon(Icons.copy),
                                      color: Colors.blueAccent,
                                      tooltip: 'Duplicate Route',
                                    ),
                                    // Delete Button
                                    IconButton(
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Route'),
                                            content: const Text(
                                              'Are you sure you want to delete this route?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: const Text('Delete',style: TextStyle(color: Colors.white),),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          deleteRoute(route['id']);
                                        }
                                      },
                                      icon: const Icon(Icons.delete),
                                      color: Colors.redAccent,
                                      tooltip: 'Delete Route',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
