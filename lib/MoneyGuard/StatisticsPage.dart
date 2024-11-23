import 'package:flutter/material.dart';
import 'category.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {

  // Variable für die Dropdown-Auswahl (Gesamtbetrag, Einnahmen, Ausgaben)
  String selectedAmountType = 'Gesamtbetrag';
  // Variable für den Zeitraum (Monat, Woche, Jahr)
  String selectedTimePeriod = 'Monat';

  // List of categories to display stats (placeholder for categories)
  final List<String> categories = [
    'Einnahmen', 'Unterhaltung', 'Lebensmittel', 'Haushalt', 'Wohnen',
    'Transport', 'Kleidung', 'Bildung', 'Finanzen', 'Gesundheit'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Oben Dropdowns für Gesamtübersicht
            Row(
              children: [
                // Dropdown für den Betrag (Gesamt, Einnahmen, Ausgaben)
                DropdownButton<String>(
                  value: selectedAmountType,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedAmountType = newValue!;
                    });
                  },
                  items: <String>['Gesamtbetrag', 'Einnahmen', 'Ausgaben']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 20),
                // Dropdown für den Zeitraum (Monat, Woche, Jahr)
                Text(
                  'im Zeitraum:     ',
                  style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                DropdownButton<String>(
                  value: selectedTimePeriod,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedTimePeriod = newValue!;
                    });
                  },
                  items: <String>['Monat', 'Woche', 'Jahr']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Gesamtübersicht (hier könnte später ein Plot eingebaut werden)
            Container(
              width: double.infinity,  // Damit der Container die volle Breite einnimmt
              height: 350,             // Höhe für den Plot-Bereich (Platzhalter)
              decoration: BoxDecoration(
                color: Colors.white,    // Weißer Hintergrund
                borderRadius: BorderRadius.circular(10),  // Abgerundete Ecken (optional)
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12, // Optionaler Schatten für den Container
                    blurRadius: 6,
                    offset: Offset(0, 2), // Position des Schattens
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Gesamtübersicht - Platz für Main Plot',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Kategoriedetails (Hier können wir später auf Kategorien swipen oder scrollen)
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return CategoryStatWidget(category: categories[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryStatWidget extends StatelessWidget {
  final String category;

  CategoryStatWidget({required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white, // Weißer Hintergrund für Kategorien
          borderRadius: BorderRadius.circular(8),  // Abgerundete Ecken
          boxShadow: [
            BoxShadow(
              color: Colors.black12, // Schattierung (subtiler Schatten)
              blurRadius: 8,          // Weicher Schatten
              offset: Offset(0, 4),   // Position des Schattens
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kategoriename
            Text(
              category,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 30),
            // Platzhalter für den Plot pro Kategorie
            Placeholder(
              fallbackHeight: 150,
              color: Colors.teal[100]!,
              child: Center(child: Text('$category - Platz für Plot')),
            ),
          ],
        ),
      ),
    );
  }
}

