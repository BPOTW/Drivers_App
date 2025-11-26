import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final String selected;
  final Function(String) onSelect;

  const Sidebar({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    // final items = ['Users', 'Routes', 'Tracking', 'Logs'];
    final items = ['Users', 'Routes', 'Tracking'];
    return Container(
      width: 220,
      color: Colors.black.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DrawerHeader(
            child: Center(
              child: Text(
                'Admin Panel',
                style: TextStyle(fontSize: 20, color: Colors.tealAccent),
              ),
            ),
          ),
          ...items.map((item) {
            final isActive = item == selected;
            return ListTile(
              title: Text(
                item,
                style: TextStyle(
                  color: isActive ? Colors.tealAccent : Colors.white70,
                ),
              ),
              onTap: () => onSelect(item),
            );
          }).toList(),
        ],
      ),
    );
  }
}
