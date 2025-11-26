import 'package:drivers_app/screens/current_order_screen.dart';
import 'package:drivers_app/screens/login_screen.dart';
import 'package:drivers_app/screens/orders_screen.dart';
import 'package:drivers_app/services/firebase_service.dart';
import 'package:flutter/material.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {


 

  Future logOutUser() async {
    final resp = await StorageService.clearUserData();
    print(resp);
    if (resp) {
      _navigateToLogin();
    }else{
      print('error');
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Location Log'),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () {
                logOutUser();
              },
              child: Icon(
                Icons.logout_rounded,
                ),
            ),
          )
        ],
      ),
      body: OrdersScreen()
    );
  }

  }
