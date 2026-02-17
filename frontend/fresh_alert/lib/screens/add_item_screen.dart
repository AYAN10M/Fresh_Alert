import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fresh_alert/models/inventory_item.dart';

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

  final List<String> _categories = [
    "Dairy",
    "Vegetables",
    "Fruits",
    "Meat",
    "Snacks",
    "Beverages",
    "Other",
  ];

  // Spotify Dark Palette
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

  void _saveItem() {
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

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: kAccent),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kTextSecondary, fontFamily: 'Manrope'),
      filled: true,
      fillColor: kInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // back arrow visible
        title: const Text(
          "Add Item",
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Barcode Card
              if (widget.barcode != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_rounded, color: kAccent),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.barcode!,
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 26),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("Product Name"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontFamily: 'Manrope',
                        ),
                        decoration: _inputDecoration("Enter product name"),
                      ),

                      const SizedBox(height: 24),

                      _sectionTitle("Category"),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        dropdownColor: kSurface,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontFamily: 'Manrope',
                        ),
                        decoration: _inputDecoration("Select category"),
                        iconEnabledColor: kAccent,
                        items: _categories
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(
                                  cat,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value);
                        },
                      ),

                      const SizedBox(height: 24),

                      _sectionTitle("Quantity"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontFamily: 'Manrope',
                        ),
                        decoration: _inputDecoration("Enter quantity"),
                      ),

                      const SizedBox(height: 24),

                      _sectionTitle("Expiry Date"),
                      const SizedBox(height: 8),

                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: kInput,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _expiryDate == null
                                  ? Colors.transparent
                                  : kAccent,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: kAccent,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                _expiryDate == null
                                    ? "Select expiry date"
                                    : _expiryDate!.toLocal().toString().split(
                                        ' ',
                                      )[0],
                                style: TextStyle(
                                  color: _expiryDate == null
                                      ? kTextSecondary
                                      : kTextPrimary,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    "Save Item",
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: kTextSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: 'Manrope',
      ),
    );
  }
}
