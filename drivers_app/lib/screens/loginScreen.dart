import 'package:drivers_app/screens/dashboardScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _keyController = TextEditingController();
  
  bool _isLoading = false;
  String userId = "";
  String storedUserKey = "";

  @override
  void initState() {
    checkIfLogedIn();
    super.initState();
  }

  void checkIfLogedIn() async {
    final prefs = await SharedPreferences.getInstance();
    // prefs.remove("loginKey");
    String loginKey = prefs.getString('loginKey') ?? "";

    if(loginKey.isNotEmpty){
      setState(() => _isLoading = true);
      Map data = await getKeyFromDatabase(loginKey);
      if(data.isNotEmpty){
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LocationLogScreen()),
      );
      }else{
        return;
      }
    }else{
      return;
    }
    setState(() => _isLoading = false);
  }

  Future getKeyFromDatabase(enteredKey) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('login_key', isEqualTo: enteredKey)
        .where('key_active', isEqualTo: true)
        .limit(1)
        .get();

    Map userData = query.docs.first.data();
    userId = query.docs.first.id;
    return userData;
  }

  void saveUserData(loginKey) async {
    final storage = await SharedPreferences.getInstance();
    await storage.setString('userId',  userId);
    await storage.setString('loginKey', loginKey);
  }

  void _login() async {
    if (_keyController.text.trim().isEmpty) {
      _showError("Please enter your access key.");
      return;
    }

    setState(() => _isLoading = true);
    // await Future.delayed(const Duration(seconds: 1)); // simulate network check

    Map data = await getKeyFromDatabase(_keyController.text.trim());

    if (_keyController.text.trim() == data["login_key"]) {
      if (!mounted) return;
      print("Success");
      saveUserData(data['login_key']);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LocationLogScreen()),
      );
    } else {
      _showError("Invalid key. Try again.");
    }

    setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  checkIfLogedIn();
                },
                child: Icon(Icons.lock, size: 80, color: Colors.tealAccent)),
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.tealAccent),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
