import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_management_app/backend/Category.dart';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:budget_management_app/backend/BankAccount.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {

  String selectedAmountType = 'Gesamtbetrag';
  String selectedTimeCategory = 'Monat';
  String selectedTimeImportance = 'Monat';
  String selectedYear = DateTime.now().year.toString();
  String selectedMonth = 'Monat';
  final List<int> availableYears =
  List.generate(DateTime.now().year - 2020 + 1, (index) => 2020 + index);
  double urgentExpenses = 0.0;
  double nonUrgentExpenses = 0.0;
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();
  String selectedAccount = 'Gesamtübersicht';
  String selectedAccountID = "";
  List<LineChartBarData>? cachedYearlyLineChartData;
  List<double>? cachedImportantChartData;
  List<LineChartBarData>? cachedCategoryLineChartData;
  List<Category> categories = [];
  List<BankAccount> allBankAccounts = [];
  Map<String, double> monthlyBalanceList = {};
  bool importedTypeOfBankAccount = false;
  User? user1;
  String? _userId;


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
    await loadBigChartBarData(selectedYear, selectedMonth);
  }
  Future<void> _reloadAllStatistics() async {
    try {
      await _loadCategories();
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
        allBankAccounts = userBankAccounts;
      });
    } catch (e) {
      print('Fehler beim Laden der UserAccounts: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Laden der Daten")),
      );
    }
  }

  Future<void> loadBigChartBarData(String chosenYear, String chosenMonth) async {
    try {
      if (chosenMonth == 'Monat') {
          List<List<FlSpot>> FlSpotListList = await generateSpotsforYear(chosenYear, chosenMonth, "null");

          LineChartBarData einnahmeDaten = await defineLineChartBarData(Colors.greenAccent.shade700, chosenYear, "Monat", "Einnahme", FlSpotListList[0]);
          LineChartBarData ausgabeDaten = await defineLineChartBarData(Colors.redAccent.shade700, chosenYear, "Monat", "Ausgabe", FlSpotListList[1]);
          LineChartBarData gesamtDaten = await defineLineChartBarData(Colors.blueAccent.shade700, chosenYear, "Monat", "null", FlSpotListList[2]);


          setState(() {
            cachedYearlyLineChartData = [einnahmeDaten, ausgabeDaten, gesamtDaten];
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
          });
        }
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
                radius: 3,
                color: bar.color ?? Colors.black,
                strokeWidth: 1,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
          spots: categoryList,
        ),
      ],
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
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

      borderData: FlBorderData(show: true,
        border: const Border(
          left: BorderSide(
              color: Colors.black,
              width: 1),
          bottom: BorderSide(
              color: Colors.black,
              width: 1),
          top: BorderSide.none,
          right: BorderSide.none,
        ),
      ),
      titlesData: categoryChartTitlesDataYear,
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (LineBarSpot spot) {
            return Theme.of(context).colorScheme.onSecondary;
          },
          tooltipBorder: BorderSide(
            color: Colors.black,
            width: 1,
          ),
          tooltipPadding: EdgeInsets.all(8),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              Map<int, String> lineLabels = {
                0: "Ausg.",
              };
              String label = lineLabels[spot.barIndex] ?? "Wert";
              return LineTooltipItem(
                "$label: ${spot.y.toStringAsFixed(2)} €",
                TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: spot.bar.color ?? Theme.of(context).textTheme.bodyLarge?.color,

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
      if(importedTypeOfBankAccount == false) {
        if (selectedAccountID == "null") {

          data = await _firestoreService.calculateMonthlyCombinedSpendingByDay(user.uid, type, chosenYear, chosenMonth, selectedAccountID);

        } else {

          data = await _firestoreService.calculateMonthlySpendingByDay(user.uid, type, chosenYear, chosenMonth, selectedAccountID);

        }
      }
      else if (importedTypeOfBankAccount == true){
        data = await _firestoreService.calculateMonthlyImportedSpendingByDay(user.uid, type, chosenYear, chosenMonth, selectedAccountID);
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
            String monthKey = entry.key;
            DateTime dateTime = DateTime.parse(monthKey + "-01");
            double y = entry.value;
            FlSpotlist.add(FlSpot(double.parse(dateTime.month.toString()), y));
          }
          FlSpotListList.add(FlSpotlist);
        }

        monthlySpending = monthlyTransactions[2];
        monthlyBalanceList.addAll(monthlySpending);
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
      isCurved: true,
      curveSmoothness: 0.35,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (FlSpot spot, double xPercentage, LineChartBarData bar, int index, {double? size}) {
          return FlDotCirclePainter(
            radius: 4,
            color: bar.color ?? Colors.black,
            strokeWidth: 1,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(show: false),
      spots: spotsList,
    );
  }
  LineChartData get chartData {
    if (cachedYearlyLineChartData == null || cachedYearlyLineChartData!.isEmpty) {
      return LineChartData(
        lineBarsData: [],
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      );
    }
    return LineChartData(
      lineBarsData: cachedYearlyLineChartData!,
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
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

      borderData: FlBorderData(
        show: true,
        border: const Border(
          left: BorderSide(
              color: Colors.black,
              width: 1),
          bottom: BorderSide
            (color: Colors.black,
              width: 1),
          top: BorderSide.none,
          right: BorderSide.none,
    ),
    ),
      titlesData: bigChartTitlesDataYear,
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (LineBarSpot spot) {
            return Theme.of(context).colorScheme.onSecondary;

            return Color.fromARGB(255, 255, 255, 255);
          },
          tooltipBorder: BorderSide(
            color: Colors.black,
            width: 1,
          ),
          tooltipPadding: EdgeInsets.all(8),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              Map<int, String> lineLabels = {
                0: "Einn.",
                1: "Ausg.",
                2: "Bilanz"
              };
              String label = lineLabels[spot.barIndex] ?? "Wert";
              return LineTooltipItem(
                "$label: ${spot.y.toStringAsFixed(2)} €",
                TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: spot.bar.color ?? Theme.of(context).textTheme.bodyLarge?.color,
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
        showTitles: true,
        reservedSize: 40,
        getTitlesWidget: (value, meta) {
          return Text(
            '${value.toInt()}€',
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
        showTitles: true,
        reservedSize: 40,
        getTitlesWidget: (value, meta) {
          return Text(
            '${value.toInt()}€',
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
    showTitles: true,
    reservedSize: 25,
    interval: 1,
    getTitlesWidget: categoryBottomTitleWidgets
  );
  Widget categoryBottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
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
        case 1:
          text = Text("${value.toString()}.${DateTime.now().month.toString().padLeft(2, '0')}", style: style);
          break;
        case 3:
          text = Text("${value.toString()}.${DateTime.now().month.toString().padLeft(2, '0')}", style: style);
          break;
        case 5:
          text = Text("${value.toString()}.${DateTime.now().month.toString().padLeft(2, '0')}", style: style);
          break;
        case 10:
          text = Text("${value.toString()}.${DateTime.now().month.toString().padLeft(2, '0')}", style: style);
          break;
        case 15:
          text = Text("${value.toString()}.${DateTime.now().month.toString().padLeft(2, '0')}", style: style);
          break;
        case 20:
          text = Text("${value.toString()}.${DateTime.now().month.toString().padLeft(2, '0')}", style: style);
          break;
        case 25:
          text = Text("${value.toString()}.${DateTime.now().month.toString().padLeft(2, '0')}", style: style);
          break;
        case 30:
          text = Text("${value.toString()}.${DateTime.now().month.toString().padLeft(2, '0')}", style: style);
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
        case 1:
          text = Text("${value.toString()}.${selectedMonth}", style: style);
          break;
        case 3:
          text = Text("${value.toString()}.${selectedMonth}", style: style);
          break;
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


  void _showYearPicker(BuildContext context) {int initialYearIndex = availableYears.indexOf(int.parse(selectedYear));
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: CupertinoPicker(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            itemExtent: 50.0,
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
    int maxMonth = (selectedYear == DateTime.now().year.toString())
        ? DateTime.now().month
        : 12;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: CupertinoPicker(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            itemExtent: 50.0,
            scrollController: FixedExtentScrollController(
              initialItem: selectedMonth == "Monat" ? 0 : int.parse(selectedMonth),
            ),
            onSelectedItemChanged: (int index) {
              setState(() {
                selectedMonth = index == 0
                    ? "Monat"
                    : index.toString().padLeft(2, '0');
                loadBigChartBarData(selectedYear, selectedMonth);
              });
            },
            children: [
              Center(child: Text("Monat",
                  style: TextStyle(fontSize: 18,
                      color: Theme.of(context).textTheme.bodyLarge?.color
                  ))),
              ...List.generate(maxMonth, (index) =>
                  Center(child: Text((index + 1).toString().padLeft(2, '0'),
                      style: TextStyle(fontSize: 18,
                          color: Theme.of(context).textTheme.bodyLarge?.color
                      )))),
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
                      color: Theme.of(context).textTheme.bodyLarge?.color
                    ),
                  ),

                  const SizedBox(width: 40),

                  DropdownButton<String>(
                    value: allBankAccounts.any((account) => account.id == selectedAccount)
                        ? selectedAccount
                        : 'Gesamtübersicht',

                    items: [
                      DropdownMenuItem(
                        value: 'Gesamtübersicht',
                        child: Row(
                          children: [
                            Icon(Icons.show_chart,
                              color: Colors.blue,
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
                          value: account.id,
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

                      if (selectedAccount == 'Gesamtübersicht') {
                      selectedAccountID = 'null';
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

                        cachedYearlyLineChartData = null;
                      });

                      await _reloadAllStatistics();
                    },
                  ),




                ],
              ),

              const Divider(
                thickness: 1,
                color: Colors.black,
                height: 0,
              ),

              const SizedBox(height: 20),



              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 20),
                  Text(
                    'Gesamtverlauf:  ',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold,

                        color: Theme.of(context).textTheme.bodyLarge?.color
                    ),
                  ),
                  const SizedBox(width: 10),

                  GestureDetector(
                    onTap: () => _showYearPicker(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Text(
                        selectedYear,
                        style: TextStyle(fontSize: 16,

                            color: Theme.of(context).textTheme.bodyLarge?.color
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  GestureDetector(
                    onTap: () => _showMonthPicker(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,


                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Text(
                        selectedMonth,
                        style: TextStyle(fontSize: 16,

                            color: Theme.of(context).textTheme.bodyLarge?.color
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              cachedYearlyLineChartData == null || cachedYearlyLineChartData!.isEmpty
                  ? Center(child: Text("Noch keine Daten verfügbar"))
                  : Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,

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


              Row(
                children: [
                  const SizedBox(width: 30),
                  Text(
                    'Kategorieausgaben:  ',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color

                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => _showCategoryPicker(context),

                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,

                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Text(
                        selectedTimeCategory,
                        style: TextStyle(fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color

                        ),
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
            ],
          ),
        ),
      ),
    );
  }
  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 220,
          child: CupertinoPicker(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            itemExtent: 50.0,
            scrollController: FixedExtentScrollController(
              initialItem: selectedTimeCategory == "Monat"
                  ? 0
                  : 1,
            ),
            onSelectedItemChanged: (int index) {
              setState(() {
                selectedTimeCategory = index == 0 ? "Monat" : "Jahr";
              });
            },
            children: [
              Center(child: Text("Monat",
                  style: TextStyle(fontSize: 18,
                      color: Theme.of(context).textTheme.bodyLarge?.color
                  ))),
              Center(child: Text("Jahr",
                  style: TextStyle(fontSize: 18,
                      color: Theme.of(context).textTheme.bodyLarge?.color
                  ))),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(12.0),
          width: 410,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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
                      color: Theme.of(context).textTheme.bodyLarge?.color
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
                  color: Theme.of(context).colorScheme.surface,
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
    return offset / 1;
  }
}
