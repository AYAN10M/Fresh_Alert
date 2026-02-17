import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fresh_alert/models/inventory_item.dart';
import 'package:fresh_alert/services/notification_service.dart';

class AddItemScreen extends StatefulWidget {
  final String? barcode;

  const AddItemScreen({super.key, this.barcode});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: "1");

  DateTime? _expiryDate;
  String? _selectedCategory;

  late Box _box;
  final NotificationService _notificationService = NotificationService();

  final List<String> _categories = [
    "Dairy",
    "Vegetables",
    "Fruits",
    "Meat",
    "Snacks",
    "Beverages",
    "Other",
  ];

  static const Color kBackground = Color(0xFF0F0F0F);
  static const Color kSurface = Color(0xFF181818);
  static const Color kInput = Color(0xFF202020);
  static const Color kAccent = Color(0xFF1DB954);
  static const Color kTextPrimary = Colors.white;
  static const Color kTextSecondary = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    _box = Hive.box('inventoryBox');
  }

  Future<void> _saveItem() async {
    if (_nameController.text.trim().isEmpty || _expiryDate == null) return;

    final item = InventoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      barcode: widget.barcode,
      buyDate: DateTime.now(),
      expiryDate: _expiryDate!,
      quantity: int.tryParse(_quantityController.text) ?? 1,
      category: _selectedCategory,
      createdAt: DateTime.now(),
    );

    _box.add(item.toMap());

    // 🔔 Schedule notification 1 day before expiry
    final notificationDate = _expiryDate!.subtract(const Duration(days: 1));

    if (notificationDate.isAfter(DateTime.now())) {
      await _notificationService.scheduleNotification(
        id: item.id.hashCode,
        title: "Item Expiring Soon",
        body: "${item.name} expires tomorrow.",
        scheduledDate: notificationDate,
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (!mounted) return;
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kTextSecondary),
      filled: true,
      fillColor: kInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: kAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Add Item",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: kTextPrimary),
              decoration: _inputDecoration("Product name"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              dropdownColor: kSurface,
              style: const TextStyle(color: kTextPrimary),
              decoration: _inputDecoration("Select category"),
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: kTextPrimary),
              decoration: _inputDecoration("Quantity"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickDate,
              style: ElevatedButton.styleFrom(backgroundColor: kAccent),
              child: Text(
                _expiryDate == null
                    ? "Select Expiry Date"
                    : _expiryDate!.toLocal().toString().split(' ')[0],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Save Item"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
