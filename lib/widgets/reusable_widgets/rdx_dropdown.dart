// import 'package:flutter/material.dart';
// import 'package:rdx_admin/core/theme/text_styles.dart';
// import '../core/theme/app_colors.dart';
// import '../core/utils/responsive_size.dart';

// class RdxDropdown<T> extends StatefulWidget {
//   final T? value;
//   final List<T> items;
//   final String Function(T) labelBuilder;
//   final ValueChanged<T?>? onChanged;
//   final String? hint;
//   final String? label;
//   final bool enabled;
//   final bool isDense;
//   final double? width;
//   final double maxMenuHeight;
//   final EdgeInsetsGeometry? margin;

//   const RdxDropdown({
//     super.key,
//     required this.items,
//     required this.labelBuilder,
//     this.value,
//     this.onChanged,
//     this.hint,
//     this.label,
//     this.enabled = true,
//     this.isDense = false,
//     this.width,
//     this.maxMenuHeight = 240,
//     this.margin,
//   });

//   @override
//   State<RdxDropdown<T>> createState() => _RdxDropdownState<T>();
// }

// class _RdxDropdownState<T> extends State<RdxDropdown<T>> {
//   final LayerLink _layerLink = LayerLink();
//   final GlobalKey _triggerKey = GlobalKey();
//   OverlayEntry? _overlay;
//   bool _open = false;

//   @override
//   void dispose() {
//     _removeOverlay();
//     super.dispose();
//   }

//   void _removeOverlay() {
//     _overlay?.remove();
//     _overlay = null;
//     if (_open && mounted) {
//       setState(() => _open = false);
//     } else {
//       _open = false;
//     }
//   }

//   void _toggle() {
//     if (!widget.enabled || widget.onChanged == null) return;
//     if (_open) {
//       _removeOverlay();
//     } else {
//       _showOverlay();
//     }
//   }

//   void _showOverlay() {
//     final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
//     if (box == null || !box.hasSize) return;

//     final triggerSize = box.size;
//     final overlay = Overlay.of(context);
//     final media = MediaQuery.of(context);
//     final triggerOffset = box.localToGlobal(Offset.zero);

//     // Prefer opening below; flip above if not enough room.
//     final spaceBelow = media.size.height -
//         (triggerOffset.dy + triggerSize.height) -
//         media.padding.bottom -
//         8;
//     final spaceAbove = triggerOffset.dy - media.padding.top - 8;
//     final openBelow = spaceBelow >= 120 || spaceBelow >= spaceAbove;
//     final available = openBelow ? spaceBelow : spaceAbove;
//     final menuMaxH = widget.maxMenuHeight.clamp(0, available).toDouble();

//     _overlay = OverlayEntry(
//       builder: (context) {
//         final colors = AppColors.of(context);
//         return Stack(
//           children: [
//             // Dismiss barrier — does not absorb pointer outside when tapping trigger again
//             Positioned.fill(
//               child: GestureDetector(
//                 behavior: HitTestBehavior.translucent,
//                 onTap: _removeOverlay,
//                 child: const SizedBox.expand(),
//               ),
//             ),
//             CompositedTransformFollower(
//               link: _layerLink,
//               showWhenUnlinked: false,
//               offset: openBelow
//                   ? Offset(0, triggerSize.height + 4)
//                   : Offset(0, -menuMaxH - 4),
//               child: Material(
//                 color: Colors.transparent,
//                 child: SizedBox(
//                   width: triggerSize.width,
//                   child: _DropdownMenuPanel<T>(
//                     items: widget.items,
//                     value: widget.value,
//                     labelBuilder: widget.labelBuilder,
//                     maxHeight: menuMaxH,
//                     colors: colors,
//                     onSelect: (item) {
//                       _removeOverlay();
//                       widget.onChanged?.call(item);
//                     },
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );

//     overlay.insert(_overlay!);
//     setState(() => _open = true);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);
//     final hasValue =
//         widget.value != null && widget.items.any((e) => e == widget.value);

