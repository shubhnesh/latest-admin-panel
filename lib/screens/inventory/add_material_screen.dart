import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/dialogs/category_dialog.dart';
import 'package:rdx_admin/widgets/dialogs/rdx_notice_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_header.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/inventory_category_model.dart';
import '../../models/inventory_item_model.dart';
import '../../models/unit_model.dart';
import '../../providers/inventory_provider.dart';
import '../../services/inventory_category_service.dart';
import '../../services/unit_service.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/rdx_text_field.dart';
import '../../widgets/reusable_widgets/rdx_dropdown.dart';
import 'inventory_manage_category_screen.dart';

/// Sentinel value placed as the first entry in the category dropdown.
/// Selecting it opens [CreateInventoryCategoryDialog] instead of setting a category.
const String _kCreateCategoryValue = '__create_category__';

/// Sentinel value placed as the first entry in the unit dropdown.
/// Selecting it opens [CreateUnitDialog].
const String _kCreateUnitValue = '__create_unit__';

/// Rejects any edit that would make the number greater than [maxValue].
/// If [maxValue] is null, all numeric input is allowed.
class _MaxValueInputFormatter extends TextInputFormatter {
  final double? maxValue;

  _MaxValueInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Allow intermediate typing like "." or "0."
    if (newValue.text == '.' || newValue.text.endsWith('.')) {
      return newValue;
    }

    final parsed = double.tryParse(newValue.text);
    if (parsed == null) {
      // Invalid number → keep old value
      return oldValue;
    }

    if (maxValue != null && parsed > maxValue!) {
      // Would exceed limit → reject the keystroke
      return oldValue;
    }

    return newValue;
  }
}

class AddMaterialScreen extends ConsumerStatefulWidget {
  final InventoryItemModel? existing;

  const AddMaterialScreen({super.key, this.existing});

  @override
  ConsumerState<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends ConsumerState<AddMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _costCtrl;

  /// Category and unit store **ids** (Firestore document ids).
  String? _category;
  String? _unit;
  bool _saving = false;

  final _categoryService = InventoryCategoryService();
  final _unitService = UnitService();

  List<InventoryCategoryModel> _categories = [];
  List<UnitModel> _units = [];
  bool _categoriesLoading = true;
  bool _unitsLoading = true;

  bool get isEdit => widget.existing != null && widget.existing!.id.isNotEmpty;

