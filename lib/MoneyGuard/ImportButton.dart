import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:budget_management_app/backend/firestore_service.dart';

class ImportButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.red, // Textfarbe
        backgroundColor: Colors.white, // Hintergrundfarbe
        side: BorderSide(color: Colors.red, width: 2), // Roter Umriss
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Abgerundete Ecken
        ),
      ),
      onPressed: () {
        _showImportDialog(context);
      },
      child: Text(
        'Import Transactions',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    String? selectedAccount;
    List<String> accounts = ['Bankkonto 1', 'Bankkonto 2', 'Bankkonto 3'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Import Transactions'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wähle den Bankaccount, dem du deine Transaktionen zuweisen möchtest:',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    hint: Text('Bankaccount wählen'),
                    items: accounts.map((String account) {
                      return DropdownMenuItem<String>(
                        value: account,
                        child: Text(account),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedAccount = value;
                      });
                    },
                  ),
                  if (selectedAccount != null) ...[
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, // Textfarbe
                        backgroundColor: Colors.blue, // Buttonfarbe
                      ),
                      onPressed: () async {
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId != null) {
                          FirestoreService firestoreService = FirestoreService();
                          await firestoreService.importCsvTransactions(userId);
                          Navigator.of(context).pop(); // Schließt den Dialog.
                        } else {
                          print("Fehler: Kein Benutzer angemeldet.");
                        }
                      },
                      child: Text(
                        'Upload CSV File',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Abbrechen'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