//     final display = hasValue
//         ? widget.labelBuilder(widget.value as T)
//         : (widget.hint ?? 'Select');

//     final field = CompositedTransformTarget(
//       link: _layerLink,
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           key: _triggerKey,
//           onTap: _toggle,
//           overlayColor: WidgetStateProperty.all(Colors.transparent),
//           borderRadius: BorderRadius.circular(context.h(8)),
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 140),
//             width: widget.width ?? double.infinity,
//             height: () {
//               final fs = context.h(widget.isDense ? 12 : 14);
//               final vp = context.h(widget.isDense ? 10 : 13);
//               return (fs * 1.2) + (vp * 2) + 2;
//             }(),
//             padding: EdgeInsets.symmetric(
//               horizontal: context.w(widget.isDense ? 11 : 12),
//               vertical: 0,
//             ),
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: _open || hasValue ? Colors.white : colors.surfaceVariant,
//               borderRadius: BorderRadius.circular(context.h(8)),
//               border: Border.all(color: colors.border, width: 1),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     display,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: hasValue
//                         ? AppTextStyles.body(context)
//                         : AppTextStyles.body(context)
//                             .copyWith(color: colors.textMuted),
//                   ),
//                 ),
//                 SizedBox(width: context.w(6)),
//                 AnimatedRotation(
//                   turns: _open ? 0.5 : 0,
//                   duration: const Duration(milliseconds: 160),
//                   child: Icon(
//                     Icons.keyboard_arrow_down_rounded,
//                     size: context.h(20),
//                     color: _open ? AppColors.primary : colors.textSecondary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );

//     if (widget.label == null) {
//       return Padding(
//         padding: widget.margin ?? EdgeInsets.zero,
//         child: field,
//       );
//     }

//     return Padding(
//       padding: widget.margin ?? EdgeInsets.zero,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             widget.label!,
//             style: AppTextStyles.label(context)
//                 .copyWith(color: colors.textSecondary),
//           ),
//           SizedBox(height: context.h(6)),
//           field,
//         ],
//       ),
//     );
//   }
// }

// class _DropdownMenuPanel<T> extends StatelessWidget {
//   final List<T> items;
//   final T? value;
//   final String Function(T) labelBuilder;
//   final double maxHeight;
//   final AppColorScheme colors;
//   final ValueChanged<T> onSelect;

//   const _DropdownMenuPanel({
//     required this.items,
//     required this.value,
//     required this.labelBuilder,
//     required this.maxHeight,
//     required this.colors,
//     required this.onSelect,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       constraints: BoxConstraints(maxHeight: maxHeight),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(context.h(10)),
//         border: Border.all(color: colors.border),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.12),
//             blurRadius: context.h(18),
//             offset: Offset(0, context.h(6)),
//           ),
//         ],
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: items.isEmpty
//           ? Padding(
//               padding: EdgeInsets.all(context.h(14)),
//               child: Text(
//                 'No options',
//                 style: AppTextStyles.caption(context),
//               ),
//             )
//           : ListView.separated(
//               padding: EdgeInsets.symmetric(vertical: context.h(6)),
//               shrinkWrap: true,
//               itemCount: items.length,
//               separatorBuilder: (_, __) => Divider(
//                 height: 1,
//                 thickness: 1,
//                 color: colors.divider.withValues(alpha: 0.6),
//                 indent: context.w(12),
//                 endIndent: context.w(12),
//               ),
//               itemBuilder: (context, index) {
//                 final item = items[index];
//                 final selected = item == value;
//                 return Material(
//                   color: selected
//                       ? AppColors.primary.withValues(alpha: 0.08)
//                       : Colors.transparent,
//                   child: InkWell(
//                     onTap: () => onSelect(item),
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: context.w(14),
//                         vertical: context.h(11),
//                       ),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               labelBuilder(item),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: selected
//                                   ? AppTextStyles.label(context)
//                                       .copyWith(color: AppColors.primary)
//                                   : AppTextStyles.body(context),
//                             ),
//                           ),
//                           if (selected)
//                             Icon(
//                               Icons.check_rounded,
//                               size: context.h(16),
//                               color: AppColors.primary,
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_search_bar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import 'rdx_text_field.dart';

