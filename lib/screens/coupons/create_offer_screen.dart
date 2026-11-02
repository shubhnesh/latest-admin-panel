import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/screens/coupons/widgets/offer_card.dart';
import 'package:rdx_admin/widgets/dialogs/rdx_notice_dialog.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/category_model.dart';
import '../../models/coupon_model.dart';
import '../../models/menu_item_model.dart';
import '../../models/offer_model.dart';
import '../../providers/offer_provider.dart';
import '../../services/category_service.dart';
import '../../services/menu_service.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/buttons/rdx_toggle_button.dart';
import '../../widgets/reusable_widgets/rdx_dropdown.dart';
import '../../widgets/reusable_widgets/rdx_text_field.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';

const String _kNoneCategoryValue = '__none_category__';
const String _kNoneSubCategoryValue = '__none_subcategory__';
const String _kNoneItemValue = '__none_item__';

class CreateOfferScreen extends ConsumerStatefulWidget {
  final OfferModel? existing;
  final VoidCallback? onCreated;
  final bool embedded;
  final String promotionType;
  final ValueChanged<String>? onPromotionTypeChanged;

  const CreateOfferScreen({
    super.key,
    this.existing,
    this.onCreated,
    this.embedded = false,
    this.promotionType = 'Offers',
    this.onPromotionTypeChanged,
  });

  @override
  ConsumerState<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends ConsumerState<CreateOfferScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final discountValueController = TextEditingController();
  final minOrderController = TextEditingController();
  final usageLimitController = TextEditingController();
  final imageController = TextEditingController();
  final homePriorityController = TextEditingController(text: '1');

  bool get isEdit => widget.existing != null && widget.existing!.id.isNotEmpty;

  DiscountType discountType = DiscountType.percentage;
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;
  bool autoApply = false;
  bool showOnHome = false;

  final _categoryService = CategoryService();
  final _menuService = MenuService();

  List<CategoryModel> _categories = [];
  bool _categoriesLoading = true;
  List<MenuItemModel> _menuItems = [];
  bool _itemsLoading = true;

  String _selectedCategoryId = _kNoneCategoryValue;
  String _selectedSubCategoryId = _kNoneSubCategoryValue;
  String _selectedItemId = _kNoneItemValue;

  List<T> _sortedByName<T>(Iterable<T> items, String Function(T) nameOf) {
    final list = List<T>.from(items);
    list.sort(
      (a, b) => nameOf(a).toLowerCase().compareTo(nameOf(b).toLowerCase()),
    );
    return list;
  }

  CategoryModel? get _selectedCategory {
    if (_selectedCategoryId == _kNoneCategoryValue) return null;
    final matches =
        _categories.where((c) => c.id == _selectedCategoryId).toList();
    return matches.isEmpty ? null : matches.first;
  }

  List<SubcategoryModel> get _subcategoriesForSelectedCategory {
    final subs = _selectedCategory?.subcategories ?? [];
    return _sortedByName(subs, (s) => s.name);
  }

  CategoryModel? _categoryForSubcategoryId(String subCategoryId) {
    for (final category in _categories) {
      if (category.subcategories.any((s) => s.id == subCategoryId)) {
        return category;
      }
    }
    return null;
  }

  List<MenuItemModel> get _itemsForSelectedSubCategory {
    if (_selectedSubCategoryId == _kNoneSubCategoryValue) return [];
    return _sortedByName(
      _menuItems.where((item) => item.subCategoryId == _selectedSubCategoryId),
      (item) => item.name,
    );
  }

  String _categoryLabel(String id) {
    if (id == _kNoneCategoryValue) return 'None';
    final match = _categories.where((c) => c.id == id).toList();
    return match.isEmpty ? id : match.first.name;
  }

  String _subCategoryLabel(String id) {
    if (id == _kNoneSubCategoryValue) return 'None';
    final match = _categories
        .expand((c) => c.subcategories)
        .where((s) => s.id == id)
        .toList();
    return match.isEmpty ? id : match.first.name;
  }

