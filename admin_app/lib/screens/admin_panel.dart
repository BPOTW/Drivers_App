import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/topbar.dart';
import 'users_screen.dart';
import 'routes_screen.dart';
import 'tracking_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  String selectedPage = 'Users';

  Widget _getSelectedPage() {
    switch (selectedPage) {
      case 'Routes':
        return const RoutesScreen();
      case 'Tracking':
        return const TrackingScreen();
      default:
        return UsersScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      drawer: isMobile
          ? Drawer(
              child: Sidebar(
                selected: selectedPage,
                onSelect: (value) {
                  setState(() => selectedPage = value);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      appBar: isMobile
          ? AppBar(
              title: Text(selectedPage),
              backgroundColor: Colors.black.withOpacity(0.3),
              actions: [
                IconButton(
                    icon: const Icon(Icons.notifications_none), onPressed: () {}),
                IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
              ],
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(
              selected: selectedPage,
              onSelect: (value) => setState(() => selectedPage = value),
            ),
          Expanded(
            child: Column(
              children: [
                if (!isMobile) TopBar(title: selectedPage),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _getSelectedPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
