// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class RouteDetailsScreen extends StatelessWidget {
//   final Map<String, dynamic> routeData;

//   const RouteDetailsScreen({super.key, required this.routeData});

//   @override
//   Widget build(BuildContext context) {
//     final driver = routeData['driver_info'] ?? {};
//     // final checkpoints = [];

//     Future<List<Map<String, dynamic>>> fetchCheckpoints(String routeId) async {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('routes')
//           .doc(routeId)
//           .collection('checkpoints')
//           .get();
//       // print(snapshot.docs.first.data());
//       return snapshot.docs.map((doc) => doc.data()).toList();
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Route Details'),
//         backgroundColor: Colors.black,
//       ),
//       backgroundColor: Colors.grey[900],
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Route info section
//             _buildSectionTitle('Route Information'),
//             const SizedBox(height: 10),
//             _buildInfoCard([
//               _buildInfoRow('Route Name', routeData['name']),
//               _buildInfoRow('Route ID', routeData['id']),
//               _buildInfoRow('Start Location', routeData['start']),
//               _buildInfoRow('End Location', routeData['end']),
//               _buildInfoRow('Total Distance', '${routeData['distance_km']} km'),
//               _buildInfoRow(
//                 'Expected Duration',
//                 '${routeData['expected_time']} hrs',
//               ),
//             ]),

//             const SizedBox(height: 20),

//             // Assigned Driver
//             _buildSectionTitle('Assigned Driver'),
//             const SizedBox(height: 10),
//             _buildInfoCard([
//               _buildInfoRow('Name', driver['name']),
//               _buildInfoRow('Phone', driver['phone_no']),
//               _buildInfoRow('Vehicle No.', driver['vehicle_no']),
//               _buildInfoRow('Driver ID', driver['id']),
//             ]),

//             const SizedBox(height: 20),

//             // Assigned Dealer
//             _buildSectionTitle('Assigned Dealer'),
//             const SizedBox(height: 10),
//             _buildInfoCard([
//               _buildInfoRow('Name', routeData['dealer_name']),
//               _buildInfoRow('Phone', routeData['dealer_phone']),
//             ]),

//             const SizedBox(height: 25),

//             // Checkpoints Section
//             _buildSectionTitle('Checkpoints'),
//             const SizedBox(height: 12),
//             FutureBuilder<List<Map<String, dynamic>>>(
//               future: fetchCheckpoints(routeData['id']),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(
//                     child: CircularProgressIndicator(color: Colors.tealAccent),
//                   );
//                 }

//                 if (snapshot.hasError) {
//                   return Center(child: Text("Error: ${snapshot.error}"));
//                 }

//                 final checkpoints = snapshot.data ?? [];
//                 // print(checkpoints);

//                 if (checkpoints.isEmpty) {
//                   return const Center(
//                     child: Text(
//                       "No checkpoints found.",
//                       style: TextStyle(color: Colors.white70),
//                     ),
//                   );
//                 }
//                 return _buildCheckpointsGrid(checkpoints);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         fontSize: 20,
//         fontWeight: FontWeight.bold,
//         color: Colors.tealAccent,
//       ),
//     );
//   }

//   Widget _buildInfoCard(List<Widget> children) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey[850],
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: children,
//       ),
//     );
//   }

//   Widget _buildInfoRow(String title, dynamic value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text("$title:", style: const TextStyle(color: Colors.white70)),
//           Flexible(
//             child: SelectableText(
//               value?.toString() ?? '—',
//               textAlign: TextAlign.right,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCheckpointsGrid(List checkpoints) {
//     if (checkpoints.isEmpty) {
//       return const Center(
//         child: Text(
//           "No checkpoints available for this route.",
//           style: TextStyle(color: Colors.white70),
//         ),
//       );
//     }

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         int crossAxisCount = 5;

//         return GridView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemCount: checkpoints.length,
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: crossAxisCount,
//             mainAxisSpacing: 16,
//             crossAxisSpacing: 16,
//             childAspectRatio: 1.2,
//           ),
//           itemBuilder: (context, index) {
//             final checkpoint = checkpoints[index];
//             final bool reached = checkpoint['status'] == 'Reached';

