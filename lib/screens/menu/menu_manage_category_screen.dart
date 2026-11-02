import 'package:flutter/material.dart';
import 'package:rdx_admin/widgets/dialogs/category_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/category_model.dart';
import '../../models/preparation_model.dart';
import '../../models/regionality_model.dart';
import '../../models/tag_model.dart';
import '../../services/category_service.dart';
import '../../services/preparation_service.dart';
import '../../services/regionality_service.dart';
import '../../services/tag_service.dart';
import '../../widgets/reusable_widgets/rdx_delete_dialog.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/buttons/rdx_header_action_button.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';

enum _CategorySection { category, preparation, regionality, tag }

/// "View all" screen for managing Category, Preparation Style,
/// Regionality, and Tag entries in one place. Editing reuses the same
/// dialog used to create each entry; deleting shows [RdxDeleteDialog].
///
/// Every create/edit/delete on THIS screen is immediate — unlike the
/// dropdown "+" on [CreateMenuScreen], where Regionality and Preparation
/// are deferred until the menu item form itself is saved. Here, all four
/// category types are standalone entities managed independently of any
/// menu item, so they persist to Firestore right away.
///
/// On narrow screens the data is shown as stacked cards (one per row)
/// instead of a wide table so nothing overflows or breaks the layout.
class MenuManageCategoryScreen extends StatefulWidget {
  const MenuManageCategoryScreen({super.key});

  @override
  State<MenuManageCategoryScreen> createState() =>
      _MenuManageCategoryScreenState();
}

class _MenuManageCategoryScreenState extends State<MenuManageCategoryScreen> {
  final _categoryService = CategoryService();
  final _preparationService = PreparationService();
  final _regionalityService = RegionalityService();
  final _tagService = TagService();

  _CategorySection _section = _CategorySection.category;
  bool _loading = true;
  String? _error;

