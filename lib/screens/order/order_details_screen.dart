import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/providers/live_orders_provider.dart';
import 'package:rdx_admin/screens/order/bill_settlement_screen.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../core/utils/tax.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/dialogs/rdx_notice_dialog.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';

final orderDetailProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  if (orderId.trim().isEmpty) return null;
  return OrderService().fetchOrderById(orderId);
});

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrder = ref.watch(orderDetailProvider(orderId));
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          RdxHeader(
            title: asyncOrder.when(
              data: (order) {
                if (order == null) return 'Order detail';
                return _headerTitle(order);
              },
              loading: () => 'Order detail',
              error: (_, __) => 'Order detail',
            ),
            showBackButton: true,
          ),
          Expanded(
            child: asyncOrder.when(
              loading: () => const LoadingIndicator(),
              error: (error, _) => EmptyState(
                message: 'Failed to load order.\n$error',
              ),
              data: (order) {
                if (order == null) {
                  return const EmptyState(message: 'Order not found.');
                }
                return _OrderDetailBody(order: order);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _shortId(String id) {
    if (id.length <= 4) return id;
    return id.substring(id.length - 4);
  }

  /// Header: prefer table number when present, e.g. "Order • Table 4".
  String _headerTitle(OrderModel order) {
    final table = order.tableNumber?.trim();
    if (table != null && table.isNotEmpty) {
      return 'Table $table';
    }
    return 'Order #${_shortId(order.id)}';
  }
}

// =============================================================================
// BODY — Create-menu style left form + cart-panel style right summary
// =============================================================================

class _OrderDetailBody extends ConsumerWidget {
  final OrderModel order;

  const _OrderDetailBody({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 900;
    final narrowSummaryHeight = (MediaQuery.sizeOf(context).height * 0.8)
        .clamp(context.h(480), 720.0)
        .toDouble();

    double subtotal = 0;
    for (final item in order.items) {
      subtotal += item.price * item.quantity;
    }
    final tax = subtotal * (AppTax.gstPercentage / 100);
    final taxPercent = AppTax.gstPercentage;

    if (narrow) {
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          context.w(20),
          context.h(16),
          context.w(20),
          context.h(28),
        ),
        child: Column(
          children: [
            _LeftFormColumn(order: order),
            SizedBox(height: context.h(16)),
            SizedBox(
              height: narrowSummaryHeight,
              child: _RightOrderSummary(
                order: order,
                subtotal: subtotal,
                tax: tax,
                taxPercent: taxPercent,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
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
              padding: EdgeInsets.only(right: context.w(22)),
              child: _LeftFormColumn(order: order),
            ),
          ),
          VerticalDivider(
            width: context.w(1),
            thickness: 1,
            color: colors.border,
          ),
          SizedBox(
            width: context.w(340),
            child: Padding(
              padding: EdgeInsets.only(left: context.w(22)),
              child: _RightOrderSummary(
                order: order,
                subtotal: subtotal,
                tax: tax,
                taxPercent: taxPercent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// LEFT — Create Menu panel style
// =============================================================================

class _LeftFormColumn extends ConsumerWidget {
  final OrderModel order;

  const _LeftFormColumn({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final customerName = order.customerName.trim().isEmpty
        ? 'Walk-in customer'
        : order.customerName.trim();

    return Column(
      children: [
        // ── Service & Customer ──────────────────────────────────────
        _FormPanel(
          title: 'Service & customer',
          icon: Icons.receipt_long_outlined,
          children: [
            // ORDER ID (left) + SERVICE OPTION (right)
            LayoutBuilder(
              builder: (context, c) {
                final stack = c.maxWidth < 400;
                final orderIdField = _InfoField(
                  label: 'Order ID',
                  value: order.id,
                );
                final serviceField = _InfoField(
                  label: 'Service option',
                  value: _orderTypeLabel(order.orderType),
                );
                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      orderIdField,
                      SizedBox(height: context.h(14)),
                      serviceField,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: orderIdField),
                    SizedBox(width: context.w(14)),
                    Expanded(child: serviceField),
                  ],
                );
              },
            ),
            SizedBox(height: context.h(16)),
            // TABLE + CUSTOMER (name + phone when provided at checkout)
            LayoutBuilder(
              builder: (context, c) {
                final stack = c.maxWidth < 400;
                final isDineIn = order.orderType == OrderType.dineIn;
                final table = _InfoField(
                  label: 'Table',
                  value: (order.tableNumber?.trim().isNotEmpty ?? false)
                      ? 'Table ${order.tableNumber}'
                      : 'No table / counter',
                );
                final customer = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _InfoField(
                        label: 'Customer',
                        value: customerName,
                      ),
                    ),
                    if (order.customerPhone.trim().isNotEmpty) ...[
                      SizedBox(width: context.w(12)),
                      Expanded(
                        child: _InfoField(
                          label: 'Mobile number',
                          value: order.customerPhone.trim(),
                        ),
                      ),
                    ],
                  ],
                );
                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isDineIn) ...[
                        table,
                        SizedBox(height: context.h(14)),
                      ],
                      customer,
                    ],
                  );
                }
                if (!isDineIn) return customer;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: table),
                    SizedBox(width: context.w(14)),
                    Expanded(child: customer),
                  ],
                );
              },
            ),
            if (order.orderType == OrderType.delivery &&
                order.deliveryAddress.trim().isNotEmpty) ...[
              SizedBox(height: context.h(14)),
              _InfoField(
                label: 'Delivery address',
                value: order.deliveryAddress,
              ),
            ],
          ],
        ),

        SizedBox(height: context.h(16)),

        // ── Workflow — step line; advance + terminate when active
        _FormPanel(
          title: 'Workflow',
          icon: Icons.sync_alt_outlined,
          children: [
            _StatusRow(order: order),
            // Only show advance button when there is a next status
            if (order.status.nextStatus != null) ...[
              SizedBox(height: context.h(40)),
              _WorkflowAction(order: order),
            ],
            if (order.status == OrderStatus.cancelled) ...[
              SizedBox(height: context.h(14)),
              _CancelledBanner(),
            ],
          ],
        ),

        if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
          SizedBox(height: context.h(16)),
          _FormPanel(
            title: 'Kitchen notes',
            icon: Icons.notes_outlined,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.h(12)),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(context.h(8)),
                ),
                child: Text(
                  order.notes!,
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],

        SizedBox(height: context.h(16)),

        // ── Payment ─────────────────────────────────────────────────
        _FormPanel(
          title: 'Payment',
          icon: Icons.payments_outlined,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: context.w(12),
                vertical: context.h(12),
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(context.h(8)),
              ),
              child: Row(
                children: [
                  Text(
                    'Total due',
                    style: AppTextStyles.section(context).copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${order.total.toStringAsFixed(2)}',
                    style: AppTextStyles.section(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.h(12)),
            _PaymentStatusCard(order: order),
          ],
        ),
      ],
    );
  }

  String _orderTypeLabel(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Eat in';
      case OrderType.delivery:
        return 'Delivery';
      case OrderType.takeaway:
        return 'To go';
    }
  }
}

