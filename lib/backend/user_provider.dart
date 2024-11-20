import 'package:flutter/material.dart';
import 'package:budget_management_app/backend/User.dart' as testUser;

/**
 * This class provides a way to store and manage the currently logged-in user's information.
 * It uses the ChangeNotifier to notify listeners (typically UI widgets) when the user changes.
 *
 * @author Ahmad
 */

class UserProvider with ChangeNotifier {
  testUser.User? _user;

  testUser.User? get user => _user;

  void setUser(testUser.User user) {
    _user = user;
    notifyListeners(); // Notify listeners when the user changes
  }
}