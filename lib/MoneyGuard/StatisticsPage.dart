//import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_management_app/backend/Category.dart';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'home_page.dart';
import 'package:budget_management_app/backend/BankAccount.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {

  String? _userId;
  String selectedAmountType = 'Gesamtbetrag';
  String selectedTimeCategory = 'Monat';
  String selectedTimeImportance = 'Monat';
  //String selectedYear = '2025';
  String selectedYear = DateTime.now().year.toString();

  String selectedMonth = 'Monat';
  final List<int> availableYears = List.generate(
      100, (index) => 2000 + index); // letze 20 und nächste 80 jare
  double urgentExpenses = 0.0;
  double nonUrgentExpenses = 0.0;
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();
  String selectedAccount = 'Gesamtübersicht'; // Standardmäßig "Gesamtübersicht"
  String selectedAccountID = "";
  List<LineChartBarData>? cachedYearlyLineChartData;
  List<double>? cachedImportantChartData;
  List<LineChartBarData>? cachedCategoryLineChartData;
  Map<String, LineChartData> chartCache = {};
  List<Category> categories = [];
  List<BankAccount> allBankAccounts = [];
  double lastMonthBalance = 0.0;
  Map<String, double> monthlyBalanceList = {};
  bool importedTypeOfBankAccount = false;


  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    await _loadCategories();
    await _loadBankAccounts();
    setState(() {
      selectedAccount = 'Gesamtübersicht';
      selectedAccountID = "null";
      importedTypeOfBankAccount = false;
    });

    await _loadAndSetExpenses(selectedTimeImportance);
    await loadBigChartBarData(selectedYear, selectedMonth);

    print("NAME UND ID: $selectedAccount, $selectedAccountID, $importedTypeOfBankAccount");
  }



  Future<void> _reloadAllStatistics() async {
    try {
      await _loadCategories();
      await _loadAndSetExpenses(selectedTimeImportance);
      await loadBigChartBarData(selectedYear, selectedMonth);




    } catch (e) {
      print('Fehler beim Aktualisieren der Statistiken: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Statistiken')),
      );
    }
  }

  Future<User?> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      return user;
    } catch (e) {
      print('Fehler beim Laden des Users: ${e.toString()}');
      return null;
    }
  }
  Future<void> _loadCategories() async {
    print("Entering loadcategories");
    final user = await _loadUser();
    if (user == null) {
      print('Kein Benutzer gefunden.');
      return;
    }
    setState(() {
      categories = [];
    });

    try {
      List<Category> userCategories = await _firestoreService.getUserCategories(user.uid);
      if (userCategories.isEmpty) {
        print("Keine Kategorien gefunden für den Benutzer.");
        return;
      }

      setState(() {
        _userId = user.uid;
        categories = userCategories;
      });
    } catch (e) {
      print('Fehler beim Laden der Kategorien: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Laden der Daten")),
      );
    }
    //print("Leaving loadcategories");
  }
  Future<void> _loadBankAccounts() async {
    final user = await _loadUser();
    if (user == null) {
      print('Kein Benutzer gefunden.');
      return;
    }
    setState(() {
      allBankAccounts = [];
    });

    try {
      final userBankAccounts = await _firestoreService.getUserBankAccounts(user.uid);
      if (userBankAccounts.isEmpty) {
        print("Keine Kategorien gefunden für den Benutzer.");
        return;
      }

      setState(() {
        //_userId = user.uid;
        allBankAccounts = userBankAccounts;
      });
    } catch (e) {
      print('Fehler beim Laden der UserAccounts: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Laden der Daten")),
      );
    }
  }
  Future<void> _loadExpenses(String chosenTime) async {
    final user = await _loadUser();
    if (user == null) {
      print("Kein Benutzer gefunden.");
      return;
    }

    DateTime today = DateTime.now();
    DateTime startdate;
    DateTime enddate;
    Map<String, double> expenses = {"Dringend": 0.0, "Nicht dringend": 0.0}; // Standardwerte setzen

    if (chosenTime == "Woche") {
      startdate = today.subtract(Duration(days: today.weekday - 1)); // Montag
      enddate = startdate.add(Duration(days: 6)); // Sonntag
    } else if (chosenTime == "Monat") {
      startdate = DateTime(today.year, today.month, 1); // Erster Tag des Monats
      enddate = DateTime(today.year, today.month + 1, 0); // Letzter Tag des Monats
    } else {
      print("Ungültiger Zeitraum angegeben.");
      return;
    }

    try {
      expenses = await _firestoreService.fetchUrgentAndNonUrgentExpenses(user.uid, startdate, enddate, selectedAccountID) ?? {"Dringend": 0.0, "Nicht dringend": 0.0};

      setState(() {
        urgentExpenses = expenses["Dringend"] ?? 0.0;
        nonUrgentExpenses = expenses["Nicht dringend"] ?? 0.0;
      });
    } catch (e) {
      print("Fehler beim Laden der Ausgaben: $e");
    }
  }

  Future<void> _loadAndSetExpenses(String chosenTime) async {
    await _loadExpenses(chosenTime);
    setState(() {}); // Aktualisiert den Zustand nach dem Laden
  }
  Future<void> loadBigChartBarData(String chosenYear, String chosenMonth) async {
    try {
      if (chosenMonth == 'Monat') {
        // Zeige den Jahresverlauf
        if (chartCache.containsKey(chosenYear)) {
          setState(() {
            cachedYearlyLineChartData = chartCache[chosenYear]?.lineBarsData;
          });
        } else {
          // Berechne die Jahresdaten


          List<List<FlSpot>> FlSpotListList = await generateSpotsforYear(chosenYear, chosenMonth, "null");

          LineChartBarData einnahmeDaten = await defineLineChartBarData(Colors.greenAccent.shade700, chosenYear, "Monat", "Einnahme", FlSpotListList[0]);
          LineChartBarData ausgabeDaten = await defineLineChartBarData(Colors.redAccent.shade700, chosenYear, "Monat", "Ausgabe", FlSpotListList[1]);
          LineChartBarData gesamtDaten = await defineLineChartBarData(Colors.blueAccent.shade700, chosenYear, "Monat", "null", FlSpotListList[2]);


          setState(() {
            cachedYearlyLineChartData = [einnahmeDaten, ausgabeDaten, gesamtDaten];
            chartCache[chosenYear] = LineChartData(
              lineBarsData: cachedYearlyLineChartData!,
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              titlesData: FlTitlesData(),
              lineTouchData: LineTouchData(handleBuiltInTouches: true),
            );
          });
        }
      } else {
        // Zeige nur den Verlauf für den bestimmten Monat
        if (chartCache.containsKey('$chosenYear-$chosenMonth')) {
          setState(() {
            cachedYearlyLineChartData =
                chartCache['$chosenYear-$chosenMonth']?.lineBarsData;
          });
        } else {
          List<FlSpot> FlSpotlist1 = await generateSpotsforMonth(
              chosenYear, chosenMonth, "Einnahme");
          List<FlSpot> FlSpotlist2 = await generateSpotsforMonth(
              chosenYear, chosenMonth, "Ausgabe");
          List<FlSpot> FlSpotlist3 = await generateSpotsforMonth(
              chosenYear, chosenMonth, "null");

          LineChartBarData einnahmeDaten = await defineLineChartBarData(
              Colors.greenAccent.shade700, chosenYear, chosenMonth, "Einnahme", FlSpotlist1);
          LineChartBarData ausgabeDaten = await defineLineChartBarData(
              Colors.redAccent.shade700, chosenYear, chosenMonth, "Ausgabe", FlSpotlist2);
          LineChartBarData gesamtDaten = await defineLineChartBarData(
              Colors.blueAccent.shade700, chosenYear, chosenMonth, "null", FlSpotlist3);

          setState(() {
            cachedYearlyLineChartData = [einnahmeDaten, ausgabeDaten, gesamtDaten];
            chartCache['$chosenYear-$chosenMonth'] = LineChartData(
              lineBarsData: cachedYearlyLineChartData!,
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              titlesData: FlTitlesData(),
              lineTouchData: LineTouchData(handleBuiltInTouches: true),
            );
          });
        }
      }
      print("leaving bigchartdata");
    } catch (e) {
      print('Fehler beim Laden der Diagrammdaten: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler beim Laden der Diagrammdaten")));
    }
  }
  Future<LineChartData> loadCategoryChartData(String category, String selectedTimeCategory) async {
    List<FlSpot> categoryList = await generateSpotsForCategory(category, selectedTimeCategory);

    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          preventCurveOverShooting: true,
          isCurved: true,
          color: Colors.redAccent.shade700,
          curveSmoothness: 0.35,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (FlSpot spot, double xPercentage, LineChartBarData bar, int index, {double? size}) {
              return FlDotCirclePainter(
                radius: 3, // Größe der Dots (Standard ist 4)
                color: bar.color ?? Colors.black, // Nutzt die Linienfarbe
                strokeWidth: 1, // Randdicke
                strokeColor: Colors.white, // Randfarbe der Dots
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
          spots: categoryList,
        ),
      ],
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: true,
        border: const Border(
          left: BorderSide(color: Colors.black, width: 1), // Linke Linie
          bottom: BorderSide(color: Colors.black, width: 1), // Untere Linie
          top: BorderSide.none, // Keine obere Linie
          right: BorderSide.none, // Keine rechte Linie
        ),
      ),
      titlesData: categoryChartTitlesDataYear,
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (LineBarSpot spot) {
            return Color.fromARGB(180, 120, 120, 120);
          },
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              Map<int, String> lineLabels = {
                0: "Ausg."
              };
              String label = lineLabels[spot.barIndex] ?? "Wert";
              return LineTooltipItem(
                "$label: ${spot.y.toStringAsFixed(2)} €", // Individueller Text
                TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: spot.bar.color ?? Colors.black,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }




  Future<List<FlSpot>> generateSpotsforMonth(String chosenYear, chosenMonth, String type) async {
    final user = await _loadUser();
    if (user == null) {
      print("Kein Benutzer gefunden.");
      return [];
    }
    double x = 1;
    List<FlSpot> FlSpotlist = [];
    List<double> data = [];

    try {
      print(monthlyBalanceList);
      lastMonthBalance = findLastMonthBalance(monthlyBalanceList, chosenYear, chosenMonth);
      print("lastMonthBalance nach Monatsangabe: $lastMonthBalance");
      if(importedTypeOfBankAccount == false) {
        if (selectedAccountID == "null") {

          data = await _firestoreService.calculateMonthlyCombinedSpendingByDay(user.uid, type, chosenYear, chosenMonth, lastMonthBalance, selectedAccountID);

        } else {

          data = await _firestoreService.calculateMonthlySpendingByDay(user.uid, type, chosenYear, chosenMonth, lastMonthBalance, selectedAccountID);

        }
      }
      else if (importedTypeOfBankAccount == true){
        data = await _firestoreService.calculateMonthlyImportedSpendingByDay(user.uid, type, chosenYear, chosenMonth, lastMonthBalance, selectedAccountID);
      }


      for (double y in data) {
        FlSpotlist.add(FlSpot(x, y));
        x = x + 1;
      }
    } catch (e) {
      print("Fehler beim Laden der Ausgaben für Monat: ${e.toString()}");
    }
    return FlSpotlist;
  }
  Future<List<List<FlSpot>>> generateSpotsforYear(String chosenYear, chosenMonth, String type) async {
    final user = await _loadUser();
    if (user == null) {
      print("Kein Benutzer gefunden.");
      return [];
    }

    List<List<FlSpot>> FlSpotListList = [];

    List<double> data = [];
    Map<String, double> monthlySpending = {};
    List<Map<String, double>> monthlyTransactions = [];


    try {
      if (chosenMonth == "Monat") {
        if(importedTypeOfBankAccount == false) {
          if (selectedAccountID == "null"){
            monthlyTransactions = await _firestoreService.combineYearlyCombinedSpendingByMonth(user.uid, chosenYear, selectedAccountID);
          } else {
            monthlyTransactions = await _firestoreService.calculateYearlySpendingByMonth2(user.uid, chosenYear, selectedAccountID);
          }
        }
        else if (importedTypeOfBankAccount == true){
          monthlyTransactions = await _firestoreService.calculateYearlyImportedSpendingByMonth(user.uid, chosenYear, selectedAccountID);
        }


        for (int j = 0; j <= 2; j++) {
          Map<String, double> monthlySpending = monthlyTransactions[j];
          List<FlSpot> FlSpotlist = [];
          for (var entry in monthlySpending.entries) {
            String monthKey = entry.key; // Beispiel: "2024-01"
            DateTime dateTime = DateTime.parse(monthKey + "-01");
            double y = entry.value;
            FlSpotlist.add(FlSpot(double.parse(dateTime.month.toString()), y));
          }
          FlSpotListList.add(FlSpotlist);
        }

        monthlySpending = monthlyTransactions[2];
        monthlyBalanceList.addAll(monthlySpending);
        print(monthlyBalanceList);
      }
    } catch (e) {
      print("Fehler beim Laden der Ausgaben für ein Jahr: ${e.toString()}");
    }
    return FlSpotListList;
  }
  Future<List<FlSpot>> generateSpotsForCategory(String category, String selectedTimeCategory) async {
    final user = await _loadUser();
    if (user == null) {
      print("Kein Benutzer gefunden.");
      return [];
    }

    Map<int, double> categoryTransactions = {};
    List<FlSpot> categoryList = [];

    try {

      if (importedTypeOfBankAccount == false) {

        if (selectedAccountID == "null"){
          if (selectedTimeCategory == "Monat") {

            categoryTransactions = await _firestoreService.getCurrentMonthCombinedTransactionsByDateRangeAndCategory(user.uid, category, selectedAccountID);

          } else if (selectedTimeCategory == "Jahr") {

            categoryTransactions = await _firestoreService.calculateYearlyCombinedCategoryExpenses(user.uid, category, selectedYear, selectedAccountID);

          } else {
            print("Keine Periode für Kategorie ausgwählt");
          }

        } else {
            if (selectedTimeCategory == "Monat") {

              categoryTransactions = await _firestoreService.getCurrentMonthTransactionsByDateRangeAndCategory(user.uid, category, selectedAccountID);

            } else if (selectedTimeCategory == "Jahr") {

              categoryTransactions = await _firestoreService.calculateYearlyCategoryExpenses(user.uid, category, selectedYear, selectedAccountID);

            } else {
              print("Keine Periode für Kategorie ausgwählt");
            }
        }

      } else if (importedTypeOfBankAccount == true){

          if (selectedTimeCategory == "Monat") {
            categoryTransactions =
            await _firestoreService.getCurrentMonthImportedTransactionsByDateRangeAndCategory(user.uid, category, selectedAccountID);
          }
          else if (selectedTimeCategory == "Jahr") {
            categoryTransactions =
            await _firestoreService.calculateYearlyCategoryImportedExpenses(user.uid, category, selectedYear, selectedAccountID);
          }
          else {
            print("Keine Periode für Kategorie ausgwählt");
          }

      } else {
        print("importedTypeofBankAcout unklar");
      }
      //print(categoryTransactions); die transactions jeder einezelenen kategorrie!

      categoryTransactions.forEach((day, amount) {
        categoryList.add(FlSpot(day.toDouble(), amount));
      });

      categoryList.sort((a, b) => a.x.compareTo(b.x));
    } catch (e) {
      print("Fehler beim Laden der Kategoriedaten: ${e.toString()}");
    }

    return categoryList;
  }




  Future<LineChartBarData> defineLineChartBarData(Color color, String chosenYear, String chosenMonth, String type, List<FlSpot> spotsList) async {
    return LineChartBarData(
      //show: false,
      isCurved: true,
      //shadow: Shadow(color: Colors.black),
      curveSmoothness: 0.35,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (FlSpot spot, double xPercentage, LineChartBarData bar, int index, {double? size}) {
          return FlDotCirclePainter(
            radius: 4, // Größe der Dots (Standard ist 4)
            color: bar.color ?? Colors.black, // Nutzt die Linienfarbe
            strokeWidth: 1, // Randdicke
            strokeColor: Colors.white, // Randfarbe der Dots
          );
        },
      ),
      belowBarData: BarAreaData(show: false),
      spots: spotsList,
    );
  }
  PieChartData definePiechartData() {
    final summary = calculateExpenseSummary();

    if (summary['totalExpenses'] == 0) {
      return PieChartData(
        sections: [
          PieChartSectionData(
            title: "Keine Daten",
            value: 1, // Dummy-Wert, damit das Diagramm nicht crasht
            color: Colors.grey,
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 50,
      );
    }

    return PieChartData(
      sections: [
        PieChartSectionData(
          title: "Dringend (${summary['urgentPercentage'].toStringAsFixed(1)}%)",
          value: urgentExpenses,
          color: Colors.red,
        ),
        PieChartSectionData(
          title: "Nicht dringend (${summary['nonUrgentPercentage'].toStringAsFixed(1)}%)",
          value: nonUrgentExpenses,
          color: Colors.blue,
        ),
      ],
      sectionsSpace: 2,
      centerSpaceRadius: 50,
    );
  }

  Widget buildPieChart() {
    final summary = calculateExpenseSummary();
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(definePiechartData()),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Gesamt',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${summary['totalExpenses'].toStringAsFixed(2)} €',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
  LineChartData get chartData { //getterfunktion für die große Statistik
    if (cachedYearlyLineChartData == null || cachedYearlyLineChartData!.isEmpty) {
      return LineChartData(
        lineBarsData: [],
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      );
    }
    return LineChartData(

      //minY: 1, // Bereich unten erweitern
      //maxY: 10000, // Bereich oben erweitern, damit "DEZ" nicht so nah am Rand ist

      lineBarsData: cachedYearlyLineChartData!,
      gridData: FlGridData(show: true),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          left: BorderSide(color: Colors.black, width: 1), // Linke Linie
          bottom: BorderSide(color: Colors.black, width: 1), // Untere Linie
          top: BorderSide.none, // Keine obere Linie
          right: BorderSide.none, // Keine rechte Linie
    ),
    ),
      titlesData: bigChartTitlesDataYear,
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (LineBarSpot spot) {
            return Color.fromARGB(180, 120, 120, 120);
          },
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              Map<int, String> lineLabels = {
                0: "Einn.",
                1: "Ausg.",
                2: "Bilanz"
              };
              String label = lineLabels[spot.barIndex] ?? "Wert";
              return LineTooltipItem(
                "$label: ${spot.y.toStringAsFixed(2)} €", // Individueller Text
                TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: spot.bar.color ?? Colors.black,
                ),
              );
            }).toList();
          },
        ),
      ),

    );
  }




  FlTitlesData get categoryChartTitlesDataYear => FlTitlesData(
    bottomTitles: AxisTitles(
      sideTitles: categoryBottomTitles
    ),
    rightTitles:  AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    topTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true, // Aktiviere die linke Achse
        reservedSize: 40, // Vergrößere den Platz links
        getTitlesWidget: (value, meta) {
          return Text(
            '${value.toInt()}€', // Beschriftung für linke Achse
            style: const TextStyle(fontSize: 10),
          );
        },
      ),
    ),
  );
  FlTitlesData get bigChartTitlesDataYear => FlTitlesData(
    bottomTitles: AxisTitles(
      sideTitles: bottomTitles,
    ),
    rightTitles:  AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    topTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true, // Aktiviere die linke Achse
        reservedSize: 40, // Vergrößere den Platz links
        getTitlesWidget: (value, meta) {
          return Text(
            '${value.toInt()}€', // Beschriftung für linke Achse
            style: const TextStyle(fontSize: 10),
          );
        },
      ),
    ),
  );
  SideTitles get bottomTitles => SideTitles(
    showTitles: true,
    reservedSize: 25,
    interval: 1,
    getTitlesWidget: bottomTitleWidgets,
  );
  SideTitles get categoryBottomTitles => SideTitles(
    showTitles: true, // Aktiviere die linke Achse
    reservedSize: 25,
    interval: 1,
    getTitlesWidget: categoryBottomTitleWidgets
  );
  Widget categoryBottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      //fontWeight: FontWeight.bold,
      fontSize: 11,
    );
    Widget text;
    if (selectedTimeCategory == "Jahr") {
      switch (value.toInt()) {
        case 1:
          text = const Text('JAN', style: style);
          break;
        case 2:
          text = const Text('FEB', style: style);
          break;
        case 3:
          text = const Text('MÄR', style: style);
          break;
        case 4:
          text = const Text('APR', style: style);
          break;
        case 5:
          text = const Text('MAI', style: style);
          break;
        case 6:
          text = const Text('JUN', style: style);
          break;
        case 7:
          text = const Text('JUL', style: style);
          break;
        case 8:
          text = const Text('AUG', style: style);
          break;
        case 9:
          text = const Text('SEP', style: style);
          break;
        case 10:
          text = const Text('OKT', style: style);
          break;
        case 11:
          text = const Text('NOV', style: style);
          break;
        case 12:
          text = const Text('DEZ', style: style);
          break;
        default:
          text = const Text('');
          break;
      }
    } else {
      switch (value.toInt()) {
        case 5:
          text = Text("${value.toString()}.${DateTime.now().month}", style: style);
          break;
        case 10:
          text = Text("${value.toString()}.${DateTime.now().month}", style: style);
          break;
        case 15:
          text = Text("${value.toString()}.${DateTime.now().month}", style: style);
          break;
        case 20:
          text = Text("${value.toString()}.${DateTime.now().month}", style: style);
          break;
        case 25:
          text = Text("${value.toString()}.${DateTime.now().month}", style: style);
          break;
        case 30:
          text = Text("${value.toString()}.${DateTime.now().month}", style: style);
        default:
          text = const Text('');
          break;
      }
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: text,
    );
  }
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      //fontWeight: FontWeight.bold,
      fontSize: 11,
    );
    Widget text;
    if (selectedMonth == "Monat") {
      switch (value.toInt()) {
        case 1:
          text = const Text('JAN', style: style);
          break;
        case 2:
          text = const Text('FEB', style: style);
          break;
        case 3:
          text = const Text('MÄR', style: style);
          break;
        case 4:
          text = const Text('APR', style: style);
          break;
        case 5:
          text = const Text('MAI', style: style);
          break;
        case 6:
          text = const Text('JUN', style: style);
          break;
        case 7:
          text = const Text('JUL', style: style);
          break;
        case 8:
          text = const Text('AUG', style: style);
          break;
        case 9:
          text = const Text('SEP', style: style);
          break;
        case 10:
          text = const Text('OKT', style: style);
          break;
        case 11:
          text = const Text('NOV', style: style);
          break;
        case 12:
          text = const Text('DEZ', style: style);
          break;
        default:
          text = const Text('');
          break;
      }
    } else {
      switch (value.toInt()) {
        case 5:
          text = Text("${value.toString()}.${selectedMonth}", style: style);
          break;
        case 10:
          text = Text("${value.toString()}.${selectedMonth}", style: style);
          break;
        case 15:
          text = Text("${value.toString()}.${selectedMonth}", style: style);
          break;
        case 20:
          text = Text("${value.toString()}.${selectedMonth}", style: style);
          break;
        case 25:
          text = Text("${value.toString()}.${selectedMonth}", style: style);
          break;
        case 30:
          text = Text("${value.toString()}.${selectedMonth}", style: style);
        default:
          text = const Text('');
          break;
      }
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: text,
    );
  }




  double findLastMonthBalance(Map<String, double> data, String chosenYear, String chosenMonth) {
    // Startwert für das vorherige Monatsguthaben
    double lastMonthBalance = 0.0;

    // Berechne den Monat vor dem gewählten Monat
    int currentMonth = int.parse(chosenMonth);

    int previousMonth = currentMonth - 1;

    String previousYear = chosenYear;

    // Wenn der aktuelle Monat Januar ist, wechsel zum Dezember des Vorjahres
    if (previousMonth == 0) {
      previousMonth = 12;
      previousYear = (int.parse(chosenYear) - 1).toString();
    }

    // Formatiere den Schlüssel für den vorherigen Monat (z. B. "2023-12")
    String previousMonthKey = "$previousYear-${previousMonth.toString().padLeft(
        2, '0')}";

    // Überprüfen, ob der Schlüssel existiert
    if (data.containsKey(previousMonthKey)) {
      lastMonthBalance = data[previousMonthKey]!;
      print("Vorheriger Monat gefunden: $previousMonthKey, Guthaben: $lastMonthBalance");
    } else {
      print("Kein Guthaben für den vorherigen Monat $previousMonthKey gefunden, weil er mit ${data} nicht übereinstimt.");
      print("previousMonthKey: $previousMonthKey");
      print("Der Typ lautet ${previousMonthKey.runtimeType} ");
      print("Der erste Schlüssel von data ist: ${data.keys.first}");
      print("Der Typ des ersten Schlüssels: ${data.keys.first.runtimeType}");
    }

    return lastMonthBalance;
  }
  Map<String, dynamic> calculateExpenseSummary() {
    double totalExpenses = urgentExpenses + nonUrgentExpenses;

    double urgentPercentage =
    totalExpenses == 0 ? 0 : (urgentExpenses / totalExpenses) * 100;
    double nonUrgentPercentage =
    totalExpenses == 0 ? 0 : (nonUrgentExpenses / totalExpenses) * 100;

    return {
      'totalExpenses': totalExpenses,
      'urgentPercentage': urgentPercentage,
      'nonUrgentPercentage': nonUrgentPercentage,
    };
  }
  void _showYearPicker(BuildContext context) {int initialYearIndex = availableYears.indexOf(int.parse(selectedYear));
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300, // Erhöhe die Höhe des Containers
          child: CupertinoPicker(
            itemExtent: 50.0, // Erhöht die Höhe der Picker-Elemente
            scrollController: FixedExtentScrollController(
                initialItem: initialYearIndex),
            onSelectedItemChanged: (int index) {
              setState(() {
                selectedYear = availableYears[index].toString();
                selectedMonth = "Monat";
                loadBigChartBarData(selectedYear, selectedMonth);
              });
            },
            children: List<Widget>.generate(availableYears.length, (index) {
              return Center(
                child: Text(availableYears[index].toString()),
              );
            }),
          ),
        );
      },
    );
  }
  void _showMonthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300, // Höhe des Containers
          child: CupertinoPicker(
            backgroundColor: Colors.white,
            itemExtent: 50.0,
            // Höhe jedes Elements
            scrollController: FixedExtentScrollController(
              initialItem: selectedMonth == "Monat" ? 0 : int.parse(
                  selectedMonth),
            ),
            onSelectedItemChanged: (int index) {
              setState(() {
                selectedMonth =
                index == 0 ? "Monat" : (index).toString().padLeft(2, '0');
                loadBigChartBarData(selectedYear, selectedMonth);
              });
            },
            children: [
              Center(child: Text("Monat",
                  style: TextStyle(fontSize: 18, color: Colors.black))),
              // Standard "Monat" als ersten Eintrag
              ...List.generate(12, (index) =>
                  Center(child: Text((index + 1).toString().padLeft(2, '0'),
                      style: TextStyle(fontSize: 18, color: Colors.black)))),
              // Monatszahlen
            ],
          ),
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Konto:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(width: 40),

                  DropdownButton<String>(
                    value: allBankAccounts.any((account) => account.id == selectedAccount)
                        ? selectedAccount
                        : 'Gesamtübersicht', // Standardwert als Fallback

                    items: [
                      DropdownMenuItem(
                        value: 'Gesamtübersicht',
                        child: Row(
                          children: [
                            Icon(Icons.show_chart,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 5),
                            Text('Gesamtübersicht'),
                          ],
                        ),
                      ),
                      ...allBankAccounts
                          .where((account) => account.id != null && account.id != '')
                          .map((BankAccount account) {
                        return DropdownMenuItem<String>(
                          value: account.id, // ID statt Name als value
                          child: Row(
                            children: [
                              Icon(
                                account.accountType == "Bargeld"
                                    ? Icons.attach_money
                                    : Icons.account_balance,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 5),
                              Text(account.accountName ?? 'Unbekanntes Konto'),
                            ],
                          ),
                        );
                      }).toList(),
                    ],

                    onChanged: (String? newValue) async {
                      setState(() {
                        selectedAccount = newValue ?? 'Gesamtübersicht';

                      // Aktualisiere die Account-ID basierend auf der Auswahl
                      if (selectedAccount == 'Gesamtübersicht') {
                      selectedAccountID = 'null'; // Keine spezifische ID für die Gesamtübersicht
                      print("Accountname gefunden!!!");
                      print("$selectedAccount");
                      importedTypeOfBankAccount = false;
                      } else {
                        // Suche nach dem Konto anhand der ID
                        for (var bA in allBankAccounts) {
                          if (bA.id == selectedAccount && bA.id != null && bA.id != '') {
                            selectedAccountID = bA.id!;
                            importedTypeOfBankAccount = bA.forImport;
                          }
                        }
                      }

                        // Reset cache to force data reload
                        chartCache.clear();
                        cachedYearlyLineChartData = null;
                      });

                      await _reloadAllStatistics();
                    },
                  ),




                ],
              ),

              const Divider(
                thickness: 1, // Stärke der Linie
                color: Colors.black, // Farbe der Linie
                height: 0, // Kein zusätzlicher Abstand unter der Linie
              ),

              const SizedBox(height: 20),


              // Gesamtübersicht im Zeitraum (Jahr und Monat nebeneinander)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 20),
                  Text(
                    'Gesamtverlauf:  ',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  // Jahr Picker
                  GestureDetector(
                    onTap: () => _showYearPicker(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Text(
                        selectedYear,
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Monat Picker
                  GestureDetector(
                    onTap: () => _showMonthPicker(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Text(
                        selectedMonth,
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Diagramm-Widget
              cachedYearlyLineChartData == null || cachedYearlyLineChartData!.isEmpty
                  ? Center(child: Text("Noch keine Daten verfügbar"))
                  : Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(right: 20, left: 10, top: 10),
                child: LineChart(chartData),
              ),

              const SizedBox(height: 40),

              // Kategorieübersicht (mit einem Picker zur Auswahl des Zeitraums)
              Row(
                children: [
                  const SizedBox(width: 30),
                  Text(
                    'Kategorieausgaben:  ',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => _showCategoryPicker(context),
                    // Picker anzeigen
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Text(
                        selectedTimeCategory, // Zeigt "Monat" oder "Woche" an
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              categories.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: CustomScrollPhysics(),
                  child: Row(
                    children: categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: CategoryStatWidget(
                          category: category,
                          chartDataFuture: loadCategoryChartData(
                            category.id!,
                            selectedTimeCategory,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              /*
              importedTypeOfBankAccount
                  ? Container() // Wenn CSV-Konto ausgewählt ist, zeige nichts
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 30),
                      Text(
                        'Ausgabenverteilung:  ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () => _showImportancePicker(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Text(
                            selectedTimeImportance,
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  urgentExpenses == 0.0 && nonUrgentExpenses == 0.0
                      ? Center(child: CircularProgressIndicator())
                      : Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 45),
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: buildPieChart(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),*/
            ],
          ),
        ),
      ),
    );
  }

  void _showImportancePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 220,
          child: CupertinoPicker(
            backgroundColor: Colors.white,
            itemExtent: 50.0,
            scrollController: FixedExtentScrollController(
              initialItem: selectedTimeImportance == "Monat" ? 0 : 1,
            ),
            onSelectedItemChanged: (int index) async {
              selectedTimeImportance = index == 0 ? "Monat" : "Woche";
              await _loadAndSetExpenses(selectedTimeImportance);
            },
            children: [
              Center(
                child: Text("Monat", style: TextStyle(fontSize: 18, color: Colors.black)),
              ),
              Center(
                child: Text("Woche", style: TextStyle(fontSize: 18, color: Colors.black)),
              ),
            ],
          ),
        );
      },
    );
  }
  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 220, // Höhe des Containers
          child: CupertinoPicker(
            backgroundColor: Colors.white,
            itemExtent: 50.0,
            // Höhe jedes Elements
            scrollController: FixedExtentScrollController(
              initialItem: selectedTimeCategory == "Monat"
                  ? 0
                  : 1, // Setzt den initialen Wert (Monat oder Woche)
            ),
            onSelectedItemChanged: (int index) {
              setState(() {
                // "Monat" oder "Woche" auswählen
                selectedTimeCategory = index == 0 ? "Monat" : "Jahr";
                // Daten nach der Auswahl neu laden
              });
            },
            children: [
              Center(child: Text("Monat",
                  style: TextStyle(fontSize: 18, color: Colors.black))),
              Center(child: Text("Jahr",
                  style: TextStyle(fontSize: 18, color: Colors.black))),
            ],
          ),
        );
      },
    );
  }

}



class CategoryStatWidget extends StatelessWidget {
  final Category category;
  final Future<LineChartData> chartDataFuture;

  CategoryStatWidget({required this.category, required this.chartDataFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LineChartData>(
      future: chartDataFuture,
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Fehler: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!.lineBarsData.isEmpty) {
          return Center(
            child: Text(
              'Keine Daten für diese Kategorie verfügbar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(12.0),
          width: 410,
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
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: category.color,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    category.icon,
                    color: category.color,
                    size: 16.0,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: LineChart(snapshot.data!),
              ),
            ],
          ),
        );
      },
    );
  }

}

class CustomScrollPhysics extends ScrollPhysics {
  const CustomScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return offset / 1; // Hier kannst du den Scrollfaktor anpassen, um die Geschwindigkeit zu reduzieren
  }
}
