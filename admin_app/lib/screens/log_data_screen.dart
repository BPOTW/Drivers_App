import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.tealAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Server Logs',
          style: TextStyle(
            color: Colors.tealAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('server_events')
            .orderBy('timestamp', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No logs available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index].data() as Map<String, dynamic>;

              final timestamp = (log['timestamp'] as Timestamp?)?.toDate();
              final formattedTime = timestamp != null
                  ? DateFormat('yyyy-MM-dd • hh:mm:ss a').format(timestamp)
                  : 'No timestamp';

              return Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event title and type
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            log['event'] ?? 'Unknown Event',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.tealAccent,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTypeColor(log['type']),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (log['type'] ?? 'INFO').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Message
                      Text(
                        log['message'] ?? 'No message provided.',
                        style: const TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 8),

                      // Metadata / Extra info
                      if (log['metadata'] != null &&
                          (log['metadata'] as Map).isNotEmpty)
                        Text(
                          'Metadata: ${log['metadata'].toString()}',
                          style: const TextStyle(color: Colors.grey),
                        ),

                      const SizedBox(height: 6),

                      // Footer info (time, user)
                      Text(
                        'User: ${log['userId'] ?? 'system'}',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      Text(
                        'Time: $formattedTime',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🔹 Helper to color-code log types
  Color _getTypeColor(String? type) {
    switch (type?.toUpperCase()) {
      case 'ERROR':
        return Colors.redAccent;
      case 'WARNING':
        return Colors.orangeAccent;
      case 'SUCCESS':
        return Colors.greenAccent;
      default:
        return Colors.tealAccent;
    }
  }
}
