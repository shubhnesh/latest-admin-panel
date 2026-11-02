import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/order_model.dart';
import '../../providers/live_orders_provider.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';

/// Kanban-style Live Orders board (NEW / PREPARING / READY / DELIVERING).
///
/// Uses Riverpod [liveOrdersProvider] — no package:provider.
class LiveOrdersScreen extends ConsumerStatefulWidget {
  const LiveOrdersScreen({super.key});

  @override
  ConsumerState<LiveOrdersScreen> createState() => _LiveOrdersScreenState();
}

class _LiveOrdersScreenState extends ConsumerState<LiveOrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(liveOrdersProvider).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(liveOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              Responsive.pageHorizontal(context),
              context.h(16),
              Responsive.pageHorizontal(context),
              context.h(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Orders',
                  style: AppTextStyles.heading(context),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  'Track orders and create orders for customers',
                  style: AppTextStyles.bodySecondary(context)
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const LoadingIndicator()
                : _buildBoard(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(LiveOrdersProvider provider) {
    final List<Widget> sections = [
      _buildSection(
        title: 'LIVE ORDERS',
        count: provider.live.length,
        color: const Color(0xFFE51B3E),
        orders: provider.live,
        actionText: 'Start Preparing',
        onAdvance: provider.advanceStatus,
      ),
      _buildSection(
        title: 'PREPARING',
        count: provider.preparing.length,
        color: const Color(0xFFE9A719),
        orders: provider.preparing,
        actionText: 'Mark Ready',
        onAdvance: provider.advanceStatus,
      ),
      _buildSection(
        title: 'READY',
        count: provider.ready.length,
        color: const Color(0xFF20B47A),
        orders: provider.ready,
        actionText: null,
        onAdvance: provider.advanceStatus,
      ),
      _buildSection(
        title: 'DELIVERING',
        count: 0,
        color: const Color(0xFF31568E),
        orders: const <OrderModel>[],
        actionText: null,
        onAdvance: provider.advanceStatus,
        emptyIcon: Icons.delivery_dining_outlined,
        emptyText: 'No active deliveries',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        final sectionGap = context.w(18);

        if (narrow) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              Responsive.pageHorizontal(context),
              context.h(12),
              Responsive.pageHorizontal(context),
              context.h(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < sections.length; i++) ...[
                  if (i > 0) SizedBox(height: context.h(20)),
                  sections[i],
                ],
              ],
            ),
          );
        }

        final horizontalPadding = context.w(44);
        final sectionWidth = ((constraints.maxWidth -
                    horizontalPadding -
                    sectionGap * (sections.length - 1)) /
                sections.length)
            .clamp(0.0, context.w(320));

        return Padding(
          padding: EdgeInsets.fromLTRB(
            context.w(22),
            context.h(18),
            context.w(22),
            context.h(24),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < sections.length; i++) ...[
                Expanded(
                  child: SizedBox(
                    width: sectionWidth,
                    child: sections[i],
                  ),
                ),
                if (i != sections.length - 1) SizedBox(width: sectionGap),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required int count,
    required Color color,
    required List<OrderModel> orders,
    required String? actionText,
    required ValueChanged<OrderModel> onAdvance,
    IconData? emptyIcon,
    String? emptyText,
  }) {
    final bool isEmpty = orders.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: context.w(3),
            right: context.w(3),
            bottom: context.h(12),
          ),
          child: Row(
            children: [
              Container(
                width: context.w(7),
                height: context.h(7),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: context.w(9)),
              Text(
                title,
                style: AppTextStyles.section(context)
                    .copyWith(color: AppColors.lightTextPrimary),
              ),
              const Spacer(),
              Container(
                constraints: BoxConstraints(
                  minWidth: context.w(21),
                  minHeight: context.h(21),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(6),
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(context.h(15)),
                  border: Border.all(
                    color: AppColors.lightBorder,
                    width: context.h(3),
                  ),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.bodySecondary(context),
                ),
              ),
            ],
          ),
        ),
        if (isEmpty)
          Container(
            width: double.infinity,
            height: context.h(170),
            decoration: BoxDecoration(
              color: AppColors.lightSurface,
              borderRadius: BorderRadius.circular(context.h(12)),
            ),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: AppColors.lightBorder,
                radius: 12,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (emptyIcon != null) ...[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1EA),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFD8C5),
                          ),
                        ),
                        child: Icon(
                          emptyIcon,
                          size: context.h(22).clamp(16.0, 26.0),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      emptyText ?? 'No orders',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary(context)
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final order in orders)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildOrderCard(
                    order: order,
                    actionText: actionText,
                    onAdvance: onAdvance,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildOrderCard({
    required OrderModel order,
    required String? actionText,
    required ValueChanged<OrderModel> onAdvance,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF302B2B),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.orderDetail,
            arguments: order,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        order.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context)
                            .copyWith(color: const Color(0xFFE0DCDC)),
                      ),
                    ),
                    Icon(
                      Icons.schedule_outlined,
                      size: context.h(12).clamp(10.0, 14.0),
                      color: Color(0xFF777070),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatOrderTime(order.createdAt),
                      style: AppTextStyles.caption(context)
                          .copyWith(color: const Color(0xFF888080)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  order.items.isEmpty
                      ? 'Order'
                      : order.items
                          .map((item) => '${item.quantity}x ${item.name}')
                          .join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context)
                      .copyWith(color: const Color(0xFFD7D1D1)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Customer: ${order.customerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context)
                      .copyWith(color: const Color(0xFF858080)),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: const Color(0xFF292525),
                ),
                const SizedBox(height: 11),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252020),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color(0xFF302A2A),
                        ),
                      ),
                      child: Text(
                        '${order.items.length} '
                        '${order.items.length == 1 ? 'Item' : 'Items'}',
                        style: AppTextStyles.caption(context)
                            .copyWith(color: const Color(0xFFA69D9D)),
                      ),
                    ),
                    const Spacer(),
                    if (actionText != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () => onAdvance(order),
                          child: Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFF214D9B),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              actionText,
                              style: AppTextStyles.caption(context)
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatOrderTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    final rect = Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1);
    path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    final PathMetrics metrics = path.computeMetrics();
    const double dashLength = 6;
    const double gapLength = 5;

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final double nextDistance =
            (distance + dashLength).clamp(0, metric.length);
        final Path segment =
            metric.extractPath(distance, nextDistance.toDouble());
        canvas.drawPath(segment, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
