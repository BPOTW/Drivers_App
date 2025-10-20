import 'package:admin_app/components/log_data_to_server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: must_be_immutable
class DriverDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> driverData;
  DriverDetailsScreen({super.key, required this.driverData});

  Future<List<Map<String, dynamic>>> fetchCheckpoints(String routeId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('routes')
          .doc(routeId)
          .collection('checkpoints')
          .get();
      // print(snapshot.docs.first.data());
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      await logEvent(
        event: 'App Error',
        message: 'Error fetching checkpoints data Page:user_details_page.',
        type: 'ERROR',
      );
      return [];
    }
  }

  Future<Map> getLocation() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await FirebaseFirestore.instance
              .collection('live_locations')
              .doc(driverData['id'])
              .get();

      if (docSnapshot.exists) {
        Map data = {
          'latitude': docSnapshot.data()!['location'].latitude,
          'longitude': docSnapshot.data()!['location'].longitude,
          'last_updated': docSnapshot.data()!['last_updated'].toDate(),
        };
        return data;
      } else {
        print("Document not found");
        return {};
      }
    } catch (e) {
      await logEvent(
        event: 'App Error',
        message: 'Error getting location data from server Page:user_details_page.',
        type: 'ERROR',
      );
      print("Error fetching document: $e");
      return {};
    }
  }

  int checkpointsLength = 0;

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.tealAccent),
      ),
    );
  }

  void hideLoadingDialog(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDeliveryAssigned = driverData['is_delivery_assigned'] ?? false;
    final double deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Details'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: isDeliveryAssigned ? 650 : deviceWidth * 0.97,
                  child: Column(
                    children: [
                      _buildSectionTitle('Driver Information'),
                      const SizedBox(height: 10),
                      _buildInfoCard([
                        _buildInfoRow('Name', driverData['name']),
                        _buildInfoRow('Phone', driverData['phone_no']),
                        _buildInfoRow('Status', driverData['status']),
                        _buildInfoRow('Vehicle No.', driverData['vehicle_id']),
                        _buildInfoRow('Driver ID', driverData['id']),
                      ]),
                    ],
                  ),
                ),
                isDeliveryAssigned
                    ? SizedBox(
                        width: 650,
                        child: Column(
                          children: [
                            _buildSectionTitle('Dealer Information'),
                            const SizedBox(height: 10),
                            _buildInfoCard([
                              _buildInfoRow(
                                'Dealer Name',
                                driverData['dealer_info']['name'],
                              ),
                              _buildInfoRow(
                                'Dealer Phone No.',
                                driverData['dealer_info']['phone_no'],
                              ),
                              _buildInfoRow("", ""),
                              _buildInfoRow("", ""),
                            ]),
                          ],
                        ),
                      )
                    : SizedBox(),
              ],
            ),

            const SizedBox(height: 20),

            // If driver is on delivery
            if (isDeliveryAssigned) ...[
              _buildSectionTitle('Delivery Details'),
              const SizedBox(height: 10),
              _buildInfoCard([
                _buildInfoRow('Route', driverData['route_name']),
                _buildInfoRow('Route Id', driverData['route_id']),
                _buildInfoRow(
                  'Total Checkpoints',
                  checkpointsLength.toString(),
                ),
              ]),

              const SizedBox(height: 15),

              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    showLoadingDialog(context);
                    Map locationData = await getLocation();
                    hideLoadingDialog(context);
                    showDialog(
                      context: context,
                      builder: (context) => LocationDialog(data: locationData),
                    );
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text(
                    "Get Driver's Current Location",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    iconColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              _buildSectionTitle('Checkpoints'),
              const SizedBox(height: 12),

              _buildCheckpointsGrid(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.tealAccent,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
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
  }

  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$title", style: const TextStyle(color: Colors.white70)),
          SelectableText(
            value ?? '—',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckpointsGrid() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchCheckpoints(driverData['route_id']),
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
          return const Center(
            child: Text(
              "No checkpoints found.",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        checkpointsLength = checkpoints.length;

        return LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 5;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: checkpoints.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                // final checkpoint = checkpoints[index];
                final bool reached = checkpoints[index]['status'] == 'Reached';
                final lat = checkpoints[index]['location'].latitude;
                final long = checkpoints[index]['location'].longitude;

                return Card(
                  color: Colors.teal.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          checkpoints[index]['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status: ${checkpoints[index]['has_reached'] ? 'Reached' : 'On The Way'}',
                                style: TextStyle(
                                  color: reached
                                      ? Colors.greenAccent
                                      : Colors.orangeAccent,
                                ),
                              ),
                              Text(
                                'Location: ${lat},${long}',
                                style: const TextStyle(color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (reached)
                                Text(
                                  'Time: ${checkpoints[index]['expected_time'] / 60} Hour',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 1),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: implement location fetch logic
                          },
                          icon: const Icon(Icons.location_on),
                          label: const Text(
                            "See Location",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            iconColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class LocationDialog extends StatelessWidget {
  final Map data;

  const LocationDialog({super.key, required this.data});

  /// Opens location in Google Maps
  Future<void> _openInGoogleMaps() async {
    final url =
        "https://www.google.com/maps/search/?api=1&query=${data['latitude']},${data['longitude']}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      await logEvent(
        event: 'App Error',
        message: 'Failed to open location Page:user_details_page.',
        type: 'ERROR',
      );
      throw 'Could not open Google Maps';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text(
        "Driver Location",
        style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Last Updated: ${data['last_updated']}",
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            "Latitude: ${data['latitude'].toStringAsFixed(5)}",
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            "Longitude: ${data['longitude'].toStringAsFixed(5)}",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openInGoogleMaps,
            icon: const Icon(Icons.map),
            label: const Text("Open in Google Maps"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent.withOpacity(0.2),
              foregroundColor: Colors.tealAccent,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Close",
            style: TextStyle(color: Colors.tealAccent),
          ),
        ),
      ],
    );
  }
}
