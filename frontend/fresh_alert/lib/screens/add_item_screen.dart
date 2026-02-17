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
  late Box _box;

  @override
  void initState() {
    super.initState();
    _box = Hive.box('inventoryBox');
  }

  void _saveItem() {
    if (_nameController.text.isEmpty || _expiryDate == null) return;

    final item = InventoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      barcode: widget.barcode,
      buyDate: DateTime.now(),
      expiryDate: _expiryDate!,
      quantity: int.tryParse(_quantityController.text) ?? 1,
      createdAt: DateTime.now(),
    );

    _box.add(item.toMap());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Item")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.barcode != null) Text("Barcode: ${widget.barcode}"),
            const SizedBox(height: 12),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Product Name"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity"),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );

                if (picked != null) {
                  setState(() {
                    _expiryDate = picked;
                  });
                }
              },
              child: const Text("Select Expiry Date"),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveItem,
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
