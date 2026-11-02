import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import 'rdx_text_field.dart';

class RdxMultiDropdown<T> extends StatefulWidget {
  final List<T> value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<List<T>>? onChanged;
  final String? hint;
  final String? label;
  final bool enabled;
  final bool isDense;
  final double? width;
  final double maxMenuHeight;
  final EdgeInsetsGeometry? margin;

  /// When true, shows a search field inside the open menu.
  /// Defaults to false (normal multi-select dropdown).
  final bool searchable;

  /// Placeholder shown in the search field (only used when searchable is true).
  final String searchHint;

  /// Max number of selected labels shown in the trigger before collapsing to "N selected".
  final int maxDisplayLabels;

  const RdxMultiDropdown({
    super.key,
    required this.items,
    required this.labelBuilder,
    this.value = const [],
    this.onChanged,
    this.hint,
    this.label,
    this.enabled = true,
    this.isDense = false,
    this.width,
    this.maxMenuHeight = 280,
    this.margin,
    this.searchable = false,
    this.searchHint = 'Search...',
    this.maxDisplayLabels = 2,
  });

  @override
  State<RdxMultiDropdown<T>> createState() => _RdxMultiDropdownState<T>();
}

class _RdxMultiDropdownState<T> extends State<RdxMultiDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _triggerKey = GlobalKey();
  OverlayEntry? _overlay;
  bool _open = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Local selection so we can update the menu without waiting for parent rebuild
  late List<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<T>.from(widget.value);
  }

  @override
  void didUpdateWidget(covariant RdxMultiDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _selected = List<T>.from(widget.value);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _overlay?.markNeedsBuild();
      });
    }
  }

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
                  child: _MultiDropdownMenuPanel<T>(
                    items: widget.items,
                    selected: _selected,
                    labelBuilder: widget.labelBuilder,
                    maxHeight: menuMaxH,
                    colors: colors,
                    searchable: widget.searchable,
                    searchHint: widget.searchHint,
                    searchController: _searchController,
                    searchFocus: _searchFocus,
                    onToggle: (item) {
                      setState(() {
                        if (_selected.any((e) => e == item)) {
                          _selected =
                              _selected.where((e) => e != item).toList();
                        } else {
                          _selected = [..._selected, item];
                        }
                      });
                      widget.onChanged?.call(List<T>.from(_selected));
                      _overlay?.markNeedsBuild();
                    },
                    onClearAll: () {
                      setState(() => _selected = []);
                      widget.onChanged?.call([]);
                      _overlay?.markNeedsBuild();
                    },
                    onSelectAll: () {
                      setState(() => _selected = List<T>.from(widget.items));
                      widget.onChanged?.call(List<T>.from(_selected));
                      _overlay?.markNeedsBuild();
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

    if (widget.searchable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_searchFocus.canRequestFocus) {
          _searchFocus.requestFocus();
        }
      });
    }
  }

  String _displayText(AppColorScheme colors) {
    if (_selected.isEmpty) return widget.hint ?? 'Select';
    if (_selected.length <= widget.maxDisplayLabels) {
      return _selected.map(widget.labelBuilder).join(', ');
    }
    return '${_selected.length} selected';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasValue = _selected.isNotEmpty;
    final display = _displayText(colors);
    final valueTextStyle = AppTextStyles.body(context).copyWith(
      fontSize: RdxTextField.textFontSize(context),
    );

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
                        : valueTextStyle.copyWith(color: colors.textMuted),
                  ),
                ),
                if (hasValue) ...[
                  SizedBox(width: context.w(4)),
                  GestureDetector(
                    onTap: () {
                      setState(() => _selected = []);
                      widget.onChanged?.call([]);
                      _overlay?.markNeedsBuild();
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: context.h(16),
                      color: colors.textSecondary,
                    ),
                  ),
                ],
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
            style: AppTextStyles.label(context)
                .copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: context.h(6)),
          field,
        ],
      ),
    );
  }
}

