import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/inventory_category_model.dart';
import 'package:rdx_admin/models/unit_model.dart';
import 'package:rdx_admin/services/inventory_category_service.dart';
import 'package:rdx_admin/services/unit_service.dart';
import 'package:rdx_admin/widgets/dialogs/category_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/empty_state.dart';
import 'package:rdx_admin/widgets/reusable_widgets/loading_indicator.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_delete_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_header.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_search_bar.dart';
import 'package:rdx_admin/widgets/buttons/rdx_header_action_button.dart';

enum _Section { category, unit }

class InventoryManageCategoryScreen extends StatefulWidget {
  const InventoryManageCategoryScreen({super.key});

  @override
  State<InventoryManageCategoryScreen> createState() =>
      _InventoryManageCategoryScreenState();
}

class _InventoryManageCategoryScreenState
    extends State<InventoryManageCategoryScreen> {
  final _categoryService = InventoryCategoryService();
  final _unitService = UnitService();

  final _tagSearchController = TextEditingController();
  final _itemSearchController = TextEditingController();

  _Section _section = _Section.category;
  bool _loading = true;
  String? _error;

  /// Filters the scrollable tag row on top (searches the section tags,
  /// e.g. "Categories" / "Units of Measurement" — and, once a category
  /// has many categories, each category's own tag).
  String _tagQuery = '';

  /// Filters the rows shown inside the active table (category or unit
  /// names), independent from the tag search above.
  String _itemQuery = '';

  List<InventoryCategoryModel> _categories = [];
  List<UnitModel> _units = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _tagSearchController.dispose();
    _itemSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _categoryService.fetchCategories(),
        _unitService.fetchUnits(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = _sortedByName(
          results[0] as List<InventoryCategoryModel>,
          (c) => c.name,
        );
        _units = _sortedByName(results[1] as List<UnitModel>, (u) => u.name);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load. Try again.';
      });
    }
  }

  // ── Category actions ──────────────────────────────────────────────

  Future<void> _createCategory() async {
    final created = await CategoryEntryDialog.show<InventoryCategoryModel>(
      context,
      title: 'Create Category',
      editTitle: 'Edit Category',
      nameLabel: 'Category Name *',
      nameHint: 'e.g. Fresh Produce',
      onSave: (name, _) => _categoryService.createCategory(name: name),
    );
    if (created == null || !mounted) return;
    setState(
      () =>
          _categories = _sortedByName([..._categories, created], (c) => c.name),
    );
  }

  Future<void> _editCategory(InventoryCategoryModel category) async {
    final updated = await CategoryEntryDialog.show<InventoryCategoryModel>(
      context,
      title: 'Create Category',
      editTitle: 'Edit Category',
      nameLabel: 'Category Name *',
      nameHint: 'e.g. Fresh Produce',
      initialName: category.name,
      onSave: (name, _) async {
        final updated = InventoryCategoryModel(id: category.id, name: name);
        await _categoryService.updateCategory(updated);
        return updated;
      },
    );
    if (updated == null || !mounted) return;
    setState(() {
      _categories = _sortedByName(
        [
          for (final c in _categories)
            if (c.id == updated.id) updated else c,
        ],
        (c) => c.name,
      );
    });
  }

  Future<void> _deleteCategory(InventoryCategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Category',
        itemName: category.name,
        deleteButtonLabel: 'Delete Category',
        warningMessage:
            'Materials using this category will keep the old name until re-saved.',
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _categoryService.deleteCategory(category.id);
      if (!mounted) return;
      setState(() {
        _categories = _categories.where((c) => c.id != category.id).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete category.')),
      );
    }
  }

  // ── Unit actions ──────────────────────────────────────────────────

  Future<void> _createUnit() async {
    final created = await CategoryEntryDialog.show<UnitModel>(
      context,
      title: 'Create Unit of Measurement',
      editTitle: 'Edit Unit',
      nameLabel: 'Unit Name *',
      nameHint: 'e.g. kg, L, box',
      onSave: (name, _) => _unitService.createUnit(name: name),
    );
    if (created == null || !mounted) return;
    setState(() => _units = _sortedByName([..._units, created], (u) => u.name));
  }

  Future<void> _editUnit(UnitModel unit) async {
    final updated = await CategoryEntryDialog.show<UnitModel>(
      context,
      title: 'Create Unit of Measurement',
      editTitle: 'Edit Unit',
      nameLabel: 'Unit Name *',
      nameHint: 'e.g. kg, L, box',
      initialName: unit.name,
      onSave: (name, _) async {
        final updated = UnitModel(id: unit.id, name: name);
        await _unitService.updateUnit(updated);
        return updated;
      },
    );
    if (updated == null || !mounted) return;
    setState(() {
      _units = _sortedByName(
        [
          for (final u in _units)
            if (u.id == updated.id) updated else u,
        ],
        (u) => u.name,
      );
    });
  }

  Future<void> _deleteUnit(UnitModel unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Unit',
        itemName: unit.name,
        deleteButtonLabel: 'Delete',
        warningMessage:
            'Materials using this unit will keep the old name until re-saved.',
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _unitService.deleteUnit(unit.id);
      if (!mounted) return;
      setState(() {
        _units = _units.where((u) => u.id != unit.id).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete unit.')),
      );
    }
  }

  // ── Filtering helpers ───────────────────────────────────────────────

  /// Section tags shown in the top scrollable row, filtered by whatever
  /// has been typed into the top search bar. Today this is just the two
  /// section tags ("Categories" / "Units of Measurement"), but it is
  /// built generically so any future per-category tags slot in the same
  /// way.
  List<(_Section, String)> get _visibleTags {
    final all = <(_Section, String)>[
      (_Section.category, 'Categories'),
      (_Section.unit, 'Units of Measurement'),
    ];
    if (_tagQuery.trim().isEmpty) return all;
    final q = _tagQuery.trim().toLowerCase();
    return all.where((t) => t.$2.toLowerCase().contains(q)).toList();
  }

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

  List<InventoryCategoryModel> get _filteredCategories {
    final source = _itemQuery.trim().isEmpty
        ? _categories
        : _categories
            .where((c) =>
                c.name.toLowerCase().contains(_itemQuery.trim().toLowerCase()))
            .toList();
    return _sortedByName(source, (c) => c.name);
  }

  List<UnitModel> get _filteredUnits {
    final source = _itemQuery.trim().isEmpty
        ? _units
        : _units
            .where((u) =>
                u.name.toLowerCase().contains(_itemQuery.trim().toLowerCase()))
            .toList();
    return _sortedByName(source, (u) => u.name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isNarrow = Responsive.isNarrow(context);
    final horizontal = Responsive.pageHorizontal(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const RdxHeader(
            title: 'Manage Inventory Category',
            showBackButton: true,
          ),
          SizedBox(height: context.h(isNarrow ? 10 : 14)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _tabs(context, colors),
                      SizedBox(height: context.h(10)),
                      Row(
                        children: [
                          Expanded(child: _tagSearchBar(context)),
                          SizedBox(width: context.w(8)),
                          _addButton(context),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _tabs(context, colors)),
                      SizedBox(width: context.w(8)),
                      SizedBox(
                        width: context.w(220),
                        child: _tagSearchBar(context),
                      ),
                      SizedBox(width: context.w(8)),
                      _addButton(context),
                    ],
                  ),
          ),
          SizedBox(height: context.h(isNarrow ? 10 : 14)),
          Expanded(
            child: _loading
                ? const LoadingIndicator()
                : _error != null
                    ? EmptyState(message: _error!)
                    : Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          0,
                          horizontal,
                          context.h(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _itemSearchBar(context),
                            SizedBox(height: context.h(12)),
                            Expanded(
                              child: _section == _Section.category
                                  ? _categoryContent(context, colors, isNarrow)
                                  : _unitContent(context, colors, isNarrow),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Search bar that filters the scrollable tag row on top of the screen.
  Widget _tagSearchBar(BuildContext context) {
    return RdxSearchBar(
      controller: _tagSearchController,
      hintText: 'Search categories',
      height: context.h(40),
      onChanged: (value) => setState(() => _tagQuery = value),
    );
  }

  /// Search bar that filters the rows inside the active table.
  Widget _itemSearchBar(BuildContext context) {
    return RdxSearchBar(
      controller: _itemSearchController,
      hintText: 'Search materials',
      height: context.h(40),
      onChanged: (value) => setState(() => _itemQuery = value),
    );
  }

  /// Scrollable row of section tags. Fades out on the trailing edge —
  /// the same treatment used for the category tags on the Menu screen —
  /// so it reads cleanly against whatever sits to its right (the tag
  /// search bar / Add button).
  Widget _tabs(BuildContext context, AppColorScheme colors) {
    final tags = _visibleTags;
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [Colors.black, Colors.black, Colors.transparent],
        stops: const [0.0, 0.9, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(right: context.w(24)),
        child: Row(
          children: [
            for (int i = 0; i < tags.length; i++) ...[
              _tab(context, colors, tags[i].$1, tags[i].$2),
              if (i != tags.length - 1) SizedBox(width: context.w(8)),
            ],
            if (tags.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.h(9)),
                child: Text(
                  'No tags match your search.',
                  style: AppTextStyles.label(context)
                      .copyWith(color: colors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    AppColorScheme colors,
    _Section section,
    String label,
  ) {
    final selected = _section == section;
    return InkWell(
      onTap: () => setState(() => _section = section),
      borderRadius: BorderRadius.circular(context.h(20)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(9),
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : colors.surface,
          borderRadius: BorderRadius.circular(context.h(20)),
          border: Border.all(
            color: selected ? AppColors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label(context).copyWith(
            color: selected ? Colors.white : colors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _addButton(BuildContext context) {
    final (label, onTap) = switch (_section) {
      _Section.category => ('Add category', _createCategory),
      _Section.unit => ('Add unit', _createUnit),
    };

    return RdxHeaderActionButton(
      label: label,
      onPressed: onTap,
    );
  }

  Widget _categoryContent(
    BuildContext context,
    AppColorScheme colors,
    bool isNarrow,
  ) {
    final categories = _filteredCategories;
    if (categories.isEmpty) {
      return EmptyState(
        message: _categories.isEmpty
            ? 'No categories yet.'
            : 'No categories match your search.',
      );
    }
    return isNarrow
        ? _simpleCards(
            context,
            colors,
            items: categories.map((c) => (c.name, c as Object)).toList(),
            onEdit: (c) => _editCategory(c as InventoryCategoryModel),
            onDelete: (c) => _deleteCategory(c as InventoryCategoryModel),
          )
        : RdxTable(
            columns: [
              RdxTableColumn(
                  title: 'Category', minWidth: context.w(180), flex: 3),
              RdxTableColumn(
                title: 'Actions',
                minWidth: context.w(90),
                alignment: Alignment.centerRight,
              ),
            ],
            rows: [
              for (final c in categories)
                [
                  Text(c.name, style: AppTextStyles.body(context)),
                  _actions(
                    onEdit: () => _editCategory(c),
                    onDelete: () => _deleteCategory(c),
                  ),
                ],
            ],
          );
  }

  Widget _unitContent(
    BuildContext context,
    AppColorScheme colors,
    bool isNarrow,
  ) {
    final units = _filteredUnits;
    if (units.isEmpty) {
      return EmptyState(
        message:
            _units.isEmpty ? 'No units yet.' : 'No units match your search.',
      );
    }
    return isNarrow
        ? _simpleCards(
            context,
            colors,
            items: units.map((u) => (u.name, u as Object)).toList(),
            onEdit: (u) => _editUnit(u as UnitModel),
            onDelete: (u) => _deleteUnit(u as UnitModel),
          )
        : RdxTable(
            columns: [
              RdxTableColumn(
                  title: 'Unit of Measurement',
                  minWidth: context.w(180),
                  flex: 3),
              RdxTableColumn(
                title: 'Actions',
                minWidth: context.w(90),
                alignment: Alignment.centerRight,
              ),
            ],
            rows: [
              for (final u in units)
                [
                  Text(u.name, style: AppTextStyles.body(context)),
                  _actions(
                    onEdit: () => _editUnit(u),
                    onDelete: () => _deleteUnit(u),
                  ),
                ],
            ],
          );
  }

  Widget _simpleCards(
    BuildContext context,
    AppColorScheme colors, {
    required List<(String, Object)> items,
    required void Function(Object) onEdit,
    required void Function(Object) onDelete,
  }) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: context.h(10)),
      itemBuilder: (context, index) {
        final (title, item) = items[index];
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.w(14),
            vertical: context.h(12),
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(context.h(12)),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _actions(
                onEdit: () => onEdit(item),
                onDelete: () => onDelete(item),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actions({
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RdxTableActionButton(
          icon: Icons.edit_outlined,
          tooltip: 'Edit',
          onPressed: onEdit,
        ),
        RdxTableActionButton(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Delete',
          onPressed: onDelete,
        ),
      ],
    );
  }
}
