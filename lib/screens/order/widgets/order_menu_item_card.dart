import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/cart_provider.dart';

// =============================================================================
// ORDER MENU ITEM CARD
// =============================================================================
//
// Same rich visual language as the Menu screen's MenuItemCard (image,
// featured/dietary badges, category, tags) but built for the Create New
// Order flow: no availability toggle or overflow menu — the bottom action
// is always "+ Add", and a cart-quantity badge overlays the card once the
// item has been added.
// =============================================================================

class OrderMenuItemCard extends ConsumerWidget {
  final MenuItemModel item;

  const OrderMenuItemCard({
    super.key,
    required this.item,
  });

  void _addItem(WidgetRef ref) {
    ref.read(cartProvider.notifier).addItem(
          menuItem: item,
          quantity: 1,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final preparation = item.preparation;
    final isNarrow = context.isNarrow;
    final unavailable = !item.available;

    final quantityInCart = ref.watch(
      cartProvider.select(
        (cart) => ref.read(cartProvider.notifier).quantityForMenuItem(item.id),
      ),
    );

    final outerRadius = context.h(isNarrow ? 12 : 10);
    final imagePadding = context.w(isNarrow ? 8 : 6);
    final imageRadius = context.h(isNarrow ? 10 : 8);
    final contentHPad = context.w(isNarrow ? 12 : 10);
    final contentTopPad = context.h(isNarrow ? 6 : 4);
    final bottomPad = EdgeInsets.fromLTRB(
      contentHPad,
      context.h(6),
      contentHPad,
      context.h(8),
    );

    return Opacity(
      opacity: unavailable ? 0.55 : 1,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(outerRadius),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: context.h(10),
                  offset: Offset(0, context.h(3)),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image ───────────────────────────────────────────
                AspectRatio(
                  aspectRatio: isNarrow ? 1.7 : 1.55,
                  child: Padding(
                    padding: EdgeInsets.all(imagePadding),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(imageRadius),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: item.imageUrl.trim().isEmpty
                                ? Container(
                                    color: colors.surfaceVariant,
                                    child: Icon(
                                      Icons.restaurant_outlined,
                                      color: colors.textMuted,
                                      size: context.h(isNarrow ? 36 : 32),
                                    ),
                                  )
                                : Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: colors.surfaceVariant,
                                      child: Icon(
                                        Icons.restaurant_outlined,
                                        color: colors.textMuted,
                                        size: context.h(isNarrow ? 36 : 32),
                                      ),
                                    ),
                                  ),
                          ),
                          if (item.featuredItem)
                            Positioned(
                              left: context.w(8),
                              top: context.h(8),
                              child: _cardBadge(
                                context,
                                'Featured',
                                AppColors.primary,
                                Colors.white,
                              ),
                            ),
                          Positioned(
                            right: context.w(8),
                            bottom: context.h(8),
                            child: _dietaryBadge(context, item),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Content ─────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      contentHPad,
                      contentTopPad,
                      contentHPad,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.category,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyTertiary(context)
                                    .copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            SizedBox(width: context.w(8)),
                            Text(
                              '₹${item.price.toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.section(context).copyWith(
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.h(2)),
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.section(context).copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        if (item.ingredients.isNotEmpty) ...[
                          SizedBox(height: context.h(2)),
                          Text(
                            item.ingredients.join(', '),
                            style: AppTextStyles.bodyTertiary(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        SizedBox(height: context.h(6)),
                        ClipRect(
                          child: Wrap(
                            spacing: context.w(4),
                            runSpacing: context.h(4),
                            children: [
                              if (preparation.isNotEmpty)
                                _detailChip(
                                  context,
                                  _titleCase(preparation),
                                  colors.textSecondary,
                                ),
                              for (final tag in item.tags
                                  .where(
                                      (tag) => tag.toLowerCase() != 'featured')
                                  .take(item.featuredItem ? 2 : 3))
                                _detailChip(
                                  context,
                                  _titleCase(tag),
                                  colors.textSecondary,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Fixed bottom — Add button ────────────────────────
                Padding(
                  padding: bottomPad,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Divider(height: 1, color: colors.divider),
                      SizedBox(height: context.h(6)),
                      SizedBox(
                        width: double.infinity,
                        height: context.h(30),
                        child: RdxActionButton(
                          label: '+ Add',
                          isPrimary: true,
                          onPressed: unavailable ? null : () => _addItem(ref),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Cart quantity badge ───────────────────────────────────
          if (quantityInCart > 0)
            Positioned(
              top: context.h(8),
              right: context.w(8),
              child: Container(
                constraints: BoxConstraints(
                  minWidth: context.h(22),
                  minHeight: context.h(22),
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(5),
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(context.h(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: context.h(4),
                    ),
                  ],
                ),
                child: Text(
                  '$quantityInCart',
                  style: AppTextStyles.caption(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          // ── Unavailable overlay ────────────────────────────────────
          if (unavailable)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(10),
                    vertical: context.h(5),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(context.h(6)),
                  ),
                  child: Text(
                    'Unavailable',
                    style: AppTextStyles.label(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  Widget _cardBadge(
    BuildContext context,
    String label,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(5),
        vertical: context.h(2),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(context.h(5)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          color: foreground,
        ),
      ),
    );
  }

  Widget _detailChip(BuildContext context, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(6),
        vertical: context.h(3),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.h(4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          color: color,
        ),
      ),
    );
  }

  Widget _dietaryBadge(BuildContext context, MenuItemModel item) {
    final color = item.isVeg ? AppColors.success : AppColors.danger;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(5),
        vertical: context.h(2),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(context.h(5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: context.h(8), color: color),
          SizedBox(width: context.w(5)),
          Text(
            _dietaryLabel(item.dietaryType),
            style: AppTextStyles.caption(context).copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _dietaryLabel(DietaryType type) {
    return type == DietaryType.veg
        ? 'Veg'
        : type == DietaryType.egg
            ? 'Contains Egg'
            : 'Non-Veg';
  }

  String _titleCase(String value) {
    return value
        .split(' ')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
