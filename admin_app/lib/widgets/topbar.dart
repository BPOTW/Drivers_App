import 'package:admin_app/components/log_data_to_server.dart';
import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final String title;
  const TopBar({super.key, required this.title});

  void addData() async {
    // When new user is created
    await logEvent(
      event: 'User Created',
      message: 'New user registered: ali@example.com',
      userId: 'user_001',
    );

    // When a new route is added
    await logEvent(
      event: 'Route Created',
      message: 'Route from Lahore to Islamabad added.',
      userId: 'admin_002',
      metadata: {'routeId': 'route_789', 'vehicle': 'Truck A'},
    );

    // When an error occurs
    await logEvent(
      event: 'App Error',
      message: 'App crashed during location update.',
      type: 'ERROR',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.black.withOpacity(0.3),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, color: Colors.tealAccent),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.logout, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
