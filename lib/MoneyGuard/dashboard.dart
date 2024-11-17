import 'package:flutter/material.dart';
import 'dateButton.dart'; // Import the DateButton widget
//import 'category.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<Map<String, String>> possibleAccounts = [
    {'type': 'Bargeld Konto', 'name': 'Mein Konto', 'balance': '0', 'currency': 'EUR'},
  ];

  Widget _buildAccountCards(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ...possibleAccounts.map((account) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccountDetailsScreen(
                        type: account['type']!,
                        onAccountCreated: (updatedAccount) {
                          setState(() {
                            final index = possibleAccounts.indexOf(account);
                            if (index != -1) {
                              possibleAccounts[index] = updatedAccount;
                            }
                          });
                        },
                        onAccountDeleted: () {
                          if (possibleAccounts.length > 1) {
                            setState(() {
                              possibleAccounts.remove(account);
                            });
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mindestens ein Konto muss vorhanden sein.'),
                              ),
                            );
                          }
                        },
                        isNewAccount: false,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 150,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            account['type'] == 'Bankkonto'
                                ? Icons.account_balance
                                : Icons.attach_money,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            account['type']!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        account['name']!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${account['balance']} ${account['currency']}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountCreation(
                    onAccountCreated: (newAccount) {
                      setState(() {
                        possibleAccounts.add(newAccount);
                      });
                    },
                  ),
                ),
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 20.0), // Optional padding for spacing
        children: [
          Center(
            child: SizedBox(
              height: 150,  // Fixed height for DateButton to ensure visibility
              child: _buildAccountCards(context),
            ),
          ),
          const SizedBox(height: 30), // Spacing between account cards and DateButton

          Center(
            child: SizedBox(
              height: 250,  // Fixed height for DateButton to ensure visibility
              child: DateButton(),
            ),
          ),

          const SizedBox(height: 30), // Spacing between DateButton and CategoryButton

          Center(
            child: SizedBox(
              height: 250,  // Fixed height for CategoryButton to ensure visibility
              //child: CategoryButton(),
            ),
          ),

        ],
      ),
    );
  }

}

class AccountCreation extends StatelessWidget {
  final Function(Map<String, String>) onAccountCreated;

  const AccountCreation({super.key, required this.onAccountCreated});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Neues Konto hinzufügen"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountDetailsScreen(
                            type: 'Automatische Konfigurierung',
                            onAccountCreated: onAccountCreated,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 150,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Text(
                          "Automatische Konfigurierung",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountDetailsScreen(
                            type: 'Manuelle Eingabe',
                            onAccountCreated: onAccountCreated,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 150,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Text(
                          "Manuelle Eingabe",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}




class AccountDetailsScreen extends StatefulWidget {
  final String type;
  final Function(Map<String, String>) onAccountCreated;
  final Function()? onAccountDeleted;
  final bool isNewAccount;

  const AccountDetailsScreen({
    required this.type,
    required this.onAccountCreated,
    this.onAccountDeleted,
    this.isNewAccount = false, // Default: Neues Konto
    super.key,
  });

  @override
  _AccountDetailsScreen createState() => _AccountDetailsScreen();
}

class _AccountDetailsScreen extends State<AccountDetailsScreen> {
  String accountName = "Mein Konto";
  String accountBalance = "0";
  final String currency = "EUR";
  String accountType = "Bargeld"; // Standardwert geändert zu "Bargeld"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Konto konfigurieren"),
      ),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.blue),
            title: const Text("Kontoname"),
            trailing: Text("$accountName >"),
            onTap: () {
              _editField("Kontoname", (value) => setState(() => accountName = value));
            },
          ),
          ListTile(
            leading: const Icon(Icons.money, color: Colors.blue),
            title: const Text("Aktueller Kontostand"),
            trailing: Text("$accountBalance EUR >"),
            onTap: () {
              _editField("Aktueller Kontostand", (value) => setState(() => accountBalance = value));
            },
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.account_balance, color: Colors.blue),
            title: const Text("Kontotyp"),
            trailing: DropdownButton<String>(
              value: accountType,
              onChanged: (String? newValue) {
                setState(() {
                  accountType = newValue!;
                });
              },
              items: <String>['Bargeld', 'Bankkonto']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text("Von Statistik ausschließen"),
            value: false,
            onChanged: (bool value) {
              setState(() {});
            },
          ),
          if (!widget.isNewAccount && widget.onAccountDeleted != null)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Konto löschen", style: TextStyle(color: Colors.red)),
              onTap: () {
                _showDeleteConfirmationDialog();
              },
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.isNewAccount)
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                    ),
                    child: const Text(
                      "Abbrechen",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onAccountCreated({
                      'type': accountType,
                      'name': accountName,
                      'balance': accountBalance,
                      'currency': currency,
                    });
                    Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    "Speichern",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editField(String fieldName, Function(String) onValueSaved) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("$fieldName bearbeiten"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Neuen Wert eingeben"),
            keyboardType: fieldName == "Aktueller Kontostand" ? TextInputType.number : TextInputType.text,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Abbrechen"),
            ),
            TextButton(
              onPressed: () {
                onValueSaved(controller.text);
                Navigator.of(context).pop();
              },
              child: const Text("Speichern"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konto löschen"),
          content: const Text("Möchtest du dieses Konto wirklich löschen?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Abbrechen"),
            ),
            TextButton(
              onPressed: () {
                if (widget.onAccountDeleted != null) {
                  widget.onAccountDeleted!();
                }
                Navigator.of(context).pop();
              },
              child: const Text("Löschen", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}



