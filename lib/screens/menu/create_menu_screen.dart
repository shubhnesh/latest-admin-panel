import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/screens/menu/menu_manage_category_screen.dart';
import 'package:rdx_admin/screens/menu/widgets/menu_item_card.dart';
import 'package:rdx_admin/widgets/dialogs/category_dialog.dart';
import 'package:rdx_admin/widgets/dialogs/rdx_notice_dialog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/category_model.dart';
import '../../models/menu_item_model.dart';
import '../../models/preparation_model.dart';
import '../../models/regionality_model.dart';
import '../../models/tag_model.dart';
import '../../providers/menu_provider.dart';
import '../../services/category_service.dart';
import '../../services/preparation_service.dart';
import '../../services/regionality_service.dart';
import '../../services/tag_service.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/rdx_dropdown.dart';
import '../../widgets/reusable_widgets/rdx_text_field.dart';
import '../../widgets/reusable_widgets/rdx_search_bar.dart';
import '../../widgets/reusable_widgets/rdx_category_tabs.dart';
import '../../widgets/buttons/rdx_toggle_button.dart';

/// Sentinel value placed as the first entry in the category dropdown.
/// Selecting it opens [CreateCategoryDialog] instead of setting a category.
const String _kCreateCategoryValue = '__create_category__';

/// Sentinel value placed as the first entry in the subcategory dropdown.
/// Only shown once a primary category is selected. Selecting it opens a
/// dialog to add one subcategory onto that category (persisted immediately).
const String _kCreateSubcategoryValue = '__create_subcategory__';

/// Sentinel value placed as the first entry in the regionality dropdown.
/// Selecting it opens [CreateRegionalityDialog].
const String _kCreateRegionalityValue = '__create_regionality__';

/// Local-only ID used to represent a regionality the user just typed but
/// that hasn't been written to Firestore yet. It's swapped for a real
/// slug ID (via [RegionalityService.createRegionality]) at save time.
const String _kPendingRegionalityId = '__pending_regionality__';

/// Sentinel value placed as the first entry in the preparation dropdown.
/// Selecting it opens [CreatePreparationDialog].
const String _kCreatePreparationValue = '__create_preparation__';

/// Local-only ID for a preparation style typed but not yet persisted —
/// same deferred-creation contract as [_kPendingRegionalityId].
const String _kPendingPreparationId = '__pending_preparation__';

class CreateMenuScreen extends ConsumerStatefulWidget {
  final String? itemId;
  const CreateMenuScreen({super.key, this.itemId});

  @override
  ConsumerState<CreateMenuScreen> createState() => _CreateMenuScreenState();
}