  List<CategoryModel> _categories = [];
  List<PreparationModel> _preparations = [];
  List<RegionalityModel> _regionalities = [];
  List<TagModel> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _categoryService.fetchCategories(),
        _preparationService.fetchPreparations(),
        _regionalityService.fetchRegionalities(),
        _tagService.fetchTags(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = _sortedByName(
          results[0] as List<CategoryModel>,
          (c) => c.name,
        );
        _preparations = _sortedByName(
          results[1] as List<PreparationModel>,
          (p) => p.name,
        );
        _regionalities = _sortedByName(
          results[2] as List<RegionalityModel>,
          (r) => r.name,
        );
        _tags = _sortedByName(results[3] as List<TagModel>, (t) => t.name);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load. Pull to refresh or try again.';
      });
    }
  }

  // ─── Category actions ─────────────────────────────────────────────

  // ─── Category actions ─────────────────────────────────────────────

  Future<void> _createCategory() async {
    final created = await CategoryEntryDialog.show<CategoryModel>(
      context,
      title: 'Create Category',
      editTitle: 'Edit Category',
      nameLabel: 'Category Name *',
      nameHint: 'e.g. Beverages',
      initialSubItems: const [],
      // One text field at a time — user can add as many subcategories as needed.
      subItemsLabel: 'Subcategories (optional)',
      subItemHintBuilder: (_) => 'Add a subcategory and press Add',
      onSave: (name, subNames) async {
        final id = await _categoryService.createCategory(
          name: name,
          subcategoryNames: subNames,
        );
        return CategoryModel(
          id: id,
          name: name,
          subcategories: [
            for (final subName in subNames)
              SubcategoryModel(id: subName, name: subName),
          ],
        );
      },
    );
    if (created == null || !mounted) return;
    setState(
      () =>
          _categories = _sortedByName([..._categories, created], (c) => c.name),
    );
  }

  Future<void> _editCategory(CategoryModel category) async {
    final updated = await CategoryEntryDialog.show<CategoryModel>(
      context,
      title: 'Create Category',
      editTitle: 'Edit Category',
      nameLabel: 'Category Name *',
      nameHint: 'e.g. Beverages',
      initialName: category.name,
      initialSubItems: category.subcategories.map((s) => s.name).toList(),
      // One text field at a time — user can add as many subcategories as needed.
      subItemsLabel: 'Subcategories (optional)',
      subItemHintBuilder: (_) => 'Add a subcategory and press Add',
      onSave: (name, subNames) async {
        final updated = CategoryModel(
          id: category.id,
          name: name,
          subcategories: [
            for (final subName in subNames)
              SubcategoryModel(
                id: '${category.id}-${subName.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}',
                name: subName,
              ),
          ],
        );
        await _categoryService.updateCategory(updated);
        return updated;
      },
    );
    if (updated == null || !mounted) return;
    setState(() {
      _categories = _sortedByName(
        [
          for (final item in _categories)
            if (item.id == updated.id) updated else item,
        ],
        (c) => c.name,
      );
    });
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Category',
        itemName: category.name,
        itemDetails: category.subcategories.isEmpty
            ? const []
            : [
                Text(
                  '${category.subcategories.length} subcategor${category.subcategories.length == 1 ? 'y' : 'ies'}',
                  style: AppTextStyles.body(context).copyWith(
                    color: AppColors.of(context).textSecondary,
                  ),
                ),
              ],
        deleteButtonLabel: 'Delete Category',
        warningMessage:
            'Deleting this category also removes all of its subcategories. '
            'Menu items using it will keep the old category name until '
            're-saved.',
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

  // ─── Preparation actions ──────────────────────────────────────────

  // ─── Preparation actions ──────────────────────────────────────────

  Future<void> _createPreparation() async {
    final created = await CategoryEntryDialog.show<PreparationModel>(
      context,
      title: 'Add Preparation Style',
      nameLabel: 'Preparation Style',
      nameHint: 'e.g. Tandoori',
      description:
          'e.g. Tandoori, Gravy, Steam. Saved right away for use across items.',
      onSave: (name, _) => _preparationService.createPreparation(name: name),
    );
    if (created == null || !mounted) return;
    setState(
      () => _preparations =
          _sortedByName([..._preparations, created], (p) => p.name),
    );
  }

  Future<void> _editPreparation(PreparationModel preparation) async {
    final updated = await CategoryEntryDialog.show<PreparationModel>(
      context,
      title: 'Add Preparation Style',
      editTitle: 'Edit Preparation Style',
      nameLabel: 'Preparation Style',
      nameHint: 'e.g. Tandoori',
      initialName: preparation.name,
      onSave: (name, _) async {
        final updated = PreparationModel(id: preparation.id, name: name);
        await _preparationService.updatePreparation(updated);
        return updated;
      },
    );
    if (updated == null || !mounted) return;
    setState(() {
      _preparations = _sortedByName(
        [
          for (final item in _preparations)
            if (item.id == updated.id) updated else item,
        ],
        (p) => p.name,
      );
    });
  }

  Future<void> _deletePreparation(PreparationModel preparation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Preparation Style',
        itemName: preparation.name,
        deleteButtonLabel: 'Delete',
        warningMessage:
            'Deleting this preparation style will permanently remove it. '
            'Menu items using it will keep the old name until re-saved.',
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _preparationService.deletePreparation(preparation.id);
      if (!mounted) return;
      setState(() {
        _preparations =
            _preparations.where((p) => p.id != preparation.id).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete preparation style.')),
      );
    }
  }

  // ─── Regionality actions ────────────────────────────────────────────
  //
  // Same immediate create/edit/delete contract as Preparation above.
  // This is the only place a regionality can be edited or deleted; the
  // "+ Add regionality" flow on CreateMenuScreen only ever *creates* one,
  // and only persists it once the menu item form is saved.

  // ─── Regionality actions ────────────────────────────────────────────

  Future<void> _createRegionality() async {
    final created = await CategoryEntryDialog.show<RegionalityModel>(
      context,
      title: 'Add Regionality',
      nameLabel: 'Regionality',
      nameHint: 'e.g. Punjabi',
      description:
          'e.g. Punjabi, Indo-Chinese, South Indian. Saved right away for use across items.',
      onSave: (name, _) => _regionalityService.createRegionality(name: name),
    );
    if (created == null || !mounted) return;
    setState(
      () => _regionalities =
          _sortedByName([..._regionalities, created], (r) => r.name),
    );
  }

  Future<void> _editRegionality(RegionalityModel regionality) async {
    final updated = await CategoryEntryDialog.show<RegionalityModel>(
      context,
      title: 'Add Regionality',
      editTitle: 'Edit Regionality',
      nameLabel: 'Regionality',
      nameHint: 'e.g. Punjabi',
      initialName: regionality.name,
      onSave: (name, _) async {
        final updated = RegionalityModel(id: regionality.id, name: name);
        await _regionalityService.updateRegionality(updated);
        return updated;
      },
    );
    if (updated == null || !mounted) return;
    setState(() {
      _regionalities = _sortedByName(
        [
          for (final item in _regionalities)
            if (item.id == updated.id) updated else item,
        ],
        (r) => r.name,
      );
    });
  }

  Future<void> _deleteRegionality(RegionalityModel regionality) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Regionality',
        itemName: regionality.name,
        deleteButtonLabel: 'Delete',
        warningMessage:
            'Deleting this regionality will permanently remove it. Menu '
            'items using it will keep the old name until re-saved.',
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _regionalityService.deleteRegionality(regionality.id);
      if (!mounted) return;
      setState(() {
        _regionalities =
            _regionalities.where((r) => r.id != regionality.id).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete regionality.')),
      );
    }
  }

  // ─── Tag actions ───────────────────────────────────────────────────

  // ─── Tag actions ───────────────────────────────────────────────────

  Future<void> _createTag() async {
    if (_tags.length >= TagService.maxCustomTags) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //       'You can only create up to ${TagService.maxCustomTags} custom tags.',
      //     ),
      //   ),
      // );
      return;
    }
    final created = await CategoryEntryDialog.show<TagModel>(
      context,
      title: 'Create Tag',
      nameLabel: 'Tag Name',
      nameHint: "e.g. Chef's Special",
      description:
          'Custom tags are saved right away so they can be reused on other items.',
      onSave: (name, _) => _tagService.createTag(name: name),
    );
    if (created == null || !mounted) return;
    setState(() => _tags = _sortedByName([..._tags, created], (t) => t.name));
  }

  Future<void> _editTag(TagModel tag) async {
    final updated = await CategoryEntryDialog.show<TagModel>(
      context,
      title: 'Create Tag',
      editTitle: 'Edit Tag',
      nameLabel: 'Tag Name',
      nameHint: "e.g. Chef's Special",
      initialName: tag.name,
      onSave: (name, _) async {
        final updated = TagModel(id: tag.id, name: name);
        await _tagService.updateTag(updated);
        return updated;
      },
    );
    if (updated == null || !mounted) return;
    setState(() {
      _tags = _sortedByName(
        [
          for (final item in _tags)
            if (item.id == updated.id) updated else item,
        ],
        (t) => t.name,
      );
    });
  }

  Future<void> _deleteTag(TagModel tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Tag',
        itemName: tag.name,
        deleteButtonLabel: 'Delete',
        warningMessage:
            'Deleting this tag will permanently remove it. Menu items '
            'using it will keep showing it until re-saved.',
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _tagService.deleteTag(tag.id);
      if (!mounted) return;
      setState(() => _tags = _tags.where((t) => t.id != tag.id).toList());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete tag.')),
      );
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────

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
            title: 'Manage Category',
            showBackButton: true,
          ),
          SizedBox(height: context.h(isNarrow ? 10 : 14)),
          // Tabs + Add button on the same row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: _tabsAndAddRow(context, colors),
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
                        child: _sectionContent(context, colors, isNarrow),
                      ),
          ),
        ],
      ),
    );
  }

  /// Tabs on the left (scrollable) + the current section’s “+ Add” button on the right.
  Widget _tabsAndAddRow(BuildContext context, AppColorScheme colors) {
    return Row(
      children: [
        Expanded(child: _sectionTabs(context, colors)),
        SizedBox(width: context.w(8)),
        _currentAddButton(context),
      ],
    );
  }

  Widget _sectionTabs(BuildContext context, AppColorScheme colors) {
    final entries = <_CategorySection, String>{
      _CategorySection.category: 'Categories',
      _CategorySection.preparation: 'Preparation Styles',
      _CategorySection.regionality: 'Regionalities',
      _CategorySection.tag: 'Tags',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in entries.entries) ...[
            _sectionTab(context, colors, entry.key, entry.value),
            SizedBox(width: context.w(8)),
          ],
        ],
      ),
    );
  }

  Widget _sectionTab(
    BuildContext context,
    AppColorScheme colors,
    _CategorySection section,
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

  Widget _currentAddButton(BuildContext context) {
    final (String label, VoidCallback onTap) = switch (_section) {
      _CategorySection.category => ('Add category', _createCategory),
      _CategorySection.preparation => (
          'Add preparation style',
          _createPreparation
        ),
      _CategorySection.regionality => ('Add regionality', _createRegionality),
      _CategorySection.tag => ('Add tag', _createTag),
    };

    return RdxHeaderActionButton(
      label: label,
      onPressed: onTap,
    );
  }

  Widget _sectionContent(
    BuildContext context,
    AppColorScheme colors,
    bool isNarrow,
  ) {
    switch (_section) {
      case _CategorySection.category:
        return _categorySection(context, colors, isNarrow);
      case _CategorySection.preparation:
        return _preparationSection(context, colors, isNarrow);
      case _CategorySection.regionality:
        return _regionalitySection(context, colors, isNarrow);
      case _CategorySection.tag:
        return _tagSection(context, colors, isNarrow);
    }
  }

  // ─── Categories ─────────────────────────────────────────────────────

  Widget _categorySection(
    BuildContext context,
    AppColorScheme colors,
    bool isNarrow,
  ) {
    return _categories.isEmpty
        ? const EmptyState(message: 'No categories yet.')
        : isNarrow
            ? _categoryCards(context, colors)
            : _categoryTable(context, colors);
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

  /// Formats subcategory names for the table/card: alphabetically sorted,
  /// up to 8 per line, then continues on the next line.
  String _formatSubcategories(List<SubcategoryModel> subs) {
    if (subs.isEmpty) return '—';
    final names =
        _sortedByName(subs, (s) => s.name).map((s) => s.name).toList();
    final lines = <String>[];
    for (var i = 0; i < names.length; i += 8) {
      final end = i + 8 > names.length ? names.length : i + 8;
      lines.add(names.sublist(i, end).join(', '));
    }
    return lines.join('\n');
  }

  Widget _categoryTable(BuildContext context, AppColorScheme colors) {
    final isMobile = Responsive.isMobile(context);
    final isNarrow = Responsive.isNarrow(context);

    final categoryMin = isMobile
        ? 140.0
        : isNarrow
            ? 160.0
            : 180.0;
    final subcategoriesMin = isMobile
        ? 150.0
        : isNarrow
            ? 170.0
            : 200.0;
    final actionsMin = isMobile
        ? 80.0
        : isNarrow
            ? 85.0
            : 90.0;

    return RdxTable(
      columns: [
        RdxTableColumn(
            title: 'Category', minWidth: context.w(categoryMin), flex: 2),
        RdxTableColumn(
            title: 'Subcategories',
            minWidth: context.w(subcategoriesMin),
            flex: 3),
        RdxTableColumn(
          title: 'Actions',
          minWidth: context.w(actionsMin),
          alignment: Alignment.centerRight,
        ),
      ],
      rows: [
        for (final category in _categories)
          [
            Text(category.name, style: AppTextStyles.body(context)),
            Text(
              category.subcategories.isEmpty
                  ? '—'
                  : _formatSubcategories(category.subcategories),
              style: AppTextStyles.bodySecondary(context)
                  .copyWith(color: colors.textSecondary),
            ),
            _actionsCell(
              onEdit: () => _editCategory(category),
              onDelete: () => _deleteCategory(category),
            ),
          ],
      ],
    );
  }

  Widget _categoryCards(BuildContext context, AppColorScheme colors) {
    return ListView.separated(
      itemCount: _categories.length,
      separatorBuilder: (_, __) => SizedBox(height: context.h(10)),
      itemBuilder: (context, index) {
        final category = _categories[index];
        final subs = category.subcategories.isEmpty
            ? 'No subcategories'
            : _formatSubcategories(category.subcategories);

        return _categoryCard(
          context: context,
          colors: colors,
          title: category.name,
          subtitle: subs,
          onEdit: () => _editCategory(category),
          onDelete: () => _deleteCategory(category),
        );
      },
    );
  }

  // ─── Preparation ────────────────────────────────────────────────────

  Widget _preparationSection(
    BuildContext context,
    AppColorScheme colors,
    bool isNarrow,
  ) {
    return _preparations.isEmpty
        ? const EmptyState(message: 'No preparation styles yet.')
        : isNarrow
            ? _preparationCards(context, colors)
            : _preparationTable(context, colors);
  }

  Widget _preparationTable(BuildContext context, AppColorScheme colors) {
    final isMobile = Responsive.isMobile(context);
    final isNarrow = Responsive.isNarrow(context);

    final nameMin = isMobile
        ? 160.0
        : isNarrow
            ? 190.0
            : 220.0;
    final actionsMin = isMobile
        ? 80.0
        : isNarrow
            ? 85.0
            : 90.0;

    return RdxTable(
      columns: [
        RdxTableColumn(
            title: 'Preparation Style', minWidth: context.w(nameMin), flex: 3),
        RdxTableColumn(
          title: 'Actions',
          minWidth: context.w(actionsMin),
          alignment: Alignment.centerRight,
        ),
      ],
      rows: [
        for (final preparation in _preparations)
          [
            Text(preparation.name, style: AppTextStyles.body(context)),
            _actionsCell(
              onEdit: () => _editPreparation(preparation),
              onDelete: () => _deletePreparation(preparation),
            ),
          ],
      ],
    );
  }

  Widget _preparationCards(BuildContext context, AppColorScheme colors) {
    return ListView.separated(
      itemCount: _preparations.length,
      separatorBuilder: (_, __) => SizedBox(height: context.h(10)),
      itemBuilder: (context, index) {
        final preparation = _preparations[index];
        return _categoryCard(
          context: context,
          colors: colors,
          title: preparation.name,
          onEdit: () => _editPreparation(preparation),
          onDelete: () => _deletePreparation(preparation),
        );
      },
    );
  }

  // ─── Regionality ────────────────────────────────────────────────────

  Widget _regionalitySection(
    BuildContext context,
    AppColorScheme colors,
    bool isNarrow,
  ) {
    return _regionalities.isEmpty
        ? const EmptyState(message: 'No regionalities yet.')
        : isNarrow
            ? _regionalityCards(context, colors)
            : _regionalityTable(context, colors);
  }

  Widget _regionalityTable(BuildContext context, AppColorScheme colors) {
    final isMobile = Responsive.isMobile(context);
    final isNarrow = Responsive.isNarrow(context);

    final nameMin = isMobile
        ? 160.0
        : isNarrow
            ? 190.0
            : 220.0;
    final actionsMin = isMobile
        ? 80.0
        : isNarrow
            ? 85.0
            : 90.0;

    return RdxTable(
      columns: [
        RdxTableColumn(
            title: 'Regionality', minWidth: context.w(nameMin), flex: 3),
        RdxTableColumn(
          title: 'Actions',
          minWidth: context.w(actionsMin),
          alignment: Alignment.centerRight,
        ),
      ],
      rows: [
        for (final regionality in _regionalities)
          [
            Text(regionality.name, style: AppTextStyles.body(context)),
            _actionsCell(
              onEdit: () => _editRegionality(regionality),
              onDelete: () => _deleteRegionality(regionality),
            ),
          ],
      ],
    );
  }

  Widget _regionalityCards(BuildContext context, AppColorScheme colors) {
    return ListView.separated(
      itemCount: _regionalities.length,
      separatorBuilder: (_, __) => SizedBox(height: context.h(10)),
      itemBuilder: (context, index) {
        final regionality = _regionalities[index];
        return _categoryCard(
          context: context,
          colors: colors,
          title: regionality.name,
          onEdit: () => _editRegionality(regionality),
          onDelete: () => _deleteRegionality(regionality),
        );
      },
    );
  }

  // ─── Tags ───────────────────────────────────────────────────────────

  Widget _tagSection(
    BuildContext context,
    AppColorScheme colors,
    bool isNarrow,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Helper text only on wider screens (add button already lives in the tabs row)
        if (!isNarrow)
          Expanded(
            child: _tags.isEmpty
                ? const EmptyState(message: 'No custom tags yet.')
                : isNarrow
                    ? _tagCards(context, colors)
                    : _tagTable(context, colors),
          ),
      ],
    );
  }

  Widget _tagTable(BuildContext context, AppColorScheme colors) {
    final isMobile = Responsive.isMobile(context);
    final isNarrow = Responsive.isNarrow(context);

    final tagMin = isMobile
        ? 150.0
        : isNarrow
            ? 170.0
            : 200.0;
    final actionsMin = isMobile
        ? 80.0
        : isNarrow
            ? 85.0
            : 90.0;

    return RdxTable(
      columns: [
        RdxTableColumn(title: 'Tag', minWidth: context.w(tagMin), flex: 3),
        RdxTableColumn(
          title: 'Actions',
          minWidth: context.w(actionsMin),
          alignment: Alignment.centerRight,
        ),
      ],
      rows: [
        for (final tag in _tags)
          [
            Text(tag.name, style: AppTextStyles.body(context)),
            _actionsCell(
              onEdit: () => _editTag(tag),
              onDelete: () => _deleteTag(tag),
            ),
          ],
      ],
    );
  }

  Widget _tagCards(BuildContext context, AppColorScheme colors) {
    return ListView.separated(
      itemCount: _tags.length,
      separatorBuilder: (_, __) => SizedBox(height: context.h(10)),
      itemBuilder: (context, index) {
        final tag = _tags[index];
        return _categoryCard(
          context: context,
          colors: colors,
          title: tag.name,
          onEdit: () => _editTag(tag),
          onDelete: () => _deleteTag(tag),
        );
      },
    );
  }

  // ─── Shared mobile card ─────────────────────────────────────────────

  Widget _categoryCard({
    required BuildContext context,
    required AppColorScheme colors,
    required String title,
    String? subtitle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  SizedBox(height: context.h(4)),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyTertiary(context)
                        .copyWith(color: colors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: context.w(8)),
          _actionsCell(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }

  Widget _actionsCell({
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
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
