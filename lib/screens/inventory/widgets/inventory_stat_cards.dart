import 'package:flutter/material.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';

class InventoryStatCards extends StatelessWidget {
  final List<Widget> cards;

  const InventoryStatCards({
    super.key,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 900) {
      final cardWidth = (width / 2.45).clamp(160.0, 215.0);
      return SizedBox(
        height: context.h(92).clamp(84.0, 100.0),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, __) => SizedBox(width: context.w(8)),
          itemBuilder: (_, index) => SizedBox(
            width: cardWidth,
            child: cards[index],
          ),
        ),
      );
    }

    return SizedBox(
      height: context.h(100).clamp(88.0, 112.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            Expanded(child: cards[index]),
            if (index != cards.length - 1) SizedBox(width: context.w(10)),
          ],
        ],
      ),
    );
  }
}