  String _itemLabel(String id) {
    if (id == _kNoneItemValue) return 'None';
    final match = _menuItems.where((i) => i.id == id).toList();
    return match.isEmpty ? id : match.first.name;
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final categories = await _categoryService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = _sortedByName(categories, (c) => c.name);
        _categoriesLoading = false;
        if (_selectedSubCategoryId != _kNoneSubCategoryValue) {
          final owner = _categoryForSubcategoryId(_selectedSubCategoryId);
          _selectedCategoryId = owner?.id ?? _kNoneCategoryValue;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _loadMenuItems() async {
    setState(() => _itemsLoading = true);
    try {
      final items = await _menuService.fetchMenuItems();
      if (!mounted) return;
      setState(() {
        _menuItems = _sortedByName(items, (i) => i.name);
        _itemsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _itemsLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    if (existing != null) {
      titleController.text = existing.title;
      descriptionController.text = existing.description;
      discountValueController.text = existing.discountValue.toString();
      minOrderController.text = existing.minOrderValue?.toString() ?? '';
      usageLimitController.text = existing.usageLimit?.toString() ?? '';
      imageController.text = existing.imageUrl ?? '';
      discountType = existing.discountType;
      startDate = existing.startDate;
      endDate = existing.endDate;
      autoApply = existing.autoApply;
      showOnHome = existing.showOnHome;
      homePriorityController.text = existing.homePriority.toString();
      _selectedSubCategoryId =
          existing.applicableSubCategoryId ?? _kNoneSubCategoryValue;
      _selectedItemId = existing.applicableItemId ?? _kNoneItemValue;
    }

    _loadCategories();
    _loadMenuItems();

    for (final control in [
      titleController,
      descriptionController,
      discountValueController,
      minOrderController,
      usageLimitController,
      imageController,
      homePriorityController,
    ]) {
      control.addListener(() => setState(() {}));
    }

    discountValueController.addListener(_clampPercentage);
  }

  void _clampPercentage() {
    if (discountType != DiscountType.percentage) return;
    final text = discountValueController.text.trim();
    if (text.isEmpty) return;
    final value = double.tryParse(text);
    if (value != null && value > 100) {
      discountValueController.text = '100';
      discountValueController.selection = TextSelection.fromPosition(
        const TextPosition(offset: 3),
      );
    }
  }

  Future<void> _showNotice(String message) async {
    if (!mounted) return;
    await RdxNoticeDialog.show(context, message: message);
  }

  Future<void> _save() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final discountText = discountValueController.text.trim();
    final minOrderText = minOrderController.text.trim();
    final usageLimitText = usageLimitController.text.trim();
    final homePriorityText = homePriorityController.text.trim();

    final discountValue = double.tryParse(discountText);
    final minOrderValue = double.tryParse(minOrderText);
    final usageLimit =
        usageLimitText.isEmpty ? null : int.tryParse(usageLimitText);
    final homePriority = int.tryParse(homePriorityText) ?? 0;

    if (title.isEmpty) {
      await _showNotice('Please enter an offer title.');
      return;
    }
    if (discountValue == null) {
      await _showNotice('Please enter a discount value.');
      return;
    }
    if (discountValue <= 0) {
      await _showNotice('Discount value must be greater than 0.');
      return;
    }
    if (discountType == DiscountType.percentage && discountValue > 100) {
      await _showNotice('Discount percentage cannot be more than 100.');
      return;
    }
    if (minOrderValue == null) {
      await _showNotice('Please enter a minimum order value.');
      return;
    }
    if (minOrderValue < 0) {
      await _showNotice('Minimum order value cannot be negative.');
      return;
    }
    if (startDate == null) {
      await _showNotice('Please select a start date.');
      return;
    }
    if (endDate == null) {
      await _showNotice('Please select an expiry date.');
      return;
    }
    if (usageLimitText.isNotEmpty && (usageLimit == null || usageLimit <= 0)) {
      await _showNotice('Usage limit must be greater than 0 when provided.');
      return;
    }
    if (endDate!.isBefore(startDate!)) {
      await _showNotice('Expiry date cannot be before the start date.');
      return;
    }
    if (_selectedCategoryId != _kNoneCategoryValue &&
        _selectedSubCategoryId == _kNoneSubCategoryValue) {
      await _showNotice(
        'Please select a subcategory, or set the category back to None.',
      );
      return;
    }
    if (showOnHome && homePriority < 0) {
      await _showNotice('Home priority must be 0 or greater.');
      return;
    }

    final offer = OfferModel(
      id: isEdit ? widget.existing!.id : '',
      title: title,
      description: description,
      discountType: discountType,
      discountValue: discountValue,
      minOrderValue: minOrderValue,
      usageLimit: usageLimit,
      startDate: startDate!,
      endDate: endDate!,
      imageUrl: imageController.text.trim().isEmpty
          ? null
          : imageController.text.trim(),
      status: startDate!.isAfter(DateTime.now())
          ? CouponStatus.scheduled
          : CouponStatus.active,
      autoApply: autoApply,
      showOnHome: showOnHome,
      homePriority: homePriority,
      applicableSubCategoryId: _selectedSubCategoryId == _kNoneSubCategoryValue
          ? null
          : _selectedSubCategoryId,
      applicableItemId:
          _selectedItemId == _kNoneItemValue ? null : _selectedItemId,
    );

    setState(() {
      isLoading = true;
    });

    try {
      final success = isEdit
          ? await ref.read(offerProvider).updateOffer(offer)
          : await ref.read(offerProvider).createOffer(offer);

      if (!mounted) return;
      setState(() => isLoading = false);

      if (success) {
        if (widget.onCreated != null) {
          widget.onCreated!.call();
        } else {
          Navigator.of(context).pop();
        }
      } else {
        await _showNotice(
          isEdit ? 'Failed to update offer.' : 'Failed to create offer.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      await _showNotice(
        isEdit ? 'Failed to update offer.' : 'Failed to create offer.',
      );
    }
  }

  @override
  void dispose() {
    discountValueController.removeListener(_clampPercentage);
    for (final control in [
      titleController,
      descriptionController,
      discountValueController,
      minOrderController,
      usageLimitController,
      imageController,
      homePriorityController,
    ]) {
      control.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 900;
    final parsedDiscount = double.tryParse(discountValueController.text.trim());

    final previewOffer = OfferModel(
      id: 'draft',
      title: titleController.text.trim().isEmpty
          ? 'Flat ₹ OFF'
          : titleController.text.trim(),
      description: descriptionController.text.trim(),
      discountType: discountType,
      discountValue: parsedDiscount ?? 0,
      minOrderValue: double.tryParse(minOrderController.text.trim()),
      usageLimit: int.tryParse(usageLimitController.text.trim()),
      startDate: startDate ?? DateTime.now(),
      endDate: endDate ?? DateTime.now(),
      imageUrl: imageController.text.trim().isEmpty
          ? null
          : imageController.text.trim(),
      status: startDate != null && !startDate!.isAfter(DateTime.now())
          ? CouponStatus.active
          : CouponStatus.scheduled,
      autoApply: autoApply,
      showOnHome: showOnHome,
      homePriority: int.tryParse(homePriorityController.text.trim()) ?? 1,
    );

    final preview = OfferCard(
      offer: previewOffer,
      onActions: (_) {},
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          if (!widget.embedded)
            RdxHeader(
              title: isEdit ? 'Edit Offer' : 'Create Promotion',
              showBackButton: true,
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final form = _formContent(context, colors);
                final pagePadding = Responsive.pagePadding(context);
                final columns = Responsive.gridColumns(context);
                final spacing = context.w(16);
                final previewCardWidth = (constraints.maxWidth -
                        pagePadding.horizontal -
                        ((columns - 1) * spacing)) /
                    columns;
                if (narrow) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      Responsive.pageHorizontal(context),
                      context.h(16),
                      Responsive.pageHorizontal(context),
                      context.h(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        form,
                        SizedBox(height: context.h(20)),
                        Text(
                          'Preview',
                          style: AppTextStyles.section(context)
                              .copyWith(color: colors.textPrimary),
                        ),
                        SizedBox(height: context.h(10)),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: previewCardWidth,
                            child: preview,
                          ),
                        ),
                        SizedBox(height: context.h(20)),
                        _actionButtons(context),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.pageHorizontal(context),
                    context.h(16),
                    Responsive.pageHorizontal(context),
                    context.h(24),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(right: context.w(22)),
                          child: form,
                        ),
                      ),
                      VerticalDivider(
                        width: context.w(1),
                        thickness: context.h(1),
                        color: colors.border,
                      ),
                      SizedBox(
                        width: previewCardWidth + context.w(22),
                        child: Padding(
                          padding: EdgeInsets.only(left: context.w(22)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Preview',
                                style: AppTextStyles.section(context)
                                    .copyWith(color: colors.textPrimary),
                              ),
                              SizedBox(height: context.h(10)),
                              SizedBox(
                                width: previewCardWidth,
                                child: preview,
                              ),
                              const Spacer(),
                              _actionButtons(context),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _formContent(BuildContext context, AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.embedded && !isEdit) ...[
          _sectionCard(
            context,
            icon: Icons.tune,
            title: 'Promotion Type',
            children: [
              RdxDropdown<String>(
                label: 'What would you like to create?',
                value: widget.promotionType,
                items: const ['Coupons', 'Offers'],
                labelBuilder: (value) => value,
                onChanged: (value) {
                  if (value != null) {
                    widget.onPromotionTypeChanged?.call(value);
                  }
                },
              ),
            ],
          ),
          SizedBox(height: context.h(20)),
        ],
        _sectionCard(
          context,
          icon: Icons.local_offer_outlined,
          title: 'Offer Basics',
          children: [
            RdxTextField(
              controller: titleController,
              label: 'Offer Title *',
              hint: 'Enter offer title',
              maxLength: 40,
            ),
            SizedBox(height: context.h(16)),
            RdxTextField(
              controller: descriptionController,
              label: 'Description',
              maxLines: 3,
              hint: 'Enter offer description',
              maxLength: 60,
            ),
            SizedBox(height: context.h(16)),
            RdxTextField(
              controller: imageController,
              maxLength: 120,
              label: 'Offer Image URL',
              hint: 'Enter image URL',
            ),
            SizedBox(height: context.h(16)),
            LayoutBuilder(builder: (context, c) {
              final stack = c.maxWidth < 420;
              final typeField = _discountTypeDropdown(context, colors);
              final valueField = RdxTextField(
                controller: discountValueController,
                maxLength: 4,
                label: 'Discount Value *',
                hint: discountType == DiscountType.percentage
                    ? 'Enter discount percentage'
                    : 'Enter flat amount',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
              );

              if (stack) {
                return Column(
                  children: [
                    typeField,
                    SizedBox(height: context.h(16)),
                    valueField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: typeField),
                  SizedBox(width: context.w(16)),
                  Expanded(child: valueField),
                ],
              );
            }),
          ],
        ),
        SizedBox(height: context.h(20)),
        _sectionCard(
          context,
          icon: Icons.category_outlined,
          title: 'Applicability (Optional)',
          children: [
            Text(
              'Restrict this offer to a specific subcategory or item. Select Category first.',
              style: AppTextStyles.bodySecondary(context)
                  .copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: context.h(16)),
            RdxDropdown<String>(
              label: 'Category',
              value: _selectedCategoryId,
              items: [
                _kNoneCategoryValue,
                ..._categories.map((c) => c.id),
              ],
              labelBuilder: _categoryLabel,
              hint: _categoriesLoading ? 'Loading...' : 'Select category',
              onChanged: _categoriesLoading
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() {
                        _selectedCategoryId = v;
                        _selectedSubCategoryId = _kNoneSubCategoryValue;
                        _selectedItemId = _kNoneItemValue;
                      });
                    },
            ),
            SizedBox(height: context.h(16)),
            LayoutBuilder(builder: (context, c) {
              final stack = c.maxWidth < 420;
              final subCategoryField = RdxDropdown<String>(
                label: _selectedCategoryId == _kNoneCategoryValue
                    ? 'Subcategory'
                    : 'Subcategory *',
                value: _selectedSubCategoryId,
                items: [
                  _kNoneSubCategoryValue,
                  ..._subcategoriesForSelectedCategory.map((s) => s.id),
                ],
                labelBuilder: _subCategoryLabel,
                hint: _selectedCategoryId == _kNoneCategoryValue
                    ? 'Select a category first'
                    : _categoriesLoading
                        ? 'Loading...'
                        : 'Select subcategory',
                onChanged: (_categoriesLoading ||
                        _selectedCategoryId == _kNoneCategoryValue)
                    ? null
                    : (v) {
                        if (v == null) return;
                        setState(() {
                          _selectedSubCategoryId = v;
                          _selectedItemId = _kNoneItemValue;
                        });
                      },
              );
              final itemField = RdxDropdown<String>(
                label: 'Item',
                value: _selectedItemId,
                items: [
                  _kNoneItemValue,
                  ..._itemsForSelectedSubCategory.map((i) => i.id),
                ],
                labelBuilder: _itemLabel,
                hint: _selectedSubCategoryId == _kNoneSubCategoryValue
                    ? 'Select a subcategory first'
                    : _itemsLoading
                        ? 'Loading...'
                        : 'Select item',
                onChanged: (_itemsLoading ||
                        _selectedSubCategoryId == _kNoneSubCategoryValue)
                    ? null
                    : (v) {
                        if (v == null) return;
                        setState(() => _selectedItemId = v);
                      },
              );

              if (stack) {
                return Column(
                  children: [
                    subCategoryField,
                    SizedBox(height: context.h(16)),
                    itemField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: subCategoryField),
                  SizedBox(width: context.w(16)),
                  Expanded(child: itemField),
                ],
              );
            }),
          ],
        ),
        SizedBox(height: context.h(20)),
        _sectionCard(
          context,
          icon: Icons.rule_folder_outlined,
          title: 'Usage Rules',
          children: [
            LayoutBuilder(builder: (context, c) {
              final stack = c.maxWidth < 420;
              final minField = RdxTextField(
                controller: minOrderController,
                maxLength: 5,
                label: 'Minimum Order Value (₹) *',
                hint: 'Enter amount',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
              );
              final limitField = RdxTextField(
                controller: usageLimitController,
                maxLength: 5,
                label: 'Usage Limit',
                hint: 'Enter usage limit',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              );

              if (stack) {
                return Column(
                  children: [
                    minField,
                    SizedBox(height: context.h(16)),
                    limitField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: minField),
                  SizedBox(width: context.w(16)),
                  Expanded(child: limitField),
                ],
              );
            }),
            SizedBox(height: context.h(16)),
            LayoutBuilder(builder: (context, c) {
              final stack = c.maxWidth < 420;
              final startCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Date *',
                    style: AppTextStyles.bodySecondary(context)
                        .copyWith(color: colors.textMuted),
                  ),
                  SizedBox(height: context.h(6)),
                  _datePickerField(
                    startDate,
                    (d) => setState(() {
                      startDate = d;
                      if (endDate != null && endDate!.isBefore(d)) {
                        endDate = null;
                      }
                    }),
                  ),
                ],
              );
              final endCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'End Date *',
                    style: AppTextStyles.bodySecondary(context)
                        .copyWith(color: colors.textMuted),
                  ),
                  SizedBox(height: context.h(6)),
                  _datePickerField(
                    endDate,
                    (d) => setState(() => endDate = d),
                    firstDate: startDate ?? DateTime(2024),
                  ),
                ],
              );

              if (stack) {
                return Column(
                  children: [
                    startCol,
                    SizedBox(height: context.h(16)),
                    endCol,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: startCol),
                  SizedBox(width: context.w(16)),
                  Expanded(child: endCol),
                ],
              );
            }),
          ],
        ),
        // SizedBox(height: context.h(20)),
        // _sectionCard(
        //   context,
        //   icon: Icons.visibility_outlined,
        //   title: 'Display & Behavior',
        //   children: [
        //     _switchRow(
        //       context,
        //       label: 'Auto Apply',
        //       value: autoApply,
        //       onChanged: (value) => setState(() => autoApply = value),
        //     ),
        //     SizedBox(height: context.h(12)),
        //     _switchRow(
        //       context,
        //       label: 'Show on Home',
        //       value: showOnHome,
        //       onChanged: (value) => setState(() => showOnHome = value),
        //     ),
        //     SizedBox(height: context.h(16)),
        //     RdxTextField(
        //       controller: homePriorityController,
        //       label: 'Home Priority',
        //       hint: '0 = default / lower priority',
        //       maxLength: 3,
        //       keyboardType: TextInputType.number,
        //       inputFormatters: [
        //         FilteringTextInputFormatter.digitsOnly,
        //       ],
        //     ),
        //   ],
        // ),
      ],
    );
  }

  Widget _switchRow(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(8),
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(context.h(8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body(context)
                  .copyWith(color: colors.textPrimary),
            ),
          ),
          RdxToggleButton(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(BuildContext context) => Row(
        children: [
          Expanded(
            child: RdxActionButton.discard(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            ),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: RdxActionButton.save(
              label: isEdit ? 'Update' : 'Done',
              isLoading: isLoading,
              onPressed: _save,
            ),
          ),
        ],
      );

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(20)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(14)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: context.h(18), color: AppColors.primary),
              SizedBox(width: context.w(8)),
              Text(
                title,
                style: AppTextStyles.section(context),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          ...children,
        ],
      ),
    );
  }

  Widget _discountTypeDropdown(BuildContext context, AppColorScheme colors) {
    return RdxDropdown<DiscountType>(
      label: 'Discount Type *',
      value: discountType,
      items: const [DiscountType.percentage, DiscountType.flat],
      labelBuilder: (v) =>
          v == DiscountType.percentage ? 'Percentage (%)' : 'Flat Amount (₹)',
      onChanged: (v) {
        if (v != null) {
          setState(() {
            discountType = v;
            if (v == DiscountType.percentage) {
              _clampPercentage();
            }
          });
        }
      },
    );
  }

  Widget _datePickerField(
    DateTime? date,
    ValueChanged<DateTime> onPick, {
    DateTime? firstDate,
  }) {
    return Builder(builder: (context) {
      final colors = AppColors.of(context);
      final fieldHeight = RdxTextField.singleLineHeight(context);
      final textFontSize = RdxTextField.textFontSize(context);
      final minimumDate = firstDate ?? DateTime(2024);
      final lastDate = DateTime(2030);
      final today = DateTime.now();
      final initialDate = today.isBefore(minimumDate)
          ? minimumDate
          : today.isAfter(lastDate)
              ? lastDate
              : today;
      return InkWell(
        borderRadius: BorderRadius.circular(context.h(8)),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: minimumDate,
            lastDate: lastDate,
            builder: (context, child) {
              final theme = Theme.of(context);
              return Theme(
                data: theme.copyWith(
                  colorScheme: theme.colorScheme.copyWith(
                    primary: colors.primary,
                    onPrimary: Colors.white,
                    surface: colors.surface,
                    onSurface: colors.textPrimary,
                  ),
                  datePickerTheme: DatePickerThemeData(
                    backgroundColor: colors.surface,
                    surfaceTintColor: Colors.transparent,
                    headerBackgroundColor: colors.primary,
                    headerForegroundColor: Colors.white,
                    todayBackgroundColor: WidgetStatePropertyAll(
                      colors.primary.withValues(alpha: 0.12),
                    ),
                    todayForegroundColor: WidgetStatePropertyAll(
                      colors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.h(16)),
                    ),
                  ),
                  dialogTheme: DialogThemeData(
                    backgroundColor: colors.surface,
                    surfaceTintColor: Colors.transparent,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.h(16)),
                    ),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) onPick(picked);
        },
        child: SizedBox(
          height: fieldHeight,
          child: Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(
              horizontal: RdxTextField.horizontalPad(context),
            ),
            decoration: BoxDecoration(
              color: date != null ? Colors.white : colors.surfaceVariant,
              borderRadius: BorderRadius.circular(context.h(8).clamp(6.0, 8.0)),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: context.h(14),
                  color: colors.textMuted,
                ),
                SizedBox(width: context.w(8)),
                Text(
                  date == null ? 'Select date' : Formatters.date(date),
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    color: date == null ? colors.textMuted : colors.textPrimary,
                    fontSize: textFontSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
