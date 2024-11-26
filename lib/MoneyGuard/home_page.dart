import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'saving_plan.dart';
import 'StatisticsPage.dart';
import 'transaction.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Dieser Import ist notwendig


/*
void main() {
  runApp(const MyApp());
}*/

class MyApp extends StatelessWidget {
  const MyApp({super.key}); //Konstruktor für MyApp. super.key hilft Flutter, Widgets effizient zu erstellen und zu identifizieren.
//Ein Widget, das keinen internen Zustand hat
  @override
  Widget build(BuildContext context) {
    return MaterialApp(   //MaterialApp ist ein Widget, das die grundlegenden Funktionen einer Flutter-App wie Navigation und Thema (Farben, Textstile) enthält.
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de', 'DE'), // Deutsche Lokalisierung
      ],
      home: const MyHomePage(title: 'MoneyGuard'),   //Setzt die Startseite der App auf MyHomePage
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;  // Diese Variable speichert den aktuell ausgewählten Index der BottomNavigationBar.

  void _tappedItem(int index) {
    setState(() {
      _selectedIndex = index;  // Überschreibt index und aktualisiert den Zustand der App, sodass das UI neu gezeichnet wird.
    });
  }

  final List<Widget> _views = [
    Dashboard(), // Dashboard Widget
    StatisticsPage(),
    AddTransactionPage(),
    SavingPlan(),
    const Center(child: Text('Einstellungen')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 2
          ? null  // Wenn der Index 2 (Plus-Button) ist, wird die AppBar nicht angezeigt.
          : AppBar(  // Wenn der Index nicht 2 ist, zeigen wir die AppBar an.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Aktion für Benachrichtigungen
            },
          ),
        ],
      ),
      body: Center(
        child: _views[_selectedIndex],  // Zeigt die aktuell ausgewählte Seite basierend auf dem Index.
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 30),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart, size: 30),
            label: 'Statistiken',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 55,
              height: 55,
              child: CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ),
            label: ' ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings, size: 30),
            label: 'Sparen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 30),
            label: 'Einstellungen',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal[300]!,
        unselectedItemColor: Colors.grey,
        onTap: _tappedItem,
      ),
    );
  }
}

