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
  String selectedAmountType = 'Gesamtbetrag';
  String selectedTimePeriod = 'Monat';

  List<Category> categories = [];
  final ScrollController _scrollController = ScrollController();  // Der ScrollController

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        List<Category> userCategories = await _firestoreService.getUserCategories(user.uid);
        setState(() {
          categories = userCategories;
        });
      } catch (e) {
        print('Fehler beim Abrufen der Kategorien: $e');
      }
    }
  }

  // Placeholder für Diagramm-Daten
  final gridData = FlGridData(
    show: true,
    getDrawingHorizontalLine: (value) {
      return FlLine(
        color: const Color(0xff37434d),
        strokeWidth: 0.5,
      );
    },
    getDrawingVerticalLine: (value) {
      return FlLine(
        color: const Color(0xff37434d),
        strokeWidth: 0.5,
      );
    },
  );

  final borderData = FlBorderData(
    show: true,
    border: Border.all(
      color: const Color(0xff37434d),
      width: 1,
    ),
  );

  // Drei Linien für das Haupt-Diagramm
  LineChartBarData get lineChartBarData1 => LineChartBarData(
    isCurved: true,
    color: Colors.green,
    barWidth: 8,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
    spots: [
      FlSpot(1, 1),
      FlSpot(2, 2),
      FlSpot(3, 1.5),
      FlSpot(4, 3),
      FlSpot(5, 2.8),
      FlSpot(6, 3.5),
      FlSpot(7, 4),
    ],
  );

  LineChartBarData get lineChartBarData2 => LineChartBarData(
    isCurved: true,
    color: Colors.blue,
    barWidth: 8,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
    spots: [
      FlSpot(1, 1),
      FlSpot(2, 2.5),
      FlSpot(3, 2),
      FlSpot(4, 3.5),
      FlSpot(5, 3),
      FlSpot(6, 3.8),
      FlSpot(7, 4.5),
    ],
  );

  LineChartBarData get lineChartBarData3 => LineChartBarData(
    isCurved: true,
    color: Colors.orange,
    barWidth: 8,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
    spots: [
      FlSpot(1, 1.2),
      FlSpot(2, 1.8),
      FlSpot(3, 2.3),
      FlSpot(4, 2.8),
      FlSpot(5, 3.2),
      FlSpot(6, 4.1),
      FlSpot(7, 4.3),
    ],
  );

  // Daten für das Haupt-Diagramm mit drei Linien
  LineChartData get chartData => LineChartData(
    lineBarsData: [
      lineChartBarData1,
      lineChartBarData2,
      lineChartBarData3,
    ],
    gridData: gridData,
    borderData: borderData,
    titlesData: FlTitlesData(

    ),
  );

  // Daten für die Kategoriediagramme mit nur einer Linie
  LineChartData categoryChartData(Category category) {
    LineChartBarData categoryLineData = LineChartBarData(
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
        FlSpot(5, 3.2),
        FlSpot(6, 4.1),
        FlSpot(7, 4.3),
      ],
    );

    return LineChartData(
      lineBarsData: [categoryLineData],
      gridData: gridData,
      borderData: borderData,
      titlesData: FlTitlesData(
      ),
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
                children: [
                  const SizedBox(width: 20),
                  Text(
                    'Gesamtübersicht im Zeitraum:  ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
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

              // Haupt-Diagramm mit drei Linien
              Container(
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
                child: LineChart(chartData), // Diagramm hier eingefügt
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  const SizedBox(width: 20),
                  Text(
                    'Kategorieübersicht im Zeitraum:  ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
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
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: LineChart(chartData), // Diagramm hier eingefügt
          ),
        ],
      ),
    );
  }
}