  /// Case-insensitive alphabetical sort for named entities.
  List<T> _sortedByName<T>(
    Iterable<T> items,
    String Function(T) nameOf,
  ) {
    final list = List<T>.from(items);
    list.sort(
      (a, b) => nameOf(a).toLowerCase().compareTo(nameOf(b).toLowerCase()),
    );
    return list;
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _qtyCtrl =
        TextEditingController(text: e != null ? e.quantity.toString() : '');
    _minCtrl =
        TextEditingController(text: e != null ? e.minRequired.toString() : '');
    _maxCtrl =
        TextEditingController(text: e != null ? e.maxCapacity.toString() : '');
    _costCtrl =
        TextEditingController(text: e != null ? e.unitCost.toString() : '');

    // existing.category / existing.unit may be stored as display names.
    // After lists load we map name → id if needed.
    if (e != null) {
      _category = e.category;
      _unit = e.unit;
    }

    _loadCategories();
    _loadUnits();
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final list = await _categoryService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = _sortedByName(list, (c) => c.name);
        _categoriesLoading = false;
        // If existing value is a name (not an id), resolve to id.
        if (_category != null && !_categories.any((c) => c.id == _category)) {
          final byName = _categories.where(
            (c) => c.name.toLowerCase() == _category!.toLowerCase(),
          );
          if (byName.isNotEmpty) {
            _category = byName.first.id;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _loadUnits() async {
    setState(() => _unitsLoading = true);
    try {
      final list = await _unitService.fetchUnits();
      if (!mounted) return;
      setState(() {
        _units = _sortedByName(list, (u) => u.name);
        _unitsLoading = false;
        if (_unit != null && !_units.any((u) => u.id == _unit)) {
          final byName = _units.where(
            (u) => u.name.toLowerCase() == _unit!.toLowerCase(),
          );
          if (byName.isNotEmpty) {
            _unit = byName.first.id;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _unitsLoading = false);
    }
  }

  Future<void> _openCreateCategoryDialog() async {
    final created = await CategoryEntryDialog.show<InventoryCategoryModel>(
      context,
      title: 'Create Category',
      editTitle: 'Edit Category',
      nameLabel: 'Category Name *',
      nameHint: 'e.g. Fresh Produce',
      onSave: (name, _) => _categoryService.createCategory(name: name),
    );
    if (created == null || !mounted) return;
    setState(() {
      _categories = _sortedByName([..._categories, created], (c) => c.name);
      _category = created.id;
    });
  }

  Future<void> _openCreateUnitDialog() async {
    final created = await CategoryEntryDialog.show<UnitModel>(
      context,
      title: 'Create Unit of Measurement',
      editTitle: 'Edit Unit',
      nameLabel: 'Unit Name *',
      nameHint: 'e.g. kg, L, box',
      onSave: (name, _) => _unitService.createUnit(name: name),
    );
    if (created == null || !mounted) return;
    setState(() {
      _units = _sortedByName([..._units, created], (u) => u.name);
      _unit = created.id;
    });
  }

  Future<void> _openManageCategory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const InventoryManageCategoryScreen(),
      ),
    );
    if (!mounted) return;
    // Refresh lists in case user created/edited/deleted entries.
    await Future.wait([_loadCategories(), _loadUnits()]);
  }

  String _categoryLabel(String id) {
    if (id == _kCreateCategoryValue) return '+ Create category';
    final match = _categories.where((c) => c.id == id);
    return match.isEmpty ? id : match.first.name;
  }

  String _unitLabel(String id) {
    if (id == _kCreateUnitValue) return '+ Create unit';
    final match = _units.where((u) => u.id == id);
    return match.isEmpty ? id : match.first.name;
  }

  String get _categoryDisplayName {
    if (_category == null) return '';
    final match = _categories.where((c) => c.id == _category);
    return match.isEmpty ? _category! : match.first.name;
  }

  String get _unitDisplayName {
    if (_unit == null) return '';
    final match = _units.where((u) => u.id == _unit);
    return match.isEmpty ? _unit! : match.first.name;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  double get _previewQty => double.tryParse(_qtyCtrl.text) ?? 0;
  double get _previewMax => double.tryParse(_maxCtrl.text) ?? 0;
  double get _previewMin => double.tryParse(_minCtrl.text) ?? 0;

  StockStatus get _previewStatus {
    if (_previewQty <= 0) return StockStatus.outOfStock;
    if (_previewQty < _previewMin * 0.25) return StockStatus.critical;
    if (_previewQty < _previewMin) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  Future<void> _showNotice(String message) async {
    if (!mounted) return;
    await RdxNoticeDialog.show(context, message: message);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final qtyText = _qtyCtrl.text.trim();
    final minText = _minCtrl.text.trim();
    final maxText = _maxCtrl.text.trim();
    final costText = _costCtrl.text.trim();

    if (!isEdit && name.isEmpty) {
      await _showNotice('Please enter a material name.');
      return;
    }
    if (!isEdit && _category == null) {
      await _showNotice('Please select a category.');
      return;
    }
    if (_unit == null) {
      await _showNotice('Please select a unit of measurement.');
      return;
    }
    if (costText.isEmpty || double.tryParse(costText) == null) {
      await _showNotice('Please enter a valid unit cost.');
      return;
    }
    if (maxText.isEmpty || double.tryParse(maxText) == null) {
      await _showNotice('Please enter maximum storage capacity.');
      return;
    }
    final maxVal = double.parse(maxText);
    if (maxVal <= 0) {
      await _showNotice('Maximum storage capacity must be greater than 0.');
      return;
    }

    // Initial stock is required when creating; on edit quantity is locked.
    if (!isEdit) {
      if (qtyText.isEmpty || double.tryParse(qtyText) == null) {
        await _showNotice('Please enter initial stock quantity.');
        return;
      }
      final qty = double.parse(qtyText);
      if (qty < 0) {
        await _showNotice('Initial stock quantity cannot be negative.');
        return;
      }
      if (qty > maxVal) {
        await _showNotice(
            'Initial stock cannot exceed maximum storage capacity.');
        return;
      }
    }

    if (minText.isEmpty || double.tryParse(minText) == null) {
      await _showNotice('Please enter minimum stock alert value.');
      return;
    }
    final minVal = double.parse(minText);
    if (minVal < 0) {
      await _showNotice('Minimum stock alert value cannot be negative.');
      return;
    }
    if (minVal > maxVal) {
      await _showNotice(
          'Minimum stock cannot exceed maximum storage capacity.');
      return;
    }
    final qtyForMin = isEdit
        ? (widget.existing?.quantity ?? 0)
        : (double.tryParse(qtyText) ?? 0);
    if (minVal > qtyForMin && qtyForMin > 0) {
      await _showNotice(
        'Minimum stock cannot exceed initial/current stock quantity.',
      );
      return;
    }

    setState(() => _saving = true);

    // A single timestamp for this save. It's threaded through to
    // InventoryProvider.saveItem → InventoryService.saveItem so that,
    // for a brand-new material, created_at and updated_at are written
    // with the exact same moment — the "added" time and the "updated"
    // time from this run of the add-material flow are identical.
    final now = DateTime.now();

    // Creating a brand-new material: totalCost is computed fresh by
    // InventoryService as quantity * unitCost (its initial cost basis).
    // createdAt/updatedAt are both set to `now`.
    //
    // Editing an existing material: pass its *existing* totalCost and
    // createdAt through unchanged. InventoryService.saveItem keeps
    // totalCost as-is for edits, so tweaking the unit cost, name,
    // category, min/max, etc. here never silently re-prices stock that
    // was already bought — only updatedAt advances to `now`. Quantity/
    // cost changes from restocking or usage go through the ADDED/USED
    // fields in the inventory table (InventoryProvider.addStock /
    // useStock), not through this form.
    //
    // In edit mode, name, category, and quantity (initial stock) are
    // locked in the UI and always resubmitted unchanged from the
    // originally-loaded `existing` values, never from user-edited state.
    final item = InventoryItemModel(
      id: widget.existing?.id ?? '',
      name: isEdit ? widget.existing!.name : _nameCtrl.text.trim(),
      category: isEdit ? widget.existing!.category : _categoryDisplayName,
      quantity: isEdit
          ? widget.existing!.quantity
          : (double.tryParse(_qtyCtrl.text) ?? 0),
      minRequired: double.tryParse(_minCtrl.text) ?? 0,
      maxCapacity: double.tryParse(_maxCtrl.text) ?? 0,
      unit: _unitDisplayName,
      unitCost: double.tryParse(_costCtrl.text) ?? 0,
      totalCost: isEdit ? widget.existing!.totalCost : 0,
      createdAt: isEdit ? widget.existing!.createdAt : now,
      updatedAt: now,
      lastAddedAt: isEdit ? widget.existing!.lastAddedAt : null,
      lastUsedAt: isEdit ? widget.existing!.lastUsedAt : null,
    );

    try {
      await ref.read(inventoryProvider).saveItem(item, timestamp: now);
      if (mounted) {
        Navigator.of(context).pop();
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(isEdit ? 'Material updated' : 'Material added'),
        //   ),
        // );
      }
    } catch (e) {
      if (mounted) {
        await _showNotice('Failed to save material.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RdxHeader(
            title: isEdit ? 'Edit Material' : 'Add New Material',
            subtitle:
                'Create a new raw ingredient or packaging item in your inventory catalog.',
            showBackButton: true,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: isNarrow
                  ? SingleChildScrollView(
                      padding: Responsive.pagePadding(
                        context,
                        top: context.h(16),
                        bottom: context.h(32),
                      ),
                      child: Column(
                        children: [
                          _basicInfoSection(context, colors),
                          SizedBox(height: context.h(16)),
                          _stockTrackingSection(context, colors),
                          SizedBox(height: context.h(16)),
                          _actionButtons(context),
                        ],
                      ),
                    )
                  : Padding(
                      padding: Responsive.pagePadding(
                        context,
                        top: context.h(16),
                        bottom: context.h(24),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.only(right: context.w(20)),
                              child: _basicInfoSection(context, colors),
                            ),
                          ),
                          VerticalDivider(
                            width: context.w(1),
                            thickness: context.h(1),
                            color: colors.border,
                          ),
                          SizedBox(width: context.w(20)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    child:
                                        _stockTrackingSection(context, colors),
                                  ),
                                ),
                                SizedBox(height: context.h(16)),
                                _actionButtons(context),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RdxActionButton.discard(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: RdxActionButton.save(
            label: 'Done',
            onPressed: _save,
            isLoading: _saving,
          ),
        ),
      ],
    );
  }

  Widget _basicInfoSection(BuildContext context, AppColorScheme colors) {
    return _SectionCard(
      title: 'Basic Information & Category',
      icon: Icons.badge_outlined,
      headerTrailing: isEdit
          ? null
          : TextButton.icon(
              onPressed: _openManageCategory,
              icon: Icon(
                Icons.add_rounded,
                size: context.h(18),
                color: AppColors.primary,
              ),
              label: Text(
                'Create & Manage Category',
                style: AppTextStyles.label(context)
                    .copyWith(color: AppColors.primary),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RdxTextField(
            controller: _nameCtrl,
            maxLength: 10,
            label: 'Material Name *',
            hint: 'Enter material name',
            enabled: !isEdit,
          ),
          if (isEdit) ...[
            SizedBox(height: context.h(6)),
            Text(
              'Material name cannot be changed after creation.',
              style: AppTextStyles.bodyTertiary(context)
                  .copyWith(color: colors.textMuted),
            ),
          ],
          SizedBox(height: context.h(16)),
          LayoutBuilder(builder: (context, c) {
            final stack = c.maxWidth < 400;
            final cat = RdxDropdown<String>(
              label: 'Category *',
              value: _category != null &&
                      (_categories.any((x) => x.id == _category) ||
                          _category == _kCreateCategoryValue)
                  ? _category
                  : null,
              items: [
                _kCreateCategoryValue,
                ..._categories.map((c) => c.id),
              ],
              labelBuilder: _categoryLabel,
              searchable: true,
              enabled: !isEdit,
              hint: _categoriesLoading
                  ? 'Loading categories...'
                  : 'Select category',
              onChanged: isEdit
                  ? null
                  : (v) {
                      if (v == _kCreateCategoryValue) {
                        _openCreateCategoryDialog();
                        return;
                      }
                      if (v != null) setState(() => _category = v);
                    },
            );
            final unit = RdxDropdown<String>(
              label: 'Unit of Measurement *',
              value: _unit != null &&
                      (_units.any((x) => x.id == _unit) ||
                          _unit == _kCreateUnitValue)
                  ? _unit
                  : null,
              items: [
                _kCreateUnitValue,
                ..._units.map((u) => u.id),
              ],
              labelBuilder: _unitLabel,
              searchable: true,
              hint: _unitsLoading ? 'Loading units...' : 'Select unit',
              onChanged: (v) {
                if (v == _kCreateUnitValue) {
                  _openCreateUnitDialog();
                  return;
                }
                if (v != null) setState(() => _unit = v);
              },
            );
            if (stack) {
              return Column(children: [
                cat,
                SizedBox(height: context.h(12)),
                unit,
              ]);
            }
            return Row(children: [
              Expanded(child: cat),
              SizedBox(width: context.w(12)),
              Expanded(child: unit),
            ]);
          }),
          if (isEdit) ...[
            SizedBox(height: context.h(6)),
            Text(
              'Category cannot be changed after creation.',
              style: AppTextStyles.bodyTertiary(context)
                  .copyWith(color: colors.textMuted),
            ),
          ],
          SizedBox(height: context.h(16)),
          RdxTextField(
            controller: _costCtrl,
            maxLength: 4,
            label: 'Unit Cost (₹) *',
            hint: 'Enter cost per unit',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
          if (isEdit) ...[
            SizedBox(height: context.h(6)),
            Text(
              'Changing this only sets the price for future restocks — it '
              'won\'t change the cost already recorded for stock on hand.',
              style: AppTextStyles.bodyTertiary(context)
                  .copyWith(color: colors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stockTrackingSection(BuildContext context, AppColorScheme colors) {
    final maxHasValue = _maxCtrl.text.trim().isNotEmpty &&
        double.tryParse(_maxCtrl.text.trim()) != null;
    final maxVal = double.tryParse(_maxCtrl.text);
    final qtyVal = double.tryParse(_qtyCtrl.text);

    return _SectionCard(
      title: 'Stock Tracking & Thresholds',
      icon: Icons.bar_chart_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Max Capacity first — always editable.
          RdxTextField(
            controller: _maxCtrl,
            maxLength: 5,
            label: 'Maximum Storage Capacity *',
            hint: 'Enter maximum storage capacity',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            onChanged: (_) {
              // When max is cleared, clear dependent min field
              // (quantity is locked in edit mode, so leave it alone then).
              if (_maxCtrl.text.trim().isEmpty) {
                if (!isEdit) _qtyCtrl.clear();
                _minCtrl.clear();
              }
              setState(() {});
            },
          ),
          SizedBox(height: context.h(16)),

          // 2. Initial / Current Stock — locked once created; only
          //    editable while adding a brand-new material, and even then
          //    disabled until max is set, with keystrokes that would
          //    exceed max rejected.
          RdxTextField(
            controller: _qtyCtrl,
            maxLength: 5,
            label:
                isEdit ? 'Current Stock Quantity' : 'Initial Stock Quantity *',
            hint: 'Enter current stock quantity',
            enabled: !isEdit && maxHasValue,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              _MaxValueInputFormatter(maxVal),
            ],
            onChanged: (!isEdit && maxHasValue)
                ? (_) {
                    // If qty drops below current min, clear min.
                    final q = double.tryParse(_qtyCtrl.text);
                    final m = double.tryParse(_minCtrl.text);
                    if (q != null && m != null && m > q) {
                      _minCtrl.clear();
                    }
                    setState(() {});
                  }
                : null,
          ),
          if (isEdit) ...[
            SizedBox(height: context.h(6)),
            Text(
              'Stock quantity is locked here — use the ADDED / USED fields '
              'in the inventory table to restock or record usage, so the '
              'cost basis stays accurate.',
              style: AppTextStyles.bodyTertiary(context)
                  .copyWith(color: colors.textMuted),
            ),
          ],
          SizedBox(height: context.h(16)),

          // 3. Minimum Required — always editable once max is set;
          //    keystrokes that would exceed current stock are rejected.
          RdxTextField(
            controller: _minCtrl,
            maxLength: 3,
            label: 'Minimum Stock Alert Value *',
            hint: 'Enter minimum stock value',
            enabled: maxHasValue,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              _MaxValueInputFormatter(qtyVal),
            ],
            onChanged: maxHasValue ? (_) => setState(() {}) : null,
          ),
          SizedBox(height: context.h(6)),
          Text(
            'Restock alert triggers when stock falls below this amount — no confusing PAR terminology',
            style: AppTextStyles.bodyTertiary(context)
                .copyWith(color: colors.textMuted),
          ),
          SizedBox(height: context.h(20)),

          // Live preview
          Container(
            padding: EdgeInsets.all(context.h(14)),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(context.h(10)),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Live Stock Preview',
                      style: AppTextStyles.bodySecondary(context).copyWith(
                        color: colors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                SizedBox(height: context.h(10)),
                Row(
                  children: [
                    Text(
                      'Initial Stock: ${_previewMax > 0 ? ((_previewQty / _previewMax) * 100).toStringAsFixed(0) : 0}%',
                      style: AppTextStyles.body(context)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '$_previewQty / $_previewMax $_unitDisplayName',
                      style: AppTextStyles.body(context)
                          .copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
                SizedBox(height: context.h(8)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _previewMax > 0
                        ? (_previewQty / _previewMax).clamp(0.0, 1.0)
                        : 0,
                    minHeight: 8,
                    backgroundColor: colors.border,
                    valueColor:
                        AlwaysStoppedAnimation(_statusColor(_previewStatus)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(12)),

          // Tip
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.w(14),
              vertical: context.h(11),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EA),
              borderRadius: BorderRadius.circular(context.h(7)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: context.h(20), color: colors.primary),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Text(
                    'Status badges (In Stock / Low Stock / Critical) are calculated automatically based on your minimum required level.',
                    style: AppTextStyles.bodyTertiary(context)
                        .copyWith(color: colors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(StockStatus s) {
    switch (s) {
      case StockStatus.inStock:
        return AppColors.success;
      case StockStatus.lowStock:
        return AppColors.warning;
      case StockStatus.critical:
      case StockStatus.outOfStock:
        return AppColors.danger;
    }
  }
}

class _SectionCard extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? headerTrailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.all(context.h(20)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: context.h(18), color: AppColors.primary),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Text(title, style: AppTextStyles.section(context)),
              ),
              if (headerTrailing != null) ...[
                headerTrailing!,
                SizedBox(width: context.w(8)),
              ],
            ],
          ),
          SizedBox(height: context.h(16)),
          child,
        ],
      ),
    );
  }
}