class _CreateMenuScreenState extends ConsumerState<CreateMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _image = TextEditingController();
  final _price = TextEditingController();
  final _sortOrder = TextEditingController(text: '0');
  final _ingredientInput = TextEditingController();

  /// When true, item uses size-based pricing instead of a single price.
  bool _hasSizes = false;

  /// Controllers for each size row (max 5). Paired with [_sizePriceControllers].
  final List<TextEditingController> _sizeNameControllers = [];
  final List<TextEditingController> _sizePriceControllers = [];

  static const int _maxSizes = 5;

  String? _primaryCategory;
  String? _subcategory;
  DietaryType? _dietaryType;
  String? _preparation;
  final Set<String> _tags = {};
  final List<String> _ingredients = [];
  bool _available = true;
  bool _loading = false;
  String? _error;

  final _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  bool _categoriesLoading = true;

  final _regionalityService = RegionalityService();
  List<RegionalityModel> _regionalities = [];
  bool _regionalitiesLoading = true;
  String? _regionality;

  /// Name typed into the regionality dialog, held locally and only
  /// written to Firestore (via [RegionalityService.createRegionality])
  /// when the menu item itself is saved.
  String? _pendingRegionalityName;

  final _preparationService = PreparationService();
  List<PreparationModel> _preparations = [];
  bool _preparationsLoading = true;

  /// Name typed into the preparation dialog, held locally and only
  /// written to Firestore (via [PreparationService.createPreparation])
  /// when the menu item itself is saved. Same contract as
  /// [_pendingRegionalityName].
  String? _pendingPreparationName;

  final _tagService = TagService();
  List<TagModel> _customTags = [];
  bool _customTagsLoading = true;

  static const _tagOptions = [
    'Featured',
    'Bestseller',
    'New',
    'Popular',
  ];

  bool get _editing => widget.itemId != null;

  List<SubcategoryModel> get _subcategories {
    if (_primaryCategory == null) return [];
    final category =
        _categories.where((item) => item.id == _primaryCategory).toList();
    if (category.isEmpty) return [];
    return _sortedByName(category.first.subcategories, (s) => s.name);
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

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final categories = await _categoryService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = _sortedByName(categories, (c) => c.name);
        _categoriesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _loadRegionalities() async {
    setState(() => _regionalitiesLoading = true);
    try {
      final regionalities = await _regionalityService.fetchRegionalities();
      if (!mounted) return;
      setState(() {
        _regionalities = _sortedByName(regionalities, (r) => r.name);
        _regionalitiesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _regionalitiesLoading = false);
    }
  }

  Future<void> _openCreateCategoryDialog() async {
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
    setState(() {
      _categories = _sortedByName([..._categories, created], (c) => c.name);
      _primaryCategory = created.id;
      _subcategory = null;
    });
  }

  /// Adds a single subcategory to the currently selected primary category.
  /// Only available once [_primaryCategory] is set (the dropdown option is
  /// gated the same way). Persists immediately via [CategoryService.updateCategory].
  Future<void> _openCreateSubcategoryDialog() async {
    if (_primaryCategory == null) return;

    final categoryMatch =
        _categories.where((c) => c.id == _primaryCategory).toList();
    if (categoryMatch.isEmpty) return;
    final category = categoryMatch.first;

    final created = await CategoryEntryDialog.show<SubcategoryModel>(
      context,
      title: 'Add Subcategory',
      nameLabel: 'Subcategory Name *',
      nameHint: 'e.g. Noodles',
      description:
          'Added to "${category.name}" and saved right away so it can be '
          'reused on other items.',
      onSave: (name, _) async {
        final trimmed = name.trim();
        if (trimmed.isEmpty) {
          throw ArgumentError('Subcategory name cannot be empty.');
        }
        final alreadyExists = category.subcategories.any(
          (s) => s.name.toLowerCase() == trimmed.toLowerCase(),
        );
        if (alreadyExists) {
          throw ArgumentError(
            'A subcategory named "$trimmed" already exists in this category.',
          );
        }

        final subId =
            '${category.id}-${trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}';
        final newSub = SubcategoryModel(id: subId, name: trimmed);
        final updated = CategoryModel(
          id: category.id,
          name: category.name,
          subcategories: [...category.subcategories, newSub],
        );
        await _categoryService.updateCategory(updated);
        return newSub;
      },
    );
    if (created == null || !mounted) return;

    setState(() {
      _categories = [
        for (final item in _categories)
          if (item.id == category.id)
            CategoryModel(
              id: item.id,
              name: item.name,
              subcategories: _sortedByName(
                [...item.subcategories, created],
                (s) => s.name,
              ),
            )
          else
            item,
      ];
      _subcategory = created.id;
    });
  }

  Future<void> _openCreateRegionalityDialog() async {
    final enteredName = await CategoryEntryDialog.show<String>(
      context,
      title: 'Add Regionality',
      nameLabel: 'Regionality',
      nameHint: 'e.g. Punjabi',
      description: 'e.g. Punjabi, Indo-Chinese, South Indian. Saved along '
          'with this item once you submit the form.',
      initialName: _pendingRegionalityName,
      // Local-only: no service call here, the menu item form persists it
      // once the item itself is saved.
      onSave: (name, _) async => name,
    );
    if (enteredName == null || enteredName.trim().isEmpty || !mounted) return;

    setState(() {
      _pendingRegionalityName = enteredName.trim();
      _regionality = _kPendingRegionalityId;
    });
  }

  Future<void> _openCreatePreparationDialog() async {
    final enteredName = await CategoryEntryDialog.show<String>(
      context,
      title: 'Add Preparation Style',
      editTitle: 'Edit Preparation Style',
      nameLabel: 'Preparation Style',
      nameHint: 'e.g. Tandoori',
      description: 'e.g. Tandoori, Gravy, Steam. Saved along with this '
          'item once you submit the form.',
      initialName: _pendingPreparationName,
      onSave: (name, _) async => name,
    );
    if (enteredName == null || enteredName.trim().isEmpty || !mounted) return;

    setState(() {
      _pendingPreparationName = enteredName.trim();
      _preparation = _kPendingPreparationId;
    });
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    await RdxNoticeDialog.show(context, message: message);
  }

  Future<void> _openCreateTagDialog() async {
    if (_customTags.length >= TagService.maxCustomTags) {
      await _showErrorDialog(
        'You can only create up to ${TagService.maxCustomTags} custom tags.',
      );
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

    setState(() {
      _customTags = _sortedByName([..._customTags, created], (t) => t.name);
      _tags.add(created.name);
    });
  }

//Fetching options is done in parallel, so they can fail independently.

  Future<void> _loadPreparations() async {
    setState(() => _preparationsLoading = true);
    try {
      final preparations = await _preparationService.fetchPreparations();
      if (!mounted) return;
      setState(() {
        _preparations = _sortedByName(preparations, (p) => p.name);
        _preparationsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _preparationsLoading = false);
    }
  }

  Future<void> _loadCustomTags() async {
    setState(() => _customTagsLoading = true);
    try {
      final tags = await _tagService.fetchTags();
      if (!mounted) return;
      setState(() {
        _customTags = _sortedByName(tags, (t) => t.name);
        _customTagsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _customTagsLoading = false);
    }
  }

  List<MenuItemSize> get _currentSizes {
    final result = <MenuItemSize>[];
    for (var i = 0; i < _sizeNameControllers.length; i++) {
      final name = _sizeNameControllers[i].text.trim();
      final price = double.tryParse(_sizePriceControllers[i].text.trim());
      if (name.isEmpty || price == null || price < 0) continue;
      result.add(MenuItemSize(name: name, price: price));
    }
    return result;
  }

  double get _resolvedPrice {
    if (_hasSizes) {
      final sizes = _currentSizes;
      if (sizes.isEmpty) return 0.0;
      return sizes.map((s) => s.price).reduce((a, b) => a < b ? a : b);
    }
    return double.tryParse(_price.text.trim()) ?? 0.0;
  }

  void _addSizeRow({String name = '', String price = ''}) {
    if (_sizeNameControllers.length >= _maxSizes) return;
    setState(() {
      _sizeNameControllers.add(TextEditingController(text: name));
      _sizePriceControllers.add(TextEditingController(text: price));
    });
  }

  void _removeSizeRow() {
    if (_sizeNameControllers.length <= 1) return;
    setState(() {
      _sizeNameControllers.removeLast().dispose();
      _sizePriceControllers.removeLast().dispose();
    });
  }

  void _setHasSizes(bool value) {
    setState(() {
      _hasSizes = value;
      if (value && _sizeNameControllers.isEmpty) {
        _sizeNameControllers.add(TextEditingController());
        _sizePriceControllers.add(TextEditingController());
      }
    });
  }

  MenuItemModel get _previewItem {
    final sizes = _hasSizes ? _currentSizes : const <MenuItemSize>[];
    final price = _resolvedPrice;

    return MenuItemModel(
      id: widget.itemId ?? 'preview',
      name: _name.text.trim().isEmpty ? 'Item Name' : _name.text.trim(),
      description: _description.text.trim(),
      imageUrl: _image.text.trim(),
      available: _available,
      featuredItem: _tags.contains('Featured'),
      sortOrder: int.tryParse(_sortOrder.text) ?? 0,
      dietaryType: _dietaryType ?? DietaryType.veg,
      preparationId: _preparation ?? '',
      preparation: _preparationLabel(_preparation),
      price: price,
      sizes: sizes,
      category: _primaryCategory == null
          ? 'Category'
          : _categoryLabel(_primaryCategory!),
      subCategoryId: _subcategory ?? '',
      subCategory: _subcategory == null ? '' : _categoryLabel(_subcategory!),
      regionalityId: _regionality ?? '',
      regionality: _regionalityLabel(_regionality),
      tags: _tags
          .where((tag) => tag != 'Featured')
          .map((tag) => tag.toLowerCase().replaceAll(' ', '_'))
          .toList(),
      ingredients: List<String>.from(_ingredients),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadRegionalities();
    _loadPreparations();
    _loadCustomTags();
    if (_editing) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final item = await ref.read(menuProvider).getItemById(widget.itemId!);
      _name.text = item.name;
      _description.text = item.description;
      _image.text = item.imageUrl;
      _price.text = item.price.toString();
      _sortOrder.text = item.sortOrder.toString();
      _primaryCategory = item.primaryCategoryId;
      _subcategory = item.subCategoryId.isEmpty ? null : item.subCategoryId;
      _regionality = item.regionalityId.isEmpty ? null : item.regionalityId;
      _pendingRegionalityName = null;
      _dietaryType = item.dietaryType;
      _preparation = item.preparationId.isEmpty ? null : item.preparationId;
      _pendingPreparationName = null;
      final loadedTags = item.tags.map(_titleCase).toList();
      if (item.featuredItem) loadedTags.insert(0, 'Featured');
      _tags
        ..clear()
        ..addAll(loadedTags.take(4));
      _ingredients
        ..clear()
        ..addAll(item.ingredients);
      _available = item.available;

      // Size-based pricing
      for (final c in _sizeNameControllers) {
        c.dispose();
      }
      for (final c in _sizePriceControllers) {
        c.dispose();
      }
      _sizeNameControllers.clear();
      _sizePriceControllers.clear();
      if (item.sizes.isNotEmpty) {
        _hasSizes = true;
        for (final s in item.sizes.take(_maxSizes)) {
          _sizeNameControllers.add(TextEditingController(text: s.name));
          _sizePriceControllers.add(
            TextEditingController(
              text: s.price == s.price.roundToDouble()
                  ? s.price.toInt().toString()
                  : s.price.toString(),
            ),
          );
        }
      } else {
        _hasSizes = false;
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        await _showErrorDialog('Failed to load menu item.');
        return;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _addIngredient() {
    final value = _ingredientInput.text.trim();
    if (value.isEmpty) return;
    if (_ingredients.length >= 10) return;
    if (_ingredients.any((e) => e.toLowerCase() == value.toLowerCase())) {
      _ingredientInput.clear();
      return;
    }
    setState(() {
      _ingredients.add(value);
      _ingredientInput.clear();
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      await _showErrorDialog('Please enter an item name.');
      return;
    }

    double price;
    List<MenuItemSize> sizes = const [];

    if (_hasSizes) {
      sizes = _currentSizes;
      if (sizes.isEmpty) {
        await _showErrorDialog(
          'Please add at least one size with a valid name and price.',
        );
        return;
      }
      if (_sizeNameControllers.any((c) => c.text.trim().isEmpty) ||
          _sizePriceControllers.any((c) {
            final p = double.tryParse(c.text.trim());
            return p == null || p < 0;
          })) {
        await _showErrorDialog(
          'Each size needs a name and a valid price.',
        );
        return;
      }
      price = sizes.map((s) => s.price).reduce((a, b) => a < b ? a : b);
    } else {
      final parsed = double.tryParse(_price.text.trim());
      if (parsed == null || parsed < 0) {
        await _showErrorDialog('Please enter a valid price.');
        return;
      }
      price = parsed;
    }

    if (_primaryCategory == null) {
      await _showErrorDialog('Please select a category.');
      return;
    }

    if (_dietaryType == null) {
      await _showErrorDialog('Please select a dietary type.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    // A regionality typed via the dialog is only held locally until now —
    // persist it (and swap the pending marker for the real ID) right
    // before the menu item itself is written.
    var regionalityId = _regionality ?? '';
    var regionalityName = _regionalityLabel(_regionality);

    if (_regionality == _kPendingRegionalityId &&
        _pendingRegionalityName != null &&
        _pendingRegionalityName!.trim().isNotEmpty) {
      try {
        final created = await _regionalityService.createRegionality(
          name: _pendingRegionalityName!,
        );
        regionalityId = created.id;
        regionalityName = created.name;
        if (mounted) {
          setState(() {
            _regionalities =
                _sortedByName([..._regionalities, created], (r) => r.name);
            _regionality = created.id;
            _pendingRegionalityName = null;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
        await _showErrorDialog('Failed to save regionality. Please try again.');
        return;
      }
    }

    // Same deferred-creation handling for a preparation typed via its
    // dialog.
    var preparationId = _preparation ?? '';
    var preparationName = _preparationLabel(_preparation);

    if (_preparation == _kPendingPreparationId &&
        _pendingPreparationName != null &&
        _pendingPreparationName!.trim().isNotEmpty) {
      try {
        final created = await _preparationService.createPreparation(
          name: _pendingPreparationName!,
        );
        preparationId = created.id;
        preparationName = created.name;
        if (mounted) {
          setState(() {
            _preparations =
                _sortedByName([..._preparations, created], (p) => p.name);
            _preparation = created.id;
            _pendingPreparationName = null;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
        await _showErrorDialog(
          'Failed to save preparation style. Please try again.',
        );
        return;
      }
    }

    final item = MenuItemModel(
      id: widget.itemId ?? '',
      name: _name.text.trim(),
      description: _description.text.trim(),
      imageUrl: _image.text.trim(),
      available: _available,
      featuredItem: _tags.contains('Featured'),
      sortOrder: int.tryParse(_sortOrder.text) ?? 0,
      dietaryType: _dietaryType!,
      preparationId: preparationId,
      preparation: preparationName,
      price: price,
      sizes: sizes,
      primaryCategoryId: _primaryCategory!,
      category: _categoryLabel(_primaryCategory!),
      subCategoryId: _subcategory ?? '',
      subCategory: _subcategory == null ? '' : _categoryLabel(_subcategory!),
      regionalityId: regionalityId,
      regionality: regionalityName,
      tags: _tags
          .where((tag) => tag != 'Featured')
          .map((tag) => tag.toLowerCase().replaceAll(' ', '_'))
          .toList(),
      ingredients: List<String>.from(_ingredients),
    );

    final success = await ref.read(menuProvider).saveItem(item);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      if (mounted) setState(() => _loading = false);
      await _showErrorDialog(
        ref.read(menuProvider).errorMessage ?? 'Failed to save menu item.',
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _image.dispose();
    _price.dispose();
    _sortOrder.dispose();
    _ingredientInput.dispose();
    for (final c in _sizeNameControllers) {
      c.dispose();
    }
    for (final c in _sizePriceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          RdxHeader(
            title: _editing ? 'Edit Menu Item' : 'Add Menu Item',
            showBackButton: true,
          ),
          Expanded(
            child: _loading && _editing
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: narrow
                        ? SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              context.w(20),
                              context.h(16),
                              context.w(20),
                              context.h(28),
                            ),
                            child: Column(
                              children: [
                                _mainColumn(context, colors),
                                SizedBox(height: context.h(16)),
                                _previewCard(context),
                                SizedBox(height: context.h(14)),
                                _actionButtons(context, colors),
                              ],
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.fromLTRB(
                              context.w(20),
                              context.h(16),
                              context.w(20),
                              context.h(24),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding:
                                        EdgeInsets.only(right: context.w(22)),
                                    child: Column(
                                      children: [
                                        _mainColumn(context, colors),
                                      ],
                                    ),
                                  ),
                                ),
                                VerticalDivider(
                                  width: context.w(1),
                                  thickness: context.h(1),
                                  color: colors.border,
                                ),
                                SizedBox(
                                  width: context.w(320),
                                  child: Padding(
                                    padding:
                                        EdgeInsets.only(left: context.w(22)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Preview',
                                          style: AppTextStyles.section(context)
                                              .copyWith(
                                                  color: colors.textPrimary),
                                        ),
                                        SizedBox(height: context.h(10)),
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: SizedBox(
                                              width: context.w(225),
                                              child: MenuItemCard(
                                                item: _previewItem,
                                                categorySelected:
                                                    _primaryCategory != null,
                                                dietarySelected:
                                                    _dietaryType != null,
                                                hasTags: _tags.any((t) =>
                                                        t != 'Featured') ||
                                                    _preparation != null,
                                                onToggleAvailability: () {
                                                  setState(() =>
                                                      _available = !_available);
                                                },
                                                onActions: (_) {},
                                              ),
                                            ),
                                          ),
                                        ),
                                        _actionButtons(context, colors),
                                      ],
                                    ),
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

  Widget _previewCard(BuildContext context) => Center(
        child: SizedBox(
          width: context.w(225),
          child: MenuItemCard(
            item: _previewItem,
            categorySelected: _primaryCategory != null,
            dietarySelected: _dietaryType != null,
            hasTags: _tags.any((t) => t != 'Featured') || _preparation != null,
            onToggleAvailability: () {
              setState(() => _available = !_available);
            },
            onActions: (_) {},
          ),
        ),
      );

  Widget _actionButtons(BuildContext context, AppColorScheme colors) => Row(
        children: [
          Expanded(
            child: RdxActionButton.discard(
              onPressed: _loading ? null : () => Navigator.pop(context),
            ),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: RdxActionButton.save(
              isLoading: _loading,
              onPressed: _save,
            ),
          ),
        ],
      );

  Widget _mainColumn(BuildContext context, AppColorScheme colors) => Column(
        children: [
          _panel(context, colors, 'Basic Information',
              Icons.description_outlined, [
            LayoutBuilder(builder: (context, c) {
              final stack = c.maxWidth < 400;
              final nameField = RdxTextField(
                controller: _name,
                maxLength: 25,
                label: 'Item Name *',
                hint: 'Enter item name',
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
              );
              if (_hasSizes) {
                return nameField;
              }
              final priceField = RdxTextField(
                controller: _price,
                maxLength: 4,
                label: 'Price *',
                hint: 'Enter price',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textCapitalization: TextCapitalization.none,
                prefixText: '₹',
                onChanged: (_) => setState(() {}),
              );
              if (stack) {
                return Column(
                  children: [
                    nameField,
                    SizedBox(height: context.h(14)),
                    priceField,
                  ],
                );
              }
              return Row(children: [
                Expanded(child: nameField),
                SizedBox(width: context.w(14)),
                SizedBox(width: context.w(130), child: priceField),
              ]);
            }),
            SizedBox(height: context.h(15)),

            // ── Size-based pricing toggle ─────────────────────────
            Row(
              children: [
                Expanded(
                  child: _switch(
                    context,
                    colors,
                    'Sizes',
                    _hasSizes,
                    _setHasSizes,
                  ),
                ),
                if (_hasSizes)
                  Text(
                    '${_sizeNameControllers.length}/$_maxSizes',
                    style: AppTextStyles.bodyTertiary(context)
                        .copyWith(color: colors.textMuted),
                  ),
              ],
            ),
            if (_hasSizes) ...[
              SizedBox(height: context.h(12)),
              // Size rows are packed tightly (small gap only) so adding
              // more sizes doesn't visually "spread out" the form.
              for (var i = 0; i < _sizeNameControllers.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: context.h(3),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: RdxTextField(
                          controller: _sizeNameControllers[i],
                          maxLength: 20,
                          label: i == 0 ? 'Size *' : '',
                          hint: 'Enter Size',
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      SizedBox(width: context.w(10)),
                      Expanded(
                        flex: 2,
                        child: RdxTextField(
                          controller: _sizePriceControllers[i],
                          maxLength: 4,
                          label: i == 0 ? 'Price *' : '',
                          hint: 'Price',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textCapitalization: TextCapitalization.none,
                          prefixText: '₹',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: context.h(4)),
              Row(
                children: [
                  RdxActionButton(
                    label: '−',
                    onPressed: _sizeNameControllers.length <= 1
                        ? null
                        : _removeSizeRow,
                    isPrimary: false,
                    height: context.h(35).clamp(30.0, 35.0),
                    minWidth: context.w(48).clamp(38.0, 48.0),
                  ),
                  SizedBox(width: context.w(8)),
                  RdxActionButton(
                    label: '+',
                    enabled: _sizeNameControllers.length < _maxSizes &&
                        _sizeNameControllers.last.text.trim().isNotEmpty &&
                        _sizePriceControllers.last.text.trim().isNotEmpty,
                    onPressed: _addSizeRow,
                    isPrimary: true,
                    height: context.h(35).clamp(30.0, 35.0),
                    minWidth: context.w(48).clamp(38.0, 48.0),
                  ),
                ],
              ),
            ],
            SizedBox(height: context.h(15)),

            // ── Ingredients ────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Ingredients',
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    color: colors.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_ingredients.length}/10',
                  style: AppTextStyles.bodyTertiary(context)
                      .copyWith(color: colors.textMuted),
                ),
              ],
            ),
            SizedBox(height: context.h(8)),
            Row(
              children: [
                Expanded(
                  child: RdxTextField(
                    controller: _ingredientInput,
                    maxLength: 25,
                    hint: 'Enter ingredient and tap +',
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                ),
                SizedBox(width: context.w(8)),
                IconButton(
                  tooltip: 'Add ingredient',
                  onPressed: _ingredientInput.text.trim().isEmpty ||
                          _ingredients.length >= 10
                      ? null
                      : _addIngredient,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE0E0E0),
                    disabledForegroundColor: const Color(0xFF757575),
                    fixedSize: Size.square(context.w(40).clamp(32.0, 40.0)),
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  icon: Icon(
                    Icons.add,
                    size: context.h(20).clamp(16.0, 20.0),
                  ),
                ),
              ],
            ),
            if (_ingredients.isNotEmpty) ...[
              SizedBox(height: context.h(10)),
              Wrap(
                spacing: context.w(8),
                runSpacing: context.h(8),
                children: [
                  for (final ing in _ingredients)
                    _IngredientChip(
                      label: ing,
                      colors: colors,
                      onDeleted: () => setState(() => _ingredients.remove(ing)),
                    ),
                ],
              ),
            ],

            SizedBox(height: context.h(15)),
            RdxTextField(
              controller: _description,
              maxLength: 300,
              label: 'Description',
              maxLines: 5,
              hint: 'Add item description',
              counterText: '${_description.text.length}/300',
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: context.h(15)),
            RdxTextField(
              controller: _image,
              maxLength: 120,
              label: 'Item Image',
              hint: 'Enter image URL',
              textCapitalization: TextCapitalization.none,
              onChanged: (_) => setState(() {}),
            ),
          ]),
          SizedBox(height: context.h(16)),
          _panel(
            context,
            colors,
            'Item Details',
            Icons.assignment_outlined,
            [
              LayoutBuilder(builder: (context, c) {
                final stack = c.maxWidth < 400;
                final cat = _dropdown(
                  'Category',
                  _primaryCategory,
                  [
                    _kCreateCategoryValue,
                    ..._categories.map((item) => item.id),
                  ],
                  (value) {
                    if (value == _kCreateCategoryValue) {
                      _openCreateCategoryDialog();
                      return;
                    }
                    setState(() {
                      _primaryCategory = value;
                      _subcategory = null;
                    });
                  },
                  _categoryLabel,
                  required: true,
                  searchable: true,
                  hint: _categoriesLoading
                      ? 'Loading categories...'
                      : 'Select category',
                );
                final sub = _dropdown(
                  'Subcategory',
                  _subcategory,
                  [
                    // "+ Create subcategory" only appears once a category is chosen.
                    if (_primaryCategory != null) _kCreateSubcategoryValue,
                    ..._subcategories.map((item) => item.id),
                  ],
                  (value) {
                    if (value == _kCreateSubcategoryValue) {
                      _openCreateSubcategoryDialog();
                      return;
                    }
                    setState(() => _subcategory = value);
                  },
                  _categoryLabel,
                  searchable: true,
                  hint: _primaryCategory == null
                      ? 'Select a category first'
                      : 'Select subcategory',
                );
                if (stack) {
                  return Column(children: [
                    cat,
                    SizedBox(height: context.h(14)),
                    sub,
                  ]);
                }
                return Row(children: [
                  Expanded(child: cat),
                  SizedBox(width: context.w(14)),
                  Expanded(child: sub),
                ]);
              }),
              SizedBox(height: context.h(15)),
              LayoutBuilder(builder: (context, c) {
                final regionality = _dropdown(
                  'Regionality',
                  _regionality,
                  [
                    _kCreateRegionalityValue,
                    ..._regionalities.map((item) => item.id),
                    if (_pendingRegionalityName != null) _kPendingRegionalityId,
                  ],
                  (value) {
                    if (value == _kCreateRegionalityValue) {
                      _openCreateRegionalityDialog();
                      return;
                    }
                    setState(() {
                      _regionality = value;
                      if (value != _kPendingRegionalityId) {
                        _pendingRegionalityName = null;
                      }
                    });
                  },
                  _regionalityLabel,
                  searchable: true,
                  hint: _regionalitiesLoading
                      ? 'Loading regionalities...'
                      : 'Select regionality',
                );
                return regionality;
              }),
              SizedBox(height: context.h(15)),
              LayoutBuilder(builder: (context, c) {
                final stack = c.maxWidth < 400;
                final diet = _dropdown(
                  'Dietary Type',
                  _dietaryType,
                  _sortedByName(
                    DietaryType.values,
                    (v) => _titleCase(v.name),
                  ),
                  (value) => setState(() => _dietaryType = value),
                  (value) => _titleCase(value.name),
                  required: true,
                );
                final prep = _dropdown(
                  'Preparation Style',
                  _preparation,
                  [
                    _kCreatePreparationValue,
                    ..._preparations.map((item) => item.id),
                    if (_pendingPreparationName != null) _kPendingPreparationId,
                  ],
                  (value) {
                    if (value == _kCreatePreparationValue) {
                      _openCreatePreparationDialog();
                      return;
                    }
                    setState(() {
                      _preparation = value;
                      if (value != _kPendingPreparationId) {
                        _pendingPreparationName = null;
                      }
                    });
                  },
                  _preparationLabel,
                  searchable: true,
                  hint: _preparationsLoading
                      ? 'Loading preparation styles...'
                      : 'Select preparation style',
                );
                if (stack) {
                  return Column(children: [
                    diet,
                    SizedBox(height: context.h(14)),
                    prep,
                  ]);
                }
                return Row(children: [
                  Expanded(child: diet),
                  SizedBox(width: context.w(14)),
                  Expanded(child: prep),
                ]);
              }),
              SizedBox(height: context.h(15)),
              Row(
                children: [
                  Text(
                    'Tags',
                    style: AppTextStyles.bodySecondary(context).copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                  SizedBox(width: context.w(6)),
                  InkWell(
                    onTap: _customTagsLoading ? null : _openCreateTagDialog,
                    borderRadius: BorderRadius.circular(context.h(6)),
                    child: Padding(
                      padding: EdgeInsets.all(context.w(2)),
                      child: Icon(
                        Icons.add_circle_outline_rounded,
                        size: context.h(18),
                        color: _customTagsLoading
                            ? colors.textMuted
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(7)),
              Wrap(
                spacing: context.w(8),
                runSpacing: context.h(8),
                children: [
                  for (final tag in _tagOptions) _tagChip(context, colors, tag),
                  for (final tag in _customTags)
                    _tagChip(context, colors, tag.name),
                ],
              ),
            ],
            headerTrailing: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MenuManageCategoryScreen(),
                  ),
                );
              },
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
          ),
          SizedBox(height: context.h(16)),
          _panel(context, colors, 'Display Settings',
              Icons.desktop_windows_outlined, [
            Row(children: [
              Expanded(
                child: _switch(
                  context,
                  colors,
                  'Available on Menu',
                  _available,
                  (value) => setState(() => _available = value),
                ),
              ),
            ]),
          ]),
          SizedBox(height: context.h(12)),
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
                Icon(Icons.lightbulb_outline,
                    size: context.h(18), color: AppColors.primary),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Text(
                    'Tip: Add high quality images and detailed descriptions to attract more customers.',
                    style: AppTextStyles.bodyTertiary(context)
                        .copyWith(color: colors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _panel(
    BuildContext context,
    AppColorScheme colors,
    String title,
    IconData icon,
    List<Widget> children, {
    Widget? headerTrailing,
  }) =>
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.h(14)),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(context.h(8)),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: context.h(18), color: AppColors.primary),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.section(context)
                        .copyWith(color: colors.textPrimary),
                  ),
                ),
                if (headerTrailing != null) headerTrailing,
              ],
            ),
            SizedBox(height: context.h(16)),
            ...children,
          ],
        ),
      );

  Widget _dropdown<T>(
    String label,
    T? value,
    List<T> values,
    ValueChanged<T?> onChanged,
    String Function(T) labelFor, {
    String? hint,
    bool required = false,
    bool searchable = false,
  }) =>
      RdxDropdown<T>(
        label: required ? '$label *' : label,
        value: values.contains(value) ? value : null,
        items: values,
        labelBuilder: labelFor,
        hint: hint ?? 'Select $label',
        onChanged: onChanged,
        searchable: searchable,
      );

  /// Title + toggle sit on the same row, hugging each other with only a
  /// small fixed gap (not spread across the row), then the subtitle
  /// wraps below at full width.
  Widget _switch(
    BuildContext context,
    AppColorScheme colors,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySecondary(context)
                    .copyWith(color: colors.textMuted),
              ),
              SizedBox(width: context.w(8)),
              RdxToggleButton(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ],
      );

  Widget _tagChip(BuildContext context, AppColorScheme colors, String tag) =>
      FilterChip(
        label: Text(
          tag,
          style: AppTextStyles.label(context).copyWith(
            color: _tags.contains(tag) ? AppColors.primary : colors.textPrimary,
          ),
        ),
        selected: _tags.contains(tag),
        showCheckmark: true,
        checkmarkColor: AppColors.primary,
        backgroundColor: colors.surfaceVariant,
        selectedColor: Colors.white,
        side: BorderSide(
          color: _tags.contains(tag) ? AppColors.primary : colors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(9),
          vertical: context.h(5),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onSelected: _tags.length >= 4 && !_tags.contains(tag)
            ? null
            : (selected) => setState(() {
                  if (selected) {
                    _tags.add(tag);
                  } else {
                    _tags.remove(tag);
                  }
                }),
      );

  String _categoryLabel(String id) {
    if (id == _kCreateCategoryValue) return '+ Create your category';
    if (id == _kCreateSubcategoryValue) return '+ Create subcategory';

    final match = _categories.where((item) => item.id == id).toList();
    if (match.isNotEmpty) return match.first.name;

    final subMatch = _subcategories.where((item) => item.id == id).toList();
    if (subMatch.isNotEmpty) return subMatch.first.name;

    return id;
  }

  /// Label for the regionality dropdown. Handles the "create" sentinel,
  /// the not-yet-persisted pending entry, and normal saved regionalities.
  String _regionalityLabel(String? id) {
    if (id == null) return '';
    if (id == _kCreateRegionalityValue) return '+ Add regionality';
    if (id == _kPendingRegionalityId) {
      return _pendingRegionalityName ?? '';
    }

    final match = _regionalities.where((item) => item.id == id).toList();
    return match.isEmpty ? id : match.first.name;
  }

  /// Label for the preparation dropdown — same shape as
  /// [_regionalityLabel] (sentinel, pending entry, saved value).
  String _preparationLabel(String? id) {
    if (id == null) return '';
    if (id == _kCreatePreparationValue) return '+ Add preparation style';
    if (id == _kPendingPreparationId) {
      return _pendingPreparationName ?? '';
    }

    final match = _preparations.where((item) => item.id == id).toList();
    return match.isEmpty ? id : match.first.name;
  }

  String _titleCase(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map((part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _IngredientChip extends ConsumerWidget {
  final String label;
  final AppColorScheme colors;
  final VoidCallback onDeleted;

  const _IngredientChip({
    required this.label,
    required this.colors,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.only(
        left: context.w(9),
        right: context.w(4),
        top: context.h(5),
        bottom: context.h(5),
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyTertiary(context),
          ),
          SizedBox(width: context.w(4)),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(context.h(10)),
            child: Padding(
              padding: EdgeInsets.all(context.h(2)),
              child: Icon(
                Icons.close_rounded,
                size: context.h(14),
                color: colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
