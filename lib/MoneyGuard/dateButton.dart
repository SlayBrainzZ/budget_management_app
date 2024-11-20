import 'package:flutter/material.dart';

/*
void main() {
  runApp(MaterialApp(
    home: DateButton(),
  ));
}*/

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

  List<String> categories = ['Kategorie 1', 'Kategorie 2', 'Kategorie 3'];
  List<String> accounts = ['Konto 1', 'Konto 2', 'Konto 3'];
  List<String> selectedCategories = [];
  List<String> selectedAccounts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    selectedCategories = ['Alle']; // Standardauswahl
    selectedAccounts = ['Alle'];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMultiSelectDialog({
    required List<String> options,
    required List<String> selectedValues,
    required ValueChanged<List<String>> onConfirm,
    required String title,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> tempSelectedValues = List.from(selectedValues);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  children: options.map((option) {
                    return CheckboxListTile(
                      title: Text(option),
                      value: tempSelectedValues.contains(option),
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            if (option == 'Alle') {
                              tempSelectedValues.clear();
                              tempSelectedValues.add('Alle');
                            } else {
                              tempSelectedValues.remove('Alle');
                              tempSelectedValues.add(option);
                            }
                          } else {
                            tempSelectedValues.remove(option);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Abbrechen'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Bestätigen'),
                  onPressed: () {
                    onConfirm(tempSelectedValues);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einnahmen und Ausgaben'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Täglich'),
            Tab(text: 'Monatlich'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filterleiste
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showMultiSelectDialog(
                        options: ['Alle', ...categories],
                        selectedValues: selectedCategories,
                        onConfirm: (values) {
                          setState(() {
                            selectedCategories = values.isEmpty ? ['Alle'] : values;
                          });
                        },
                        title: 'Kategorien auswählen',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      side: BorderSide(color: Colors.grey),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedCategories.contains('Alle')
                              ? 'Alle Kategorien'
                              : selectedCategories.join(', '),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.black),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showMultiSelectDialog(
                        options: ['Alle', ...accounts],
                        selectedValues: selectedAccounts,
                        onConfirm: (values) {
                          setState(() {
                            selectedAccounts = values.isEmpty ? ['Alle'] : values;
                          });
                        },
                        title: 'Konten auswählen',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      side: BorderSide(color: Colors.grey),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedAccounts.contains('Alle')
                              ? 'Alle Konten'
                              : selectedAccounts.join(', '),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Einnahmen-/Ausgaben-Info
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoCard('Einnahmen', '0 €', Colors.blue),
                _buildInfoCard('Ausgaben', '0 €', Colors.red),
                _buildInfoCard('Gesamt', '0 €', Colors.black),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListView('Tägliche Daten'),
                _buildListView('Monatliche Daten'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildListView(String type) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('$type Eintrag ${index + 1}'),
          subtitle: Text('Details zu $type Eintrag ${index + 1}'),
        );
      },
    );
  }
}
