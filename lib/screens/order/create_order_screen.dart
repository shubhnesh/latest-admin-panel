import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/screens/order/checkout_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/reusable_widgets/rdx_search_bar.dart';
import 'widgets/cart_panel.dart';
import 'widgets/live_order_menu_card.dart';

class PlaceOrderScreen extends ConsumerStatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  ConsumerState<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends ConsumerState<PlaceOrderScreen> {
  // ── Category filter (same UX as MenuScreen) ───────────────────
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

  @override
  void dispose() {
    _categoryOverlay?.remove();
    _categoryOverlay = null;
    super.dispose();
  }

  /// Handles system back and header back.
  ///
  /// If the cart has items, shows a discard confirmation dialog.
  /// On confirm: clears the cart, then pops. On cancel: stays on screen.
  Future<void> _handleBack() async {
    final cart = ref.read(cartProvider);

    if (cart.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final colors = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Discard cart?',
            style: AppTextStyles.section(ctx).copyWith(
              color: colors.textPrimary,
            ),
          ),
          content: Text(
            'You have items in your cart. Do you want to discard them ?',
            style: AppTextStyles.bodySecondary(ctx).copyWith(
              color: colors.textSecondary,
            ),
          ),
          actions: [
            RdxActionButton.discard(
              height: 36,
              label: 'No',
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            RdxActionButton(
              height: 36,
              label: 'Yes',
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (discard == true && mounted) {
      ref.read(cartProvider.notifier).clear();
      Navigator.of(context).pop();
    }
  }

  /// Moves from the active order/cart screen to checkout.
  ///
  /// IMPORTANT:
  /// This does NOT create the Firestore order.
  /// CheckoutScreen is responsible for final submission.
  void _goToCheckout() {
    final cart = ref.read(cartProvider);

    if (cart.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CheckoutScreen(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CATEGORY FILTER — same as MenuScreen
  // ═══════════════════════════════════════════════════════════════

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
    final panelHeight = context.h(280); // fixed height — same as MenuScreen

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
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuProvider);
    final colors = AppColors.of(context);

    final width = MediaQuery.sizeOf(context).width;

    // Keep the two-column POS layout on desktop/tablet.
    final isCompact = width < 900;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: Column(
          children: [
            RdxHeader(
              title: 'Create New Order',
              showBackButton: true,
              onBack: _handleBack,
            ),
            Expanded(
              child: menuState.isLoading
                  ? const LoadingIndicator()
                  : Padding(
                      padding: isCompact
                          ? EdgeInsets.fromLTRB(
                              context.w(20),
                              context.h(16),
                              context.w(20),
                              context.h(8),
                            )
                          : EdgeInsets.fromLTRB(
                              context.w(20),
                              context.h(16),
                              context.w(20),
                              context.h(24),
                            ),
                      child: isCompact
                          ? _buildCompactLayout(
                              context,
                              menuState,
                              colors,
                            )
                          : _buildDesktopLayout(
                              context,
                              menuState,
                              colors,
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DESKTOP / TABLET
  // ===========================================================================

  Widget _buildDesktopLayout(
    BuildContext context,
    MenuProvider menuState,
    AppColorScheme colors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------------------------------------------------------------------
        // LEFT - MENU (same filters + grid as MenuScreen)
        // ---------------------------------------------------------------------
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: context.w(20),
            ),
            child: _buildMenuArea(context, menuState, colors),
          ),
        ),

        // ---------------------------------------------------------------------
        // DIVIDER
        // ---------------------------------------------------------------------
        VerticalDivider(
          width: context.w(1),
          thickness: context.h(1),
          color: colors.border,
        ),
        SizedBox(width: context.w(20)),

        // ---------------------------------------------------------------------
        // RIGHT - ACTIVE ORDER / CART
        // ---------------------------------------------------------------------
        SizedBox(
          width: context.w(360).clamp(320.0, 400.0),
          child: CartPanel(onProceed: _goToCheckout),
        ),
      ],
    );
  }

  // ===========================================================================
  // COMPACT
  // ===========================================================================

  Widget _buildCompactLayout(
    BuildContext context,
    MenuProvider menuState,
    AppColorScheme colors,
  ) {
    final hasCartItems = ref.watch(cartProvider).isNotEmpty;
    final cartPanelHeight =
        (MediaQuery.sizeOf(context).height * 0.20).clamp(136.0, 164.0);

    return Column(
      children: [
        Expanded(
          child: _buildMenuArea(
            context,
            menuState,
            colors,
          ),
        ),
        if (hasCartItems) ...[
          SizedBox(height: context.h(3)),
          SizedBox(
            height: cartPanelHeight,
            child: CartPanel(
              onProceed: _goToCheckout,
              compactLayout: true,
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // MENU AREA
  //
  // Search + category filter button + grid — same widgets and behaviour as
  // MenuScreen. Only the card (LiveOrderMenuCard) and cart stay order-specific.
  // ===========================================================================

  Widget _buildMenuArea(
    BuildContext context,
    MenuProvider menuState,
    AppColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Filters row (identical to MenuScreen) ─────────────────
        _buildFiltersRow(menuState, colors),

        SizedBox(height: context.h(16)),

        // ── MENU GRID ─────────────────────────────────────────────
        Expanded(
          child: menuState.filteredItems.isEmpty
              ? const EmptyState(
                  message: 'No menu items found',
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Same grid formula as MenuScreen / CouponsScreen.
                    final columns = Responsive.gridColumns(context);
                    final spacing = context.w(16);
                    final cardWidth =
                        (constraints.maxWidth - ((columns - 1) * spacing)) /
                            columns;

                    return SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: context.h(24)),
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final item in menuState.filteredItems)
                            SizedBox(
                              width: cardWidth,
                              child: LiveOrderMenuCard(item: item),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTERS ROW — search + category filter (same as MenuScreen)
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
                provider.selectedCategory,
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
  // CATEGORY PICKER PANEL — chips that wrap + vertical scroll
  // (identical to MenuScreen)
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
}

// ─── Filter chip (same look as MenuScreen / RdxCategoryTabs) ─────────

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
