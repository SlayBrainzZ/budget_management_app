import 'package:flutter/material.dart';
import 'dart:math';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'package:budget_management_app/backend/Category.dart';

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
    final userId = "test_user_id"; // Dynamische Benutzer-ID ersetzen
    userCategories = FirestoreService().getUserCategories(userId);
  }*/
  @override
  void initState() {
    super.initState();
    final userId = "test_user_id"; // Dynamisch durch echte Benutzer-ID ersetzen

    // Initialisieren: Standardkategorien speichern
    FirestoreService().createDefaultCategories(userId).then((_) {
      // Kategorien laden
      setState(() {
        userCategories = FirestoreService().getUserCategories(userId);
      });
    });
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
  /// Liste der Kategorien anzeigen
  Widget _buildCategoryList() {
    return FutureBuilder<List<Category>>(
      future: userCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Fehler beim Laden der Kategorien.'));
        } else {
          final combinedCategories = snapshot.data ?? [];

          return ListView.builder(
            itemCount: combinedCategories.length,
            itemBuilder: (context, index) {
              final category = combinedCategories[index];

              // Überprüfen, ob es sich um eine Standardkategorie handelt (userId == "system")
              final isDefault = category.userId == "system";
              print("Kategorie: ${category.name}, isDefault: $isDefault"); // Debugging-Zeile

              return ListTile(
                leading: Icon(category.icon, color: category.color),
                title: Text(category.name),
                subtitle: Text('Budget: €${category.budgetLimit?.toStringAsFixed(2)}'),
                trailing: isDefault
                    ? null // Keine Mülltonne für Standardkategorien
                    : IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteCategory(category),
                ),
                onTap: isDefault ? () => _editCategoryBudget(category) : null,
              );
            },
          );
        }
      },
    );
  }






  /// Kategorie hinzufügen
  void _addCategory() {
    String newCategoryName = '';
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Kategoriename'),
                    onChanged: (value) {
                      newCategoryName = value;
                    },
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
                        budgetAmount = double.tryParse(value) ?? 0.0;
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: () async {
                    if (newCategoryName.isNotEmpty) {
                      final newCategory = Category(
                        userId: "test_user_id",
                        name: newCategoryName,
                        budgetLimit: hasBudget ? budgetAmount : 0.0,
                        icon: selectedIcon,
                        color: selectedColor,
                      );
                      await FirestoreService().createCategory("test_user_id", newCategory);
                      setState(() {
                        userCategories = FirestoreService().getUserCategories("test_user_id");
                      });
                    }
                    Navigator.of(context).pop();
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
  // Bearbeiten des Budgets für eine Kategorie
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
                    // Budgetlimit aktualisieren
                    category.budgetLimit = budgetAmount;

                    if (category.userId != "system") {
                      // Benutzerdefinierte Kategorien in Firestore aktualisieren
                      await FirestoreService().updateCategory("test_user_id", category);
                    } else {
                      // Standardkategorien: Budgetlimit aktualisieren
                      await FirestoreService().updateCategoryBudgetLimit("test_user_id", category.id!, budgetAmount);
                    }

                    setState(() {
                      userCategories = FirestoreService().getUserCategories("test_user_id");
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




  /// Benutzerdefinierte Kategorie löschen
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
                //await FirestoreService().deleteCategory("test_user_id", category);
                setState(() {
                  //userCategories = FirestoreService().getUserCategories("test_user_id");
                });
                Navigator.of(context).pop();
              },
              child: Text('Löschen'),
            ),
          ],
        );
      },
    );
  }
}
