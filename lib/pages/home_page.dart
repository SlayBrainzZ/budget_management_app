import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_management_app/auth.dart';

class HomePage extends StatelessWidget{
  HomePage({super.key});

  final User? user = Auth().currentUser; // Fetches the current user if logged in

  Future<void> signOut() async {
    await Auth().signOut(); // Calls signOut() method in Auth class to log the user out
  }

  Widget _title(){
    return const Text('Authentication'); // Displays title
  }

  Widget _userId(){
    return Text(user?.email ?? 'User email'); // Displays the user's email or placeholder if null
  }

  Widget _signOutButton(){
    return ElevatedButton(
      onPressed: signOut, // Signs out the user when pressed
      child: const Text('Sign Out'),
    );
  }

  @override
  Widget build(BuildContext context){ // Builds the UI layout of the home screen using a Scaffold with centered content in a Column.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: const Text(
          'MoneyGuard',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _userId(),
            _signOutButton()
          ],
        ),
      ),
    );
  }

}