import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:budget_management_app/backend/firestore_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });

      // Alle Benachrichtigungen als gelesen markieren
      _firestoreService.markAllNotificationsAsRead(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Benachrichtigungen")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getUserNotificationsStream(_userId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(child: Text("Keine Benachrichtigungen vorhanden."));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification = notifications[index];
              var message = notification['message'] ?? "";
              var isRead = notification['isRead'] ?? false;
              String notificationId = notification['id'];

              return ListTile(
                title: Text(message),
                leading: Icon(
                  isRead ? Icons.notifications_none : Icons.notifications_active,
                  color: isRead ? Colors.grey : Colors.blue,
                ),
                onTap: () async {
                  await _firestoreService.markNotificationAsRead(_userId!, notificationId);
                },
              );
            },
          );
        },
      ),
    );
  }
}
