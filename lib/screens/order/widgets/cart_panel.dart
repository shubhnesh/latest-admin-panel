import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/screens/order/checkout_screen.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../providers/cart_provider.dart';
import 'order_summary_widgets.dart';

/// Right-side panel for Create Order — same sectional layout as
/// CheckoutScreen's Order Summary, but each item shows a quantity
/// counter + delete button instead of static "Qty: N".
class CartPanel extends ConsumerWidget {
  final VoidCallback? onClose;
  final VoidCallback? onProceed;
  final bool compactLayout;

  const CartPanel({
    super.key,
    this.onClose,
    this.onProceed,
    this.compactLayout = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final cart = ref.watch(cartProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: OrderSummaryPanel(
            title: 'Added Items',
            icon: Icons.receipt_long_outlined,
            itemCount: cart.length,
            compactLayout: compactLayout,
            expandedContent: cart.isEmpty
                ? _emptyCart(context, colors)
                : compactLayout
                    ? _CompactCartItems(items: cart)
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: cart.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: context.h(10)),
                        itemBuilder: (context, index) =>
                            _CartItem(line: cart[index]),
                      ),
          ),
        ),
        SizedBox(height: context.h(compactLayout ? 8 : 16)),
        // Keep the actions outside the summary container, like Checkout.
        Row(
          children: [
            Expanded(
              child: RdxActionButton.discard(
                label: 'Discard',
                height: compactLayout ? 32 : null,
                onPressed: cart.isEmpty
                    ? null
                    : () => ref.read(cartProvider.notifier).clear(),
              ),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: RdxActionButton(
                label: 'Next',
                height: compactLayout ? 32 : null,
                isPrimary: cart.isNotEmpty,
                onPressed: cart.isEmpty
                    ? null
                    : onProceed ??
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CheckoutScreen(),
                            ),
                          );
                        },
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _emptyCart(
    BuildContext context,
    AppColorScheme colors,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.h(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: context.h(30),
              color: colors.textMuted,
            ),
            SizedBox(height: context.h(8)),
            Text(
              'No items added',
              style: AppTextStyles.label(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: context.h(3)),
            Text(
              'Select items from the menu',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactCartItems extends StatefulWidget {
  final List<CartLineItem> items;

  const _CompactCartItems({required this.items});

  @override
  State<_CompactCartItems> createState() => _CompactCartItemsState();
}

class _CompactCartItemsState extends State<_CompactCartItems> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent ||
        event.scrollDelta.dx != 0 ||
        event.scrollDelta.dy == 0 ||
        !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final offset = (_scrollController.offset + event.scrollDelta.dy)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    _scrollController.jumpTo(offset);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = context.w(10);
        final cardWidth = (constraints.maxWidth - spacing * 2) / 2.5;

        return Listener(
          onPointerSignal: _handlePointerSignal,
          child: ScrollConfiguration(
            behavior: const _MouseDragScrollBehavior(),
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => SizedBox(width: spacing),
              itemBuilder: (context, index) => SizedBox(
                width: cardWidth,
                child: _CartItem(
                  line: widget.items[index],
                  compactLayout: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  const _MouseDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
      };
}

// =============================================================================
// CART ITEM
// Same card shell as Checkout Order Summary, but the "Qty: N" line is
// replaced by:  [ −  N  + ] ………… [delete]
// =============================================================================

class _CartItem extends ConsumerWidget {
  final CartLineItem line;
  final bool compactLayout;

  const _CartItem({
    required this.line,
    this.compactLayout = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.read(cartProvider.notifier);

    return OrderSummaryItemCard(
      line: line,
      compactLayout: compactLayout,
      // Replaces the static "Qty: N" text with counter + delete on one row
      quantityControlBuilder: (context, quantity) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Quantity counter
            _stepperPill(
              context,
              compactLayout: compactLayout,
              quantity: quantity,
              onDecrement: () =>
                  cartNotifier.updateQuantity(line.id, quantity - 1),
              onIncrement: () =>
                  cartNotifier.updateQuantity(line.id, quantity + 1),
            ),
            // Delete at the end of the same row
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => cartNotifier.updateQuantity(line.id, 0),
                borderRadius: BorderRadius.circular(context.h(6)),
                child: Container(
                  width: compactLayout ? 18 : context.h(28),
                  height: compactLayout ? 18 : context.h(28),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE05151).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.h(6)),
                    border: Border.all(
                      color: const Color(0xFFE05151).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: compactLayout ? 13 : context.h(16),
                    color: const Color(0xFFE05151),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _stepperPill(
    BuildContext context, {
    required bool compactLayout,
    required int quantity,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return SizedBox(
      height: compactLayout ? 18 : context.h(28),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _stepperButton(
            context,
            icon: Icons.remove,
            onTap: onDecrement,
            compactLayout: compactLayout,
          ),
          SizedBox(
            width: compactLayout ? 20 : context.w(28),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: (compactLayout
                      ? AppTextStyles.caption(context).copyWith(
                          fontSize: 12,
                        )
                      : AppTextStyles.section(context))
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          _stepperButton(
            context,
            icon: Icons.add,
            onTap: onIncrement,
            compactLayout: compactLayout,
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required bool compactLayout,
  }) {
    final buttonSize = compactLayout ? 16.0 : context.h(24);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.h(6)),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(context.h(6)),
          ),
          child: Icon(
            icon,
            size: compactLayout ? 11 : context.h(14),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
