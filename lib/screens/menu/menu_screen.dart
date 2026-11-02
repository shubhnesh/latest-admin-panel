import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/screens/menu/widgets/menu_item_card.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_action_menu_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_delete_dialog.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/menu_item_model.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/buttons/rdx_header_action_button.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/rdx_search_bar.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  bool _categoryPickerOpen = false;
  final GlobalKey _categoryButtonKey = GlobalKey();
  OverlayEntry? _categoryOverlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(menuProvider).load();
    });
  }

  void _openCategoryPicker(MenuProvider provider) {
    if (_categoryPickerOpen) {
      _closeCategoryPicker();
      return;
    }

    final buttonContext = _categoryButtonKey.currentContext;
    if (buttonContext == null) return;

    final renderBox = buttonContext.findRenderObject();
    if (renderBox is! RenderBox) return;

    final buttonOffset = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    final panelWidth = context.w(320);
    final horizontalMargin = context.w(16);
    final verticalGap = context.h(8);
    final panelHeight = context.h(280); // fixed height

    final availableBelow = screenSize.height -
        (buttonOffset.dy + buttonSize.height) -
        mediaQuery.padding.bottom -
        horizontalMargin;

    final availableAbove =
        buttonOffset.dy - mediaQuery.padding.top - horizontalMargin;

    final showBelow =
        availableBelow >= panelHeight || availableBelow >= availableAbove;

    double top;
    if (showBelow) {
      top = buttonOffset.dy + buttonSize.height + verticalGap;
    } else {
      top = buttonOffset.dy - panelHeight - verticalGap;
    }

    final maxTop = screenSize.height - panelHeight - horizontalMargin;
    top = top.clamp(
      mediaQuery.padding.top + horizontalMargin,
      maxTop > mediaQuery.padding.top
          ? maxTop
          : mediaQuery.padding.top + horizontalMargin,
    );

    double left = buttonOffset.dx + buttonSize.width - panelWidth;
    left = left.clamp(
      horizontalMargin,
      screenSize.width - panelWidth - horizontalMargin,
    );

    _categoryOverlay = OverlayEntry(
      builder: (_) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeCategoryPicker,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: panelWidth,
              child: Material(
                color: Colors.transparent,
                child: _categoryPickerPanel(
                  AppColors.of(context),
                  provider,
                  panelHeight: panelHeight,
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_categoryOverlay!);
    setState(() => _categoryPickerOpen = true);
  }

  void _closeCategoryPicker() {
    final overlay = _categoryOverlay;
    _categoryOverlay = null;
    overlay?.remove();

    if (!mounted) return;
    setState(() => _categoryPickerOpen = false);
  }

  void _selectCategory(MenuProvider provider, String category) {
    provider.setCategory(category);
    _closeCategoryPicker();
  }

  @override
  void dispose() {
    _categoryOverlay?.remove();
    _categoryOverlay = null;
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // MENU ITEM ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void _showMenuItemActions(
    BuildContext buttonContext,
    MenuItemModel item,
  ) {
    final renderObject = buttonContext.findRenderObject();
    if (renderObject is! RenderBox) return;

    final buttonPosition = renderObject.localToGlobal(Offset.zero);

    showGeneralDialog<void>(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: 'Menu item actions',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return RdxActionMenuDialog(
          position: buttonPosition,
          gap: 6,
          items: [
            RdxActionMenuItem(
              title: 'Edit',
              onTap: () async {
                await Navigator.of(context).pushNamed(
                  AppRoutes.editMenuItem,
                  arguments: item.id,
                );
                if (context.mounted) {
                  ref.read(menuProvider).load();
                }
              },
            ),
            RdxActionMenuItem(
              title: 'Delete',
              textColor: AppColors.danger,
              onTap: () {
                _confirmDeleteMenuItem(context, item);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteMenuItem(
    BuildContext context,
    MenuItemModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Menu Item',
        itemName: item.name,
        itemDetails: [
          Text(
            item.category,
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ],
        deleteButtonLabel: 'Delete Item',
        warningMessage:
            'Deleting this menu item will permanently remove it from your '
            'menu. This action cannot be undone.',
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref.read(menuProvider).deleteItem(item.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Menu item deleted.'
                : ref.read(menuProvider).errorMessage ??
                    'Failed to delete menu item.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(menuProvider);
    final colors = AppColors.of(context);

    final pagePad = context.defaultScreenPadding();

    Widget bodyContent;
    final showGrid = !provider.isLoading &&
        provider.errorMessage == null &&
        provider.filteredItems.isNotEmpty;

    if (provider.isLoading) {
      bodyContent = const LoadingIndicator();
    } else if (provider.errorMessage != null &&
        provider.filteredItems.isEmpty) {
      bodyContent = Center(
        child: Padding(
          padding: EdgeInsets.all(context.w(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context),
              ),
              SizedBox(height: context.h(12)),
              RdxActionButton(
                label: 'Retry',
                onPressed: () => provider.load(),
                isPrimary: true,
              ),
            ],
          ),
        ),
      );
    } else if (provider.filteredItems.isEmpty) {
      bodyContent = const EmptyState(message: 'No menu items found');
    } else {
      bodyContent = const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Heading + Add Item
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  pagePad.left,
                  pagePad.top,
                  pagePad.right,
                  0,
                ),
                child: _buildHeadingRow(context, colors),
              ),
            ),

            // Search + Filter icon only
            SliverPersistentHeader(
              pinned: true,
              delegate: _MenuFiltersHeader(
                background: colors.background,
                horizontalPad: pagePad.left,
                child: _buildFiltersRow(provider, colors),
              ),
            ),

            if (showGrid)
              _buildGrid(context, provider, colors, pagePad)
            else
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    pagePad.left,
                    context.h(12),
                    pagePad.right,
                    pagePad.bottom,
                  ),
                  child: bodyContent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADING ROW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeadingRow(BuildContext context, AppColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menu Items',
                style: AppTextStyles.heading(context),
              ),
              SizedBox(height: context.h(4)),
              Text(
                'Manage your menu items, pricing and categories.',
                style: AppTextStyles.bodySecondary(context).copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: context.w(12)),
        RdxHeaderActionButton(
          label: 'Add Item',
          onPressed: () async {
            await Navigator.of(context).pushNamed(AppRoutes.editMenuItem);
            if (context.mounted) ref.read(menuProvider).load();
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTERS ROW  – search takes almost full width + filter icon
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFiltersRow(MenuProvider provider, AppColorScheme colors) {
    final searchHeight = RdxSearchBar.standardHeight(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: RdxSearchBar(
            height: searchHeight,
            hintText: 'Search menu items',
            onChanged: (value) => ref.read(menuProvider).setSearchQuery(value),
          ),
        ),
        SizedBox(width: context.w(10)),
        _filterButton(colors, provider),
      ],
    );
  }

// ─── Replace the existing _filterButton method with this ───────────────

  Widget _filterButton(AppColorScheme colors, MenuProvider provider) {
    final isActive = provider.selectedCategory != 'All';
    final labels = ['All', ...provider.categoryList.map((c) => c.name)];

    // Measure the widest label so the button never changes size
    final textStyle = AppTextStyles.label(context);
    double maxTextWidth = 0;
    for (final label in labels) {
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (tp.width > maxTextWidth) maxTextWidth = tp.width;
    }

    // Extra breathing room so the button feels comfortable
    final fixedWidth = context.w(16) * 2 + // left + right padding
        context.h(19) + // tune icon
        context.w(8) + // gap after icon
        maxTextWidth + // longest label
        context.w(20) + // extra space after text
        context.w(4) + // gap before chevron
        context.h(20); // chevron

    return InkWell(
      key: _categoryButtonKey,
      onTap: () => _openCategoryPicker(provider),
      borderRadius: BorderRadius.circular(context.h(8)),
      child: Container(
        width: fixedWidth.clamp(context.w(140), context.w(260)),
        height: RdxSearchBar.standardHeight(context),
        padding: EdgeInsets.symmetric(horizontal: context.w(16)),
        decoration: BoxDecoration(
          color: _categoryPickerOpen || isActive
              ? AppColors.primary.withValues(alpha: 0.08)
              : colors.surface,
          borderRadius: BorderRadius.circular(context.h(8)),
          border: Border.all(
            color: _categoryPickerOpen || isActive
                ? AppColors.primary
                : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(
              Icons.tune,
              size: context.h(19),
              color: AppColors.primary,
            ),
            SizedBox(width: context.w(8)),
            Expanded(
              child: Text(
                provider
                    .selectedCategory, // always shows "All" or the selected name
                style: AppTextStyles.label(context).copyWith(
                  color: isActive ? AppColors.primary : colors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(width: context.w(4)),
            Icon(
              _categoryPickerOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: context.h(20),
              color: colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CATEGORY PICKER PANEL  – chips that wrap + vertical scroll
  // ═══════════════════════════════════════════════════════════════

  Widget _categoryPickerPanel(
    AppColorScheme colors,
    MenuProvider provider, {
    required double panelHeight,
  }) {
    final labels = ['All', ...provider.categoryList.map((c) => c.name)];

    return Container(
      height: panelHeight,
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(13),
        context.w(14),
        context.h(12),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: context.h(18),
            offset: Offset(0, context.h(7)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by category',
            style: AppTextStyles.section(context)
                .copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: context.h(4)),
          Text(
            'Tap a chip to filter the menu items.',
            style: AppTextStyles.caption(context)
                .copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: context.h(12)),
          Expanded(
            child: labels.isEmpty
                ? Center(
                    child: Text(
                      'No categories yet.',
                      style: AppTextStyles.bodySecondary(context)
                          .copyWith(color: colors.textMuted),
                    ),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: context.w(8),
                      runSpacing: context.h(8),
                      children: [
                        for (final label in labels)
                          _FilterChip(
                            label: label,
                            selected: provider.selectedCategory == label,
                            colors: colors,
                            onTap: () => _selectCategory(provider, label),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // GRID — same pattern as CouponsScreen / PromotionCard
  // Width is derived from Responsive.gridColumns so the number of
  // cards per row adapts to screen size. Card height is intrinsic
  // (image aspect + content); no forced height so cards stay stable.
  // ═══════════════════════════════════════════════════════════════

  Widget _buildGrid(
    BuildContext context,
    MenuProvider provider,
    AppColorScheme colors,
    EdgeInsets pagePad,
  ) {
    final items = provider.filteredItems;
    final showAddItemTile = provider.selectedCategory == 'All';

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        pagePad.left,
        context.h(12),
        pagePad.right,
        pagePad.bottom + context.h(24),
      ),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final columns = Responsive.gridColumns(context);
          final spacing = context.w(16);
          // Same formula as CouponsScreen: only width is constrained;
          // height comes from the card itself.
          final cardWidth =
              (constraints.crossAxisExtent - ((columns - 1) * spacing)) /
                  columns;
          final cards = <Widget>[];

          if (showAddItemTile) {
            cards.add(
              SizedBox(
                width: cardWidth,
                child: _AddItemTile(
                  colors: colors,
                  onTap: () async {
                    await Navigator.of(context)
                        .pushNamed(AppRoutes.editMenuItem);
                    if (context.mounted) {
                      ref.read(menuProvider).load();
                    }
                  },
                ),
              ),
            );
          }

          for (final item in items) {
            cards.add(
              SizedBox(
                width: cardWidth,
                child: MenuItemCard(
                  item: item,
                  onToggleAvailability: () => provider.toggleAvailability(item),
                  onActions: (buttonContext) {
                    _showMenuItemActions(buttonContext, item);
                  },
                ),
              ),
            );
          }

          return SliverToBoxAdapter(
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: cards,
            ),
          );
        },
      ),
    );
  }
}

// ─── Filter chip (same look as RdxCategoryTabs) ───────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _FilterChip({
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
          horizontal: context.w(14),
          vertical: context.h(8),
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

// ─── Add Item Tile ────────────────────────────────────────────────────
// Mirrors MenuItemCard structure (image aspect + content slots + bottom
// bar) so it occupies the same height in the Wrap grid.

class _AddItemTile extends ConsumerWidget {
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _AddItemTile({required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNarrow = context.isNarrow;
    final outerRadius = context.h(isNarrow ? 12 : 10);
    final imageAspect = isNarrow ? 1.7 : 1.55;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentAreaHeight = context.h(isNarrow ? 92 : 88);
        final totalHeight = (constraints.maxWidth / imageAspect) + contentAreaHeight;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(outerRadius),
          child: SizedBox(
            width: constraints.maxWidth,
            height: totalHeight,
            child: DottedBorderContainer(
              color: colors.border,
              radius: outerRadius,
              dashLength: context.h(6),
              gapLength: context.h(5),
              strokeWidth: context.h(1.2),
              child: Padding(
                padding: EdgeInsets.all(context.w(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: imageAspect,
                        child: Center(
                          child: Container(
                            width: context.w(40),
                            height: context.h(40),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.border),
                            ),
                            child: Icon(
                              Icons.add,
                              color: colors.textMuted.withValues(alpha: 0.55),
                              size: context.h(24),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: context.h(10)),
                    Text(
                      'Add Item',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.section(context).copyWith(
                        color: colors.textMuted.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Dotted Border helpers ────────────────────────────────────────────

class DottedBorderContainer extends ConsumerWidget {
  final Color color;
  final double radius;
  final double dashLength;
  final double gapLength;
  final double strokeWidth;
  final Widget child;

  const DottedBorderContainer({
    super.key,
    required this.color,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
    required this.strokeWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: color,
        radius: radius,
        dashLength: dashLength,
        gapLength: gapLength,
        strokeWidth: strokeWidth,
      ),
      child: child,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashLength;
  final double gapLength;
  final double strokeWidth;

  _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.6, 0.6, size.width - 1.2, size.height - 1.2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashLength).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next.toDouble()), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Pinned filter strip (search + filter button).
class _MenuFiltersHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color background;
  final double horizontalPad;

  _MenuFiltersHeader({
    required this.child,
    required this.background,
    required this.horizontalPad,
  });

  static const double _height = 56;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: background,
      elevation: overlapsContent || shrinkOffset > 0 ? 1.5 : 0,
      shadowColor: Colors.black26,
      child: Container(
        height: _height,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: horizontalPad),
        decoration: BoxDecoration(
          color: background,
          border: Border(
            bottom: BorderSide(
              color: overlapsContent || shrinkOffset > 0
                  ? AppColors.of(context).border
                  : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _MenuFiltersHeader oldDelegate) {
    return child != oldDelegate.child ||
        background != oldDelegate.background ||
        horizontalPad != oldDelegate.horizontalPad;
  }
}
