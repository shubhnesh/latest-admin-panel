import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';

class RdxCategoryTabs extends StatefulWidget {
  final List<String> labels;
  final String selectedLabel;
  final ValueChanged<String> onSelected;
  final String? allLabel;
  final bool expand;

  const RdxCategoryTabs({
    super.key,
    required this.labels,
    required this.selectedLabel,
    required this.onSelected,
    this.allLabel,
    this.expand = true,
  });

  @override
  State<RdxCategoryTabs> createState() => _RdxCategoryTabsState();
}

class _RdxCategoryTabsState extends State<RdxCategoryTabs> {
  final ScrollController _scrollController = ScrollController();

  List<String> get _labels => [
        if (widget.allLabel != null) widget.allLabel!,
        ...widget.labels,
      ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scrollController.hasClients) return;

    final position = _scrollController.position;
    final offset = (position.pixels + event.scrollDelta.dy).clamp(
      0.0,
      position.maxScrollExtent,
    );
    _scrollController.jumpTo(offset);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tabs = Listener(
      onPointerSignal: _handlePointerSignal,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
          },
        ),
        child: ClipRect(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < _labels.length; index++) ...[
                  if (index > 0) SizedBox(width: context.w(8)),
                  _CategoryTabChip(
                    label: _labels[index],
                    selected: widget.selectedLabel == _labels[index],
                    colors: colors,
                    onTap: () => widget.onSelected(_labels[index]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return widget.expand ? Expanded(child: tabs) : tabs;
  }
}

class _CategoryTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _CategoryTabChip({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.h(20)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(9),
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : colors.surface,
          borderRadius: BorderRadius.circular(context.h(20)),
          border: Border.all(
            color: selected ? AppColors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: selected
              ? AppTextStyles.label(context).copyWith(color: Colors.white)
              : AppTextStyles.label(context)
                  .copyWith(color: colors.textSecondary),
        ),
      ),
    );
  }
}
