import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../backend/ImportedTransaction.dart';
import '../main.dart';
import 'dateButton.dart';
import 'category.dart';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:budget_management_app/backend/BankAccount.dart';
import 'package:budget_management_app/backend/Transaction.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<BankAccount> bankAccounts = [];

  @override
  void initState() {
    super.initState();
    _fetchBankAccounts();
    _createDefaultAccount();
    FirestoreService().createDefaultCategories(currentUser!.uid).then((_) {
      return FirestoreService().getSortedUserCategories(currentUser!.uid);
    });
  }

  Future<void> _createDefaultAccount() async {
    if (currentUser != null) {
      List<BankAccount> accounts = await FirestoreService().getUserBankAccounts(currentUser!.uid);


      if (accounts.isEmpty) {
        final defaultAccount = BankAccount(
          userId: currentUser!.uid,
          accountName: 'Mein Konto',
          balance: 0.0,
          accountType: 'Bargeld',
          exclude: false,
          forImport: false,
        );

        await FirestoreService().createBankAccount(currentUser!.uid, defaultAccount);
        _fetchBankAccounts();
      }
    }
  }
  Future<void> _fetchBankAccounts() async {
    if (currentUser != null) {
      List<BankAccount> accounts =
      await FirestoreService().getUserBankAccounts(currentUser!.uid);


      for (BankAccount account in accounts) {
        if (account.forImport) {
          await FirestoreService().calculateImportBankAccountBalance(currentUser!.uid, account);

        } else {
          await FirestoreService().calculateBankAccountBalance(currentUser!.uid, account);
        }
      }

      setState(() {
        bankAccounts = accounts;
      });
    }
  }


  Future<void> _createBankAccount(Map<String, String> accountData, bool forImport) async {
    if (currentUser != null) {

    if (accountData['name'] == null || accountData['name']!.trim().isEmpty) {
        print("FEHLER: Name des Kontos ist leer!");
        return;
      }

      final account = BankAccount(
        userId: currentUser!.uid,
        accountName: accountData['name'],
        balance: double.tryParse(accountData['balance'] ?? '0') ?? 0.0,
        accountType: forImport ? 'Bankkonto' : accountData['type']!,
        exclude: false,
        forImport: forImport,
      );
      await FirestoreService().createBankAccount(currentUser!.uid, account);
      _fetchBankAccounts();
    }
  }




  Widget _buildAccountCards(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.onSecondary;
    final primaryColor2 = theme.colorScheme.onSurface;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ...bankAccounts.map((account) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccountDetailsScreen(
                        type: 'Bearbeiten',
                        account: account,
                        onAccountCreated: (updatedAccount) {
                          _fetchBankAccounts();
                        },
                        onAccountDeleted: bankAccounts.length > 1 ? () async {
                          await FirestoreService()
                              .deleteBankAccount(currentUser!.uid, account.id!);
                          _fetchBankAccounts();
                        } : null,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 150,
                  height: 140,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        spreadRadius: 1,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            account.accountType == 'Bankkonto'
                                ? Icons.account_balance
                                : Icons.attach_money,
                            color: Colors.blue,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            account.accountType,
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryColor2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        account.accountName ?? '',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: primaryColor2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${account.balance?.toStringAsFixed(2) ?? "0.00"} EUR',
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        account.forImport ? 'For Imports' : '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF388E3C),
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
                    onAccountCreated: (newAccount, forImport) {
                      _createBankAccount(newAccount, forImport);
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
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        children: [
          Center(
            child: SizedBox(
              height: 150,
              child: _buildAccountCards(context),
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: SizedBox(
              height: 250,
              child: DateButton(),
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: SizedBox(
              height: 250,
              child: CategoryButton(),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountCreation extends StatelessWidget {
  final Function(Map<String, String>, bool) onAccountCreated;

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
                            type: 'Konfigurierung durch Import von CSV Dateien',
                            onAccountCreated: (accountData) {
                              accountData['type'] = 'Bankkonto'; // Typ wird festgelegt
                              onAccountCreated(accountData, true);
                            },
                            isNewAccount: true,
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
                          "Konfigurierung durch Import von CSV Dateien",
                          textAlign: TextAlign.center,
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
                            type: 'Manuelle Eingaben',
                            onAccountCreated: (accountData) {
                              onAccountCreated(accountData, false);
                            },
                            isNewAccount: true,
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
                          "Manuelle Eingaben",
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
  final BankAccount? account;
  final Function(Map<String, String>) onAccountCreated;
  final Function()? onAccountDeleted;
  final bool isNewAccount;

  const AccountDetailsScreen({
    required this.type,
    this.account,
    required this.onAccountCreated,
    this.onAccountDeleted,
    this.isNewAccount = false,
    super.key,
  });

  @override
  _AccountDetailsScreen createState() => _AccountDetailsScreen();
}

class _AccountDetailsScreen extends State<AccountDetailsScreen> {
  late String accountName;
  late String accountBalance;
  late String accountType;

  @override
  void initState() {
    super.initState();
    accountName = widget.account?.accountName ?? "Mein Konto";
    accountBalance = widget.account?.balance?.toStringAsFixed(2) ?? "0";
    accountType = widget.account?.accountType ?? "Bargeld";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Konto konfigurieren"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MyApp()),
            );
          },
        ),
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
            trailing: Text("$accountBalance EUR"),
            onTap: null,
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.account_balance, color: Colors.blue),
            title: const Text("Kontotyp"),
            trailing: widget.account?.forImport == true || widget.type.contains('CSV')
                ? const Text(
              "Bankkonto",
              style: TextStyle(fontSize: 16),
            )
                : DropdownButton<String>(
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
                ElevatedButton(
                  onPressed: () async {
                    Map<String, String> accountData = {
                      'type': accountType,
                      'name': accountName,
                      'balance': accountBalance,
                    };

                    if (widget.account != null && widget.account!.id != null) {
                      BankAccount updatedAccount = BankAccount(
                        userId: widget.account!.userId,
                        accountName: accountName,
                        balance: double.tryParse(accountBalance) ?? 0.0,
                        accountType: accountType,
                        exclude: widget.account!.exclude,
                        forImport: widget.account!.forImport, // Behalte den ursprünglichen Wert bei
                        lastUpdated: DateTime.now(),
                      );
                      updatedAccount.id = widget.account!.id;
                      await FirestoreService().updateBankAccount(widget.account!.userId, updatedAccount);
                    } else {
                      widget.onAccountCreated(accountData);
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyApp(),
                      ),
                    );
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

  void _editField(String title, Function(String) onSubmit) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Eingeben"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Abbrechen"),
            ),
            TextButton(
              onPressed: () {
                onSubmit(controller.text);
                Navigator.pop(context);
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
      builder: (context) {
        return AlertDialog(
          title: const Text("Konto löschen"),
          content: widget.account != null
              ? FutureBuilder<List<dynamic>>(
            future: widget.account!.forImport
                ? FirestoreService().getImportedTransactionsByAccountIds(
                widget.account!.userId, [widget.account!.id!])
                : FirestoreService().getTransactionsByAccountIds(
                widget.account!.userId, [widget.account!.id!]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text("Prüfe, ob Transaktionen vorhanden sind...");
              }

              if (snapshot.hasError) {
                return const Text("Fehler beim Abrufen der Transaktionen.");
              }

              final transactions = snapshot.data ?? [];

              if (transactions.isNotEmpty) {
                return Text(
                  "Dieses Konto hat ${transactions.length} Transaktion(en). "
                      "Wenn Sie das Konto löschen, werden die Transaktionen ebenfalls gelöscht. "
                      "Möchten Sie fortfahren?",
                );
              } else {
                return const Text(
                  "Sind Sie sicher, dass Sie dieses Konto löschen möchten? "
                );
              }
            },
          )
              : const Text(
              "Sind Sie sicher, dass Sie dieses Konto löschen möchten?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Abbrechen"),
            ),
            TextButton(
              onPressed: () async {
                if (widget.account != null) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text('Lösche Transaktionen...'),
                        ],
                      ),
                    ),
                  );

                  try {
                    if (widget.account!.forImport) {
                      List<ImportedTransaction> importedTransactions =
                      await FirestoreService().getImportedTransactionsByAccountIds(
                          widget.account!.userId, [widget.account!.id!]);

                      for (var transaction in importedTransactions) {
                        await FirestoreService().deleteImportedTransaction(
                            widget.account!.userId, transaction.id!);
                      }
                    } else {
                      List<Transaction> transactions = await FirestoreService()
                          .getTransactionsByAccountIds(
                          widget.account!.userId, [widget.account!.id!]);

                      for (var transaction in transactions) {
                        await FirestoreService().deleteTransaction(
                            widget.account!.userId, transaction.id!);
                      }
                    }

                    await FirestoreService().deleteBankAccount(
                        widget.account!.userId, widget.account!.id!);


                    widget.onAccountDeleted?.call();
                  } finally {

                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyApp()),
                    );
                  }
                }
              },
              child: const Text("Löschen"),
            ),
          ],
        );
      },
    );
  }
}