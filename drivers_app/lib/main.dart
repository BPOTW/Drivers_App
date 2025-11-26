import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DriverLogApp());
}

class DriverLogApp extends StatelessWidget {
  const DriverLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver Location Log',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(AppConstants.backgroundColorValue),
        colorScheme: const ColorScheme.dark(
          primary: Color(AppConstants.primaryColorValue),
          secondary: Color(AppConstants.secondaryColorValue),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