// =============================================================================
// RIGHT — Cart panel style
// =============================================================================

class _RightOrderSummary extends ConsumerWidget {
  final OrderModel order;
  final double subtotal;
  final double tax;
  final double taxPercent;

  const _RightOrderSummary({
    required this.order,
    required this.subtotal,
    required this.tax,
    required this.taxPercent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final isPaid = order.paymentStatus == PaymentStatus.paid;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          // Header — no PAID / UNPAID badge
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(12),
              context.h(12),
              context.w(12),
              context.h(10),
            ),
            child: Row(
              children: [
                Text(
                  'Order items',
                  style: AppTextStyles.section(context).copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                if (order.items.isNotEmpty) ...[
                  SizedBox(width: context.w(6)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(7),
                      vertical: context.h(2),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(context.h(20)),
                    ),
                    child: Text(
                      '${order.items.length}',
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(height: 1, color: colors.divider),

          // Items — card style with no image (matches provided design)
          Expanded(
            child: order.items.isEmpty
                ? _emptyItems(context, colors)
                : ListView.separated(
                    primary: false,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(10),
                      vertical: context.h(10),
                    ),
                    itemCount: order.items.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: context.h(10)),
                    itemBuilder: (context, index) {
                      return _CartStyleItemCard(item: order.items[index]);
                    },
                  ),
          ),

          // Totals + Print (primary only — no Paid button)
          Container(
            padding: EdgeInsets.fromLTRB(
              context.w(12),
              context.h(10),
              context.w(12),
              context.h(12),
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _amountRow(context, colors, 'Subtotal', subtotal),
                SizedBox(height: context.h(6)),
                _amountRow(
                  context,
                  colors,
                  'GST (${taxPercent.toStringAsFixed(0)}%)',
                  tax,
                ),
                SizedBox(height: context.h(10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total due',
                      style: AppTextStyles.section(context),
                    ),
                    Text(
                      '₹${order.total.toStringAsFixed(2)}',
                      style: AppTextStyles.section(context).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(14)),
                if (!isPaid)
                  SizedBox(
                    width: double.infinity,
                    child: RdxActionButton(
                      label: 'Pay Now',
                      isPrimary: true,
                      onPressed: () => _openSettlement(context, ref),
                    ),
                  ),
                if (order.status != OrderStatus.cancelled &&
                    order.status != OrderStatus.delivered) ...[
                  SizedBox(height: context.h(10)),
                  _TerminateAction(order: order),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyItems(BuildContext context, AppColorScheme colors) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.h(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: context.h(30),
              color: colors.textMuted,
            ),
            SizedBox(height: context.h(8)),
            Text(
              'No items',
              style: AppTextStyles.label(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountRow(
    BuildContext context,
    AppColorScheme colors,
    String label,
    double amount,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySecondary(context)),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: AppTextStyles.bodySecondary(context),
        ),
      ],
    );
  }

  Future<void> _openSettlement(BuildContext context, WidgetRef ref) async {
    if (order.paymentStatus == PaymentStatus.paid) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BillSettlementScreen(
          bill: BillSettlementData(
            orderNumber: order.id,
            restaurantName: 'RDX Fast Food',
            orderType: _orderTypeLabel(order.orderType),
            tableNumber: order.tableNumber,
            billingMode: _orderTypeLabel(order.orderType),
            cashier: 'Staff',
            server: 'Staff',
            kitchenName: 'Main Kitchen',
            sequence: null,
            covers: 1,
            items: [
              for (final item in order.items)
                BillItemData(
                  name: item.name,
                  quantity: item.quantity,
                  amount: item.price * item.quantity,
                  modifiers: [
                    if (item.spiceLevel != null &&
                        item.spiceLevel!.trim().isNotEmpty)
                      item.spiceLevel!,
                    ...item.addOns,
                  ],
                ),
            ],
            paymentMethod: order.paymentMethod?.label,
            cardLastFour: null,
            subtotal: subtotal,
            taxPercentage: AppTax.gstPercentage,
            guestName: order.customerName.trim().isEmpty
                ? 'Walk-in customer'
                : order.customerName,
            phoneNumber: order.customerPhone,
            deliveryAddress: order.deliveryAddress,
            sendDigitalReceipt: false,
            invoiceReference: order.id,
            receiptDateTime: DateTime.now(),
          ),
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );

    if (!context.mounted) return;
    ref.invalidate(orderDetailProvider(order.id));
    await ref.read(liveOrdersProvider).load();
  }

  String _orderTypeLabel(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Eat in';
      case OrderType.delivery:
        return 'Delivery';
      case OrderType.takeaway:
        return 'To go';
    }
  }
}

// =============================================================================
// CART-STYLE ITEM CARD (no image — matches provided design)
// =============================================================================

class _CartStyleItemCard extends StatelessWidget {
  final OrderItemModel item;

  const _CartStyleItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final amount = item.price * item.quantity;

    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: context.h(10),
            offset: Offset(0, context.h(3)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.section(context).copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: context.w(8)),
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: AppTextStyles.section(context).copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(2)),
          Text(
            '₹${item.price.toStringAsFixed(2)} each',
            style: AppTextStyles.bodySecondary(context).copyWith(
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: context.h(6)),
          Text(
            'Qty: ${item.quantity}',
            style: AppTextStyles.label(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
          if ((item.spiceLevel != null && item.spiceLevel!.trim().isNotEmpty) ||
              item.addOns.isNotEmpty) ...[
            SizedBox(height: context.h(4)),
            Text(
              [
                if (item.spiceLevel != null &&
                    item.spiceLevel!.trim().isNotEmpty)
                  item.spiceLevel!,
                ...item.addOns,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
            SizedBox(height: context.h(2)),
            Text(
              item.notes!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                color: colors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// SHARED LEFT-COLUMN WIDGETS
// =============================================================================

class _FormPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FormPanel({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

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
            ],
          ),
          SizedBox(height: context.h(16)),
          ...children,
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySecondary(context).copyWith(
            color: colors.textMuted,
          ),
        ),
        SizedBox(height: context.h(6)),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final OrderModel order;

  const _StatusRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final steps = [
      OrderStatus.pending,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.delivered,
    ];

    final currentIndex = steps.indexOf(order.status);
    // When cancelled, treat as no progress
    final activeIndex =
        order.status == OrderStatus.cancelled ? -1 : currentIndex;

    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: context.h(28),
                  height: context.h(28),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i <= activeIndex
                        ? AppColors.primary
                        : colors.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          i <= activeIndex ? AppColors.primary : colors.border,
                    ),
                  ),
                  // Always show check for completed + current when delivered;
                  // never show the step number on a finished step.
                  child: i <= activeIndex
                      ? Icon(
                          Icons.check,
                          size: context.h(14),
                          color: Colors.white,
                        )
                      : Text(
                          '${i + 1}',
                          style: AppTextStyles.caption(context).copyWith(
                            color: colors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                SizedBox(height: context.h(6)),
                Text(
                  _statusLabel(steps[i]),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(context).copyWith(
                    color: i <= activeIndex
                        ? colors.textPrimary
                        : colors.textMuted,
                    fontWeight:
                        i == activeIndex ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (i < steps.length - 1)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: context.h(18)),
                child: Container(
                  height: 2,
                  color: i < activeIndex ? AppColors.primary : colors.border,
                ),
              ),
            ),
        ],
      ],
    );
  }

  String _statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 'Live';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class _WorkflowAction extends ConsumerWidget {
  final OrderModel order;

  const _WorkflowAction({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextStatus = order.status.nextStatus;
    if (nextStatus == null) return const SizedBox.shrink();

    final buttonLabel = switch (order.status) {
      OrderStatus.pending => 'Move to preparing',
      OrderStatus.preparing => 'Mark ready',
      OrderStatus.ready =>
        order.needsDelivery ? 'Mark delivered' : 'Mark served',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
    };

    return Align(
      alignment: Alignment.center,
      child: RdxActionButton(
        label: buttonLabel,
        trailingIcon: Icons.arrow_forward_outlined,
        isPrimary: true,
        onPressed: () async {
          try {
            await OrderService().updateOrderStatus(order.id, nextStatus);
            if (!context.mounted) return;
            ref.invalidate(orderDetailProvider(order.id));
            await ref.read(liveOrdersProvider).load();
            if (!context.mounted) return;
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text('Order moved to ${nextStatus.label}.'),
            //   ),
            // );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update status. $e')),
            );
          }
        },
      ),
    );
  }
}

class _TerminateAction extends ConsumerWidget {
  final OrderModel order;

  const _TerminateAction({required this.order});

  Future<void> _confirmAndCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await RdxNoticeDialog.showConfirmation(
      context,
      title: 'Terminate order?',
      message: 'This will cancel the order. It will be kept in history and '
          'shown under the Cancelled tab. This cannot be undone.',
      cancelButtonLabel: 'Keep order',
      confirmButtonLabel: 'Terminate',
      confirmButtonColor: const Color(0xFFE05151),
    );

    if (confirmed != true) return;

    try {
      await OrderService().updateOrderStatus(
        order.id,
        OrderStatus.cancelled,
      );
      if (!context.mounted) return;
      ref.invalidate(orderDetailProvider(order.id));
      await ref.read(liveOrdersProvider).load();
      if (!context.mounted) return;
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to terminate order. $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: RdxActionButton(
        label: 'Terminate',
        isPrimary: false,
        onPressed: () => _confirmAndCancel(context, ref),
      ),
    );
  }
}

class _CancelledBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFE05151).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(
          color: const Color(0xFFE05151).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cancel_outlined,
            size: context.h(18),
            color: const Color(0xFFE05151),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(
              'This order was terminated and is kept in history.',
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusCard extends StatelessWidget {
  final OrderModel order;

  const _PaymentStatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isPaid = order.paymentStatus == PaymentStatus.paid;

    if (isPaid) {
      // Original surface color for the whole container;
      // only the check-mark circle is green.
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.h(12)),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(context.h(8)),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            // Green circle + white tick only
            Container(
              width: context.h(34),
              height: context.h(34),
              decoration: const BoxDecoration(
                color: Color(0xFF20B47A),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: context.h(18),
                color: Colors.white,
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment completed',
                    style: AppTextStyles.body(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: context.h(2)),
                  Text(
                    order.paymentMethod?.label ?? 'Paid',
                    style: AppTextStyles.label(context).copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹${order.total.toStringAsFixed(2)}',
              style: AppTextStyles.section(context).copyWith(
                color: const Color(0xFF20B47A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
