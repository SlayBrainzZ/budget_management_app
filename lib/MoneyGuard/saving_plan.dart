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
  List<double> combinedTransactions = [];


  Map<String, int> streakCounterDictionary = {};

  // Methode zum Laden der Kategorien und Benutzerinformationen
  Future<void> _loadUserAndCategories() async {
    final user = FirebaseAuth.instance.currentUser;

    // Falls user null ist, breche die Funktion ab
    if (user == null) {
      print("Kein angemeldeter Benutzer gefunden.");
      return;
    }

    setState(() {
      categories = [];
      remainingBudget = [];
    });

    try {
      // Nutzer-ID sicher abrufen
      _userId = user.uid;

      // Lade Kategorien mit sicherer User-ID
      List<Category> userCategories = await _firestoreService.getUserCategoriesWithBudget(_userId!);

      if (userCategories.isEmpty) {
        print("Keine Kategorien gefunden für den Benutzer.");
        setState(() {
          totalIncome = 0.0;
        });
        return;
      }

      // Lade kombinierte Transaktionen
      List<Future<double>> transactionFutures = userCategories.map((category) {
        return _firestoreService.getCurrentMonthCombinedTransactions(
          _userId!,
          category.id!,
          "null", // Account-ID hier optional anpassen
        );
      }).toList();

      // Warte auf alle Transaktionssummen
      List<double> spentAmounts = await Future.wait(transactionFutures);

      setState(() {
        categories = userCategories;

        // Berechne verbleibende Budgets und aktualisiere den Streak-Counter
        remainingBudget = List.generate(userCategories.length, (index) {
          double remaining = (userCategories[index].budgetLimit ?? 0) - spentAmounts[index];
          String categoryId = userCategories[index].id ?? "";

          // Aktualisiere den Streak-Counter
          if (remaining >= 0) {
            streakCounterDictionary[categoryId] = (streakCounterDictionary[categoryId] ?? 0) + 1;
          } else {
            streakCounterDictionary[categoryId] = 0;
          }

          return remaining;
        });

        // Gesamteinnahmen berechnen
        totalIncome = categories.fold(0.0, (sum, category) => sum + (category.budgetLimit ?? 0));
      });

      // Prüfe Budgetüberschreitungen und sende Benachrichtigungen
      for (int index = 0; index < userCategories.length; index++) {
        double remaining = (userCategories[index].budgetLimit ?? 0) - spentAmounts[index];
        String categoryId = userCategories[index].id ?? "";

        if (remaining < 0) {
          bool alreadyExists = await _firestoreService.doesNotificationExist(
            _userId!,
            categoryId,
            "budget_overflow",
          );
          //print("der Wert von bool ist $alreadyExists");

          if (!alreadyExists) {
            await _firestoreService.createNotification(
              _userId!,
              "Budget für ${userCategories[index].name} überschritten um ${(remaining * -1).toStringAsFixed(2)}€!",
              "budget_overflow",
              categoryId: categoryId,
            );
          }
        }
      }


    } catch (e) {
      print('Fehler beim Laden der Kategorien: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Laden der Daten")),
      );
    }
  }

  /*Future<void> _loadUserAndCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      categories = [];
      remainingBudget = [];
    });

    try {
      _userId = user.uid;

      // Daten aus Firestore abrufen
      Map<String, dynamic> data = await _firestoreService.fetchCategoriesAndTransactions(_userId!);
      List<Category> userCategories = data["categories"];
      List<double> spentAmounts = data["spentAmounts"];

      setState(() {
        categories = userCategories;

        // Berechne verbleibende Budgets
        remainingBudget = List.generate(userCategories.length, (index) {
          double remaining = (userCategories[index].budgetLimit ?? 0) - spentAmounts[index];
          return remaining;
        });

        // Gesamteinnahmen berechnen
        totalIncome = categories.fold(0.0, (sum, category) => sum + (category.budgetLimit ?? 0));
      });

    } catch (e) {
      print('Fehler beim Laden der Kategorien: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Laden der Daten")),
      );
    }
  }*/











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
      body: CustomScrollView(
        slivers: [
          // Statischer Bereich oben (Budgetlimit in einer SliverAppBar)
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.onSecondary,
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
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            //fontFamily: 'Roboto,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '€',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            //fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'monatliches Budget',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        //fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Balkendiagramm oder Hinweis anzeigen
          SliverToBoxAdapter(
            child: categories.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            )
                : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSecondary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(right: 20, left: 5, bottom: 10, top: 10),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceEvenly, // Mehr Platz zwischen den Balken
                    maxY: 100, // Maximaler Y-Wert für die Prozentanzeige
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false, // Rechte Achse deaktivieren
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, // Aktiviere die linke Achse
                          reservedSize: 40, // Vergrößere den Platz links
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%', // Beschriftung für linke Achse
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false, // Kategorienamen unter dem Balken anzeigen
                          getTitlesWidget: (double value, TitleMeta meta) {
                            int index = value.toInt();
                            if (index < categories.length) {
                              return Text(
                                categories[index].name, // Kategorienname
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  fontFamily: 'Roboto',
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                        show: true,
                        border: const Border(
                      left: BorderSide(
                          color: Colors.black,
                          width: 1), // Linke Linie
                      bottom: BorderSide
                        (color: Colors.black,
                          width: 1), // Untere Linie
                      top: BorderSide.none, // Keine obere Linie
                      right: BorderSide.none, // Keine rechte Linie
                    )), // Keine Border anzeigen
                    barGroups: _buildCategoryData(),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.2) // Helle Linien im Dark Mode
                              : Colors.black.withOpacity(0.1), // Dunkle Linien im Light Mode
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (BarChartGroupData group) {
                          return Theme.of(context).colorScheme.onSecondary;
                        },
                        tooltipBorder: BorderSide(
                          color: Colors.black, // Farbe des Randes
                          width: 1, // Dicke des Randes
                        ),
                        tooltipPadding: EdgeInsets.all(8), // Abstand innerhalb des Tooltips
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final category = categories[groupIndex];
                          final double percentage = (category.budgetLimit! / totalIncome) * 100;
                          return BarTooltipItem(
                            '${category.name}\n'
                                '📊 Anteil: ${percentage.toStringAsFixed(1)}%\n'
                                '💰 Budget: ${category.budgetLimit!}€',
                            TextStyle(
                              color: category.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              /*foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 2 // Dicke der Umrandung
                                ..color = Colors.white, // Farbe der Umrandung
                            */),
                          );
                        },
                      ),
                    ),

                  ),
                ),
              ),
            ),
          ),

          // Kategorienliste oder Hinweis anzeigen
          categories.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Noch keine Kategorien vorhanden! \n Bitte lege ein Budget für deine Kategorien fest,\n um loszulegen :)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final category = categories[index];
                final remaining = remainingBudget[index];
                final spentAmount = (category.budgetLimit ?? 0) - remaining;
                final spentPercent = 1 - (remaining / (category.budgetLimit ?? 1)).clamp(0.0, 1.0);

                    // Neue Anzeige-Bedingung
                    String spentMessage;
                    if (remaining < 0) {
                      spentMessage = "${(spentAmount).toStringAsFixed(2)}€ ausgegeben";
                    } else if (remaining == 0) {
                      spentMessage = "${(spentAmount).toStringAsFixed(2)}€ ausgegeben";
                    } else {
                      spentMessage = "${spentAmount.toStringAsFixed(2)}€ ausgegeben";
                    }


                    // Bedingte Nachricht je nach Budgetstatus
                String statusMessage = remaining < 0
                    ? "Limit um ${(remaining * -1).toStringAsFixed(2)}€ überschritten!"
                    : remaining == 0
                    ? "Limit optimal eingehalten!"
                    : remaining / (category.budgetLimit ?? 1) < 0.05
                    ? "Achtung, Limit bald überschritten!"
                    : "Super! ${remaining.toStringAsFixed(2)}€ verfügbar";

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSecondary,
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
                              shadows: [],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "${category.name}: ${category.budgetLimit.toString()}€"  ?? "Unbekannt",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                  /*foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 2 // Dicke der Umrandung
                                    ..color = Colors.white, // Farbe der Umrandung
                                */),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Anzeige der verbleibenden Budgetanzeige
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                spentMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  fontFamily: 'Roboto',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),

                            ),
                            const SizedBox(width: 10),
                            Text(
                              statusMessage,
                              style: TextStyle(
                                fontSize: 12,
                                color: remaining < 0
                                    ? Colors.red
                                    : Colors.green,
                                fontFamily: 'Roboto',
                                /*foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 2 // Dicke der Umrandung
                                  ..color = Colors.white, // Farbe der Umrandung

                              */),
                            ),
                          ],
                        ),




                        const SizedBox(height: 8),

                        // LinearProgressIndicator
                        LinearProgressIndicator(
                          value: spentPercent, // Dieser Wert wird nun angepasst
                          backgroundColor: Theme.of(context).colorScheme.onSecondary,
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
