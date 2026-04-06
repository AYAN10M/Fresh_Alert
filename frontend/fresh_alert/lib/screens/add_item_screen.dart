import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fresh_alert/models/inventory_item.dart';
import 'package:fresh_alert/services/notification_service.dart';
import 'package:fresh_alert/services/open_food_facts_service.dart';
import 'package:fresh_alert/theme/app_colors.dart';

class AddItemScreen extends StatefulWidget {
  final String? barcode;
  const AddItemScreen({super.key, this.barcode});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: "1");
  final _locationController = TextEditingController();

  DateTime? _expiryDate;
  String? _selectedCategory;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _imageUrl; // network URL (Open Food Facts) or local file path

  late Box _box;
  final NotificationService _notificationService = NotificationService();
  final ImagePicker _imagePicker = ImagePicker();

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
    if (widget.barcode != null && widget.barcode!.isNotEmpty) {
      _fetchProductDetails(widget.barcode!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ── AUTO-FETCH ──────────────────────────────────────────────────────────────
  Future<void> _fetchProductDetails(String barcode) async {
    setState(() => _isLoading = true);

    final product = await OpenFoodFactsService.fetchProduct(barcode);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (product != null) {
      setState(() {
        _nameController.text = product.name;
        if (product.category != null) _selectedCategory = product.category;
        _imageUrl = product.imageUrl;
      });
      _showSnack('Product found: ${product.name}');
    } else {
      _showSnack('Product not found — fill details manually');
    }
  }

  // ── PHOTO PICKER ────────────────────────────────────────────────────────────
  void _showImageOptions() {
    final c = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: c.dragHandle,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              _ImageOptionTile(
                icon: Icons.camera_alt_outlined,
                label: 'Take Photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              _ImageOptionTile(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_imageUrl != null) ...[
                const SizedBox(height: 8),
                _ImageOptionTile(
                  icon: Icons.close_rounded,
                  label: 'Remove Photo',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _imageUrl = null);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() => _imageUrl = picked.path);
      }
    } catch (_) {
      // Permission denied or camera unavailable — silently ignore
    }
  }

  // ── SAVE ────────────────────────────────────────────────────────────────────
  Future<void> _saveItem() async {
    final name = _nameController.text.trim();

    // Validate name
    if (name.isEmpty) {
      HapticFeedback.mediumImpact();
      _showSnack('Please enter a product name');
      return;
    }

    // Validate expiry
    if (_expiryDate == null) {
      HapticFeedback.mediumImpact();
      _showSnack('Please select an expiry date');
      return;
    }

    // Date-only comparison to avoid time-of-day edge cases
    final todayDate = DateUtils.dateOnly(DateTime.now());
    final expiryDateOnly = DateUtils.dateOnly(_expiryDate!);

    if (!expiryDateOnly.isAfter(todayDate)) {
      _showSnack('Item is already expired or expires today');
      return;
    }

    // Prevent double-tap
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final category = _selectedCategory ?? 'Other';
    final location = _locationController.text.trim();

    final item = InventoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      barcode: widget.barcode,
      buyDate: DateTime.now(),
      expiryDate: _expiryDate!,
      quantity: int.tryParse(_quantityController.text) ?? 1,
      category: category,
      location: location.isNotEmpty ? location : null,
      imageUrl: _imageUrl,
      createdAt: DateTime.now(),
    );

    _box.add(item.toMap());

    // Schedule notification
    try {
      final leadDays = _notificationService.getLeadDays(category);
      final notificationDate = _expiryDate!.subtract(Duration(days: leadDays));
      if (notificationDate.isAfter(DateTime.now())) {
        final bodyText = leadDays == 1
            ? '${item.name} expires tomorrow.'
            : '${item.name} expires in $leadDays days.';
        await _notificationService.scheduleNotification(
          id: item.id.hashCode,
          title: 'Item Expiring Soon',
          body: bodyText,
          scheduledDate: notificationDate,
        );
      }
    } catch (_) {
      // Item is already saved — still pop.
    }

    if (!mounted) return;
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  // ── DATE PICKER ─────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
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
    final days = DateUtils.dateOnly(
      d,
    ).difference(DateUtils.dateOnly(DateTime.now())).inDays;
    final rel = days == 1 ? "in 1 day" : "in $days days";
    return "${d.day} ${months[d.month]} ${d.year}  ·  $rel";
  }

  Color get _dateColor {
    if (_expiryDate == null) return AppColors.of(context).onSurfaceVariant;
    final days = DateUtils.dateOnly(
      _expiryDate!,
    ).difference(DateUtils.dateOnly(DateTime.now())).inDays;
    if (days <= 1) return StatusColors.red;
    if (days <= 3) return StatusColors.orange;
    return StatusColors.green;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final hasBarcode = widget.barcode != null && widget.barcode!.isNotEmpty;
    final bool isLocalImage =
        _imageUrl != null && !_imageUrl!.startsWith('http');
    final theme = Theme.of(context);
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.onSurfaceVariant),
        titleSpacing: 4,
        title: Text(
          "Add Item",
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: c.onSurface,
          ),
        ),
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 420;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── BARCODE CHIP + IMAGE ─────────────────────────
                      if (hasBarcode) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: c.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: c.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.qr_code_rounded,
                                    size: 13,
                                    color: c.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.barcode!,
                                    style: TextStyle(
                                      fontFamily: 'NotoSans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: c.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (_isLoading) ...[
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    c.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Fetching product…',
                                style: TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 12,
                                  color: c.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── IMAGE ───────────────────────────────────────
                      GestureDetector(
                        onTap: _showImageOptions,
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            color: c.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: c.outlineVariant.withValues(alpha: 0.45),
                            ),
                          ),
                          child: _imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: isLocalImage
                                      ? Image.file(
                                          File(_imageUrl!),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _imagePlaceholder(context),
                                        )
                                      : Image.network(
                                          _imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _imagePlaceholder(context),
                                        ),
                                )
                              : _imagePlaceholder(context),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── PRODUCT NAME ────────────────────────────────
                      const _Label("Product name"),
                      const SizedBox(height: 8),
                      _InputField(
                        controller: _nameController,
                        hint: "e.g. Whole Milk",
                        autofocus: !hasBarcode,
                      ),

                      const SizedBox(height: 20),

                      // ── CATEGORY ────────────────────────────────────
                      const _Label("Category"),
                      const SizedBox(height: 8),
                      _CategoryPicker(
                        categories: _categories,
                        selected: _selectedCategory,
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      ),

                      const SizedBox(height: 20),

                      // ── QUANTITY + DATE ──────────────────────────────
                      if (isCompact)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Label("Quantity"),
                            const SizedBox(height: 8),
                            _QuantityStepper(
                              value: _qty,
                              onDecrement: () => _changeQty(-1),
                              onIncrement: () => _changeQty(1),
                            ),
                            const SizedBox(height: 20),
                            const _Label("Expiry date"),
                            const SizedBox(height: 8),
                            _DateTap(
                              label: _dateLabel,
                              color: _dateColor,
                              hasValue: _expiryDate != null,
                              onTap: _pickDate,
                            ),
                          ],
                        )
                      else
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

                      const SizedBox(height: 20),

                      // ── LOCATION ────────────────────────────────────
                      const _Label("Storage location (optional)"),
                      const SizedBox(height: 8),
                      _InputField(
                        controller: _locationController,
                        hint: "e.g. Fridge, Pantry, Freezer",
                      ),

                      const Spacer(),
                      const SizedBox(height: 20),

                      // ── SAVE ────────────────────────────────────────
                      _SaveButton(onTap: _saveItem, isLoading: _isSaving),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo_outlined,
          size: 24,
          color: c.onSurfaceVariant,
        ),
        SizedBox(height: 4),
        Text(
          'Photo',
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 11,
            color: c.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE OPTION TILE (bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────
class _ImageOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _ImageOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = destructive ? StatusColors.red : c.primary;
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: color.withValues(alpha: 0.07),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: destructive ? StatusColors.red : c.onSurface,
                ),
              ),
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
    style: TextStyle(
      fontFamily: 'NotoSans',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: AppColors.of(context).onSurfaceVariant,
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
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return TextField(
      controller: controller,
      autofocus: autofocus,
      style: TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: c.onSurface,
      ),
      cursorColor: c.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'NotoSans',
          color: c.onSurfaceVariant,
          fontSize: 15,
        ),
        filled: true,
        fillColor: c.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: c.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                color: sel
                    ? c.primary.withValues(alpha: 0.15)
                    : c.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: sel
                      ? c.primary.withValues(alpha: 0.5)
                      : c.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: sel ? c.primary : c.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: c.outlineVariant.withValues(alpha: 0.45),
        ),
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
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.onSurface,
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
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
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
          color: _pressed
              ? c.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          widget.icon,
          size: 18,
          color: widget.enabled
              ? c.onSurfaceVariant
              : c.onSurface.withValues(alpha: 0.25),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
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
          color: _pressed
              ? widget.color.withValues(alpha: 0.08)
              : c.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.hasValue
                ? widget.color.withValues(alpha: 0.4)
                : c.outlineVariant.withValues(alpha: 0.45),
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
                  color: widget.hasValue
                      ? widget.color
                      : c.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SAVE BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _SaveButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLoading;
  const _SaveButton({required this.onTap, this.isLoading = false});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.isLoading
          ? null
          : (_) {
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
            color: widget.isLoading
                ? c.primary.withValues(alpha: 0.5)
                : c.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(c.onPrimary),
                  ),
                )
              : Text(
                  "Save Item",
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: c.onPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
