import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/cart_provider.dart';
import '../../menu/widgets/menu_item_card.dart';

class LiveOrderMenuCard extends ConsumerWidget {
  final MenuItemModel item;

  const LiveOrderMenuCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final line = _lineFor(cart);

    return Opacity(
      opacity: item.available ? 1 : 0.55,
      child: MenuItemCard.withFooter(
        item: item,
        footerBuilder: (context) => _orderFooter(context, ref, line),
      ),
    );
  }

  Widget _orderFooter(
    BuildContext context,
    WidgetRef ref,
    CartLineItem? line,
  ) {
    final isMobile = context.isMobile;
    final controlHeight = context.h(isMobile ? 42 : 38);

    return Padding(
      padding: EdgeInsets.only(right: context.w(6)),
      child: SizedBox(
        width: double.infinity,
        height: controlHeight,
        child: Align(
          alignment: Alignment.bottomRight,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
                alignment: Alignment.centerRight,
                child: child,
              ),
            ),
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.centerRight,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            child: line == null
                ? _addButton(
                    context,
                    key: const ValueKey('add'),
                    enabled: item.available,
                    onTap: () => ref.read(cartProvider.notifier).addItem(
                          menuItem: item,
                          quantity: 1,
                        ),
                  )
                : _quantityStepper(
                    context,
                    key: const ValueKey('stepper'),
                    quantity: line.quantity,
                    onDecrement: () => ref
                        .read(cartProvider.notifier)
                        .updateQuantity(line.id, line.quantity - 1),
                    onIncrement: () => ref
                        .read(cartProvider.notifier)
                        .updateQuantity(line.id, line.quantity + 1),
                    isMobile: isMobile,
                  ),
          ),
        ),
      ),
    );
  }

  CartLineItem? _lineFor(List<CartLineItem> cart) {
    for (final line in cart) {
      if (line.menuItem.id == item.id) {
        return line;
      }
    }
    return null;
  }

  Widget _addButton(
    BuildContext context, {
    Key? key,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final isMobile = context.isMobile;
    final buttonHeight = context.h(isMobile ? 32 : 28);

    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(context.h(7)),
        child: SizedBox(
          height: buttonHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(context.h(7)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(isMobile ? 18 : 15),
              ),
              child: Align(
                alignment: Alignment.center,
                widthFactor: 1,
                child: Text(
                  '+ Add',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: context.h(isMobile ? 14 : 13),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _quantityStepper(
    BuildContext context, {
    Key? key,
    required int quantity,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required bool isMobile,
  }) {
    return SizedBox(
      key: key,
      height: context.h(isMobile ? 40 : 36),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _stepperButton(
            context,
            icon: Icons.remove,
            onTap: onDecrement,
            isMobile: isMobile,
          ),
          SizedBox(width: isMobile ? context.w(8) : 0),
          SizedBox(
            width: context.w(isMobile ? 38 : 28),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.section(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: isMobile ? context.w(8) : 0),
          _stepperButton(
            context,
            icon: Icons.add,
            onTap: onIncrement,
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    final buttonSize = context.h(isMobile ? 32 : 24);

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
            size: context.h(isMobile ? 16 : 14),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
