import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:fresh_alert/models/inventory_item.dart';
import 'package:fresh_alert/services/notification_service.dart';

// ── colour tokens ─────────────────────────────────────────────────────────────
const _kBg = Color(0xFF0A0A0A);
const _kInput = Color(0xFF1A1A1A);
const _kGreen = Color(0xFF1DB954);
const _kBorder = Color(0xFF242424);
const _kMuted = Color(0xFF555555);

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

  @override
  void initState() {
    super.initState();
    _box = Hive.box('inventoryBox');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _expiryDate == null) {
      HapticFeedback.mediumImpact();
      return;
    }

    final item = InventoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      barcode: widget.barcode,
      buyDate: DateTime.now(),
      expiryDate: _expiryDate!,
      quantity: int.tryParse(_quantityController.text) ?? 1,
      category: _selectedCategory,
      createdAt: DateTime.now(),
    );

    _box.add(item.toMap());

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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kGreen,
            surface: Color(0xFF1C1C1C),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted) return;
    if (picked != null) setState(() => _expiryDate = picked);
  }

  int get _qty => int.tryParse(_quantityController.text) ?? 1;

  void _changeQty(int delta) {
    final next = (_qty + delta).clamp(1, 99);
    _quantityController.text = next.toString();
    setState(() {});
  }

  String get _dateLabel {
    if (_expiryDate == null) return "Select expiry date";
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = _expiryDate!;
    final days = d.difference(DateTime.now()).inDays;
    final rel = days == 0
        ? "today"
        : days == 1
        ? "in 1 day"
        : "in $days days";
    return "${d.day} ${months[d.month]} ${d.year}  ·  $rel";
  }

  Color get _dateColor {
    if (_expiryDate == null) return _kMuted;
    final days = _expiryDate!.difference(DateTime.now()).inDays;
    if (days <= 1) return const Color(0xFFFF453A);
    if (days <= 3) return const Color(0xFFFF9F0A);
    return _kGreen;
  }

  @override
  Widget build(BuildContext context) {
    final hasBarcode = widget.barcode != null && widget.barcode!.isNotEmpty;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
        titleSpacing: 4,
        title: const Text(
          "Add Item",
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: Colors.white,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── BARCODE CHIP ────────────────────────────────────────
              if (hasBarcode) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.qr_code_rounded,
                        size: 13,
                        color: _kGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.barcode!,
                        style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── PRODUCT NAME ────────────────────────────────────────
              const _Label("Product name"),
              const SizedBox(height: 8),
              _InputField(
                controller: _nameController,
                hint: "e.g. Whole Milk",
                autofocus: true,
              ),

              const SizedBox(height: 20),

              // ── CATEGORY ───────────────────────────────────────────
              const _Label("Category"),
              const SizedBox(height: 8),
              _CategoryPicker(
                categories: _categories,
                selected: _selectedCategory,
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),

              const SizedBox(height: 20),

              // ── QUANTITY + DATE ─────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label("Quantity"),
                        const SizedBox(height: 8),
                        _QuantityStepper(
                          value: _qty,
                          onDecrement: () => _changeQty(-1),
                          onIncrement: () => _changeQty(1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label("Expiry date"),
                        const SizedBox(height: 8),
                        _DateTap(
                          label: _dateLabel,
                          color: _dateColor,
                          hasValue: _expiryDate != null,
                          onTap: _pickDate,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ── SAVE ────────────────────────────────────────────────
              _SaveButton(onTap: _saveItem),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD LABEL
// ─────────────────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'NotoSans',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: Colors.white38,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TEXT INPUT
// ─────────────────────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;

  const _InputField({
    required this.controller,
    required this.hint,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: autofocus,
    style: const TextStyle(
      fontFamily: 'NotoSans',
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    cursorColor: _kGreen,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'NotoSans',
        color: _kMuted,
        fontSize: 15,
      ),
      filled: true,
      fillColor: _kInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kGreen, width: 1.5),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY CHIP ROW
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryPicker extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _CategoryPicker({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final cat = categories[i];
        final sel = cat == selected;
        return GestureDetector(
          onTap: () => onChanged(sel ? null : cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sel ? _kGreen.withValues(alpha: 0.15) : _kInput,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sel ? _kGreen.withValues(alpha: 0.5) : _kBorder,
              ),
            ),
            child: Text(
              cat,
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sel ? _kGreen : Colors.white38,
              ),
            ),
          ),
        );
      },
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// QUANTITY STEPPER
// ─────────────────────────────────────────────────────────────────────────────
class _QuantityStepper extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    decoration: BoxDecoration(
      color: _kInput,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _kBorder),
    ),
    child: Row(
      children: [
        _StepBtn(
          icon: Icons.remove_rounded,
          onTap: onDecrement,
          enabled: value > 1,
        ),
        Expanded(
          child: Center(
            child: Text(
              "$value",
              style: const TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        _StepBtn(
          icon: Icons.add_rounded,
          onTap: onIncrement,
          enabled: value < 99,
        ),
      ],
    ),
  );
}

class _StepBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _StepBtn({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<_StepBtn> createState() => _StepBtnState();
}

class _StepBtnState extends State<_StepBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
    onTapUp: widget.enabled
        ? (_) {
            setState(() => _pressed = false);
            widget.onTap();
          }
        : null,
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: 44,
      height: 48,
      decoration: BoxDecoration(
        color: _pressed ? _kGreen.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        widget.icon,
        size: 18,
        color: widget.enabled ? Colors.white54 : Colors.white12,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE TAP BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _DateTap extends StatefulWidget {
  final String label;
  final Color color;
  final bool hasValue;
  final VoidCallback onTap;

  const _DateTap({
    required this.label,
    required this.color,
    required this.hasValue,
    required this.onTap,
  });

  @override
  State<_DateTap> createState() => _DateTapState();
}

class _DateTapState extends State<_DateTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      widget.onTap();
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _pressed ? widget.color.withValues(alpha: 0.08) : _kInput,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.hasValue
              ? widget.color.withValues(alpha: 0.4)
              : _kBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: widget.color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.hasValue ? widget.color : _kMuted,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SAVE BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _SaveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SaveButton({required this.onTap});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      widget.onTap();
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: _kGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: const Text(
          "Save Item",
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: 0.2,
          ),
        ),
      ),
    ),
  );
}
