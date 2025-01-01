import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:budget_management_app/backend/BankAccount.dart';

class ImportButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.red[300], // Textfarbe
        backgroundColor: Colors.white, // Hintergrundfarbe
        side: BorderSide(color: Colors.red[300]!, width: 2), // Roter Umriss
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<BankAccount>>(
          future: _fetchUserBankAccounts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return AlertDialog(
                title: Text('Fehler'),
                content: Text('Fehler beim Laden der Bankkonten.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Schließen'),
                  ),
                ],
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return AlertDialog(
                title: Text('Keine Konten gefunden'),
                content: Text('Es wurden keine Bankkonten gefunden.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Schließen'),
                  ),
                ],
              );
            } else {
              return _buildBankAccountDialog(context, snapshot.data!);
            }
          },
        );
      },
    );
  }

  Future<List<BankAccount>> _fetchUserBankAccounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kein Benutzer angemeldet.');
    final firestoreService = FirestoreService();
    return await firestoreService.getUserBankAccounts(user.uid);
  }

  Widget _buildBankAccountDialog(
      BuildContext context, List<BankAccount> accounts) {
    String? selectedAccount;

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
                value: selectedAccount,
                items: accounts.map((account) {
                  final icon = account.accountType == "Bargeld"
                      ? Icons.attach_money
                      : Icons.account_balance;
                  return DropdownMenuItem<String>(
                    value: account.id,
                    child: Row(
                      children: [
                        Icon(icon, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(account.accountName ?? 'Unbenanntes Konto'),
                      ],
                    ),
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
  }
}


/*

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:budget_management_app/backend/BankAccount.dart';

class ImportButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.red[300], // Textfarbe
        backgroundColor: Colors.white, // Hintergrundfarbe
        side: BorderSide(color: Colors.red[300]!, width: 2), // Roter Umriss
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<BankAccount>>(
          future: _fetchUserBankAccounts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return AlertDialog(
                title: Text('Fehler'),
                content: Text('Fehler beim Laden der Bankkonten.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Schließen'),
                  ),
                ],
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return AlertDialog(
                title: Text('Keine Konten gefunden'),
                content: Text('Es wurden keine Bankkonten gefunden.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Schließen'),
                  ),
                ],
              );
            } else {
              return _buildBankAccountDialog(context, snapshot.data!);
            }
          },
        );
      },
    );
  }

  Future<List<BankAccount>> _fetchUserBankAccounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kein Benutzer angemeldet.');
    final firestoreService = FirestoreService();
    return await firestoreService.getUserBankAccounts(user.uid);
  }

  Widget _buildBankAccountDialog(
      BuildContext context, List<BankAccount> accounts) {
    String? selectedAccount;

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
                value: selectedAccount,
                items: accounts.map((account) {
                  final icon = account.accountType == "Bargeld"
                      ? Icons.attach_money
                      : Icons.account_balance;
                  return DropdownMenuItem<String>(
                    value: account.id,
                    child: Row(
                      children: [
                        Icon(icon, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(account.accountName ?? 'Unbenanntes Konto'),
                      ],
                    ),
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
                    if (userId != null && selectedAccount != null) {
                      FirestoreService firestoreService = FirestoreService();
                      // Use the `importCsvTransactionsV2` method and pass the selected account ID
                      await firestoreService.importCsvTransactionsV2(userId, selectedAccount!);
                      Navigator.of(context).pop(); // Schließt den Dialog.
                    } else {
                      print("Fehler: Kein Benutzer angemeldet oder kein Konto ausgewählt.");
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
  }
}

 */