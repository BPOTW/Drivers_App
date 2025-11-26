import 'package:admin_app/components/log_data_to_server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tracking_detail_screen.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  Future<List<Map<String, dynamic>>> fetchLocations() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('live_locations').get();

      // Convert each Firestore doc to Map
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['driver_name'] ?? 'Unknown',
          'route_id': data['route_id'] ?? 'Unassigned',
          'location': data['location'] ?? {},
          'status': data['status'] ?? 'inactive',
          'last_updated': data['last_updated'] ?? 'inactive',
        };
      }).toList();
    } catch (e) {
      await logEvent(
        event: 'App Error',
        message: 'Error fetching location data. Page:tracking_screen',
        type: 'ERROR',
      );
      print('Error fetching drivers: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final crossAxisCount = isMobile ? 1 : 3;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  "Routes",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                
              ],
            ),
          ),

          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchLocations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
            
                final drivers = snapshot.data ?? [];
                if (drivers.isEmpty) {
                  return const Center(child: Text('No drivers found.'));
                }
            
                return GridView.builder(
                  itemCount: drivers.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.9,
                  ),
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    final location = driver['location'];
            
                    String locationText =
                          'https://maps.google.com/?q=${location.latitude},${location.longitude}';
            
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriversLocationScreen(driverData: driver, locationData: location,),
                          ),
                        );
                      },
                      child: Card(
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
                                driver['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.tealAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Driver ID: ${driver['id']}'),
                              Text('Route: ${driver['route_id'] != '' ? driver['route_id'] : "Not Assigned"}'),
                              // Text(
                              //   'Status: ${driver['status']}',
                              //   style: TextStyle(
                              //     color: driver['status'] == 'active'
                              //         ? Colors.greenAccent
                              //         : Colors.redAccent,
                              //   ),
                              // ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.tealAccent),
                                  TextButton(
                                    onPressed: () async {
                                      // You can open the link using url_launcher if needed
                                      launchUrl(Uri.parse(locationText));
                                    },
                                    child: const Text(
                                      "View Location",
                                      style: TextStyle(color: Colors.tealAccent),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
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
