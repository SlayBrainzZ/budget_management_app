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
  Future<void> _loadExpenses(String chosenTime) async { //gloabel variablen urgentexpenses udn nonurgendstexepenses werden defineirt
    final user = await _loadUser();

    if (user == null) {
      print("Kein Benutzer gefunden.");
      return;
    }

    DateTime today = DateTime.now();
    DateTime startdate;
    DateTime enddate;
    Map<String, double> expenses;

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
      // Rufe die summierten Ausgaben ab
        expenses = await _firestoreService.fetchUrgentAndNonUrgentExpenses(user.uid, startdate, enddate, selectedAccountID);

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

          LineChartBarData einnahmeDaten = await defineLineChartBarData(Colors.green, chosenYear, "Monat", "Einnahme", FlSpotListList[0]);
          LineChartBarData ausgabeDaten = await defineLineChartBarData(Colors.red, chosenYear, "Monat", "Ausgabe", FlSpotListList[1]);
          LineChartBarData gesamtDaten = await defineLineChartBarData(Colors.blue, chosenYear, "Monat", "null", FlSpotListList[2]);


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
              Colors.green, chosenYear, chosenMonth, "Einnahme", FlSpotlist1);
          LineChartBarData ausgabeDaten = await defineLineChartBarData(
              Colors.red, chosenYear, chosenMonth, "Ausgabe", FlSpotlist2);
          LineChartBarData gesamtDaten = await defineLineChartBarData(
              Colors.blue, chosenYear, chosenMonth, "null", FlSpotlist3);

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
          color: Colors.red,
          curveSmoothness: 0.35,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
          spots: categoryList,
        ),
      ],
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: true),
      titlesData: FlTitlesData(
      ),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
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
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
      spots: spotsList,
    );
  }
  PieChartData definePiechartData() {
    final summary = calculateExpenseSummary();
    return PieChartData(
      sections: [
        PieChartSectionData(
          title:
          "Dringend (${summary['urgentPercentage'].toStringAsFixed(1)}%)",
          value: urgentExpenses,
          color: Colors.red,
        ),
        PieChartSectionData(
          title:
          "Nicht dringend (${summary['nonUrgentPercentage'].toStringAsFixed(1)}%)",
          value: nonUrgentExpenses,
          color: Colors.blue,
        ),
      ],
      sectionsSpace: 2,
      centerSpaceRadius: 50, // Platz in der Mitte
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
    if (cachedYearlyLineChartData == null) {
      throw Exception("Daten müssen vorab geladen werden!");
    }
    return LineChartData(
      lineBarsData: cachedYearlyLineChartData!,
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: true),
      titlesData: FlTitlesData(),
      lineTouchData: LineTouchData(handleBuiltInTouches: true),
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
                  selectedMonth) - 1,
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
                    'Statistiken für:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  DropdownButton<String>(
                    value: allBankAccounts.any((account) => account.accountName == selectedAccount)
                        ? selectedAccount
                        : 'Gesamtübersicht', // Fallback zu "Gesamtübersicht"
                    items: [
                      DropdownMenuItem(
                        value: 'Gesamtübersicht',
                        child: Text('Gesamtübersicht'),
                      ),
                      ...allBankAccounts.map((BankAccount account) {
                        return DropdownMenuItem<String>(
                          value: account.accountName,
                          child: Text(account.accountName ?? 'Unbekanntes Konto'),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? newValue) async {
                      setState(() {
                        selectedAccount = newValue!;

                        // Aktualisiere die Account-ID basierend auf der Auswahl
                        if (selectedAccount == 'Gesamtübersicht') {
                          selectedAccountID = 'null'; // Keine spezifische ID für die Gesamtübersicht
                          print("Accountname gefunden!!!");
                          print("$selectedAccount");
                          importedTypeOfBankAccount = false;
                        } else {
                          for (var bA in allBankAccounts){
                            if (bA.accountName == selectedAccount){
                              print("Accountname gefunden!!!");
                              print("$selectedAccount");
                              selectedAccountID = bA.id!;
                              importedTypeOfBankAccount = bA.forImport;
                            } else {
                              //print("Accountname NICHTTTTTTT gefunden!!!");
                            }
                          }
                        } // Reset cache to force data reload
                        chartCache.clear();
                        cachedYearlyLineChartData = null;
                      });

                      await _reloadAllStatistics();
                    },
                  ),



                ],
              ),


              const SizedBox(height: 20),


              // Gesamtübersicht im Zeitraum (Jahr und Monat nebeneinander)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 20),
                  Text(
                    'Gesamtübersicht:  ',
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
              cachedYearlyLineChartData == null
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
                child: LineChart(chartData), // Diagramm anzeigen
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
              ),
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
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('Keine Daten verfügbar'));
        }

        return Container(
          padding: const EdgeInsets.all(12.0),
          width: 410, // Responsive Anpassung
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
              Text(
                category.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: LineChart(snapshot.data!), // Anzeige des Diagramms
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
