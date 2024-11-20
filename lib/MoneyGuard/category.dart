import 'package:flutter/material.dart';
import 'dart:math';

class CategoryButton extends StatelessWidget {
  final List<IconData> icons = [
    Icons.restaurant,
    Icons.home,
    Icons.directions_car,
    Icons.apartment,
    Icons.attach_money,
    Icons.shopping_cart,
    Icons.school,
    Icons.sports_basketball,
    Icons.work,
    Icons.pets,
  ];

  final List<Color> colors = [
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
  ];

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
            children: List.generate(icons.length, (index) {
              final angle = (2 * pi * index) / icons.length;
              final double radius = 80;

              return Positioned(
                left: radius * cos(angle) + (250 / 2) - 28 / 2,
                top: radius * sin(angle) + (250 / 2) - 28 / 2,
                child: Icon(
                  icons[index],
                  color: colors[index],
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
  final List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Einnahmen', 'icon': Icons.attach_money, 'color': Colors.green},
    {'name': 'Unterhaltung', 'icon': Icons.movie, 'color': Colors.blue},
    {'name': 'Lebensmittel', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'Haushalt', 'icon': Icons.home, 'color': Colors.teal},
    {'name': 'Wohnen', 'icon': Icons.apartment, 'color': Colors.indigo},
    {'name': 'Transport', 'icon': Icons.directions_car, 'color': Colors.purple},
    {'name': 'Kleidung', 'icon': Icons.shopping_bag, 'color': Colors.pink},
    {'name': 'Bildung', 'icon': Icons.school, 'color': Colors.amber},
    {'name': 'Finanzen', 'icon': Icons.account_balance, 'color': Colors.lightGreen},
    {'name': 'Gesundheit', 'icon': Icons.health_and_safety, 'color': Colors.red},
  ];

  List<String> customCategories = [];
  List<IconData> customIcons = [];
  List<Color> customColors = [];

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
    Icons.pets
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

  void _addCategory() {
    String newCategoryName = '';
    IconData selectedIcon = availableIcons[0];
    Color selectedColor = availableColors[0];

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
                      Text("Icon:"),
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
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text("Farbe:"),
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
                            child: Container(
                              width: 24,
                              height: 24,
                              color: color,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Icon(selectedIcon, color: selectedColor, size: 48),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: () {
                    if (newCategoryName.isNotEmpty) {
                      setState(() {
                        customCategories.add(newCategoryName);
                        customIcons.add(selectedIcon);
                        customColors.add(selectedColor);
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

  void _confirmDeleteCategory(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kategorie löschen?'),
          content: Text('Möchten Sie diese Kategorie wirklich löschen?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  customCategories.removeAt(index);
                  customIcons.removeAt(index);
                  customColors.removeAt(index);
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

  Widget _buildCategoryList() {
    return Expanded(
      child: ListView(
        children: [
          ...defaultCategories.map((category) {
            return ListTile(
              leading: Icon(category['icon'], color: category['color']),
              title: Text(category['name']),
            );
          }).toList(),
          ...customCategories.asMap().entries.map((entry) {
            int index = entry.key;
            String category = entry.value;

            return ListTile(
              leading: Icon(customIcons[index], color: customColors[index]),
              title: Text(category),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _confirmDeleteCategory(index);
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kategorien')),
      body: Column(
        children: [
          _buildCategoryList(),
          SizedBox(height: 70),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: Icon(Icons.add),
        tooltip: 'Kategorie hinzufügen',
      ),
    );
  }
}
