import 'package:flutter/material.dart';
import 'category.dart';

class SavingPlan extends StatelessWidget {
  final List<CategoryData> categories = [
    CategoryData(name: 'Unterhaltung', limit: 150, spent: 75, icon: Icons.movie),
    CategoryData(name: 'Lebensmittel', limit: 200, spent: 120, icon: Icons.local_grocery_store),
    CategoryData(name: 'Haushalt', limit: 100, spent: 40, icon: Icons.home),
    CategoryData(name: 'Wohnen', limit: 500, spent: 450, icon: Icons.house),
    CategoryData(name: 'Transport', limit: 100, spent: 140, icon: Icons.directions_car),
    CategoryData(name: 'Kleidung', limit: 80, spent: 30, icon: Icons.shopping_bag),
    CategoryData(name: 'Bildung', limit: 120, spent: 60, icon: Icons.school),
    CategoryData(name: 'Finanzen', limit: 100, spent: 20, icon: Icons.account_balance_wallet),
    CategoryData(name: 'Gesundheit', limit: 150, spent: 100, icon: Icons.healing),
  ];

  // Farben für Icons und Fortschrittsbalken
  final List<Color> _categoryColors = [
    Colors.orange,
    Colors.blue,
    Colors.purple,
    Colors.red,
    Colors.brown,
    Colors.green,
    Colors.cyan,
    Colors.pink,
    Colors.amber,
    Colors.deepPurple,
  ];

  double get totalIncome =>
      1000; // Die Einnahmen (Monatslimit) direkt hier setzen

  Color getCategoryColor(int index) {
    return _categoryColors[index % _categoryColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Monatslimit zentriert und fett, €-Zeichen hinten
            Center(
              child: Column(
                children: [
                  Text(
                    '€${totalIncome.toStringAsFixed(2)}',  // Monatslimit mit Euro-Zeichen
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'to spend',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Platzhalter für zukünftige Statistik
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white!,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(child: Text('Statistik (Prozentuale Aufteilung)', textAlign: TextAlign.center)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final double spentRatio = category.spent / totalIncome;
                  final Color color = getCategoryColor(index);

                  final double remaining = category.limit - category.spent;
                  final bool isOverBudget = remaining < 0;
                  final Color balanceColor = isOverBudget ? Colors.red : Colors.green;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white, // Weißer Hintergrund für Kategorien
                        borderRadius: BorderRadius.circular(8), // Abgerundete Ecken
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(category.icon, color: color), // Kategorie-Icon mit individueller Farbe
                                  const SizedBox(width: 10),
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal[800],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Anzeige des verbleibenden Betrags (grün, wenn unter dem Limit)
                                  Text(
                                    '${isOverBudget ? "+" : "-"}${remaining.abs().toStringAsFixed(0)}€', // Anzeige von + oder - je nach Budget
                                    style: TextStyle(
                                      color: balanceColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              // Anzeige des Restbetrags auf der rechten Seite
                              Text(
                                '${remaining.abs().toStringAsFixed(0)}€ left of ${category.limit.toStringAsFixed(0)}€',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: spentRatio.clamp(0.0, 1.0),
                            backgroundColor: Colors.teal[100],
                            color: color, // Fortschrittsbalken mit individueller Farbe
                            minHeight: 8,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryData {
  final String name;
  final double limit;
  final double spent;
  final IconData icon;

  CategoryData({
    required this.name,
    required this.limit,
    required this.spent,
    required this.icon,
  });
}
