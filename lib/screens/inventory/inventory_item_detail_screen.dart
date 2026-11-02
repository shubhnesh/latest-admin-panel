import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/dialogs/rdx_notice_dialog.dart';
import '../../widgets/reusable_widgets/rdx_delete_dialog.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/reusable_widgets/rdx_text_field.dart';
import '../../widgets/reusable_widgets/stat_card.dart';
import 'add_material_screen.dart';

enum _StockAction { add, use }

class InventoryItemDetailScreen extends ConsumerStatefulWidget {
  final InventoryItemModel item;

  const InventoryItemDetailScreen({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<InventoryItemDetailScreen> createState() =>
      _InventoryItemDetailScreenState();
}

class _InventoryItemDetailScreenState
    extends ConsumerState<InventoryItemDetailScreen> {
  final _addController = TextEditingController();
  final _useController = TextEditingController();
  _StockAction? _saving;

  @override
  void dispose() {
    _addController.dispose();
    _useController.dispose();
    super.dispose();
  }

  InventoryItemModel _currentItem(List<InventoryItemModel> items) {
    for (final item in items) {
      if (item.id == widget.item.id) return item;
    }
    return widget.item;
  }

  Future<void> _saveStockChange(
    InventoryItemModel item,
    _StockAction action,
  ) async {
    final controller =
        action == _StockAction.add ? _addController : _useController;
    final quantity = double.tryParse(controller.text.trim());
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a quantity greater than zero.')),
      );
      return;
    }

    if (action == _StockAction.add) {
      if (quantity > 999) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot add more than 999 units at once.'),
          ),
        );
        return;
      }
      if (item.maxCapacity > 0 && item.quantity + quantity > item.maxCapacity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Available capacity is ${_format(item.maxCapacity - item.quantity)} ${item.unit}.',
            ),
          ),
        );
        return;
      }
    } else if (quantity > item.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot use more than current stock.')),
      );
      return;
    }

    final actionLabel = action == _StockAction.add ? 'add to' : 'use from';
    final confirmed = await RdxNoticeDialog.showConfirmation(
      context,
      title: 'Update inventory?',
      message:
          'Confirm ${_format(quantity)} ${item.unit} to $actionLabel ${item.name}.',
      cancelButtonLabel: 'Cancel',
      confirmButtonLabel: 'Update',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = action);
    try {
      final provider = ref.read(inventoryProvider);
      if (action == _StockAction.add) {
        await provider.addStock(item.id, quantity);
      } else {
        await provider.useStock(item.id, quantity);
      }
      if (!mounted) return;
      controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == _StockAction.add
                ? 'Stock added successfully.'
                : 'Stock usage saved successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save stock change. $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  Future<void> _editItem(InventoryItemModel item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddMaterialScreen(existing: item),
      ),
    );
    if (mounted) await ref.read(inventoryProvider).load();
  }

  Future<void> _deleteItem(InventoryItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Material',
        itemName: item.name,
        deleteButtonLabel: 'Delete Material',
        warningMessage: 'This permanently deletes this inventory material.',
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(inventoryProvider).deleteItem(item.id);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete material. $error')),
      );
    }
  }

  String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final item = _currentItem(ref.watch(inventoryProvider).items);
    final narrow = MediaQuery.sizeOf(context).width < 760;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            RdxHeader(
              title: item.name,
              showBackButton: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: Responsive.pagePadding(context, top: 12, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1) Stats
                    _InventoryItemSummary(item: item),
                    SizedBox(height: context.h(14)),

                    // 2) Add / Use stock
                    if (narrow) ...[
                      _StockChangeCard(
                        title: 'Add Stock',
                        icon: Icons.add_circle_outline,
                        color: AppColors.success,
                        subtitle: 'Restock ${item.name}.',
                        unit: item.unit,
                        controller: _addController,
                        saving: _saving == _StockAction.add,
                        disabled: _saving != null,
                        onSave: () =>
                            _saveStockChange(item, _StockAction.add),
                      ),
                      SizedBox(height: context.h(14)),
                      _StockChangeCard(
                        title: 'Use Stock',
                        icon: Icons.remove_circle_outline,
                        color: AppColors.danger,
                        subtitle: 'Record material used.',
                        unit: item.unit,
                        controller: _useController,
                        saving: _saving == _StockAction.use,
                        disabled: _saving != null,
                        onSave: () =>
                            _saveStockChange(item, _StockAction.use),
                      ),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _StockChangeCard(
                              title: 'Add Stock',
                              icon: Icons.add_circle_outline,
                              color: AppColors.success,
                              subtitle: 'Restock ${item.name}.',
                              unit: item.unit,
                              controller: _addController,
                              saving: _saving == _StockAction.add,
                              disabled: _saving != null,
                              onSave: () =>
                                  _saveStockChange(item, _StockAction.add),
                            ),
                          ),
                          SizedBox(width: context.w(14)),
                          Expanded(
                            child: _StockChangeCard(
                              title: 'Use Stock',
                              icon: Icons.remove_circle_outline,
                              color: AppColors.danger,
                              subtitle: 'Record material used.',
                              unit: item.unit,
                              controller: _useController,
                              saving: _saving == _StockAction.use,
                              disabled: _saving != null,
                              onSave: () =>
                                  _saveStockChange(item, _StockAction.use),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: context.h(14)),

                    // 3) Actions LAST — Edit primary, Delete discard, no icons
                    _ActionsSection(
                      enabled: _saving == null,
                      onEdit: () => _editItem(item),
                      onDelete: () => _deleteItem(item),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Shared section shell — same approach as Settings _SettingsCard
// (header + edge-to-edge divider + padded body)
// =============================================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? iconColor;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(16),
              context.h(14),
              context.w(16),
              context.h(14),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: context.h(18),
                  color: iconColor ?? AppColors.primary,
                ),
                SizedBox(width: context.w(8)),
                Text(
                  title,
                  style: AppTextStyles.section(context).copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Full-bleed underline (touches card edges)
          Divider(height: 1, thickness: 1, color: colors.divider),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(16),
              context.h(14),
              context.w(16),
              context.h(16),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Stats — single row (same as Inventory overview)
// =============================================================================

class _InventoryItemSummary extends StatelessWidget {
  final InventoryItemModel item;

  const _InventoryItemSummary({required this.item});

  static String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final spacing = isNarrow ? context.w(6) : context.w(12);
          final minH = isNarrow ? 62.0 : 72.0;

          final cards = <Widget>[
            StatCard(
              label: 'Current Stock (${item.unit})',
              value: _format(item.quantity),
              icon: Icons.inventory_2_outlined,
              accentColor: AppColors.primary,
              minHeight: minH,
            ),
            StatCard(
              label: 'Added (${item.unit})',
              value: _format(item.totalAdded),
              icon: Icons.add_circle_outline,
              accentColor: AppColors.success,
              minHeight: minH,
            ),
            StatCard(
              label: 'Used (${item.unit})',
              value: _format(item.totalUsed),
              icon: Icons.remove_circle_outline,
              accentColor: AppColors.danger,
              minHeight: minH,
            ),
            StatCard(
              label: 'Total Cost (₹)',
              value: Formatters.currency(item.totalCost),
              icon: Icons.payments_outlined,
              accentColor: AppColors.primary,
              minHeight: minH,
            ),
            StatCard(
              label: 'Unit Cost (₹/${item.unit})',
              value: Formatters.currency(item.unitCost),
              icon: Icons.sell_outlined,
              accentColor: AppColors.warning,
              minHeight: minH,
            ),
          ];

          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) SizedBox(width: spacing),
              ],
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// Actions — LAST section; Edit = primary, Delete = discard; no icons
// =============================================================================

class _ActionsSection extends StatelessWidget {
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActionsSection({
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return _SectionCard(
      title: 'Actions',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit material details or remove this item from inventory.',
            style: AppTextStyles.bodySecondary(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: context.h(14)),
          Wrap(
            spacing: context.w(10),
            runSpacing: context.h(10),
            children: [
              RdxActionButton(
                label: 'Edit',
                isPrimary: true,
                onPressed: enabled ? onEdit : null,
              ),
              RdxActionButton.discard(
                label: 'Delete',
                onPressed: enabled ? onDelete : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Add / Use stock — Settings-style section card
// =============================================================================

class _StockChangeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String unit;
  final TextEditingController controller;
  final bool saving;
  final bool disabled;
  final VoidCallback onSave;

  const _StockChangeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.unit,
    required this.controller,
    required this.saving,
    required this.disabled,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      icon: icon,
      iconColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: AppTextStyles.bodySecondary(context)),
          SizedBox(height: context.h(14)),
          RdxTextField(
            controller: controller,
            enabled: !disabled,
            label: 'Quantity ($unit)',
            hint: 'Enter quantity',
            maxLength: 12,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
          ),
          SizedBox(height: context.h(12)),
          Align(
            alignment: Alignment.centerRight,
            child: RdxActionButton(
              label: saving ? 'Updating...' : 'Update',
              isPrimary: true,
              isLoading: saving,
              onPressed: disabled ? null : onSave,
            ),
          ),
        ],
      ),
    );
  }
}