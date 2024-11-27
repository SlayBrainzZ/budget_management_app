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
  List<String> selectedCategories = [];
  List<String> selectedAccounts = [];

  // Beispiel-Daten für die Dropdown-Listen
  List<String> categories = ['Einkaufen', 'Miete', 'Freizeit', 'Essen'];
  List<String> accounts = ['Konto 1', 'Konto 2', 'Konto 3'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTransactions();
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

      final userTransactions = await firestoreService.getUserTransactions(userId);

      // Lade Kategorie-Daten für jede Transaktion
      for (var transaction in userTransactions) {
        if (transaction.categoryId != null) {
          final category = await firestoreService.getCategory(userId, transaction.categoryId!);
          transaction.categoryData = category; // Ergänze Kategorie-Daten zur Transaktion
        }
      }

      setState(() {
        dailyTransactions = userTransactions;
      });
    } catch (e) {
      print('Fehler beim Abrufen der Transaktionen: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
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


  Widget _buildMultiSelectDropdown({
    required String title,
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onConfirm,
  }) {
    return InkWell(
      onTap: () async {
        final List<String>? result = await showDialog<List<String>>(
          context: context,
          builder: (context) {
            List<String> tempSelected = List.from(selectedItems);
            final String allOption = 'Alle'; // Option "Alle"

            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  children: [allOption, ...items].map((item) {
                    final isSelected = tempSelected.contains(item);

                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(item),
                      onChanged: (isChecked) {
                        setState(() {
                          if (item == allOption) {
                            // Wenn "Alle" gewählt wird, wähle alles oder setze zurück
                            if (isChecked == true) {
                              tempSelected
                                ..clear()
                                ..addAll([allOption, ...items]);
                            } else {
                              tempSelected.clear();
                            }
                          } else {
                            // Individuelle Items hinzufügen/entfernen
                            if (isChecked == true) {
                              tempSelected.add(item);
                              tempSelected.remove(allOption); // Entferne "Alle", wenn etwas anderes ausgewählt ist
                            } else {
                              tempSelected.remove(item);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Abbrechen"),
                  onPressed: () {
                    Navigator.pop(context, null);
                  },
                ),
                ElevatedButton(
                  child: Text("Bestätigen"),
                  onPressed: () {
                    Navigator.pop(context, tempSelected);
                  },
                ),
              ],
            );
          },
        );

        if (result != null) {
          onConfirm(result);
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
              selectedItems.isEmpty ? title : selectedItems.join(', '),
              style: TextStyle(color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }


  Widget _buildDailyTransactionList() {
    if (dailyTransactions.isEmpty) {
      return Center(
        child: Text(
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
          leading: _buildLeadingIcon(transaction.type), // Neuer Kreis mit Pfeil
          title: Row(
            children: [
              if (category != null) ...[
                Icon(
                  category.icon ?? Icons.category,
                  color: category.color ?? Colors.grey, // Farbe des Kategorie-Icons
                  size: 24,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                Text(
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
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
        color: type == 'Einnahme' ? Colors.green : Colors.red, // Kreisfarbe
        shape: BoxShape.circle,
      ),
      child: Icon(
        type == 'Einnahme' ? Icons.arrow_upward : Icons.arrow_downward, // Pfeil
        color: Colors.white, // Weißer Pfeil
        size: 20,
      ),
    );
  }


  Widget _buildEmptyMonthlyView() {
    return Center(
      child: Text(
        'Keine Daten für die monatliche Ansicht.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}

