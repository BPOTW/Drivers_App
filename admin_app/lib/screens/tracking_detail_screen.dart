import 'package:admin_app/components/log_data_to_server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DriversLocationScreen extends StatefulWidget {
  final Map<String, dynamic> driverData;
  final GeoPoint locationData;

  const DriversLocationScreen({super.key, required this.driverData, required this.locationData});

  @override
  State<DriversLocationScreen> createState() => _DriversLocationScreenState();
}

class _DriversLocationScreenState extends State<DriversLocationScreen> {
  Map<String, dynamic>? routeData;
  List<Map<String, dynamic>> checkpoints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDriverDetails();
  }

  Future<void> openLocation() async {
    final url =
        "https://www.google.com/maps/search/?api=1&query=${widget.locationData.latitude},${widget.locationData.longitude}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      await logEvent(
        event: 'App Error',
        message: 'Error opening location Page:tracking_detail_screen.',
        type: 'ERROR',
      );
      throw 'Could not open Google Maps';
    }
  }

  Future<void> _loadDriverDetails() async {
    // print(widget.driverData);
    try {
      final routeId = widget.driverData['route_id'];

      if (routeId == null || routeId.isEmpty) {
        setState(() => isLoading = false);
        return;
      }
      // Fetch route data
      final routeDoc = await FirebaseFirestore.instance
          .collection('routes')
          .doc(routeId)
          .get();

      if (!routeDoc.exists) {
        setState(() => isLoading = false);
        return;
      }

      routeData = routeDoc.data()!;
      print(routeData);

      // Fetch checkpoints inside route subcollection
      final checkpointsSnapshot = await FirebaseFirestore.instance
          .collection('routes')
          .doc(routeId)
          .collection('checkpoints')
          .orderBy('order')
          .get();

      checkpoints = checkpointsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'],
          'status': data['status'],
          'location': data['location'],
          'expected_time': data['expected_time'],
          'time_reached': data['time_reached'] != null
              ? (data['time_reached'] as Timestamp).toDate().toString()
              : '-',
        };
      }).toList();
    } catch (e) {
      await logEvent(
        event: 'App Error',
        message: 'Error fetching driver details Page:tracking_detail_screen.',
        type: 'ERROR',
      );
      print('Error loading driver details: $e');
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.driverData['name']),
        backgroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 160,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              widget.driverData['name'],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.tealAccent,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Driver ID: ${widget.driverData['id']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Assigned Route: ${routeData?['name'] ?? 'None'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            TextButton(
                              onPressed: () {
                                openLocation();
                              },
                              child: const Text(
                                "View Current Location",
                                style: TextStyle(color: Colors.tealAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Checkpoints",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.tealAccent,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (checkpoints.isEmpty)
                    const Text(
                      "No checkpoints found.",
                      style: TextStyle(color: Colors.white70),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: checkpoints.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.7,
                          ),
                      itemBuilder: (context, index) {
                        final cp = checkpoints[index];
                        return Card(
                          color: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cp['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.tealAccent,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Status: ${cp['status']}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Time: ${cp['time_reached']}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.tealAccent,
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Open Google Maps link
                                      },
                                      child: const Text(
                                        "View",
                                        style: TextStyle(
                                          color: Colors.tealAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
