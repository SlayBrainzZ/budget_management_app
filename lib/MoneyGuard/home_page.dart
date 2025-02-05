import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:budget_management_app/backend/firestore_service.dart';

import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'saving_plan.dart';
import 'StatisticsPage.dart';
import 'transaction.dart';
import 'settings.dart';
import 'notifications_page.dart';

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
  User? user;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadUser();

  }



  Future<void> _loadUser() async {
    setState(() {
      user = FirebaseAuth.instance.currentUser;
    });
  }

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

          if (user != null) // Sicherstellen, dass user nicht null ist
            StreamBuilder<int>(
            stream: _firestoreService.getUnreadNotificationsCount(user!.uid),
            builder: (context, snapshot) {
              int unreadCount = snapshot.data ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white, size: 32),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsPage()),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                ],
              );
            },
          )
          else
            IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
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

