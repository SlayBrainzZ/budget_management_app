import 'package:firebase_core/firebase_core.dart';
import 'package:budget_management_app/widget_tree.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized for Firebase

  try {
    if (kIsWeb) { // Only for Web!
      await Firebase.initializeApp(options: const FirebaseOptions(
        apiKey: "AIzaSyBRElGRhjY1HjJqe7Zt-PKLn1YRy9IEkXs",
        authDomain: "budget-management-app-a9b5e.firebaseapp.com",
        projectId: "budget-management-app-a9b5e",
        storageBucket: "budget-management-app-a9b5e.appspot.com",
        messagingSenderId: "528312897299",
        appId: "1:528312897299:web:e19b90d51e49dba62b54e6",
        measurementId: "G-LKZ75WL9T7",
      ));
    } else { // Android or iOS
      await Firebase.initializeApp();
    }
    runApp(const MyApp());
  } catch (e) {
    print("Firebase initialization failed: $e");
    // Optionally, you can show a Snackbar or some UI to indicate the error.
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget Management App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WidgetTree(), // Use WidgetTree for authentication
    );
  }
}