import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false; // Zustand für den Dark Mode
  bool notificationsEnabled = true; // Zustand für Benachrichtigungen

  void _logout() {
    // Logout-Logik hier einfügen
    print("User ausgeloggt");
    // Zur Login-Seite navigieren (falls implementiert)
  }

  void _deleteAccount() {
    // Account-Löschlogik hier einfügen
    print("Account gelöscht");
    // Eventuell zur Login-Seite navigieren
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
