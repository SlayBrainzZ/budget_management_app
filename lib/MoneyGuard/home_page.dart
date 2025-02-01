import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'saving_plan.dart';
import 'StatisticsPage.dart';
import 'transaction.dart';
import 'settings.dart';

import 'package:flutter_localizations/flutter_localizations.dart'; // Dieser Import ist notwendig




class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        Locale('de', 'DE'),
      ],
      home: const MyHomePage(title: 'MoneyGuard'),
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
  int _selectedIndex = 0;

  void _tappedItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  final List<Widget> _views = [
    Dashboard(),
    StatisticsPage(),
    AddTransactionPage(),
    SavingPlan(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 2
          ? null
          : AppBar(
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
        child: _views[_selectedIndex],
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

