import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/buttons/rdx_action_button.dart';
import '../../../widgets/reusable_widgets/rdx_text_field.dart';

class ItemCustomizeSheet extends ConsumerStatefulWidget {
  final MenuItemModel item;
  const ItemCustomizeSheet({super.key, required this.item});

  @override
  ConsumerState<ItemCustomizeSheet> createState() => _ItemCustomizeSheetState();
}

class _ItemCustomizeSheetState extends ConsumerState<ItemCustomizeSheet> {
  int _quantity = 1;
  String? _spiceLevel;
  final Set<int> _selectedQuickAddOns = {};
  final List<CartAddOn> _customAddOns = [];
  final _notesController = TextEditingController();
  final _customNameController = TextEditingController();
  final _customPriceController = TextEditingController();
  bool _addingCustom = false;

  List<CartAddOn> get _allSelectedAddOns => [
        for (final index in _selectedQuickAddOns) kQuickAddOns[index],
        ..._customAddOns,
      ];

  double get _unitPrice =>
      widget.item.price +
      _allSelectedAddOns.fold(0.0, (sum, a) => sum + a.price);

  @override
  void dispose() {
    _notesController.dispose();
    _customNameController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  void _addCustomAddOn() {
    final name = _customNameController.text.trim();
    if (name.isEmpty) return;
    final price = double.tryParse(_customPriceController.text.trim()) ?? 0;
    setState(() {
      _customAddOns.add(CartAddOn(name: name, price: price));
      _customNameController.clear();
      _customPriceController.clear();
      _addingCustom = false;
    });
  }

  void _submit() {
    ref.read(cartProvider.notifier).addItem(
          menuItem: widget.item,
          quantity: _quantity,
          spiceLevel: _spiceLevel,
          addOns: _allSelectedAddOns,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(context.h(18))),
          ),
          child: Column(
            children: [
              SizedBox(height: context.h(10)),
              Container(
                width: context.w(40),
                height: context.h(4),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(context.h(2)),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    context.w(18),
                    context.h(14),
                    context.w(18),
                    context.h(14),
                  ),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item.name,
                                style: AppTextStyles.section(context)
                                    .copyWith(color: colors.textPrimary),
                              ),
                              SizedBox(height: context.h(3)),
                              Text(
                                '₹${widget.item.price.toStringAsFixed(0)} base price',
                                style: AppTextStyles.bodySecondary(context)
                                    .copyWith(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: colors.textMuted),
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(18)),
                    Text('Quantity',
                        style: AppTextStyles.bodySecondary(context)
                            .copyWith(color: colors.textMuted)),
                    SizedBox(height: context.h(8)),
                    Row(
                      children: [
                        _stepperButton(
                          colors,
                          icon: Icons.remove,
                          onTap: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        SizedBox(width: context.w(16)),
                        Text('$_quantity',
                            style: AppTextStyles.section(context)
                                .copyWith(color: colors.textPrimary)),
                        SizedBox(width: context.w(16)),
                        _stepperButton(
                          colors,
                          icon: Icons.add,
                          onTap: _quantity < 20
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(20)),
                    Text('Spice Level',
                        style: AppTextStyles.bodySecondary(context)
                            .copyWith(color: colors.textMuted)),
                    SizedBox(height: context.h(8)),
                    Wrap(
                      spacing: context.w(8),
                      runSpacing: context.h(8),
                      children: [
                        for (final level in kSpiceLevels)
                          ChoiceChip(
                            label: Text(level),
                            selected: _spiceLevel == level,
                            onSelected: (selected) => setState(
                                () => _spiceLevel = selected ? level : null),
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            labelStyle: AppTextStyles.label(context).copyWith(
                              color: _spiceLevel == level
                                  ? AppColors.primary
                                  : colors.textPrimary,
                            ),
                            side: BorderSide(
                              color: _spiceLevel == level
                                  ? AppColors.primary
                                  : colors.border,
                            ),
                            backgroundColor: colors.surfaceVariant,
                          ),
                      ],
                    ),
                    SizedBox(height: context.h(20)),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Add-ons',
                              style: AppTextStyles.bodySecondary(context)
                                  .copyWith(color: colors.textMuted)),
                        ),
                        InkWell(
                          onTap: () =>
                              setState(() => _addingCustom = !_addingCustom),
                          child: Text(
                            _addingCustom ? 'Cancel' : '+ Custom add-on',
                            style: AppTextStyles.label(context)
                                .copyWith(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(8)),
                    for (var i = 0; i < kQuickAddOns.length; i++)
                      _addOnRow(
                        colors,
                        label: kQuickAddOns[i].displayLabel,
                        selected: _selectedQuickAddOns.contains(i),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selectedQuickAddOns.add(i);
                          } else {
                            _selectedQuickAddOns.remove(i);
                          }
                        }),
                      ),
                    for (final custom in _customAddOns)
                      _addOnRow(
                        colors,
                        label: custom.displayLabel,
                        selected: true,
                        onChanged: (_) =>
                            setState(() => _customAddOns.remove(custom)),
                      ),
                    if (_addingCustom) ...[
                      SizedBox(height: context.h(6)),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: RdxTextField(
                              controller: _customNameController,
                              maxLength: 25,
                              hint: 'Add-on name',
                            ),
                          ),
                          SizedBox(width: context.w(8)),
                          Expanded(
                            flex: 2,
                            child: RdxTextField(
                              controller: _customPriceController,
                              maxLength: 4,
                              hint: '₹0',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                          SizedBox(width: context.w(8)),
                          RdxActionButton(
                            label: 'Add',
                            isPrimary: true,
                            onPressed: _addCustomAddOn,
                            height: context.h(38),
                            minWidth: context.w(60),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: context.h(20)),
                    Text('Special Instructions',
                        style: AppTextStyles.bodySecondary(context)
                            .copyWith(color: colors.textMuted)),
                    SizedBox(height: context.h(8)),
                    RdxTextField(
                      controller: _notesController,
                      maxLength: 200,
                      hint: 'e.g. no onions, extra crispy',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  context.w(18),
                  context.h(12),
                  context.w(18),
                  context.h(16),
                ),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.divider)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '₹${(_unitPrice * _quantity).toStringAsFixed(0)}',
                        style: AppTextStyles.section(context)
                            .copyWith(color: colors.textPrimary),
                      ),
                    ),
                    SizedBox(
                      width: context.w(180),
                      child: RdxActionButton(
                        label: 'Add to Cart',
                        isPrimary: true,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stepperButton(AppColorScheme colors,
      {required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.h(18)),
      child: Container(
        padding: EdgeInsets.all(context.h(8)),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap == null
              ? colors.surfaceVariant
              : AppColors.primary.withValues(alpha: 0.1),
        ),
        child: Icon(icon,
            size: context.h(18),
            color: onTap == null ? colors.textMuted : AppColors.primary),
      ),
    );
  }

  Widget _addOnRow(
    AppColorScheme colors, {
    required String label,
    required bool selected,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(4)),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.body(context)
                      .copyWith(color: colors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
