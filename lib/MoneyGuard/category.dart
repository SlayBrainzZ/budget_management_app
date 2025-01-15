import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:budget_management_app/backend/Category.dart';
import 'package:budget_management_app/backend/User.dart';

import '../backend/Transaction.dart';


final List<Map<String, dynamic>> defaultCategories = [
  {'name': 'Einnahmen', 'icon': Icons.attach_money, 'color': Colors.green, 'budgetLimit': 0.0},
  {'name': 'Unterhaltung', 'icon': Icons.movie, 'color': Colors.blue, 'budgetLimit': 0.0},
  {'name': 'Lebensmittel', 'icon': Icons.restaurant, 'color': Colors.orange, 'budgetLimit': 0.0},
  {'name': 'Haushalt', 'icon': Icons.home, 'color': Colors.teal, 'budgetLimit': 0.0},
  {'name': 'Wohnen', 'icon': Icons.apartment, 'color': Colors.indigo, 'budgetLimit': 0.0},
  {'name': 'Transport', 'icon': Icons.directions_car, 'color': Colors.purple, 'budgetLimit': 0.0},
  {'name': 'Kleidung', 'icon': Icons.shopping_bag, 'color': Colors.pink, 'budgetLimit': 0.0},
  {'name': 'Bildung', 'icon': Icons.school, 'color': Colors.amber, 'budgetLimit': 0.0},
  {'name': 'Finanzen', 'icon': Icons.account_balance, 'color': Colors.lightGreen, 'budgetLimit': 0.0},
  {'name': 'Gesundheit', 'icon': Icons.health_and_safety, 'color': Colors.red, 'budgetLimit': 0.0},
];



final List<IconData> availableIcons = [
  Icons.more_horiz,
  Icons.restaurant,
  Icons.home,
  Icons.directions_car,
  Icons.shopping_cart,
  Icons.health_and_safety,
  Icons.attach_money,
  Icons.safety_check,
  Icons.shopping_bag,
  Icons.savings,
  Icons.school,
  Icons.sports_basketball,
  Icons.work,
  Icons.pets,
];

final List<Color> availableColors = [
  Colors.blueGrey,
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.yellow,
  Colors.cyan,
  Colors.indigo,
  Colors.pink,
  Colors.brown,
];

class CategoryButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CategoryScreen()),
          );
        },
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 4,
                blurRadius: 8,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(defaultCategories.length, (index) {
              final angle = (2 * pi * index) / defaultCategories.length;
              final double radius = 80;

              return Positioned(
                left: radius * cos(angle) + (250 / 2) - 28 / 2,
                top: radius * sin(angle) + (250 / 2) - 28 / 2,
                child: Icon(
                  defaultCategories[index]['icon'] as IconData,
                  color: defaultCategories[index]['color'] as Color,
                  size: 28,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
class CategoryScreen extends StatefulWidget {
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<Category>> userCategories;
/*
  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userId = user.uid;  // Hier die UID verwenden
      setState(() {
        FirestoreService().createDefaultCategories(userId);
        userCategories = FirestoreService().getSortedUserCategories(userId);
      });
    } else {
      // Falls kein Benutzer angemeldet ist, handle diesen Fall
      print("Kein Benutzer angemeldet.");
    }
  }*/


  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userId = user.uid;

      // Erstellen und Laden der Kategorien
      userCategories = FirestoreService().createDefaultCategories(userId).then((_) {
        return FirestoreService().getSortedUserCategories(userId);
      });
    } else {
      print("Kein Benutzer angemeldet.");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kategorien")),
      body: _buildCategoryList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: Icon(Icons.add),
      ),
    );
  }

  /// Liste der Kategorien anzeigen
  Widget _buildCategoryList() {
    final double fabHeight = 56.0; // Standardhöhe des FloatingActionButton
    final double fabPadding = 16.0; // Abstand zwischen Liste und FAB

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight - fabHeight - fabPadding;

        return FutureBuilder<List<Category>>(
          future: userCategories,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Fehler beim Laden der Kategorien.'));
            } else {
              var categories = snapshot.data ?? [];

              // Standardkategorien zuerst sortieren
              categories.sort((a, b) {
                if (a.isDefault && !b.isDefault) return -1;
                if (!a.isDefault && b.isDefault) return 1;
                return 0;
              });

              // Beschränke die Liste auf den Platz oberhalb des FAB
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];

                    return ListTile(
                      leading: Icon(category.icon, color: category.color),
                      title: Text(category.name),
                      subtitle: Text('Budget: €${category.budgetLimit?.toStringAsFixed(2)}'),
                      trailing: category.isDefault
                          ? null // Keine Mülltonne für Standardkategorien
                          : IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteCategory(category),
                      ),
                      onTap: () => _editCategoryBudget(category),
                    );
                  },
                ),
              );
            }
          },
        );
      },
    );
  }



  void _addCategory() {
    final nameController = TextEditingController();
    IconData selectedIcon = availableIcons.first;
    Color selectedColor = availableColors.first;
    double? budgetAmount;
    bool hasBudget = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Neue Kategorie hinzufügen'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Kategoriename'),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Icon:'),
                        SizedBox(width: 10),
                        DropdownButton<IconData>(
                          value: selectedIcon,
                          onChanged: (IconData? newIcon) {
                            if (newIcon != null) {
                              setDialogState(() {
                                selectedIcon = newIcon;
                              });
                            }
                          },
                          items: availableIcons.map((icon) {
                            return DropdownMenuItem(
                              value: icon,
                              child: Icon(icon),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Farbe:'),
                        SizedBox(width: 10),
                        DropdownButton<Color>(
                          value: selectedColor,
                          onChanged: (Color? newColor) {
                            if (newColor != null) {
                              setDialogState(() {
                                selectedColor = newColor;
                              });
                            }
                          },
                          items: availableColors.map((color) {
                            return DropdownMenuItem(
                              value: color,
                              child: Container(width: 24, height: 24, color: color),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Budget hinzufügen'),
                        Switch(
                          value: hasBudget,
                          onChanged: (value) {
                            setDialogState(() {
                              hasBudget = value;
                            });
                          },
                        ),
                      ],
                    ),
                    if (hasBudget)
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Budget (€)'),
                        onChanged: (value) {
                          budgetAmount = double.tryParse(value);
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: () async {
                    final newCategoryName = nameController.text.trim();
                    if (newCategoryName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Bitte einen gültigen Kategorienamen eingeben')),
                      );
                      return;
                    }

                    if (budgetAmount == null) {
                      budgetAmount = 0.0;
                    }

                    // Hole die Benutzer-ID
                    final user = FirebaseAuth.instance.currentUser;

                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Kein Benutzer angemeldet.')),
                      );
                      return;
                    }

                    final userId = user.uid;

                    // Neue Kategorie erstellen
                    Category newCategory = Category(
                      userId: userId,
                      name: newCategoryName,
                      budgetLimit: hasBudget ? budgetAmount : 0.0,
                      icon: selectedIcon,
                      color: selectedColor,
                    );

                    try {
                      await FirestoreService().createCategory(userId, newCategory);

                      setState(() {
                        userCategories = FirestoreService().getSortedUserCategories(userId);
                      });

                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fehler beim Speichern der Kategorie: $e')),
                      );
                    }
                  },
                  child: Text('Hinzufügen'),
                ),
              ],
            );
          },
        );
      },
    );
  }




  /// Kategorie-Budget bearbeiten
  void _editCategoryBudget(Category category) {
    double budgetAmount = category.budgetLimit ?? 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Budget bearbeiten: ${category.name}'),
              content: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Budget (€)'),
                onChanged: (value) {
                  budgetAmount = double.tryParse(value) ?? 0.0;
                },
                controller: TextEditingController(text: budgetAmount.toStringAsFixed(2)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;

                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Kein Benutzer angemeldet.')),
                      );
                      return;
                    }

                    // Budgetlimit aktualisieren
                    category.budgetLimit = budgetAmount;

                    if (category.userId != "system") {
                      // Benutzerdefinierte Kategorien in Firestore aktualisieren
                      await FirestoreService().updateCategoryBudgetLimit(user.uid, category.id!, category.budgetLimit!);
                    } else {
                      // Standardkategorien: Budgetlimit aktualisieren
                      await FirestoreService()
                          .updateCategoryBudgetLimit(user.uid, category.id!, budgetAmount);
                    }

                    setState(() {
                      userCategories = FirestoreService().getSortedUserCategories(user.uid);
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('Speichern'),
                ),
              ],
            );
          },
        );
      },
    );
  }




/*
  void _confirmDeleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kategorie löschen'),
          content: Text('Möchten Sie die Kategorie "${category.name}" wirklich löschen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;

                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kein Benutzer angemeldet.')),
                  );
                  return;
                }

                try {
                  await FirestoreService().deleteCategory(user.uid, category.id!);

                  setState(() {
                    userCategories = FirestoreService().getSortedUserCategories(user.uid);
                  });
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler beim Löschen der Kategorie: $e')),
                  );
                }
              },
              child: Text('Löschen'),
            ),
          ],
        );
      },
    );
  }*/
  void _confirmDeleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kategorie löschen'),
          content: FutureBuilder<List<Transaction>>(
            future: FirestoreService().getTransactionsByCategory(FirebaseAuth.instance.currentUser!.uid, category.id!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Fehler beim Abrufen der Transaktionen.');
              } else {
                final transactions = snapshot.data ?? [];
                return Text(transactions.isNotEmpty
                    ? 'Die Kategorie "${category.name}" hat ${transactions.length} zugehörige Transaktionen. Wenn Sie die Kategorie löschen, werden diese ebenfalls entfernt. Möchten Sie fortfahren?'
                    : 'Möchten Sie die Kategorie "${category.name}" wirklich löschen?');
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;

                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kein Benutzer angemeldet.')),
                  );
                  return;
                }

                try {
                  // Hole Transaktionen zur Kategorie
                  final transactions = await FirestoreService().getTransactionsByCategory(user.uid, category.id!);

                  // Lösche alle Transaktionen der Kategorie
                  for (var transaction in transactions) {
                    await FirestoreService().deleteTransaction(user.uid, transaction.id!);
                  }

                  // Lösche die Kategorie
                  await FirestoreService().deleteCategory(user.uid, category.id!);

                  setState(() {
                    userCategories = FirestoreService().getSortedUserCategories(user.uid);
                  });
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler beim Löschen der Kategorie: $e')),
                  );
                }
              },
              child: Text('Löschen'),
            ),
          ],
        );
      },
    );
  }

}