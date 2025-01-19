import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_management_app/backend/firestore_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false; // Zustand für den Dark Mode
  bool notificationsEnabled = true; // Zustand für Benachrichtigungen

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _logout() async {
    try {
      await _auth.signOut();
      print("User ausgeloggt");
      // Navigiere zur Login-Seite (ersetze 'LoginPage' mit deiner Login-Seite)
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print("Fehler beim Logout: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout fehlgeschlagen. Bitte erneut versuchen.")),
      );
    }
  }

  void _deleteAccount() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        // First, delete the user document from Firestore
        await FirestoreService().deleteUser(user.uid);

        // Then delete the user from Firebase Authentication
        await user.delete();
        print("Account gelöscht");

        // Navigate to the login screen
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

  void _changeLanguage() {
    // Logik für das Ändern der Sprache
    print("Sprache geändert");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Dark Mode Toggle
            SwitchListTile(
              title: const Text("Dark Mode"),
              subtitle: const Text("Aktivieren Sie den dunklen Modus."),
              value: isDarkMode,
              onChanged: (value) {
                setState(() {
                  isDarkMode = value;
                });
                // Aktualisiere das App-Theme
                print("Dark Mode: $isDarkMode");
              },
            ),

            const Divider(),

            // Notifications Toggle
            SwitchListTile(
              title: const Text("Benachrichtigungen"),
              subtitle: const Text("Aktivieren oder deaktivieren Sie Benachrichtigungen."),
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  notificationsEnabled = value;
                });
                print("Benachrichtigungen: $notificationsEnabled");
              },
            ),

            const Divider(),

            // Sprache ändern
            ListTile(
              title: const Text("Sprache ändern"),
              subtitle: const Text("Aktuelle Sprache: Deutsch"),
              trailing: const Icon(Icons.language),
              onTap: _changeLanguage,
            ),

            const Divider(),

            // Logout Button
            ListTile(
              title: const Text("Ausloggen"),
              trailing: const Icon(Icons.logout),
              onTap: _logout,
            ),

            const Divider(),

            // Account löschen
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
