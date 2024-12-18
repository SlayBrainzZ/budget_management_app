import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_management_app/backend/Category.dart';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String? _userId;
  String selectedAmountType = 'Gesamtbetrag';

  String selectedTimeCategory = 'Jahr';

  String selectedYear = '2024'; // Standardwert für das Jahr
  String selectedMonth = 'Monat'; // Standardwert für den Monat


  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();

  List<LineChartBarData>? cachedLineChartData;
  Map<String, LineChartData> chartCache = {};


  List<Category> categories = [];
  List <double> allMonthBalanceData = [];
  double lastMonthBalance = 0.0;
  Map<String, double> monthlyBalanceList = {};


  @override
  void initState() {
    super.initState();
    _loadCategories();
    loadLineChartBarData('2024', 'Monat');
  }

  Future<User?> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      await _firestoreService.getUserCategories(
          user.uid); // Just loading categories for now
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
        monthlyTransactions = await _firestoreService.calculateYearlySpendingByMonth2(user.uid, chosenYear);

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
      print("Fehler beim Laden der Ausgaben für Jahr: ${e.toString()}");
    }
    return FlSpotListList;
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

  Future<void> loadLineChartBarData(String chosenYear, String chosenMonth) async {

    try {
      if (chosenMonth == 'Monat') {
        // Zeige den Jahresverlauf
        if (chartCache.containsKey(chosenYear)) {
          setState(() {
            cachedLineChartData = chartCache[chosenYear]?.lineBarsData;
          });
        } else {
          // Berechne die Jahresdaten




          List<List<FlSpot>> FlSpotListList = await generateSpotsforYear(chosenYear, chosenMonth, "null");

          LineChartBarData einnahmeDaten = await defineLineChartBarData(Colors.green, chosenYear,"Monat", "Einnahme", FlSpotListList[0]);
          LineChartBarData ausgabeDaten = await defineLineChartBarData(Colors.red, chosenYear,"Monat", "Ausgabe", FlSpotListList[1]);
          LineChartBarData gesamtDaten = await defineLineChartBarData(Colors.blue, chosenYear, "Monat", "null", FlSpotListList[2]);





          setState(() {
            cachedLineChartData = [einnahmeDaten, ausgabeDaten, gesamtDaten];
            chartCache[chosenYear] = LineChartData(
              lineBarsData: cachedLineChartData!,
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
            cachedLineChartData = chartCache['$chosenYear-$chosenMonth']?.lineBarsData;
          });
        } else {
          List<FlSpot> FlSpotlist1 = await generateSpotsforMonth(chosenYear, chosenMonth, "Einnahme");
          List<FlSpot> FlSpotlist2 = await generateSpotsforMonth(chosenYear, chosenMonth, "Ausgabe");
          List<FlSpot> FlSpotlist3 = await generateSpotsforMonth(chosenYear, chosenMonth, "null");

          LineChartBarData einnahmeDaten = await defineLineChartBarData(Colors.green, chosenYear, chosenMonth, "Einnahme", FlSpotlist1);
          LineChartBarData ausgabeDaten = await defineLineChartBarData(Colors.red, chosenYear, chosenMonth, "Ausgabe", FlSpotlist2);
          LineChartBarData gesamtDaten = await defineLineChartBarData(Colors.blue, chosenYear, chosenMonth, "null", FlSpotlist3);

          setState(() {
            cachedLineChartData = [einnahmeDaten, ausgabeDaten, gesamtDaten];
            chartCache['$chosenYear-$chosenMonth'] = LineChartData(
              lineBarsData: cachedLineChartData!,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler beim Laden der Diagrammdaten")));
    }
  }



  LineChartData get chartData {

    if (cachedLineChartData == null) {
      throw Exception("Daten müssen vorab geladen werden!");
    }
    return LineChartData(
      lineBarsData: cachedLineChartData!,
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: true),
      titlesData: FlTitlesData(),
      lineTouchData: LineTouchData(handleBuiltInTouches: true),
    );
  }


  LineChartData categoryChartData(Category category) {
    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          color: Colors.blue,
          barWidth: 8,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
          spots: [
            FlSpot(1, 1.2),
            FlSpot(2, 1.8),
            FlSpot(3, 2.3),
            FlSpot(4, 2.8),
            FlSpot(5, 3.2)
          ],
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

  int dayCurrentMonth() {
    DateTime now = DateTime.now();
    // Ermitteln des letzten Tages des aktuellen Monats
    DateTime lastDayOfMonth = DateTime.utc(now.year, now.month + 1, 0);
    // Anzahl der Tage im aktuellen Monat
    int daysInMonth = lastDayOfMonth.day;

    print("Der aktuelle Monat hat $daysInMonth Tage.");
    return daysInMonth;
  }

  double findLastMonthBalance1(Map<String, double> data, String chosenYear, String chosenMonth) {
    //es muss ein sortiertes Dictonary sein, zeitlich aufsteigend
    try {
      print("Der aktuelle Monat ist der $chosenMonth oder auch in int: ${int.parse(chosenMonth)}");

      double lastMonthBalance = 0.0;
      DateTime today = DateTime(int.parse(chosenYear), int.parse(chosenMonth));
      print(today);
      String currentMonth = "${today.year}-${today.month.toString().padLeft(2, '0')}";
      print(currentMonth);



      // Iteriere durch die Map
      data.forEach((key, value) {
        // String in DateTime umwandeln
        DateTime keyDate = DateTime.parse(key); // "-01" hinzufügen, um ein gültiges Datum zu erstellen
        print("Der Key lautet $key");
        print("Und die andere Datetime ist: ${DateTime(today.year, today.month)}");
        // Vergleiche mit aktuellem Datum
        if (keyDate == DateTime(today.year, today.month -1 )) {
          print("Der Schlüssel $key entspricht dem vorherigen Monat. Wert: $value");
          lastMonthBalance = value;
        } else if (keyDate.isBefore(today)) {
          print("Der Schlüssel $key liegt vor dem heutigen Monat.");
        } else if (keyDate.isAfter(today)) {
          print("Der Schlüssel $key liegt nach dem heutigen Monat.");
        } else{
          print("No match found");
        }
      });
      print(lastMonthBalance);


    } catch (e) {
      print("Fehler beim Laden der Ausgaben: ${e.toString()}");
    }
    return lastMonthBalance;
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
    String previousMonthKey = "$previousYear-${previousMonth.toString().padLeft(2, '0')}";

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





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  // Abstand zwischen Text und Dropdowns

                  // Dropdown für Jahr
                  DropdownButton<String>(
                    value: selectedYear,
                    onChanged: (String? newValue) {
                      setState(() {
                        if (selectedMonth == "Monat"){
                          selectedYear = newValue!;
                          loadLineChartBarData(selectedYear, selectedMonth);
                        } else {
                          selectedYear = newValue!;
                          selectedMonth = "Monat";
                          loadLineChartBarData(selectedYear, selectedMonth);
                        }
                      });
                    },
                    items: <String>[
                      '2024',
                      '2023',
                      '2022',
                      '2021'
                    ]
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),

                  const SizedBox(width: 20),
                  // Abstand zwischen den beiden Dropdowns

                  // Dropdown für Monat
                  DropdownButton<String>(
                    value: selectedMonth,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedMonth = newValue!;
                        loadLineChartBarData(selectedYear,selectedMonth);
                      });
                    },
                    items: <String>[
                      'Monat',
                      '01',
                      '02',
                      '03',
                      '04',
                      '05',
                      '06',
                      '07',
                      '08',
                      '09',
                      '10',
                      '11',
                      '12'
                    ]
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

              cachedLineChartData == null
                  ? Center(child: CircularProgressIndicator()) // Ladeanzeige
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

              // Kategorieübersicht (mit einem Dropdown zur Auswahl des Zeitraums)
              Row(
                children: [
                  const SizedBox(width: 20),
                  Text(
                    'Kategorieübersicht im Zeitraum:  ',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  // Abstand zwischen Text und Dropdown

                  // Dropdown für Zeitraum in der Kategorieübersicht
                  DropdownButton<String>(
                    value: selectedTimeCategory,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedTimeCategory = newValue!;
                      });
                    },
                    items: <String>['Jahr', 'Monat', 'Woche']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),

              categories.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: CategoryStatWidget(
                          category: category,
                          chartData: categoryChartData(category),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class CategoryStatWidget extends StatelessWidget {
  final Category category;
  final LineChartData chartData;

  CategoryStatWidget({required this.category, required this.chartData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      width: 400,  // Breite des CategoryStatWidgets, damit es horizontal scrollt
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
          ),
          const SizedBox(height: 20),
          // Kategoriediagramm mit einer Linie
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: LineChart(chartData),
          ),
        ],
      ),
    );
  }
}
