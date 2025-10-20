import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RouteDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> routeData;

  const RouteDetailsScreen({super.key, required this.routeData});

  @override
  Widget build(BuildContext context) {
    final driver = routeData['driver_info'] ?? {};
    // final checkpoints = [];

    Future<List<Map<String, dynamic>>> fetchCheckpoints(String routeId) async {
      final snapshot = await FirebaseFirestore.instance
          .collection('routes')
          .doc(routeId)
          .collection('checkpoints')
          .get();
      // print(snapshot.docs.first.data());
      return snapshot.docs.map((doc) => doc.data()).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route info section
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

            // Assigned Driver
            _buildSectionTitle('Assigned Driver'),
            const SizedBox(height: 10),
            _buildInfoCard([
              _buildInfoRow('Name', driver['name']),
              _buildInfoRow('Phone', driver['phone_no']),
              _buildInfoRow('Vehicle No.', driver['vehicle_no']),
              _buildInfoRow('Driver ID', driver['id']),
            ]),

            const SizedBox(height: 20),

            // Assigned Dealer
            _buildSectionTitle('Assigned Dealer'),
            const SizedBox(height: 10),
            _buildInfoCard([
              _buildInfoRow('Name', routeData['dealer_name']),
              _buildInfoRow('Phone', routeData['dealer_phone']),
            ]),

            const SizedBox(height: 25),

            // Checkpoints Section
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
                // print(checkpoints);

                if (checkpoints.isEmpty) {
                  return const Center(
                    child: Text(
                      "No checkpoints found.",
                      style: TextStyle(color: Colors.white70),
                    ),
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

  Widget _buildInfoRow(String title, dynamic value) {
    return Padding(
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
  }

  Widget _buildCheckpointsGrid(List checkpoints) {
    if (checkpoints.isEmpty) {
      return const Center(
        child: Text(
          "No checkpoints available for this route.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

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
            final checkpoint = checkpoints[index];
            final bool reached = checkpoint['status'] == 'Reached';

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
                    Text(
                      checkpoint['name'] ?? 'Checkpoint ${index + 1}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Status: ${checkpoint['status']}',
                      style: TextStyle(
                        color: reached
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                      ),
                    ),
                    SizedBox(height: 3,),
                    Text(
                      'Location: ${checkpoint['location'].latitude},${checkpoint['location'].longitude}',
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3,),
                    if (reached)
                      Text(
                        'Time Reached: ${checkpoint['time_reached'].toDate()}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
