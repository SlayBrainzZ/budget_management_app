import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_management_app/backend/Category.dart';
import 'package:budget_management_app/backend/Transaction.dart';
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
  List<Transaction> monthlyTransactionCategoryAll = [];
  List<double> remainingBudget = []; // Liste, um verbleibende Budgets für jede Kategorie zu speichern

  // Methode zum Laden der Kategorien und Benutzerinformationen
  Future<void> _loadUserAndCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      categories = [];
      remainingBudget = [];
    });

    try {
      List<Category> userCategories = await _firestoreService.getUserCategoriesWithBudget(user.uid);

      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime.utc(now.year, now.month, 1);
      DateTime endOfMonth = DateTime.utc(now.year, now.month + 1, 0);

      List<Future<double>> transactionFutures = [];
      for (final userCategory in userCategories) {
        transactionFutures.add(
          _firestoreService.getTransactionsByDateRangeAndCategory(
            user.uid,
            userCategory.id!,
            startOfMonth,
            endOfMonth,
          ).then((transactions) async {
            // Summiere die Beträge und stelle sicher, dass jeder Betrag ein finaler 'double' ist
            double sum = 0.0;
            for (final transaction in transactions) {
              final amount = transaction.amount is int
                  ? (transaction.amount as int).toDouble()
                  : transaction.amount ?? 0.0;
              sum += amount;
            }
            return sum;
          }),
        );
      }

      List<double> spentAmounts = await Future.wait(transactionFutures);

      setState(() {
        _userId = user.uid;
        categories = userCategories;
        remainingBudget = List.generate(
          userCategories.length,
              (index) => (userCategories[index].budgetLimit ?? 0) - spentAmounts[index],
        );
        totalIncome = categories.fold(
          0.0,
              (sum, category) => sum + (category.budgetLimit ?? 0),
        );
      });
    } catch (e) {
      print('Fehler beim Laden der Kategorien: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Laden der Daten")),
      );
    }

  }







// Berechne die Daten für das Balkendiagramm
  List<BarChartGroupData> _buildCategoryData() {
    List<BarChartGroupData> barGroups = [];

    for (var i = 0; i < categories.length; i++) {
      var category = categories[i];

      // Sicherstellen, dass category.budgetLimit und totalIncome gültig sind
      double percentage = 0;
      if (totalIncome > 0 && category.budgetLimit != null) {
        percentage = (category.budgetLimit! / totalIncome) * 100;
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: percentage, // Nur wenn gültig berechnet
              color: category.color ?? Colors.blue, // Default-Farbe, falls null
              width: 30,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      );
    }

    return barGroups;
  }



  @override
  void initState() {
    super.initState();
    _loadUserAndCategories();
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
                          showTitles: false,  // Kategorienamen unter dem Balken anzeigen
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
                final remaining = remainingBudget[index];
                final spentPercent = 1 - (remaining / (category.budgetLimit ?? 1)).clamp(0.0, 1.0);

                // Bedingte Nachricht je nach Budgetstatus
                String statusMessage = remaining < 0
                    ? "Limit überschritten!"
                    : remaining / (category.budgetLimit ?? 1) < 0.05
                    ? "Achtung, Limit bald überschritten!"
                    : "Super!";


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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Icon und Kategoriename auf der linken Seite
                            Icon(
                              category.icon,
                              color: category.color,
                              size: 31.0,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                category.name ?? "Unbekannt",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Nachricht rechts oben im Widget
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  statusMessage,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: remaining < 0 ? Colors.red : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Anzeige der verbleibenden Budgetanzeige
                        Text(
                          '${remaining.toStringAsFixed(2)}€ von ${category.budgetLimit?.toStringAsFixed(2)}€ verfügbar',
                          style: TextStyle(
                            fontSize: 14,
                            color: remaining < 0 ? Colors.red : Colors.green,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // LinearProgressIndicator
                        LinearProgressIndicator(
                          value: spentPercent, // Dieser Wert wird nun angepasst
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
