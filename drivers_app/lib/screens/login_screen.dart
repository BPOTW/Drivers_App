import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../widgets/loading_indicator.dart';
import '../utils/app_utils.dart';
import '../constants/app_constants.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _keyController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    await LocationService.requestLocationPermission();
  }

  Future<void> _checkIfLoggedIn() async {
    try {
      final loginKey = await StorageService.getLoginKey();
      
      if (loginKey.isNotEmpty) {
        setState(() => _isLoading = true);
        
        final user = await FirebaseService.getUserByLoginKey(loginKey);
        
        if (user!.keyActive && mounted) {
          await StorageService.saveUserId(user.id);
          _navigateToDashboard();
        } else if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error checking login status: $error');
    }
  }

  Future<void> _login() async {
    if (_keyController.text.trim().isEmpty) {
      AppUtils.showErrorSnackBar(context, "Please enter your access key.");
      return;
    }

    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      final user = await FirebaseService.getUserByLoginKey(_keyController.text.trim());
      print("User is $user");
      if (user != null && user.keyActive && mounted) {
        await StorageService.saveUserId(user.id);
        await StorageService.saveLoginKey(user.loginKey);
        _navigateToDashboard();
      } else if (mounted) {
        if(!user!.keyActive){
          AppUtils.showErrorSnackBar(context, "Login blocked by Admin.");
        }else{
          AppUtils.showErrorSnackBar(context, "Invalid key. Try again.");
        }
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showErrorSnackBar(context, "Login failed. Please try again.");
      }
      print('Login error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDashboard() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: "Checking login status..."),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                size: 80,
                color: Colors.tealAccent,
              ),
              const SizedBox(height: 30),
              const Text(
                "Driver Login",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Enter your access key to continue",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _keyController,
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[850],
                  hintText: 'Enter Access Key',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.tealAccent),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "LOGIN",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
