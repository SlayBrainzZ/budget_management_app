import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:provider/provider.dart';
import 'themeProvider.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _logout() async {
    try {
      await _auth.signOut();
      print("User ausgeloggt");

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      print("Fehler beim Logout: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logout fehlgeschlagen. Bitte erneut versuchen.")),
        );
      }
    }
  }


  void _deleteAccount() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        await FirestoreService().deleteUser(user.uid);

        await user.delete();
        print("Account gelöscht");

        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        print("Kein eingeloggter Nutzer gefunden.");
      }
    } catch (e) {
      print("Fehler beim Löschen des Accounts: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account-Löschung fehlgeschlagen. Bitte erneut versuchen.")),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [

            SwitchListTile(
              title: const Text("Dark Mode"),
              subtitle: const Text("Aktivieren Sie den dunklen Modus."),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
            ),

            const Divider(),

            ListTile(
              title: const Text("Ausloggen"),
              trailing: const Icon(Icons.logout),
              onTap: _logout,
            ),

            const Divider(),

            ListTile(
              title: const Text(
                "Account löschen",
                style: TextStyle(color: Colors.red),
              ),
              trailing: const Icon(Icons.delete, color: Colors.red),
              onTap: _deleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}