class _MultiDropdownMenuPanel<T> extends StatefulWidget {
  final List<T> items;
  final List<T> selected;
  final String Function(T) labelBuilder;
  final double maxHeight;
  final AppColorScheme colors;
  final ValueChanged<T> onToggle;
  final VoidCallback onClearAll;
  final VoidCallback onSelectAll;
  final bool searchable;
  final String searchHint;
  final TextEditingController searchController;
  final FocusNode searchFocus;

  const _MultiDropdownMenuPanel({
    required this.items,
    required this.selected,
    required this.labelBuilder,
    required this.maxHeight,
    required this.colors,
    required this.onToggle,
    required this.onClearAll,
    required this.onSelectAll,
    required this.searchable,
    required this.searchHint,
    required this.searchController,
    required this.searchFocus,
  });

  @override
  State<_MultiDropdownMenuPanel<T>> createState() =>
      _MultiDropdownMenuPanelState<T>();
}

class _MultiDropdownMenuPanelState<T>
    extends State<_MultiDropdownMenuPanel<T>> {
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
  void didUpdateWidget(covariant _MultiDropdownMenuPanel<T> oldWidget) {
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

  void _onSearchChanged() => _applyFilter(widget.searchController.text);

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

  bool _isSelected(T item) => widget.selected.any((e) => e == item);

  @override
  Widget build(BuildContext context) {
    final allSelected = widget.items.isNotEmpty &&
        widget.selected.length == widget.items.length;
    final optionTextStyle = AppTextStyles.body(context).copyWith(
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
          // Search field
          if (widget.searchable) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(10),
                context.h(10),
                context.w(10),
                context.h(6),
              ),
              child: TextField(
                controller: widget.searchController,
                focusNode: widget.searchFocus,
                maxLength: 20,
                style: optionTextStyle,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.searchHint,
                  hintStyle:
                      optionTextStyle.copyWith(color: widget.colors.textMuted),
                  counterText: '',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: context.h(18),
                    color: widget.colors.textSecondary,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: context.w(36),
                    minHeight: context.h(36),
                  ),
                  suffixIcon: widget.searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: context.h(16),
                            color: widget.colors.textSecondary,
                          ),
                          onPressed: () => widget.searchController.clear(),
                          splashRadius: context.h(16),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: context.w(32),
                            minHeight: context.h(32),
                          ),
                        )
                      : null,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.w(10),
                    vertical: context.h(10),
                  ),
                  filled: true,
                  fillColor: widget.colors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.h(8)),
                    borderSide: BorderSide(color: widget.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.h(8)),
                    borderSide: BorderSide(color: widget.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.h(8)),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: widget.colors.divider.withValues(alpha: 0.6),
            ),
          ],

          // Select all / Clear all row
          if (widget.items.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(10),
                vertical: context.h(6),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed:
                        allSelected ? widget.onClearAll : widget.onSelectAll,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(8),
                        vertical: context.h(4),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      allSelected ? 'Clear all' : 'Select all',
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.selected.isNotEmpty)
                    Text(
                      '${widget.selected.length} selected',
                      style: AppTextStyles.caption(context).copyWith(
                        color: widget.colors.textMuted,
                      ),
                    ),
                ],
              ),
            ),

          if (widget.items.isNotEmpty)
            Divider(
              height: 1,
              thickness: 1,
              color: widget.colors.divider.withValues(alpha: 0.6),
            ),

          // Options list
          Flexible(
            child: _filtered.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(context.h(14)),
                    child: Text(
                      widget.searchable &&
                              widget.searchController.text.trim().isNotEmpty
                          ? 'No matches'
                          : 'No options',
                      style: AppTextStyles.caption(context),
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
                      final selected = _isSelected(item);
                      return Material(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () => widget.onToggle(item),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(12),
                              vertical: context.h(10),
                            ),
                            child: Row(
                              children: [
                                // Checkbox-style indicator
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  width: context.h(18),
                                  height: context.h(18),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius:
                                        BorderRadius.circular(context.h(4)),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : widget.colors.border,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: selected
                                      ? Icon(
                                          Icons.check_rounded,
                                          size: context.h(12),
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                SizedBox(width: context.w(10)),
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