//             return Card(
//               color: Colors.teal.withOpacity(0.15),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(14),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       checkpoint['name'] ?? 'Checkpoint ${index + 1}',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       'Status: ${checkpoint['status']}',
//                       style: TextStyle(
//                         color: reached
//                             ? Colors.greenAccent
//                             : Colors.orangeAccent,
//                       ),
//                     ),
//                     SizedBox(height: 3,),
//                     Text(
//                       'Location: ${checkpoint['location'].latitude},${checkpoint['location'].longitude}',
//                       style: const TextStyle(color: Colors.white70),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     SizedBox(height: 3,),
//                     if (reached)
//                       Text(
//                         'Time Reached: ${checkpoint['time_reached'].toDate()}',
//                         style: const TextStyle(color: Colors.white70),
//                       ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RouteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> routeData;

  const RouteDetailsScreen({super.key, required this.routeData});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  late FirebaseFirestore firestore;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    firestore = FirebaseFirestore.instance;
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

  /// 🔹 Fetch all drivers (for assigning)
  Future<List<QueryDocumentSnapshot>> fetchDrivers() async {
    final snapshot = await firestore.collection('users').get();
    return snapshot.docs;
  }

  /// 🔹 Fetch assigned drivers for the current route
  Stream<QuerySnapshot> assignedDriversStream() {
    return firestore
        .collection('routes')
        .doc(widget.routeData['id'])
        .collection('assigned_drivers')
        .snapshots();
  }

  /// 🔹 Assign route to selected driver(s)
  Future<void> assignDriversToRoute(List<String> driverIds) async {
    final routeId = widget.routeData['id'];
    final batch = firestore.batch();

    setState(() => _isLoading = true);

    try {
      for (var driverId in driverIds) {
        final driverRef = firestore.collection('users').doc(driverId);
        final routeRef =
            firestore.collection('routes').doc(routeId).collection('assigned_drivers').doc(driverId);

        // Update driver’s route info
        batch.update(driverRef, {
          'route_id': routeId,
          'route_name': widget.routeData['name'],
        });

        // Add to route’s assigned list
        batch.set(routeRef, {
          'driver_id': driverId,
          'assigned_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Driver(s) successfully assigned!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error assigning driver(s): $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Remove (deassign) a driver
  Future<void> deassignDriver(String driverId) async {
    final routeId = widget.routeData['id'];
    try {
      await firestore
          .collection('routes')
          .doc(routeId)
          .collection('assigned_drivers')
          .doc(driverId)
          .delete();

      await firestore.collection('users').doc(driverId).update({
        'route_id': '',
        'route_name': '',
        'is_delivery_assigned': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Driver deassigned successfully!"),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deassigning driver: $e")),
      );
    }
  }

  /// 🔹 Show driver selection dialog
  Future<void> _showDriverSelectionDialog() async {
    final allDrivers = await fetchDrivers();
    final selectedDrivers = <String>{};

    // ignore: use_build_context_synchronously
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Assign Drivers",
              style: TextStyle(color: Colors.tealAccent),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                children: allDrivers.map((doc) {
                  final driver = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  final isSelected = selectedDrivers.contains(id);

                  return CheckboxListTile(
                    value: isSelected,
                    activeColor: Colors.tealAccent,
                    contentPadding: EdgeInsets.all(12),
                            title: Text(driver['name'] ?? 'Unknown',
                                style: TextStyle(color: Colors.tealAccent, fontSize: 20, fontWeight: FontWeight.w400)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8,),
                                Row(
                                  children: [
                                    Icon(Icons.drive_eta_rounded),
                                    SizedBox(width: 15,),
                                    Text(driver['vehicle_id'] ?? '',
                                style: const TextStyle(color: Colors.white70)),
                                  ],
                                ),
                                SizedBox(height: 8,),
                               Row(
                                  children: [
                                    Icon(Icons.phone),
                                    SizedBox(width: 15,),
                                    Text(driver['phone_no'] ?? '',
                                style: const TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ],
                            ),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedDrivers.add(id);
                        } else {
                          selectedDrivers.remove(id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent),
                onPressed: () async {
                  Navigator.pop(context);
                  await assignDriversToRoute(selectedDrivers.toList());
                },
                child: const Text("Assign", style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeData = widget.routeData;
    // final driver = routeData['driver_info'] ?? {};

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
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                icon: const Icon(Icons.person_add, color: Colors.tealAccent),
                tooltip: "Assign to Driver(s)",
                onPressed: _showDriverSelectionDialog,
              ),
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
              _buildInfoRow('Expected Duration', '${routeData['expected_time']} hrs'),
            ]),

            const SizedBox(height: 20),

            _buildSectionTitle('Assigned Drivers'),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: assignedDriversStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                }

                final assigned = snapshot.data?.docs ?? [];
                if (assigned.isEmpty) {
                  return const Text(
                    'No drivers assigned yet.',
                    style: TextStyle(color: Colors.white70),
                  );
                }

                return Column(
                  children: assigned.map((doc) {
                    final driverId = doc.id;
                    return FutureBuilder<DocumentSnapshot>(
                      future: firestore.collection('users').doc(driverId).get(),
                      builder: (context, driverSnap) {
                        if (!driverSnap.hasData) {
                          return const SizedBox.shrink();
                        }
                        final driverData = driverSnap.data!.data() as Map<String, dynamic>;

                        return Card(
                          color: Colors.grey[850],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(12),
                            title: Text(driverData['name'] ?? 'Unknown',
                                style: TextStyle(color: Colors.tealAccent, fontSize: 20, fontWeight: FontWeight.w400)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8,),
                                Row(
                                  children: [
                                    Icon(Icons.drive_eta_rounded),
                                    SizedBox(width: 15,),
                                    Text(driverData['vehicle_id'] ?? '',
                                style: const TextStyle(color: Colors.white70)),
                                  ],
                                ),
                                SizedBox(height: 8,),
                               Row(
                                  children: [
                                    Icon(Icons.phone),
                                    SizedBox(width: 15,),
                                    Text(driverData['phone_no'] ?? '',
                                style: const TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => deassignDriver(driverId),
                            ),

                          ),
                        );
                      },
                    );
                  }).toList(),
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
                      child: CircularProgressIndicator(color: Colors.tealAccent));
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cp['name'] ?? 'Checkpoint ${index + 1}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 6),
                  Text('Status: ${cp['status']}',
                      style: TextStyle(
                          color: reached
                              ? Colors.greenAccent
                              : Colors.orangeAccent)),
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
