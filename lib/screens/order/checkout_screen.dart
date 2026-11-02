import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/screens/order/bill_settlement_screen.dart';
import 'package:rdx_admin/widgets/dialogs/rdx_notice_dialog.dart';
import 'package:rdx_admin/services/table_config_service.dart';
import 'package:rdx_admin/widgets/dialogs/category_dialog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../core/utils/tax.dart';
import '../../models/order_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_providers.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/buttons/rdx_toggle_button.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/reusable_widgets/rdx_dropdown.dart';
import '../../widgets/reusable_widgets/rdx_text_field.dart';
import 'widgets/order_summary_widgets.dart';

/// Sentinel value as the first entry in the table dropdown.
/// Selecting it opens the set/edit total-tables dialog (same pattern as
/// create-category on the menu screen).
const String _kSetTableCountValue = '__set_table_count__';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final _deliveryAddress = TextEditingController();
  final _orderNotes = TextEditingController();

  OrderType _orderType = OrderType.dineIn;
  bool _longDistanceFeeSelected = false;

  final _tableConfigService = TableConfigService();

  /// Total tables configured for the restaurant (`null` = not set yet).
  int? _totalTables;

  /// Selected table number as a string (e.g. `"4"`), or `null`.
  String? _selectedTable;

  @override
  void initState() {
    super.initState();
    _loadTableCount();
  }

  Future<void> _loadTableCount() async {
    try {
      final count = await _tableConfigService.fetchTableCount();
      if (!mounted) return;
      setState(() {
        _totalTables = count;
        if (_selectedTable != null && count != null) {
          final n = int.tryParse(_selectedTable!);
          if (n == null || n < 1 || n > count) {
            _selectedTable = null;
          }
        }
      });
    } catch (_) {
      // Leave null; user can still set count from the dropdown.
    }
  }

  /// Opens the set/edit total-tables dialog ([CategoryEntryDialog]) and
  /// persists via [TableConfigService] independently of form submission.
  Future<void> _openTableCountDialog() async {
    final result = await CategoryEntryDialog.show<int>(
      context,
      title: 'Set Total Tables',
      editTitle: 'Edit Total Tables',
      nameLabel: 'Total tables *',
      nameHint: 'Enter count',
      initialName: _totalTables?.toString(),
      saveButtonLabel: 'Done',
      onSave: (name, _) async {
        final n = int.tryParse(name.trim());
        if (n == null ||
            n < TableConfigService.minTables ||
            n > TableConfigService.maxTables) {
          throw FormatException(
            'Enter a number between ${TableConfigService.minTables} '
            'and ${TableConfigService.maxTables}.',
          );
        }
        // Persist independently of the checkout form.
        await _tableConfigService.saveTableCount(n);
        return n;
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      _totalTables = result;
      if (_selectedTable != null) {
        final n = int.tryParse(_selectedTable!);
        if (n == null || n < 1 || n > result) {
          _selectedTable = null;
        }
      }
    });
  }

  @override
  void dispose() {
    _customerName.dispose();
    _customerPhone.dispose();
    _deliveryAddress.dispose();
    _orderNotes.dispose();
    super.dispose();
  }

  // ===========================================================================
  // PLACE ORDER
  // ===========================================================================

  Future<void> _placeOrder() async {
    // Same pattern as CreateCouponScreen: one notice dialog per missing
    // mandatory field (no inline Form validators for these checks).
    final cart = ref.read(cartProvider);

    if (cart.isEmpty) {
      await _showNotice('Your order is empty. Please add items first.');
      return;
    }

    if (_orderType == OrderType.dineIn &&
        (_selectedTable == null || _selectedTable!.isEmpty)) {
      await _showNotice('Please select a table number.');
      return;
    }

    if (_orderType == OrderType.delivery &&
        _deliveryAddress.text.trim().isEmpty) {
      await _showNotice('Please enter a delivery address.');
      return;
    }

    final subtotal = ref.read(cartTotalProvider);
    final tax = subtotal * (AppTax.gstPercentage / 100);
    final settings = ref.read(settingsProvider);
    // Late-night fee: auto-applied on Delivery when the setting is enabled.
    final lateNightFee =
        _orderType == OrderType.delivery && settings.lateNightDelivery
            ? 5.0
            : 0.0;
    final longDistanceFee =
        _orderType == OrderType.delivery && _longDistanceFeeSelected
            ? 29.0
            : 0.0;
    final total = subtotal + tax + lateNightFee + longDistanceFee;

    final order = OrderModel(
      id: '',
      customerName: _customerName.text.trim(),
      customerPhone: _customerPhone.text.trim(),
      deliveryAddress:
          _orderType == OrderType.delivery ? _deliveryAddress.text.trim() : '',
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.unpaid,
      paymentMethod: null,
      total: total,
      createdAt: DateTime.now(),
      items: [
        for (final line in cart)
          OrderItemModel(
            name: line.menuItem.name,
            quantity: line.quantity,
            price: line.unitPrice,
            spiceLevel: line.spiceLevel,
            addOns: line.addOns.map((addOn) => addOn.displayLabel).toList(),
            notes: line.notes,
          ),
      ],
      notes: _orderNotes.text.trim().isEmpty ? null : _orderNotes.text.trim(),
      orderType: _orderType,
      tableNumber: _orderType == OrderType.dineIn ? _selectedTable : null,
      // Admin / POS checkout always creates a staff (restaurant) order.
      orderSource: OrderSource.staff,
    );

    try {
      final newOrderId =
          await ref.read(placeOrderControllerProvider.notifier).submit(order);

      if (!mounted) return;

      if (newOrderId == null || newOrderId.isEmpty) {
        await _showNotice('Failed to place order. Please try again.');
        return;
      }

      final billItems = <BillItemData>[
        for (final line in cart)
          BillItemData(
            name: line.menuItem.name,
            quantity: line.quantity,
            amount: line.subtotal,
            modifiers: [
              if (line.spiceLevel != null && line.spiceLevel!.trim().isNotEmpty)
                'Spice: ${line.spiceLevel}',
              ...line.addOns.map((addOn) => addOn.displayLabel),
              if (line.notes != null && line.notes!.trim().isNotEmpty)
                'Note: ${line.notes}',
            ],
          ),
      ];

      final guestName = _customerName.text.trim().isEmpty
          ? 'Walk-in Customer'
          : _customerName.text.trim();

      final phoneNumber = _customerPhone.text.trim();
      final tableNumber =
          _orderType == OrderType.dineIn ? _selectedTable : null;

      ref.read(cartProvider.notifier).clear();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BillSettlementScreen(
            bill: BillSettlementData(
              orderNumber: newOrderId,
              restaurantName: 'RDX Fast Food',
              orderType: _orderType.label,
              tableNumber: tableNumber,
              billingMode: _orderType.label,
              cashier: 'Staff',
              server: 'Staff',
              kitchenName: 'Main Kitchen',
              sequence: null,
              covers: 1,
              items: billItems,
              paymentMethod: null,
              cardLastFour: null,
              subtotal: subtotal,
              taxPercentage: AppTax.gstPercentage,
              lateNightFee: lateNightFee,
              longDistanceFee: longDistanceFee,
              guestName: guestName,
              phoneNumber: phoneNumber,
              deliveryAddress: _orderType == OrderType.delivery
                  ? _deliveryAddress.text.trim()
                  : '',
              sendDigitalReceipt: false,
              invoiceReference: newOrderId,
              receiptDateTime: DateTime.now(),
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      await _showNotice('Failed to place order. Please try again.');
    }
  }

  /// Same notice-dialog pattern as [CreateCouponScreen].
  Future<void> _showNotice(String message) async {
    if (!mounted) return;
    await RdxNoticeDialog.show(context, message: message);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalProvider);
    final totalItems =
        cart.fold<int>(0, (count, line) => count + line.quantity);
    final tax = subtotal * (AppTax.gstPercentage / 100);
    final settings = ref.watch(settingsProvider);
    // Late-night fee: auto-applied on Delivery when the setting is enabled.
    final lateNightFee =
        _orderType == OrderType.delivery && settings.lateNightDelivery
            ? 5.0
            : 0.0;
    final longDistanceFee =
        _orderType == OrderType.delivery && _longDistanceFeeSelected
            ? 29.0
            : 0.0;
    final total = subtotal + tax + lateNightFee + longDistanceFee;
    final placing = ref.watch(placeOrderControllerProvider).isLoading;
    final isNarrow = MediaQuery.sizeOf(context).width < 900;

    final emptyOrderMessage = Text(
      'No items in the order.',
      style: AppTextStyles.body(context).copyWith(
        color: colors.textSecondary,
      ),
    );
    final orderItems = LayoutBuilder(
      builder: (context, constraints) {
        final spacing = context.w(10);
        final maxCardWidth = context.w(280);
        final columns =
            (constraints.maxWidth / (maxCardWidth + spacing)).floor().clamp(
                  1,
                  3,
                );
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final cards = Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final line in cart)
              SizedBox(
                width: cardWidth,
                child: OrderSummaryItemCard(line: line),
              ),
          ],
        );
        final scrollView = SingleChildScrollView(child: cards);

        if (!isNarrow) return scrollView;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: context.h(360)),
          child: scrollView,
        );
      },
    );

    final orderSummary = OrderSummaryPanel(
      title: 'Order Summary',
      icon: Icons.receipt_long_outlined,
      itemCount: cart.length,
      expandedContent: isNarrow
          ? null
          : cart.isEmpty
              ? emptyOrderMessage
              : orderItems,
      children: [
        if (isNarrow) cart.isEmpty ? emptyOrderMessage : orderItems,
        Divider(
          color: colors.divider,
          height: context.h(20),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Total items',
                style: AppTextStyles.bodySecondary(context)
                    .copyWith(color: colors.textSecondary),
              ),
            ),
            Text(
              '$totalItems',
              style: AppTextStyles.bodySecondary(context)
                  .copyWith(color: colors.textPrimary),
            ),
          ],
        ),
        SizedBox(height: context.h(6)),
        _summaryAmountRow(context, colors, 'Subtotal', subtotal),
        SizedBox(height: context.h(6)),
        _summaryAmountRow(
          context,
          colors,
          'GST (${AppTax.gstPercentage.toStringAsFixed(0)}%)',
          tax,
        ),
        if (lateNightFee > 0) ...[
          SizedBox(height: context.h(6)),
          _summaryAmountRow(
            context,
            colors,
            'Late Night Delivery',
            lateNightFee,
          ),
        ],
        if (longDistanceFee > 0) ...[
          SizedBox(height: context.h(6)),
          _summaryAmountRow(
            context,
            colors,
            'Long Distance Fee',
            longDistanceFee,
          ),
        ],
        SizedBox(height: context.h(10)),
        Row(
          children: [
            Text(
              'Total',
              style: AppTextStyles.section(context).copyWith(
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '₹${total.toStringAsFixed(2)}',
              style: AppTextStyles.section(context).copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );

    final detailPanels = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panel(
          context,
          colors,
          title: 'Customer Details',
          icon: Icons.person_outline_rounded,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 400;
                final nameField = RdxTextField(
                  controller: _customerName,
                  maxLength: 20,
                  label: 'Customer Name',
                  hint: 'Enter customer name',
                );
                final phoneField = RdxTextField(
                  controller: _customerPhone,
                  maxLength: 10,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                );
                if (stack) {
                  return Column(
                    children: [
                      nameField,
                      SizedBox(height: context.h(14)),
                      phoneField,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: nameField),
                    SizedBox(width: context.w(14)),
                    Expanded(child: phoneField),
                  ],
                );
              },
            ),
          ],
        ),
        SizedBox(height: context.h(16)),
        _panel(
          context,
          colors,
          title: 'Order Type',
          icon: Icons.room_service_outlined,
          children: [
            RdxDropdown<OrderType>(
              label: 'Order Type *',
              value: _orderType,
              items: OrderType.values,
              labelBuilder: (type) => type.label,
              hint: 'Select order type',
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _orderType = value;
                  if (value != OrderType.dineIn) {
                    _selectedTable = null;
                  }
                  if (value != OrderType.delivery) {
                    _deliveryAddress.clear();
                    _longDistanceFeeSelected = false;
                  }
                });
              },
            ),
            if (_orderType == OrderType.dineIn) ...[
              SizedBox(height: context.h(14)),
              RdxDropdown<String>(
                label: 'Table Number *',
                value: _selectedTable,
                searchable: true,
                items: [
                  _kSetTableCountValue,
                  if (_totalTables != null)
                    for (var i = 1; i <= _totalTables!; i++) '$i',
                ],
                labelBuilder: (value) {
                  if (value == _kSetTableCountValue) {
                    return _totalTables == null
                        ? '+ Set table count'
                        : '+ Edit table count ($_totalTables)';
                  }
                  return 'Table $value';
                },
                hint: _totalTables == null
                    ? 'Set table count first'
                    : 'Select or search table',
                onChanged: (value) {
                  if (value == null) return;
                  if (value == _kSetTableCountValue) {
                    _openTableCountDialog();
                    return;
                  }
                  setState(() => _selectedTable = value);
                },
              ),
            ],
            if (_orderType == OrderType.delivery) ...[
              SizedBox(height: context.h(14)),
              RdxTextField(
                controller: _deliveryAddress,
                maxLength: 200,
                label: 'Delivery Address *',
                hint: 'Enter delivery address',
                maxLines: 3,
              ),
              SizedBox(height: context.h(12)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Long Distance Fee (₹29)',
                    style: AppTextStyles.bodySecondary(context)
                        .copyWith(color: colors.textMuted),
                  ),
                  SizedBox(width: context.w(8)),
                  RdxToggleButton(
                    value: _longDistanceFeeSelected,
                    onChanged: (value) =>
                        setState(() => _longDistanceFeeSelected = value),
                  ),
                ],
              ),
            ],
          ],
        ),
        SizedBox(height: context.h(16)),
        _panel(
          context,
          colors,
          title: 'Order Notes',
          icon: Icons.sticky_note_2_outlined,
          children: [
            RdxTextField(
              controller: _orderNotes,
              maxLength: 40,
              label: 'Kitchen Notes',
              hint: 'Write any special instructions for your order',
              maxLines: 3,
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const RdxHeader(
            title: 'Checkout',
            showBackButton: true,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: isNarrow
                  ? SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        context.w(20),
                        context.h(16),
                        context.w(20),
                        context.h(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          orderSummary,
                          SizedBox(height: context.h(16)),
                          detailPanels,
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
                              padding: EdgeInsets.only(right: context.w(20)),
                              child: detailPanels,
                            ),
                          ),
                          VerticalDivider(
                            width: context.w(1),
                            thickness: context.h(1),
                            color: colors.border,
                          ),
                          SizedBox(width: context.w(20)),
                          SizedBox(
                            width: context.w(360).clamp(320.0, 400.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: orderSummary),
                                SizedBox(height: context.h(16)),
                                _actionButtons(
                                    context, cart.isNotEmpty, placing),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (isNarrow)
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(20),
                  context.h(10),
                  context.w(20),
                  context.h(14),
                ),
                child: _actionButtons(context, cart.isNotEmpty, placing),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButtons(BuildContext context, bool hasItems, bool placing) {
    return Row(
      children: [
        Expanded(
          child: RdxActionButton.discard(
            enabled: !placing,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: RdxActionButton.save(
            isLoading: placing,
            enabled: hasItems,
            onPressed: _placeOrder,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SUMMARY AMOUNTS
  // ===========================================================================

  Widget _summaryAmountRow(
    BuildContext context,
    AppColorScheme colors,
    String label,
    double amount,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySecondary(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: AppTextStyles.bodySecondary(context).copyWith(
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // PANEL
  // ===========================================================================

  Widget _panel(
    BuildContext context,
    AppColorScheme colors, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? headerTrailing,
    Widget? expandedContent,
  }) {
    return Container(
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
                  style: AppTextStyles.section(context).copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (headerTrailing != null) headerTrailing,
            ],
          ),
          SizedBox(height: context.h(16)),
          if (expandedContent != null) Expanded(child: expandedContent),
          ...children,
        ],
      ),
    );
  }
}
