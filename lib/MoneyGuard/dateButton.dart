import 'package:budget_management_app/MoneyGuard/transaction.dart';
import 'package:flutter/material.dart';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:budget_management_app/backend/Transaction.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_management_app/backend/Category.dart';
import 'package:budget_management_app/backend/BankAccount.dart';
import 'package:budget_management_app/backend/ImportedTransaction.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';



import 'ImportButton.dart';

class DateButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String day = now.day.toString();
    final String month = _getMonthName(now.month);
    final String weekday = _getWeekdayName(now.weekday);

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 250, // Feste Breite
          height: 250, // Feste Höhe
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: EdgeInsets.all(0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 5.0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DateButtonScreen()),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month,
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  weekday,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    return months[month - 1];
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'
    ];
    return weekdays[weekday % 7];
  }
}


class DateButtonScreen extends StatefulWidget {
  @override
  _DateButtonScreenState createState() => _DateButtonScreenState();
}

class _DateButtonScreenState extends State<DateButtonScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> dailyTransactions = [];

  bool isLoading = true;

// Dropdown-Werte
  List<Category> selectedCategories = []; // Vollständige Category-Objekte
  List<BankAccount> selectedAccounts = [];

// Kategorien und Konten
  List<Category> categories = [];
  List<BankAccount> bankAccounts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) { // Monatlich ausgewählt
        setState(() {
          _generateMonthlyData(); // Daten berechnen
        });
      }
    });
    _fetchBankAccounts();
    _fetchTransactions();
    //_fetchCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final DateFormat dateFormat = DateFormat('dd.MM.yyyy');
    final DateFormat timeFormat = DateFormat('HH:mm');
    return '${dateFormat.format(date)} um ${timeFormat.format(date)}';
  }

//Monthly ##########################
  Map<int, Map<String, double>> _generateMonthlyData() {
    Map<int, Map<String, double>> monthlyData = {};

    for (var transaction in dailyTransactions) {
      final type = transaction['type'];
      final data = transaction['data'];
      final date = type == 'regular'
          ? (data as Transaction).date
          : (data as ImportedTransaction).date;
      final amount = type == 'regular'
          ? (data as Transaction).amount
          : (data as ImportedTransaction).amount;
      final inflow = type == 'regular'
          ? (data as Transaction).type == 'Einnahme'
          : (data as ImportedTransaction).inflow > 0;

      final month = date.month;
      if (!monthlyData.containsKey(month)) {
        monthlyData[month] = {'einnahmen': 0.0, 'ausgaben': 0.0, 'gesamt': 0.0};
      }

      if (inflow) {
        monthlyData[month]!['einnahmen'] =
            monthlyData[month]!['einnahmen']! + amount;
      } else {
        monthlyData[month]!['ausgaben'] =
            monthlyData[month]!['ausgaben']! + amount.abs();
      }

      monthlyData[month]!['gesamt'] =
          monthlyData[month]!['einnahmen']! - monthlyData[month]!['ausgaben']!;
    }

    return monthlyData;
  }

// Für multiselect
  Future<void> _fetchBankAccounts() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Kein Benutzer angemeldet.');
      }

      final firestoreService = FirestoreService();
      final userId = currentUser.uid;

      // Hier rufst du die Bankkonten ab
      final accounts = await firestoreService.getUserBankAccounts(userId);
      setState(() {
        bankAccounts = accounts;
      });
    } catch (e) {
      print('Fehler beim Abrufen der Bankkonten: $e');
    }
  }
