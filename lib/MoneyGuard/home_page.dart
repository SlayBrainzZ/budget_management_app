import 'package:flutter/material.dart';
import 'dashboard.dart';

/*
void main() {
  runApp(const MyApp());
}*/

class MyApp extends StatelessWidget {
  const MyApp({super.key}); //Konstruktor für MyApp. super.key hilft Flutter, Widgets effizient zu erstellen und zu identifizieren.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(   //MaterialApp ist ein Widget, das die grundlegenden Funktionen einer Flutter-App wie Navigation und Thema (Farben, Textstile) enthält.
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _views = [
    Dashboard(),
    const Center(child: Text('Statistiken')),
    const Center(child: Text('Add')),
    const Center(child: Text('Sparmaßnahmen')),
    const Center(child: Text('Einstellungen')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white, // Titel "MoneyGuard" in Weiß
            fontFamily: 'Roboto',
          ),
        ),
        actions: [    //actions: [: Dies beginnt eine Liste von Widgets, die in der rechten Ecke der App-Leiste angezeigt werden (
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white), // Glocken-Symbol
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
        onTap: _onItemTapped,
      ),
    );
  }
}
