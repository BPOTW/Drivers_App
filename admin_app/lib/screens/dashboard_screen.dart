import 'package:admin_app/screens/log_data_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/topbar.dart';
import 'users_screen.dart';
import 'routes_screen.dart';
import 'tracking_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedPage = 'Users';

  Widget _getSelectedPage() {
    switch (selectedPage) {
      case 'Routes':
        return const RoutesScreen();
      case 'Tracking':
        return const TrackingScreen();
      // case 'Logs':
      //   return const LogsPage();
      default:
        return UsersScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selected: selectedPage,
            onSelect: (value) => setState(() => selectedPage = value),
          ),
          Expanded(
            child: Column(
              children: [
                // TopBar(title: selectedPage),
                Expanded(child: _getSelectedPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
