import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_management_app/backend/Category.dart';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';

class SavingPlan extends StatefulWidget {
  const SavingPlan({super.key});

  @override
  _SavingPlanState createState() => _SavingPlanState();
}

class _SavingPlanState extends State<SavingPlan> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Category> categories = [];
  String? _userId;

  double totalIncome = 0.0;

  // Methode zum Laden der Kategorien und Benutzerinformationen
  Future<void> _loadUserAndCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Kategorien für den Benutzer aus Firestore abrufen
        List<Category> userCategories = await _firestoreService.getUserCategories(user.uid);
        setState(() {
          _userId = user.uid;
          categories = userCategories;

          // Berechne totalIncome als Summe der Limits der Kategorien
          totalIncome = categories.fold(0.0, (sum, category) => sum + category.budgetLimit!);
        });
      } catch (e) {
        print('Fehler beim Abrufen der Kategorien: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserAndCategories();
  }

  // Berechne die Daten für das Balkendiagramm
  List<BarChartGroupData> _buildCategoryData() {
    List<BarChartGroupData> barGroups = [];
    for (var i = 0; i < categories.length; i++) {
      var category = categories[i];
      double percentage = (category.budgetLimit! / totalIncome) * 100; // Prozentualer Anteil
      barGroups.add(
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: percentage,  // Skalierung auf Prozent
            color: category.color, // Farbe der Kategorie
            width: 30,  // Breitere Balken (anpassbar)
            borderRadius: BorderRadius.circular(8),  // Ecken abrunden
          ),
        ]),
      );
    }
    return barGroups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Statischer Bereich oben (Budgetlimit in einer SliverAppBar)
          SliverAppBar(
            backgroundColor: Colors.white,
            pinned: true,
            elevation: 2,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          totalIncome.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '€',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'monatliches Budget',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Balkendiagramm anzeigen
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: categories.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceEvenly, // Mehr Platz zwischen den Balken
                    maxY: 100, // Maximaler Y-Wert für die Prozentanzeige
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false, // Keine Y-Beschriftung anzeigen
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,  // Kategorienamen unter dem Balken anzeigen
                          getTitlesWidget: (double value, TitleMeta meta) {
                            int index = value.toInt();
                            if (index < categories.length) {
                              return Text(
                                categories[index].name, // Kategorienname
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false), // Keine Border anzeigen
                    barGroups: _buildCategoryData(),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final category = categories[groupIndex];
                          final double percentage = (category.budgetLimit! / totalIncome) * 100;
                          return BarTooltipItem(
                            '${category.name}\n${percentage.toStringAsFixed(1)}%', // Tooltip mit Prozentwert
                            TextStyle(color: Colors.white), // Textfarbe des Tooltips
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Kategorienliste
          categories.isEmpty
              ? SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final category = categories[index];
                final double remaining = category.budgetLimit! - 0;
                final bool isOverBudget = remaining < 0;
                final Color balanceColor =
                isOverBudget ? Colors.red : Colors.green;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon und Kategoriename links
                            Row(
                              children: [
                                Icon(
                                  category.icon,
                                  color: category.color,
                                  size: 31.0, // Größeres Icon
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 18.0, // Größerer Text
                                  ),
                                ),
                              ],
                            ),
                            Spacer(), // Füllt den Platz zwischen den beiden Teilen
                            // Budgetanzeige oben rechts
                            Text(
                              '${remaining.abs().toStringAsFixed(0)}€ von ${category.budgetLimit}€ verfügbar',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14.0,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Bewertung (Good Job oder Budget überschritten)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end, // Nach rechts ausgerichtet
                          children: [
                            Icon(
                              isOverBudget ? Icons.warning : Icons.thumb_up,
                              color: isOverBudget ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOverBudget ? 'Budget überschritten!' : 'Good Job!',
                              style: TextStyle(
                                color: isOverBudget ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Fortschrittsanzeige
                        LinearProgressIndicator(
                          value: (category.budgetLimit! / totalIncome).clamp(0.0, 1.0),
                          backgroundColor: Colors.teal[100],
                          color: category.color,
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ),
                );

                  },
              childCount: categories.length,
            ),
          ),
        ],
      ),
    );
  }
}
