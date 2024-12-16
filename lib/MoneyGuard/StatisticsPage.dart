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

  Future<List<FlSpot>> generateSpots(String chosenYear, chosenMonth, String type) async {
    final user = await _loadUser();
    if (user == null) {
      print("Kein Benutzer gefunden.");
      return [];
    }

    List<FlSpot> FlSpotlist = [];
    List<double> data = [];

    Map<String, double> monthlySpending = {};
    double x = 1;
    int iter = 1;

    try {
      if (chosenMonth == "Monat") {
        monthlySpending = await _firestoreService.calculateYearlySpendingByMonth(user.uid, type, chosenYear);

        if (type == "null") {
          lastMonthBalance = findLastMonthBalance(monthlySpending);
          print(lastMonthBalance);
        }
      } else {
        data = await _firestoreService.calculateMonthlySpendingByDay(user.uid, type, chosenYear, chosenMonth ,0.0);
        print(data);}

      if (chosenMonth == "Monat") {
        for (var entry in monthlySpending.entries) {
          // Hier wird der Schlüssel (Monat) aus der Map als DateTime-String im Format "YYYY-MM" genommen
          String monthKey = entry.key; // Beispiel: "2024-01"

          // Konvertiere den Monatsschlüssel in ein gültiges DateTime-Format (füge "-01" für den Tag hinzu)
          DateTime dateTime = DateTime.parse(monthKey + "-01");

          // Betrag der Ausgabe
          double y = entry.value;

          // Füge den FlSpot zur Liste hinzu, wobei x den Monat (1 für Januar, 2 für Februar ...) und y den Betrag repräsentiert
          FlSpotlist.add(FlSpot(double.parse(dateTime.month.toString()), y));
          x = x + 1;
        }
      } else {

        for (double y in data) {
          FlSpotlist.add(FlSpot(x, y));
          x = x + 1;
        }
      }
    } catch (e) {
      print("Fehler beim Laden der Ausgaben: ${e.toString()}");
    }

    return FlSpotlist;
  }


  Future<LineChartBarData> defineLineChartBarData(Color color, String chosenYear, String chosenMonth, String type) async {
    List<FlSpot> spotsList = await generateSpots(chosenYear, chosenMonth, type);

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
          LineChartBarData einnahmeDaten = await defineLineChartBarData(Colors.green, chosenYear,"Monat", "Einnahme");
          LineChartBarData ausgabeDaten = await defineLineChartBarData(Colors.red, chosenYear,"Monat", "Ausgabe");
          LineChartBarData gesamtDaten = await defineLineChartBarData(Colors.blue, chosenYear, "Monat", "null");

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
          // Berechne die Monatsdaten
          LineChartBarData einnahmeDaten = await defineLineChartBarData(Colors.green, chosenYear, chosenMonth, "Einnahme");
          LineChartBarData ausgabeDaten = await defineLineChartBarData(Colors.red, chosenYear, chosenMonth, "Ausgabe");
          LineChartBarData gesamtDaten = await defineLineChartBarData(Colors.blue, chosenYear, chosenMonth, "null");

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

  double findLastMonthBalance(Map<String, double> data) {
    //es muss ein sortiertes Dictonary sein, zeitlich aufsteigend

    double lastMonthBalance = 0.0;
    DateTime today = DateTime.now();
    String currentMonth = "${today.year}-${today.month.toString().padLeft(
        2, '0')}";

    // Iteriere durch die Map
    data.forEach((key, value) {
      // String in DateTime umwandeln
      DateTime keyDate = DateTime.parse(
          key + "-01"); // "-01" hinzufügen, um ein gültiges Datum zu erstellen
      // Vergleiche mit aktuellem Datum
      if (keyDate == DateTime(today.year, today.month)) {
        print("Der Schlüssel $key entspricht dem heutigen Monat. Wert: $value");
      } else if (keyDate.isBefore(today)) {
        print("Der Schlüssel $key liegt vor dem heutigen Monat.");
        lastMonthBalance = value;
      } else if (keyDate.isAfter(today)) {
        print("Der Schlüssel $key liegt nach dem heutigen Monat.");
      }
    });
    print(lastMonthBalance);
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
                        selectedYear = newValue!;
                        loadLineChartBarData(selectedYear, selectedMonth);
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
