import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_management_app/backend/Category.dart';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'home_page.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String? _userId;
  String selectedAmountType = 'Gesamtbetrag';

  String selectedTimeCategory = 'Monat';
  String selectedTimeImportance = 'Monat';
  String selectedYear = '2025'; // Standardwert für das Jahr
  String selectedMonth = 'Monat'; // Standardwert für den Monat
  final List<int> availableYears = List.generate(
      100, (index) => 2000 + index); // letze 20 und nächste 80 jare

  double urgentExpenses = 0.0;
  double nonUrgentExpenses = 0.0;

  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();
  String selectedAccount = 'Gesamtübersicht'; // Standardmäßig "Gesamtübersicht"


  List<LineChartBarData>? cachedYearlyLineChartData;
  List<double>? cachedImportantChartData;
  List<LineChartBarData>? cachedCategoryLineChartData;

  Map<String, LineChartData> chartCache = {};


  List<Category> categories = [];

  //List <double> allMonthBalanceData = [];
  double lastMonthBalance = 0.0;
  Map<String, double> monthlyBalanceList = {};


  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (monthlyBalanceList.isEmpty) {
      loadLineChartBarData('2025', 'Monat');
    }
    _loadWeeklyExpenses(); // Ausgaben für diese Woche laden
  }


  Future<User?> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      await _firestoreService.getUserCategories(
          user.uid); // Just loading categories for now
      //print("Der Benutzer im Allgemeinen ist ${user.uid}");
      return user;
    } catch (e) {
      print('Fehler beim Laden des Users: ${e.toString()}');
      return null;
    }
  }

  Future<void> _loadCategories() async {
    final user = await _loadUser();
    if (user == null) {
      print('Kein Benutzer gefunden.');
      return;
    }
    setState(() {
      categories = [];
    });

    try {
      List<Category> userCategories = await _firestoreService.getUserCategories(
          user.uid);
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
  }
  Future<void> _loadWeeklyExpenses() async {
    final user = await _loadUser(); // Aktuellen Benutzer abrufen
    if (user == null) {
      print("Kein Benutzer gefunden.");
      return;
    }

    DateTime today = DateTime.now();
    DateTime monday = today.subtract(Duration(days: today.weekday - 1)); // Montag
    DateTime sunday = monday.add(Duration(days: 6)); // Sonntag

    // Rufe die summierten Ausgaben ab
    Map<String, double> expenses = await _firestoreService.fetchWeeklyUrgentAndNonUrgentExpenses(
      user.uid,
      monday,
      sunday,
    );

    setState(() {
      urgentExpenses = expenses["Dringend"] ?? 0.0;
      nonUrgentExpenses = expenses["Nicht dringend"] ?? 0.0;
      //print("HALLLLLLLLLLLOOOOOOO: $urgentExpenses");
      //print("HALLLLLLLLLLLOOOOOOO: $nonUrgentExpenses");
    });
  }


  Future<List<FlSpot>> generateSpotsforMonth(String chosenYear, chosenMonth,
      String type) async {
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
      lastMonthBalance =
          findLastMonthBalance(monthlyBalanceList, chosenYear, chosenMonth);
      print("lastMonthBalance nach Monatsangabe: $lastMonthBalance");
      data = await _firestoreService.calculateMonthlySpendingByDay(
          user.uid, type, chosenYear, chosenMonth, lastMonthBalance);
      for (double y in data) {
        FlSpotlist.add(FlSpot(x, y));
        x = x + 1;
      }
    } catch (e) {
      print("Fehler beim Laden der Ausgaben für Monat: ${e.toString()}");
    }
    return FlSpotlist;
  }


  Future<List<List<FlSpot>>> generateSpotsforYear(String chosenYear,
      chosenMonth, String type) async {
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
        monthlyTransactions =
        await _firestoreService.calculateYearlySpendingByMonth2(
            user.uid, chosenYear);

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


  Future<LineChartBarData> defineLineChartBarData(Color color,
      String chosenYear, String chosenMonth, String type,
      List<FlSpot> spotsList) async {
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

  Future<void> loadLineChartBarData(String chosenYear,
      String chosenMonth) async {
    try {
      if (chosenMonth == 'Monat') {
        // Zeige den Jahresverlauf
        if (chartCache.containsKey(chosenYear)) {
          setState(() {
            cachedYearlyLineChartData = chartCache[chosenYear]?.lineBarsData;
          });
        } else {
          // Berechne die Jahresdaten


          List<List<FlSpot>> FlSpotListList = await generateSpotsforYear(
              chosenYear, chosenMonth, "null");

          LineChartBarData einnahmeDaten = await defineLineChartBarData(
              Colors.green, chosenYear, "Monat", "Einnahme", FlSpotListList[0]);
          LineChartBarData ausgabeDaten = await defineLineChartBarData(
              Colors.red, chosenYear, "Monat", "Ausgabe", FlSpotListList[1]);
          LineChartBarData gesamtDaten = await defineLineChartBarData(
              Colors.blue, chosenYear, "Monat", "null", FlSpotListList[2]);


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
    } catch (e) {
      print('Fehler beim Laden der Diagrammdaten: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler beim Laden der Diagrammdaten")));
    }
  }

  //Future<void> loadCategoryLineChartBarData(String chosenYear, String chosenMonth) async {}


  LineChartData get chartData {
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


  Future<List<FlSpot>> generateSpotsForCategory(String category,
      String selectedTimeCategory) async {
    final user = await _loadUser();
    if (user == null) {
      print("Kein Benutzer gefunden.");
      return [];
    }

    Map<int, double> categoryTransactions = {};
    List<FlSpot> categoryList = [];

    try {
      if (selectedTimeCategory == "Monat") {
        //print("Der Benutzer in Categorie ist ${user.uid}");
        categoryTransactions = await _firestoreService
            .getCurrentMonthTransactionsByDateRangeAndCategory(
            user.uid, category);
      } else if (selectedTimeCategory == "Woche") {
        categoryTransactions = await _firestoreService
            .getCurrentWeekTransactionsByDateRangeAndCategory(
            user.uid, category);
      } else {
        print("Keine Periode für Kategorie ausgwählt");
      }
      print(categoryTransactions);

      categoryTransactions.forEach((day, amount) {
        categoryList.add(FlSpot(day.toDouble(), amount));
      });

      categoryList.sort((a, b) => a.x.compareTo(b.x));
    } catch (e) {
      print("Fehler beim Laden der Kategoriedaten: ${e.toString()}");
    }

    return categoryList;
  }


  Future<LineChartData> categoryChartData(String category,
      String selectedTimeCategory) async {
    // Abrufen der Datenpunkte
    //print("Der Kategoriename lautet:  $category");
    List<FlSpot> categoryList = await generateSpotsForCategory(
        category, selectedTimeCategory);

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


  double findLastMonthBalance(Map<String, double> data, String chosenYear,
      String chosenMonth) {
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
      print(
          "Vorheriger Monat gefunden: $previousMonthKey, Guthaben: $lastMonthBalance");
    } else {
      print(
          "Kein Guthaben für den vorherigen Monat $previousMonthKey gefunden, weil er mit ${data} nicht übereinstimt.");
      print("previousMonthKey: $previousMonthKey");
      print("Der Typ lautet ${previousMonthKey.runtimeType} ");
      print("Der erste Schlüssel von data ist: ${data.keys.first}");
      print("Der Typ des ersten Schlüssels: ${data.keys.first.runtimeType}");
    }

    return lastMonthBalance;
  }


  void _showYearPicker(BuildContext context) {
    int initialYearIndex = availableYears.indexOf(int.parse(selectedYear));
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
                loadLineChartBarData(selectedYear,
                    selectedMonth); // Beispiel für das Laden der Daten nach Auswahl loadLineChartBarData(selectedYear, selectedMonth);
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
                loadLineChartBarData(selectedYear, selectedMonth);
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


  void _updateDataForSelectedAccount() {
    switch (selectedAccount) {
      case 'Gesamtübersicht':
        loadLineChartBarData(selectedYear, selectedMonth);
        break;
      case 'Konto 1':
        loadLineChartBarDataForAccount('Konto 1');
        break;
      case 'Konto 2':
        loadLineChartBarDataForAccount('Konto 2');
        break;
    }
  }

  Future<void> loadLineChartBarDataForAccount(String account) async {
    // Implementiere hier die Logik zum Laden von Daten für das spezifische Konto
    print('Daten für $account werden geladen.');
    // Beispieldaten
    // cachedYearlyLineChartData = await fetchDataForAccount(account);
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
                    value: selectedAccount,
                    items: [
                      DropdownMenuItem(
                        value: 'Gesamtübersicht',
                        child: Text('Gesamtübersicht'),
                      ),
                      DropdownMenuItem(
                        value: 'Konto 1',
                        child: Text('Konto 1'),
                      ),
                      DropdownMenuItem(
                        value: 'Konto 2',
                        child: Text('Konto 2'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedAccount = newValue!;
                        _updateDataForSelectedAccount(); // Methode zum Aktualisieren der Daten
                      });
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
                    'Gesamtübersicht im Zeitraum:  ',
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
                    'Kategorieübersicht im Zeitraum:  ',
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
                          chartDataFuture: categoryChartData(
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
              Row(
                children: [
                  const SizedBox(width: 30),
                  Text(
                    'Relevanz der Ausgabenverteilung:  ',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => _showImportancePicker(context), // Klammer hinzufügen, um die Methode aufzurufen
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
              cachedImportantChartData == [50.0,50.0]
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
                      child: PieChart(
                        PieChartData(
                            sections: [
                              PieChartSectionData(title: "Dringend", value: urgentExpenses, color: Colors.red),
                              PieChartSectionData(title: "Nicht dringend",value: nonUrgentExpenses, color: Colors.blue)
                            ]
                        ),
                        duration: Duration(milliseconds: 150), // Optional
                        curve: Curves.linear, // Optional
                      ),
                    ),
                  ],
                ),
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
          height: 220, // Höhe des Containers
          child: CupertinoPicker(
            backgroundColor: Colors.white,
            itemExtent: 50.0, // Höhe jedes Elements
            scrollController: FixedExtentScrollController(
              initialItem: selectedTimeImportance == "Monat" ? 0 : 1, // Setzt den initialen Wert
            ),
            onSelectedItemChanged: (int index) {
              setState(() {
                selectedTimeImportance = index == 0 ? "Monat" : "Woche";
                // Hier kannst du die Daten für "Relevanz der Ausgabenverteilung" neu laden
                print('Zeitraum geändert: $selectedTimeImportance');
              });
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
                selectedTimeCategory = index == 0 ? "Monat" : "Woche";
                // Daten nach der Auswahl neu laden
              });
            },
            children: [
              Center(child: Text("Monat",
                  style: TextStyle(fontSize: 18, color: Colors.black))),
              Center(child: Text("Woche",
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
          return Text('Fehler beim Laden der Daten');
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Text('Keine Daten verfügbar');
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

