import 'package:flutter/material.dart';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:budget_management_app/backend/Transaction.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_management_app/backend/Category.dart';

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
  List<Transaction> dailyTransactions = [];
  bool isLoading = true;

  // Dropdown-Werte
  List<Category> selectedCategories = []; // Vollständige Category-Objekte
  List<String> selectedAccounts = [];

  // Kategorien und Konten
  List<Category> categories = [];
  List<String> accounts = ['Konto 1', 'Konto 2', 'Konto 3'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTransactions();
    _fetchCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

      List<Transaction> transactions;
      if (selectedCategories.isEmpty || selectedCategories.length == categories.length) {
        // "Alle" ist gewählt, lade alle Transaktionen
        transactions = await firestoreService.getUserTransactions(userId);
      } else {
        // Lade Transaktionen für spezifische Kategorien
        transactions = [];
        for (final category in selectedCategories) {
          final filteredTransactions = await firestoreService.getTransactionsByCategory(
            userId,
            category.id!,
          );
          transactions.addAll(filteredTransactions);
        }
      }

      // Lade Kategorie-Daten für jede Transaktion
      for (var transaction in transactions) {
        if (transaction.categoryId != null) {
          final category = await firestoreService.getCategory(userId, transaction.categoryId!);
          transaction.categoryData = category;
        }
      }

      setState(() {
        dailyTransactions = transactions;
      });
    } catch (e) {
      print('Fehler beim Abrufen der Transaktionen: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> _fetchCategories() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Kein Benutzer angemeldet.');
      }

      final firestoreService = FirestoreService();
      final userId = currentUser.uid;

      final userCategories = await firestoreService.getUserCategories(userId);

      setState(() {
        categories = userCategories; // Vollständige Kategorie-Objekte speichern
        selectedCategories = List.from(userCategories); // Standardmäßig alle wählen
      });

      _fetchTransactions(); // Lade Transaktionen basierend auf allen Kategorien
    } catch (e) {
      print('Fehler beim Abrufen der Kategorien: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einnahmen und Ausgaben'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(120.0), // Platz für Dropdowns
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMultiSelectDropdown(
                      title: "Kategorie wählen",
                      items: categories,
                      selectedItems: selectedCategories,
                      onConfirm: (selected) {
                        setState(() {
                          selectedCategories = selected;
                        });
                      },
                    ),
                    _buildMultiSelectDropdown(
                      title: "Konto wählen",
                      items: accounts,
                      selectedItems: selectedAccounts,
                      onConfirm: (selected) {
                        setState(() {
                          selectedAccounts = selected;
                        });
                      },
                    ),
                  ],
                ),
              ),
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
          _buildEmptyMonthlyView(),
        ],
      ),
    );
  }

  Widget _buildMultiSelectDropdown<T>({
    required String title,
    required List<T> items,
    required List<T> selectedItems,
    required Function(List<T>) onConfirm,
  }) {
    return InkWell(
      onTap: () async {
        final List<T>? result = await showDialog<List<T>>(
          context: context,
          builder: (context) {
            List<T> tempSelected = List.from(selectedItems);
            final bool isCategory = items is List<Category>;

            return StatefulBuilder(
              builder: (context, setState) {
                final bool isAllSelected = tempSelected.length == items.length;

                void toggleAllSelection(bool isSelected) {
                  setState(() {
                    if (isSelected) {
                      tempSelected = List.from(items); // Alle auswählen
                    } else {
                      tempSelected.clear(); // Alle abwählen
                    }
                  });
                }

                return AlertDialog(
                  title: Text(title),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: isAllSelected,
                          title: Text("Alle"),
                          onChanged: (isChecked) {
                            toggleAllSelection(isChecked == true);
                          },
                        ),
                        ...items.map((item) {
                          final bool isSelected = tempSelected.contains(item);

                          return CheckboxListTile(
                            value: isSelected,
                            title: Row(
                              children: [
                                if (isCategory)
                                  Icon(
                                    (item as Category).icon ?? Icons.category,
                                    color: item.color ?? Colors.grey,
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isCategory
                                        ? (item as Category).name
                                        : item.toString(),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            onChanged: (isChecked) {
                              setState(() {
                                if (isChecked == true) {
                                  tempSelected.add(item);
                                } else {
                                  tempSelected.remove(item);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Abbrechen"),
                      onPressed: () {
                        Navigator.pop(context, null);
                      },
                    ),
                    ElevatedButton(
                      child: const Text("Bestätigen"),
                      onPressed: () {
                        Navigator.pop(context, tempSelected);
                      },
                    ),
                  ],
                );
              },
            );
          },
        );

        if (result != null) {
          onConfirm(result);
          _fetchTransactions(); // Aktualisiere Transaktionen basierend auf Auswahl
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedItems.isEmpty
                  ? title
                  : (selectedItems.length == items.length
                  ? 'Alle' // Zeige "Alle" an, wenn alle Kategorien ausgewählt sind
                  : selectedItems
                  .map((e) => e is Category ? e.name : e.toString())
                  .join(', ')),
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
        final transaction = dailyTransactions[index];
        final category = transaction.categoryData;

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
              Text(transaction.note ?? 'Keine Notiz'),
              Text(
                'Datum: ${transaction.date.toLocal().toIso8601String()}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
        );
      },
    );
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

  Widget _buildEmptyMonthlyView() {
    return Center(
      child: const Text(
        'Keine Daten für die monatliche Ansicht.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}

