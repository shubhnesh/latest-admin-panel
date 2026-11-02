import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../providers/cart_provider.dart';

class OrderSummaryPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final int itemCount;
  final Widget? expandedContent;
  final List<Widget> children;
  final bool compactLayout;

  const OrderSummaryPanel({
    super.key,
    this.title = 'Order Summary',
    this.icon = Icons.receipt_long_outlined,
    required this.itemCount,
    required this.expandedContent,
    this.children = const [],
    this.compactLayout = false,
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
                  '$itemCount',
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          if (expandedContent != null) Expanded(child: expandedContent!),
          ...children,
        ],
      ),
    );
  }
}

class OrderSummaryItemCard extends StatelessWidget {
  final CartLineItem line;
  final bool compactLayout;
  final Widget Function(BuildContext context, int quantity)?
      quantityControlBuilder;

  const OrderSummaryItemCard({
    super.key,
    required this.line,
    this.compactLayout = false,
    this.quantityControlBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final imageUrl = line.menuItem.imageUrl.trim();
    final imageSize = compactLayout ? 40.0 : context.w(64);
    final details = [
      if (line.spiceLevel != null && line.spiceLevel!.trim().isNotEmpty)
        line.spiceLevel!.trim(),
      ...line.addOns.map((addOn) => addOn.displayLabel),
      if (line.notes != null && line.notes!.trim().isNotEmpty)
        line.notes!.trim(),
    ];

    return Container(
      padding: EdgeInsets.all(context.w(compactLayout ? 5 : 10)),
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
      child: compactLayout
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(context.h(6)),
                  child: SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: imageUrl.isEmpty
                        ? _thumbnailPlaceholder(context, colors)
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _thumbnailPlaceholder(context, colors),
                          ),
                  ),
                ),
                SizedBox(width: context.w(compactLayout ? 10 : 4)),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.menuItem.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          fontSize: 13,
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (details.isNotEmpty)
                        Text(
                          details.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      SizedBox(height: context.h(5)),
                      if (quantityControlBuilder != null)
                        quantityControlBuilder!(context, line.quantity)
                      else
                        Text(
                          'Qty: ${line.quantity}',
                          style: AppTextStyles.caption(context).copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(context.h(8)),
                  child: SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: imageUrl.isEmpty
                        ? _thumbnailPlaceholder(context, colors)
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _thumbnailPlaceholder(context, colors),
                          ),
                  ),
                ),
                SizedBox(width: context.w(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              line.menuItem.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.section(context).copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: context.w(8)),
                          Text(
                            '₹${line.subtotal.toStringAsFixed(2)}',
                            style: AppTextStyles.section(context).copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.h(2)),
                      Text(
                        '₹${line.unitPrice.toStringAsFixed(2)} each',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyTertiary(context).copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: context.h(6)),
                      quantityControlBuilder?.call(context, line.quantity) ??
                          Text(
                            'Qty: ${line.quantity}',
                            style: AppTextStyles.caption(context).copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                      if (line.spiceLevel != null &&
                          line.spiceLevel!.trim().isNotEmpty) ...[
                        SizedBox(height: context.h(4)),
                        Text(
                          line.spiceLevel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                      if (line.addOns.isNotEmpty) ...[
                        SizedBox(height: context.h(2)),
                        Text(
                          line.addOns
                              .map((addOn) => addOn.displayLabel)
                              .join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                      if (line.notes != null &&
                          line.notes!.trim().isNotEmpty) ...[
                        SizedBox(height: context.h(2)),
                        Text(
                          line.notes!,
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
                ),
              ],
            ),
    );
  }

  Widget _thumbnailPlaceholder(
    BuildContext context,
    AppColorScheme colors,
  ) {
    return Container(
      color: colors.surfaceVariant,
      child: Icon(
        Icons.restaurant_outlined,
        color: colors.textMuted,
        size: context.h(22),
      ),
    );
  }
}