class RdxDropdown<T> extends StatefulWidget {
  final T? value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? label;
  final bool enabled;
  final bool isDense;
  final double? width;
  final double maxMenuHeight;
  final EdgeInsetsGeometry? margin;

  /// When true, shows a search field inside the open menu.
  /// Defaults to false (normal dropdown).
  final bool searchable;

  /// Placeholder shown in the search field (only used when searchable is true).
  final String searchHint;

  const RdxDropdown({
    super.key,
    required this.items,
    required this.labelBuilder,
    this.value,
    this.onChanged,
    this.hint,
    this.label,
    this.enabled = true,
    this.isDense = false,
    this.width,
    this.maxMenuHeight = 240,
    this.margin,
    this.searchable = false, // default: normal dropdown
    this.searchHint = 'Search...',
  });

  @override
  State<RdxDropdown<T>> createState() => _RdxDropdownState<T>();
}

class _RdxDropdownState<T> extends State<RdxDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _triggerKey = GlobalKey();
  OverlayEntry? _overlay;
  bool _open = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _removeOverlay(rebuild: false);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _removeOverlay({bool rebuild = true}) {
    _overlay?.remove();
    _overlay = null;
    _searchController.clear();
    if (rebuild && _open && mounted) {
      setState(() => _open = false);
    } else {
      _open = false;
    }
  }

  void _toggle() {
    if (!widget.enabled || widget.onChanged == null) return;
    if (_open) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final triggerSize = box.size;
    final overlay = Overlay.of(context);
    final media = MediaQuery.of(context);
    final triggerOffset = box.localToGlobal(Offset.zero);

    // Prefer opening below; flip above if not enough room.
    final spaceBelow = media.size.height -
        (triggerOffset.dy + triggerSize.height) -
        media.padding.bottom -
        8;
    final spaceAbove = triggerOffset.dy - media.padding.top - 8;
    final openBelow = spaceBelow >= 120 || spaceBelow >= spaceAbove;
    final available = openBelow ? spaceBelow : spaceAbove;
    final menuMaxH = widget.maxMenuHeight.clamp(0, available).toDouble();

    _overlay = OverlayEntry(
      builder: (context) {
        final colors = AppColors.of(context);
        return Stack(
          children: [
            // Dismiss barrier
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: openBelow
                  ? Offset(0, triggerSize.height + 4)
                  : Offset(0, -menuMaxH - 4),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: triggerSize.width,
                  child: _DropdownMenuPanel<T>(
                    items: widget.items,
                    value: widget.value,
                    labelBuilder: widget.labelBuilder,
                    maxHeight: menuMaxH,
                    colors: colors,
                    searchable: widget.searchable,
                    searchHint: widget.searchHint,
                    searchController: _searchController,
                    searchFocus: _searchFocus,
                    onSelect: (item) {
                      _removeOverlay();
                      widget.onChanged?.call(item);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlay!);
    setState(() => _open = true);

    // Auto-focus the search field only when searchable
    if (widget.searchable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_searchFocus.canRequestFocus) {
          _searchFocus.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasValue =
        widget.value != null && widget.items.any((e) => e == widget.value);
    final valueTextStyle = AppTextStyles.bodySecondary(context).copyWith(
      fontSize: RdxTextField.textFontSize(context),
    );

    final display = hasValue
        ? widget.labelBuilder(widget.value as T)
        : (widget.hint ?? 'Select');

    final field = CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: _triggerKey,
          onTap: _toggle,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          borderRadius: BorderRadius.circular(context.h(8)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: widget.width ?? double.infinity,
            height: () {
              final fs = context.h(widget.isDense ? 12 : 14);
              final vp = context.h(widget.isDense ? 10 : 13);
              return (fs * 1.2) + (vp * 2) + 2;
            }(),
            padding: EdgeInsets.symmetric(
              horizontal: context.w(widget.isDense ? 11 : 12),
              vertical: 0,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _open || hasValue ? Colors.white : colors.surfaceVariant,
              borderRadius: BorderRadius.circular(context.h(8)),
              border: Border.all(color: colors.border, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: hasValue
                        ? valueTextStyle
                        : AppTextStyles.bodySecondary(context).copyWith(
                            color: colors.textMuted,
                            fontSize: RdxTextField.textFontSize(context),
                          ),
                  ),
                ),
                SizedBox(width: context.w(6)),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: context.h(20),
                    color: _open ? AppColors.primary : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.label == null) {
      return Padding(
        padding: widget.margin ?? EdgeInsets.zero,
        child: field,
      );
    }

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label!,
            // style: AppTextStyles.bodySecondary(context)
            //     .copyWith(color: colors.textSecondary),
            style: AppTextStyles.bodySecondary(context)
                .copyWith(color: colors.textMuted),
          ),
          SizedBox(height: context.h(6)),
          field,
        ],
      ),
    );
  }
}

class _DropdownMenuPanel<T> extends StatefulWidget {
  final List<T> items;
  final T? value;
  final String Function(T) labelBuilder;
  final double maxHeight;
  final AppColorScheme colors;
  final ValueChanged<T> onSelect;
  final bool searchable;
  final String searchHint;
  final TextEditingController searchController;
  final FocusNode searchFocus;

  const _DropdownMenuPanel({
    required this.items,
    required this.value,
    required this.labelBuilder,
    required this.maxHeight,
    required this.colors,
    required this.onSelect,
    required this.searchable,
    required this.searchHint,
    required this.searchController,
    required this.searchFocus,
  });

  @override
  State<_DropdownMenuPanel<T>> createState() => _DropdownMenuPanelState<T>();
}

class _DropdownMenuPanelState<T> extends State<_DropdownMenuPanel<T>> {
  late List<T> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List<T>.from(widget.items);
    if (widget.searchable) {
      widget.searchController.addListener(_onSearchChanged);
    }
  }

  @override
  void didUpdateWidget(covariant _DropdownMenuPanel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _applyFilter(widget.searchController.text);
    }
  }

  @override
  void dispose() {
    if (widget.searchable) {
      widget.searchController.removeListener(_onSearchChanged);
    }
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilter(widget.searchController.text);
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<T>.from(widget.items);
      } else {
        _filtered = widget.items
            .where(
                (item) => widget.labelBuilder(item).toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final optionTextStyle = AppTextStyles.bodySecondary(context).copyWith(
      fontSize: RdxTextField.textFontSize(context),
    );

    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: widget.colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: context.h(18),
            offset: Offset(0, context.h(6)),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.searchable) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(10),
                context.h(10),
                context.w(10),
                context.h(6),
              ),
              child: RdxSearchBar(
                controller: widget.searchController,
                focusNode: widget.searchFocus,
                hintText: widget.searchHint,
                height: context.h(40),
                onChanged: (_) {
                  // Listener already handles filtering via _onSearchChanged
                },
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: widget.colors.divider.withValues(alpha: 0.6),
            ),
          ],
          Flexible(
            child: _filtered.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(context.h(14)),
                    child: Text(
                      widget.searchable &&
                              widget.searchController.text.trim().isNotEmpty
                          ? 'No matches'
                          : 'No options',
                      style: optionTextStyle,
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: context.h(6)),
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: widget.colors.divider.withValues(alpha: 0.6),
                      indent: context.w(12),
                      endIndent: context.w(12),
                    ),
                    itemBuilder: (context, index) {
                      final item = _filtered[index];
                      final selected = item == widget.value;
                      return Material(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () => widget.onSelect(item),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(14),
                              vertical: context.h(11),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.labelBuilder(item),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: selected
                                        ? optionTextStyle.copyWith(
                                            color: AppColors.primary,
                                          )
                                        : optionTextStyle,
                                  ),
                                ),
                                if (selected)
                                  Icon(
                                    Icons.check_rounded,
                                    size: context.h(16),
                                    color: AppColors.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