//##################################
  /*
  Future<void> _fetchTransactions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Kein Benutzer angemeldet.');
      }

      final firestoreService = FirestoreService();
      final userId = currentUser.uid;

      // Hole reguläre Transaktionen
      List<Transaction> transactions;
      if (selectedCategories.isEmpty || selectedCategories.length == categories.length) {
        transactions = await firestoreService.getUserTransactions(userId);
      } else {
        transactions = [];
        for (final category in selectedCategories) {
          final filteredTransactions = await firestoreService.getTransactionsByCategory(
            userId,
            category.id!,
          );
          transactions.addAll(filteredTransactions);
        }
      }

      // Kategorie-Daten für jede Transaktion laden
      for (var transaction in transactions) {
        if(transaction.accountId != null){
          final bankAccount = await firestoreService.getBankAccount(userId, transaction.accountId!);
          transaction.bankAccount = bankAccount;
        }
        if (transaction.categoryId != null) {
          final category = await firestoreService.getCategory(userId, transaction.categoryId!);
          transaction.categoryData = category;
        }
      }

      // Hole importierte Transaktionen
      final importedTransactions = await firestoreService.getImportedTransactions(userId);
      for (var importedTransaction in importedTransactions) {
        if(importedTransaction.accountId != null){
          final bankAccount = await firestoreService.getBankAccount(userId, importedTransaction.accountId!);
          importedTransaction.linkedAccount = bankAccount;
        } /*
        if (importedTransaction.categoryId != null) {
          final category = await firestoreService.getCategory(userId, transaction.categoryId!);
          transaction.categoryData = category;
        }*/
      }
      final combinedTransactions = [
        ...transactions.map((t) => {
          'type': 'regular',
          'data': t,
        }),
        ...importedTransactions.map((t) => {
          'type': 'imported',
          'data': t,
        }),
      ];

      // Sortiere die Transaktionen nach Datum
      combinedTransactions.sort((a, b) {
        final aDate = a['type'] == 'regular'
            ? (a['data'] as Transaction).date
            : (a['data'] as ImportedTransaction).date;
        final bDate = b['type'] == 'regular'
            ? (b['data'] as Transaction).date
            : (b['data'] as ImportedTransaction).date;
        return bDate.compareTo(aDate);
      });

      setState(() {
        dailyTransactions = combinedTransactions;
      });
    } catch (e) {
      print('Fehler beim Abrufen der Transaktionen: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }*/
  Future<void> _fetchTransactions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Kein Benutzer angemeldet.');
      }

      final firestoreService = FirestoreService();
      final userId = currentUser.uid;

      // Extrahiere die IDs der ausgewählten Konten
      List<String> selectedAccountIds =
      selectedAccounts.map((account) => account.id!).toList();

      List<Transaction> transactions = [];
      List<ImportedTransaction> importedTransactions = [];

      if (selectedAccounts.isEmpty) {
        // Falls keine Konten ausgewählt sind, lade alle Transaktionen
        transactions = await firestoreService.getUserTransactions(userId);
        importedTransactions = await firestoreService.getImportedTransactions(userId);
      } else {
        // Falls Konten ausgewählt sind, filtere nach diesen
        transactions = await firestoreService.getTransactionsByAccountIds(userId, selectedAccountIds);
        importedTransactions = await firestoreService.getImportedTransactionsByAccountIds(userId, selectedAccountIds);
      }

      // Kategorie- und Kontodaten für jede Transaktion laden
      for (var transaction in transactions) {
        if (transaction.accountId != null) {
          final bankAccount = await firestoreService.getBankAccount(userId, transaction.accountId!);
          transaction.bankAccount = bankAccount;
        }
        if (transaction.categoryId != null) {
          final category = await firestoreService.getCategory(userId, transaction.categoryId!);
          transaction.categoryData = category;
        }
      }

      // Importierte Transaktionen verarbeiten
      for (var importedTransaction in importedTransactions) {
        if (importedTransaction.accountId != null) {
          final bankAccount = await firestoreService.getBankAccount(userId, importedTransaction.accountId!);
          importedTransaction.linkedAccount = bankAccount;
        }
        if (importedTransaction.categoryId != null) {
          final category = await firestoreService.getCategory(userId, importedTransaction.categoryId!);
          importedTransaction.categoryData = category;
        }
      }

      final combinedTransactions = [
        ...transactions.map((t) => {
          'type': 'regular',
          'data': t,
        }),
        ...importedTransactions.map((t) => {
          'type': 'imported',
          'data': t,
        }),
      ];

      // Sortiere die Transaktionen nach Datum
      combinedTransactions.sort((a, b) {
        final aDate = a['type'] == 'regular'
            ? (a['data'] as Transaction).date
            : (a['data'] as ImportedTransaction).date;
        final bDate = b['type'] == 'regular'
            ? (b['data'] as Transaction).date
            : (b['data'] as ImportedTransaction).date;
        return bDate.compareTo(aDate);
      });

      setState(() {
        dailyTransactions = combinedTransactions;
      });
    } catch (e) {
      print('Fehler beim Abrufen der Transaktionen: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<List<Category>> _fetchSortedCategories() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Kein Benutzer angemeldet.');
    }
    final userId = currentUser.uid;
    final firestoreService = FirestoreService();

    return await firestoreService.getSortedUserCategories(userId);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einnahmen und Ausgaben'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Zurück zum vorherigen Bildschirm
          },
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(120.0), // Platz für Dropdowns
          child: Column(
            children: [
              if (_tabController.index == 0) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMultiSelectDropdown(
                      title: "Konto wählen",
                      items: bankAccounts,
                      selectedItems: selectedAccounts,
                      onConfirm: (selected) {
                        setState(() {
                          selectedAccounts = selected;
                        });
                        _fetchTransactions();
                      },
                    ),
                    ImportButton(
                      onImportCompleted: _fetchTransactions, // Callback zum Aktualisieren der Daten
                    ),
                  ],
                ),
              ),],
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Täglich'),
                  Tab(text: 'Monatlich'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildDailyTransactionList(),
          _buildMonthlyView(_generateMonthlyData()),
        ],
      ),
    );
  }

  Widget _buildMultiSelectDropdown({
    required String title,
    required List<BankAccount> items,
    required List<BankAccount> selectedItems,
    required Function(List<BankAccount>) onConfirm,
  }) {
    return GestureDetector(
      onTap: () async {
        final selected = await showDialog<List<BankAccount>>(
          context: context,
          builder: (BuildContext context) {
            List<BankAccount> tempSelectedItems = List.from(selectedItems);

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 400, // Dialog breiter machen
                        maxHeight: 500, // Dialoghöhe anpassen
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final account = items[index];
                                final isSelected =
                                tempSelectedItems.contains(account);

                                return ListTile(
                                  leading: Icon(
                                    account.accountType == "Bargeld"
                                        ? Icons.attach_money
                                        : Icons.account_balance,
                                    color: Colors.blue,
                                  ),
                                  title: Text(
                                    account.accountName ?? "Unbenannt",
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  trailing: Checkbox(
                                    value: isSelected,
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked == true) {
                                          tempSelectedItems.add(account);
                                        } else {
                                          tempSelectedItems.remove(account);
                                        }
                                      });
                                    },
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        tempSelectedItems.remove(account);
                                      } else {
                                        tempSelectedItems.add(account);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Abbrechen
                                },
                                child: const Text(
                                  "Abbrechen",
                                  //style: TextStyle(color: Colors.black), // Textfarbe
                                ),
                              ),
                              const SizedBox(width: 16),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(tempSelectedItems); // Bestätigen
                                },
                                child: const Text(
                                  "Bestätigen",
                                  //style: TextStyle(color: Colors.black), // Textfarbe
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );

        if (selected != null) {
          onConfirm(selected);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedItems.isEmpty
                  ? title // Wenn keine Konten ausgewählt sind, zeige den Titel
                  : selectedItems
                  .map((e) => e.accountName ?? "Unbenannt")
                  .join(", "), // Wenn Konten ausgewählt sind, zeige deren Namen
              style: const TextStyle(color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }








  Widget _buildDailyTransactionList() {
    if (dailyTransactions.isEmpty) {
      return Center(
        child: const Text(
          'Keine Transaktionen verfügbar.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: dailyTransactions.length,
      itemBuilder: (context, index) {
        final transactionData = dailyTransactions[index];
        final type = transactionData['type'];
        final data = transactionData['data'];

        if (type == 'regular') {
          final transaction = data as Transaction;
          final category = transaction.categoryData;
          final bankAccount = transaction.bankAccount;

          return ListTile(
              leading: _buildLeadingIcon(transaction.type),
              title: Row(
                children: [
                  if (category != null) ...[
                    Icon(
                      category.icon ?? Icons.category,
                      color: category.color ?? Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Text(
                      'Keine Kategorie',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (transaction.note?.isNotEmpty ?? false)
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Notiz: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12, // Kleinere Schriftgröße für das Label
                              color: Colors.blueGrey,
                            ),
                          ),
                          TextSpan(
                            text: transaction.note!,
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 12, // Gleiche Schriftgröße für den Inhalt
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (bankAccount != null)
                    Row(
                      children: [
                        _buildAccountLogo(bankAccount.accountType),
                        const SizedBox(width: 10),
                        Text(
                          '${bankAccount.accountName}',
                          style: const TextStyle(color: Colors.black, fontSize: 13),
                        ),
                      ],
                    )
                  else
                    const Text('Konto: Unbekannt', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  /*Text(
                  'Datum: ${transaction.date.toLocal().toIso8601String()}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),*/
                  Text(
                    'Datum: ${_formatDate(transaction.date)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]!),
                  ),
                ],
              ),
              trailing: Text(
                '${transaction.amount.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: transaction.type == 'Einnahme' ? Colors.green : Colors.red,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTransactionPage(transaction: transaction),
                  ),
                ).then((_) {
                  _fetchTransactions();
                });
              }
          );
          /*
        } else if (type == 'imported') {
          final importedTransaction = data as ImportedTransaction;
          final bankAccount = importedTransaction.linkedAccount;

          return ListTile(
            leading: _buildLeadingIcon(importedTransaction.inflow > 0 ? 'Einnahme' : 'Ausgabe'),
            title: Text(
              importedTransaction.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Empfänger: ${importedTransaction.payerOrRecipient}'),
                const Text('Kategorie: Keine Kategorie'),
                if (bankAccount != null)
                  Row(
                    children: [
                      _buildAccountLogo(bankAccount.accountType),
                      const SizedBox(width: 10),
                      Text(
                        '${bankAccount.accountName ?? 'Unbekannt'}',
                        style: const TextStyle(color: Colors.black, fontSize: 13),
                      ),
                    ],
                  ),
                /*Text(
                  'Datum: ${importedTransaction.date.toLocal().toIso8601String()}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),*/
                Text(
                  'Datum: ${_formatDate(importedTransaction.date)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: SizedBox(
              width: 300, // Feste Breite für die gesamte trailing-Spalte
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Imp',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${importedTransaction.amount.toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: importedTransaction.inflow > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              _showCategoryAssignDialog(context, importedTransaction);
            },
          );
        }*/
        } else if (type == 'imported') {
          final importedTransaction = data as ImportedTransaction;
          final bankAccount = importedTransaction.linkedAccount;
          final category = importedTransaction.categoryData; // Kategorie-Daten

          return ListTile(
            leading: _buildLeadingIcon(importedTransaction.inflow > 0 ? 'Einnahme' : 'Ausgabe'),
            title: Text(
              importedTransaction.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               // Text('Empfänger: ${importedTransaction.payerOrRecipient}'),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Empfänger: ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12, // Kleinere Schriftgröße für das Label
                          color: Colors.blueGrey,
                        ),
                      ),
                      TextSpan(
                        text: importedTransaction.payerOrRecipient ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 12, // Gleiche Schriftgröße für den Inhalt
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                if (category != null)
                  Row(
                    children: [
                      Icon(
                        category?.icon ?? Icons.help_outline, // Standard-Icon für keine Kategorie
                        color: category?.color ?? Colors.grey, // Standard-Farbe für keine Kategorie
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(category?.name ?? 'Keine Kategorie'), // Standard-Text für keine Kategorie
                    ],
                  ),
                if (bankAccount != null)
                  Row(
                    children: [
                      _buildAccountLogo(bankAccount.accountType),
                      const SizedBox(width: 10),
                      Text(
                        '${bankAccount.accountName ?? 'Unbekannt'}',
                        style: const TextStyle(color: Colors.black, fontSize: 13),
                      ),
                    ],
                  ),
                Text(
                  'Datum: ${_formatDate(importedTransaction.date)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]!),
                ),
              ],
            ),
            trailing: SizedBox(
              width: 300,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Imp',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${importedTransaction.amount.toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: importedTransaction.inflow > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              _showCategoryAssignDialog(context, importedTransaction);
            },
          );
        }

        return SizedBox.shrink();
      },
    );
  }
/*
  Future<void> _showCategoryAssignDialog(
      BuildContext context, ImportedTransaction transaction) async {
    List<Category> categories = await _fetchSortedCategories();
    Category? selectedCategory;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kategorie zuweisen'),
          content: DropdownButton<Category>(
            isExpanded: true,
            value: selectedCategory,
            hint: const Text('Kategorie auswählen'),
            items: categories.map((category) {
              return DropdownMenuItem<Category>(
                value: category,
                child: Row(
                  children: [
                    Icon(
                      category.icon ?? Icons.category,
                      color: category.color ?? Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(category.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (Category? newValue) {
              setState(() {
                selectedCategory = newValue;
              });
            },
          ),
          actions: [
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Speichern'),
              onPressed: () async {
                if (selectedCategory != null) {
                  // Hier könntest du die Kategorie der Transaktion zuweisen
                  // await _assignCategoryToTransaction(transaction, selectedCategory!);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );

    // Aktualisiere die Transaktionsliste nach dem Speichern
    _fetchTransactions();
  }*/

  Future<void> _showCategoryAssignDialog(
      BuildContext context, ImportedTransaction transaction) async {
    List<Category> categories = await _fetchSortedCategories();
    Category? selectedCategory;

    if (transaction.categoryId != null) {
      selectedCategory = categories.firstWhere(
            (category) => category.id == transaction.categoryId,
        //orElse: () => null,
      );
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder( // Nutze StatefulBuilder, um den Dialog dynamisch zu aktualisieren
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Kategorie zuweisen'),
              content: DropdownButton<Category>(
                isExpanded: true,
                value: selectedCategory,
                hint: const Text('Kategorie auswählen'),
                items: categories.map((category) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          category.icon ?? Icons.category,
                          color: category.color ?? Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Category? newValue) {
                  setState(() {
                    selectedCategory = newValue; // Aktualisiere die Auswahl im Dialog
                  });
                },
              ),
              actions: [
                TextButton(
                  child: const Text('Abbrechen'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Speichern'),
                  onPressed: () async {
                    if (selectedCategory != null) {
                      try {
                        // Aktualisiere die Kategorie in der Transaktion
                        transaction.categoryId = selectedCategory!.id;

                        // Speichere die Transaktion in Firestore
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser != null && transaction.id != null) {
                          await FirestoreService().updateImportedTransaction(
                            currentUser.uid,
                            transaction.id!,
                            transaction,
                          );
                        }

                        Navigator.of(context).pop();
                        _fetchTransactions(); // Aktualisiere die Liste der Transaktionen
                      } catch (e) {
                        print('Fehler beim Speichern der Kategorie: $e');
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }




  Widget _buildAccountLogo(String accountType) {
    if (accountType == 'Bankkonto') {
      return Icon(
        Icons.account_balance,
        color: Colors.blue,
        size: 16,
      );
    } else if (accountType == 'Bargeld') {
      return Icon(
        Icons.attach_money,
        color: Colors.blue,
        size: 17,
      );
    } else {
      return Icon(
        Icons.help_outline, // Using a help icon for unknown accounts
        color: Colors.grey,
        size: 16,
      );
    }
  }

  Widget _buildLeadingIcon(String type) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: type == 'Einnahme' ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
      child: Icon(
        type == 'Einnahme' ? Icons.arrow_upward : Icons.arrow_downward,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildMonthlyView(Map<int, Map<String, double>> monthlyData) {
    if (monthlyData.isEmpty) {
      return _buildEmptyMonthlyView();
    }

    return ListView.builder(
      itemCount: monthlyData.length,
      itemBuilder: (context, index) {
        final month = monthlyData.keys.elementAt(index);
        final data = monthlyData[month]!;

        final String monthName = _getMonthName(month); // Helper to get month name

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monat: $monthName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Einnahmen: ${data['einnahmen']!.toStringAsFixed(2)} €',
                    style: const TextStyle(fontSize: 16, color: Colors.green),
                  ),
                  Text(
                    'Ausgaben: ${data['ausgaben']!.toStringAsFixed(2)} €',
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  Text(
                    'Gesamt: ${data['gesamt']!.toStringAsFixed(2)} €',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      "Januar",
      "Februar",
      "März",
      "April",
      "Mai",
      "Juni",
      "Juli",
      "August",
      "September",
      "Oktober",
      "November",
      "Dezember"
    ];
    return months[month - 1];
  }

  Widget _buildEmptyMonthlyView() {
    return const Center(
      child: Text(
        'Keine Daten für die monatliche Ansicht.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

}