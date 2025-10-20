import 'package:admin_app/screens/create_new_user_screen.dart';
import 'package:admin_app/screens/user_details_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _usersScreen();
}

class _usersScreen extends State<UsersScreen> {

  List<bool> toggleButton = [];

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      // print(snapshot.docs);
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<void> updateUserStatus(String id, bool isActive) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(id).update({
        'key_active': isActive,
        'status': isActive ? "Active" : "Inactive",
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User status updated to ${isActive ? 'Active' : 'Inactive'}'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {}); // refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header and Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Users",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateUserScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  "Create User",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  iconColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Grid Cards
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchUsers(), // 👈 Calling the function here
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }
          // print(users);

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              toggleButton.add(user['key_active']);
              // user.
              // print(user.);
              return Card(
                      color: Colors.teal.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.teal,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Role: ${user['role']}',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            user['route_name'] != '' && user['route_name'] != null ? Text(
                              'Assigned Route: ${user['route_name']}',
                              style: TextStyle(color: Colors.white70),
                            ) : SizedBox(),
                            const SizedBox(height: 10),
                            user['route_id'] != '' && user['route_id'] != null ? SelectableText(
                              'Route Id: ${user['route_id']}',

                              style: TextStyle(color: Colors.white70),
                            ) : SizedBox(),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DriverDetailsScreen(
                                          driverData: user
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.info_outline),
                                  label: const Text(
                                    "Details",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade700,
                                    iconColor: Colors.white,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Switch(
                                      value: toggleButton[index],
                                      activeThumbColor: Colors.green,
                                      inactiveThumbColor: Colors.red,
                                      onChanged: (bool value) {
                                        toggleButton[index] = value;
                                        updateUserStatus(user['id'], toggleButton[index]);
                                      },
                                    ),
                                    IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.delete),
                                      color: Colors.redAccent,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
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
