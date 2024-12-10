import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:budget_management_app/backend/Transaction.dart';
import 'package:budget_management_app/backend/Category.dart';
import 'package:budget_management_app/backend/firestore_service.dart';
import 'home_page.dart';

class AddTransactionPage extends StatefulWidget {
  final Transaction? transaction; // Optional: übergebene Transaktion

  const AddTransactionPage({Key? key, this.transaction}) : super(key: key);

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isUrgent = false;
  String? _userId;
  String? _selectedAccount;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final List<String> accounts = ['Konto 1', 'Konto 2', 'Konto 3'];
  List<Category> categories = [];
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserAndCategories();

    if (widget.transaction != null) {
      final transaction = widget.transaction!;
      _selectedDate = transaction.date;
      _noteController.text = transaction.note ?? '';
      _amountController.text = transaction.amount.toStringAsFixed(2);
      _selectedCategory = transaction.categoryId;
      _isUrgent = transaction.importance;

      // Setze den Tab basierend auf dem Transaktionstyp
      if (transaction.type == 'Einnahme') {
        _tabController.index = 1; // Setze auf Einnahme-Tab
      } else {
        _tabController.index = 0; // Setze auf Ausgabe-Tab
      }
    }
  }


  Future<void> _loadUserAndCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      List<Category> userCategories =
      await _firestoreService.getUserCategories(user.uid);
      setState(() {
        _userId = user.uid;
        categories = userCategories;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('de', 'DE'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked =
    await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveTransaction(String type) {
    final transaction = Transaction(
      userId: _userId!,
      amount: double.tryParse(_amountController.text) ?? 0.0,
      date: _selectedDate,
      categoryId: _selectedCategory,
      type: type,
      importance: _isUrgent,
      note: _noteController.text,
    );

    _firestoreService.createTransaction(_userId!, transaction).then((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyHomePage(title: 'MoneyGuard')),
            (Route<dynamic> route) => false,
      );
    });
  }

  void _deleteTransaction() {
    if (widget.transaction == null) return;

    _firestoreService
        .deleteTransaction(_userId!, widget.transaction!.id!)
        .then((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyHomePage(title: 'MoneyGuard')),
            (Route<dynamic> route) => false,
      );
    });
  }

  void _saveOrUpdateTransaction(String type) {

    if (_selectedAccount == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte wählen Sie ein Konto und eine Kategorie aus.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }//entferne diese if bedingung wenn auch ohne kategorie auswahl oder konto auswahl

    if (widget.transaction != null) {
      // Update bestehende Transaktion
      final updatedTransaction = widget.transaction!.copyWith(
        //userId: _userId,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        date: _selectedDate,
        categoryId: _selectedCategory,
        type: type,
        importance: _isUrgent,
        note: _noteController.text,
        id: widget.transaction!.id, // Übergibt die ID hier
      );

      _firestoreService.updateTransaction(_userId!,widget.transaction!.id!, updatedTransaction).then((_) {
        Navigator.of(context).pop(); // Zurück zur vorherigen Seite
      });
    } else {
      // Neue Transaktion erstellen
      _saveTransaction(type);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuer Eintrag'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ausgabe'),
            Tab(text: 'Einnahme'),
          ],
        ),
      ),
      body: _userId == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildForm(context, 'Ausgabe'),
          _buildForm(context, 'Einnahme'),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, String type) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Row(
            children: [
              const SizedBox(width: 20),
              Text(
                'EUR',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: type == 'Ausgabe' ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Betrag',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: _selectedAccount,
            decoration: const InputDecoration(labelText: 'Konto auswählen'),
            items: accounts
                .map((account) =>
                DropdownMenuItem(value: account, child: Text(account)))
                .toList(),
            onChanged: (value) => setState(() => _selectedAccount = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Kategorie auswählen'),
            items: categories.map((category) {
              return DropdownMenuItem(
                value: category.id,
                child: Row(
                  children: [
                    if (category.icon != null) ...[
                      Icon(category.icon, color: category.color ?? Colors.black),
                      const SizedBox(width: 10),
                    ],
                    Text(category.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(
                'Datum: ${DateFormat('dd.MM.yyyy', 'de_DE').format(_selectedDate)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context),
          ),
          ListTile(
            title: Text('Uhrzeit: ${_selectedTime.format(context)}'),
            trailing: const Icon(Icons.access_time),
            onTap: () => _selectTime(context),
          ),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Notiz hinzufügen'),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Dringend'),
            value: _isUrgent,
            onChanged: (bool value) {
              setState(() {
                _isUrgent = value;
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_userId != null) {
                _saveOrUpdateTransaction(type);
              }
            },
            child: const Text('Speichern'),
          ),
          const SizedBox(height: 16),
          if (widget.transaction != null) // Zeige Löschen-Button nur bei existierenden Transaktionen
            ElevatedButton(
              onPressed: _deleteTransaction,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Löschen',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
