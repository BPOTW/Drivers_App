import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin_app/screens/update_route_screen.dart';

class RouteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> routeData;

  const RouteDetailsScreen({super.key, required this.routeData});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  late FirebaseFirestore firestore;
  bool _isLoading = false;
  bool _isDriverAssigned = false;

  @override
  void initState() {
    super.initState();
    firestore = FirebaseFirestore.instance;
  }

  void setAssignedDriver(bool assigned) {
    setState(() {
      _isDriverAssigned = assigned;
    });
  }

  Future<Map<String, dynamic>?> getAssignedDriver(String routeId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Get route document
      final routeDoc = await firestore.collection('routes').doc(routeId).get();

      if (!routeDoc.exists) return null;

      final routeData = routeDoc.data()!;
      final driverId = routeData['driver_info']?['driver_id'];

      if (driverId == null || driverId.isEmpty){
         return null;};

      // Get driver details
      final driverDoc = await firestore.collection('users').doc(driverId).get();
      if (!driverDoc.exists) return null;

    
      final data = driverDoc.data();

      data!['id'] = driverId;

      return data;
    } catch (e) {
      debugPrint('Error fetching driver: $e');

      return null;
    }
  }

  /// 🔹 Fetch all checkpoints for the route
  Future<List<Map<String, dynamic>>> fetchCheckpoints(String routeId) async {
    final snapshot = await firestore
        .collection('routes')
        .doc(routeId)
        .collection('checkpoints')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// 🔹 Fetch all drivers (for assigning) - only unassigned drivers
  Future<List<QueryDocumentSnapshot>> fetchDrivers() async {
    final snapshot = await firestore
        .collection('users')
        // .where('is_delivery_assigned', isEqualTo: false)
        .get();
    return snapshot.docs;
  }

  /// 🔹 Assign route to selected driver (single driver only)
  Future<void> assignDriverToRoute(String driverId, Map driverData) async {
    final routeId = widget.routeData['id'];
    final batch = firestore.batch();

    // print(driverData);

    setState(() => _isLoading = true);

    try {
      final driverRef = firestore.collection('users').doc(driverId);

      // Update driver's route info
      batch.update(driverRef, {
        'route_id': routeId,
        'route_name': widget.routeData['name'],
        'is_delivery_assigned': true,
      });

      // Update route with driver info
      final routeRef = firestore.collection('routes').doc(routeId);
      batch.update(routeRef, {
        'driver_info': {
          'driver_id': driverId,
          'name': driverData['name'],
          'phone_no': driverData['phone_no'],
          'vehicle_no': driverData['vehicle_id'],
          'assigned_at': FieldValue.serverTimestamp(),
        },
      });

      await batch.commit();
      // Update local route data and UI state so the assign button disables immediately
      widget.routeData['driver_info'] = {
        'driver_id': driverId,
        'name': driverData['name'],
        'phone_no': driverData['phone_no'],
        'vehicle_id': driverData['vehicle_id'],
        'assigned_at': DateTime.now(),
      };
      setAssignedDriver(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Driver successfully assigned!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error assigning driver: $e")));
      
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Remove (deassign) the driver
  Future<void> deassignDriver(String driverId) async {
    final routeId = widget.routeData['id'];
    try {
      // Update driver to remove route assignment
      await firestore.collection('users').doc(driverId).update({
        'route_id': '',
        'route_name': '',
        'is_delivery_assigned': false,
        'is_active': false,
      });

      // Update route to remove driver info
      await firestore.collection('routes').doc(routeId).update({
        'driver_info': {
          'driver_id': '',
          'name': '',
          'phone_no': '',
          'vehicle_no': '',
          'assigned_at': null,
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Driver deassigned successfully!"),
          backgroundColor: Colors.orange,
        ),
      );
      // Update local route data and UI state so the assign button enables immediately
      widget.routeData['driver_info'] = {
        'driver_id': '',
        'name': '',
        'phone_no': '',
        'vehicle_id': '',
        'assigned_at': null,
      };
      setAssignedDriver(false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deassigning driver: $e")));
    }
  }

  Future<void> reassignDriverToRoute({
    required String oldDriverId,
    required String newDriverId,
    required Map newDriverData,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final routeId = widget.routeData['id'];
    final batch = firestore.batch();

    setState(() => _isLoading = true);

    try {
      final oldDriverRef = firestore.collection('users').doc(oldDriverId);
      final newDriverRef = firestore.collection('users').doc(newDriverId);
      final routeRef = firestore.collection('routes').doc(routeId);

      // Deassign old driver
      batch.update(oldDriverRef, {
        'route_id': '',
        'route_name': '',
        'is_delivery_assigned': false,
        'is_active': false,
      });

      // Assign new driver
      batch.update(newDriverRef, {
        'route_id': routeId,
        'route_name': newDriverData['name'],
        'is_delivery_assigned': true,
      });

      // Update route driver info
      batch.update(routeRef, {
        'driver_info': {
          'driver_id': newDriverId,
          'name': newDriverData['name'],
          'phone_no': newDriverData['phone_no'],
          'vehicle_id': newDriverData['vehicle_id'],
          'assigned_at': FieldValue.serverTimestamp(),
        },
      });

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Driver reassigned successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      setAssignedDriver(true);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error reassigning driver: $e")));
      setAssignedDriver(false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Show driver selection dialog (single selection)
  Future<void> _showDriverSelectionDialog() async {
    final allDrivers = await fetchDrivers();
    String? selectedDriverId;
    Map selectedDriverData = {};

    // ignore: use_build_context_synchronously
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                "Assign Driver (Single Selection)",
                style: TextStyle(color: Colors.tealAccent),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  children: allDrivers.map((doc) {
                    final driver = doc.data() as Map<String, dynamic>;
                    final id = doc.id;

                    return RadioListTile<String>(
                      value: id,
                      groupValue: selectedDriverId,
                      activeColor: Colors.tealAccent,
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(
                        driver['name'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.drive_eta_rounded),
                              const SizedBox(width: 15),
                              Text(
                                driver['vehicle_id'] ?? '',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.phone),
                              const SizedBox(width: 15),
                              Text(
                                driver['phone_no'] ?? '',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onChanged: (String? value) {
                        selectedDriverData = driver;
                        setDialogState(() {
                          selectedDriverId = value;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                  ),
                  onPressed: selectedDriverId != null
                      ? () async {
                          Navigator.pop(context);

                          // if (widget.routeData['driver_info']['driver_id'] !=
                          //         '' &&
                          //     widget.routeData['driver_info']['driver_id'] !=
                          //         null) {
                          //   await reassignDriverToRoute(
                          //     oldDriverId:
                          //         widget.routeData['driver_info']['driver_id'],
                          //     newDriverId: selectedDriverId!,
                          //     newDriverData: selectedDriverData,
                          //   );
                          // } else {
                            await assignDriverToRoute(
                              selectedDriverId!,
                              selectedDriverData,
                            );
                          // }

                          // {
                          //   await deassignDriver(widget.routeData['driver_info']['driver_id']);
                          // }
                          // await assignDriverToRoute(
                          //   selectedDriverId!,
                          //   selectedDriverData,
                          // );
                        }
                      : null,
                  child: const Text(
                    "Assign",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
  final routeData = widget.routeData;
  // final driver = routeData['driver_info'] ?? {};
  final routeId = routeData['id'];

  final driverId = (routeData['driver_info'] ?? {})['driver_id'] ?? '';
  final bool isDriverAssigned = driverId.toString().isNotEmpty || _isDriverAssigned;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
        backgroundColor: Colors.black,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: CircularProgressIndicator(color: Colors.tealAccent),
              ),
            )
          else
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.tealAccent),
                  tooltip: 'Update Route',
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UpdateRouteScreen(routeData: widget.routeData),
                      ),
                    );
                    if (result == true) {
                      // Refresh the page or show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Route updated successfully!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: IconButton(
                    icon: Icon(
                      Icons.person_add,
                      color: isDriverAssigned ? Colors.grey : Colors.tealAccent,
                    ),
                    tooltip: "Assign to Driver",
                    onPressed: isDriverAssigned ? null : _showDriverSelectionDialog,
                  ),
                ),
              ],
            ),
        ],
      ),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Route Information'),
            const SizedBox(height: 10),
            _buildInfoCard([
              _buildInfoRow('Route Name', routeData['name']),
              _buildInfoRow('Route ID', routeData['id']),
              _buildInfoRow('Start Location', routeData['start']),
              _buildInfoRow('End Location', routeData['end']),
              _buildInfoRow('Total Distance', '${routeData['distance_km']} km'),
              _buildInfoRow(
                'Expected Duration',
                '${routeData['expected_time']} hrs',
              ),
            ]),

            const SizedBox(height: 20),

            _buildSectionTitle('Assigned Driver'),
            const SizedBox(height: 10),

            FutureBuilder<Map<String, dynamic>?>(
              future: getAssignedDriver(routeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
                  );
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text(
                    'No driver assigned yet.',
                    style: TextStyle(color: Colors.white70),
                  );
                }

                final driverData = snapshot.data!;

                return Card(
                  color: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      driverData['name'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.drive_eta_rounded),
                            const SizedBox(width: 15),
                            Text(
                              driverData['vehicle_id'] ?? '',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone),
                            const SizedBox(width: 15),
                            Text(
                              driverData['phone_no'] ?? '',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => deassignDriver(driverData['id'])
                        ,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            _buildSectionTitle('Checkpoints'),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchCheckpoints(routeData['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final checkpoints = snapshot.data ?? [];
                if (checkpoints.isEmpty) {
                  return const Text(
                    "No checkpoints found.",
                    style: TextStyle(color: Colors.white70),
                  );
                }
                return _buildCheckpointsGrid(checkpoints);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 UI helpers
  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.tealAccent,
    ),
  );

  Widget _buildInfoCard(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[850],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _buildInfoRow(String title, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$title:", style: const TextStyle(color: Colors.white70)),
        Flexible(
          child: SelectableText(
            value?.toString() ?? '—',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildCheckpointsGrid(List checkpoints) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: checkpoints.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
    ),
    itemBuilder: (context, index) {
      final cp = checkpoints[index];
      final reached = cp['status'] == 'Reached';

      return Card(
        color: Colors.teal.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cp['name'] ?? 'Checkpoint ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Status: ${cp['status']}',
                style: TextStyle(
                  color: reached ? Colors.greenAccent : Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 3),
              if (cp['location'] != null)
                Text(
                  'Location: ${cp['location'].latitude}, ${cp['location'].longitude}',
                  style: const TextStyle(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 3),
              if (reached && cp['time_reached'] != null)
                Text(
                  'Time Reached: ${cp['time_reached'].toDate()}',
                  style: const TextStyle(color: Colors.white70),
                ),
            ],
          ),
        ),
      );
    },
  );
}
