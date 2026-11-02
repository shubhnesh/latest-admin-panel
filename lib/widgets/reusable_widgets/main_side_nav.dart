import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import '../../core/theme/app_colors.dart';

class SidebarItem {
  final String label;
  final IconData icon;
  final String route;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

const List<SidebarItem> kPrimaryNavItems = [
  SidebarItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: '/dashboard',
  ),
  SidebarItem(
    label: 'Live Orders',
    icon: Icons.receipt_long_outlined,
    route: '/live-orders',
  ),
  SidebarItem(
    label: 'Menu',
    icon: Icons.restaurant_menu_outlined,
    route: '/menu',
  ),
  SidebarItem(
    label: 'Coupons',
    icon: Icons.local_offer_outlined,
    route: '/coupons',
  ),
  SidebarItem(
    label: 'Inventory',
    icon: Icons.inventory_2_outlined,
    route: '/inventory',
  ),
];

/// Professional collapsible side navigation rail.
/// Expanded width ~240, collapsed ~78. Smooth width + fade animation.
class MainSideNav extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback? onLogout;
  final VoidCallback? onAddOrder;

  /// Design-time widths (scaled at runtime via [context.w]).
  static const double expandedWidth = 240;
  static const double collapsedWidth = 78;

  static const Duration _animDuration = Duration(milliseconds: 280);
  static const Curve _animCurve = Curves.easeInOutCubic;

  const MainSideNav({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.expanded,
    required this.onToggleExpand,
    this.onLogout,
    this.onAddOrder,
  });

  @override
  Widget build(BuildContext context) {
    const sidebarBg = AppColors.lightSidebar;
    const textPrimary = AppColors.lightTextPrimary;
    const textSecondary = AppColors.lightTextSecondary;

    final expandedW = context.w(expandedWidth);
    final collapsedW = context.w(collapsedWidth);
    final currentW = expanded ? expandedW : collapsedW;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: _animDuration,
          curve: _animCurve,
          width: currentW,
          decoration: const BoxDecoration(
            color: sidebarBg,
            border: Border(
              right: BorderSide(color: AppColors.lightBorder, width: 1),
            ),
          ),
          // ClipRect prevents any mid-animation overflow from ever
          // painting outside the rail's current (animating) width.
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header / brand ────────────────────────────────────
                _buildHeader(context, textPrimary, textSecondary),
                SizedBox(height: context.h(8)),
                // ── Primary nav ───────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(expanded ? 10 : 8),
                      vertical: context.h(10),
                    ),
                    children: [
                      for (final item in kPrimaryNavItems)
                        _NavTile(
                          item: item,
                          selected: currentRoute == item.route,
                          expanded: expanded,
                          onTap: () => onNavigate(item.route),
                        ),
                    ],
                  ),
                ),
                // ── Footer actions ────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(expanded ? 10 : 8),
                  ),
                  child: Divider(
                    color: AppColors.lightDivider.withOpacity(0.8),
                    height: 1,
                  ),
                ),
                SizedBox(height: context.h(8)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(expanded ? 10 : 8),
                  ),
                  child: Column(
                    children: [
                      _FooterTile(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        expanded: expanded,
                        selected: currentRoute == '/settings' ||
                            currentRoute == '/support',
                        onTap: () => onNavigate('/settings'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.h(16)),
              ],
            ),
          ),
        ),
        // ── Floating edge toggle ────────────────────────────────────
        AnimatedPositioned(
          duration: _animDuration,
          curve: _animCurve,
          top: context.h(28),
          left: currentW - context.w(14),
          child: _EdgeToggleButton(
            expanded: expanded,
            onTap: onToggleExpand,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(expanded ? 16 : 12),
        context.h(20),
        context.w(expanded ? 16 : 12),
        context.h(12),
      ),
      child: Row(
        mainAxisAlignment:
            expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          // Safe logo: SVG decode can fail on web (CanvasKit not ready /
          // hot-restart). Fallback icon avoids crashing the whole shell.
          _NavLogo(
            width: context.w(50),
            height: context.h(35),
          ),
          Flexible(
            child: AnimatedSize(
              duration: _animDuration,
              curve: _animCurve,
              alignment: Alignment.centerLeft,
              child: ClipRect(
                child: expanded
                    ? Padding(
                        padding: EdgeInsets.only(left: context.w(10)),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: expanded ? 1.0 : 0.0,
                          child: Text(
                            'Admin Panel',
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                            style: AppTextStyles.heading(context).copyWith(
                              color: textPrimary,
                              fontSize: context.h(20),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(width: 0, height: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating circular toggle that sits on the right edge of the rail.
class _EdgeToggleButton extends StatefulWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _EdgeToggleButton({required this.expanded, required this.onTap});

  @override
  State<_EdgeToggleButton> createState() => _EdgeToggleButtonState();
}

class _EdgeToggleButtonState extends State<_EdgeToggleButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    // Single scale factor for both dimensions so the button stays a true circle.
    final size = context.w(28);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Tooltip(
        message: widget.expanded ? 'Collapse sidebar' : 'Expand sidebar',
        waitDuration: const Duration(milliseconds: 400),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _hovering ? AppColors.primary : AppColors.lightSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: _hovering ? AppColors.primary : AppColors.lightBorder,
                width: 1.5,
              ),
            ),
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 280),
              turns: widget.expanded ? 0 : 0.5,
              child: Icon(
                Icons.keyboard_double_arrow_left_rounded,
                size: size * (18 / 28),
                color: _hovering ? Colors.white : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sectional widgets ────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final SidebarItem item;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  static const Duration _d = Duration(milliseconds: 280);
  static const Curve _c = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final bg =
        selected ? AppColors.primary.withOpacity(0.15) : Colors.transparent;
    final color = selected ? AppColors.primary : AppColors.lightTextSecondary;

    final tileHeight = context.h(42);
    final squareSide = tileHeight;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(6)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // constraints.maxWidth is the real, concrete width available
          // (the ListView's content width), so we can animate to it
          // instead of jumping to double.infinity.
          final fullWidth = constraints.maxWidth;
          final targetWidth = expanded ? fullWidth : squareSide;

          return Center(
            child: AnimatedContainer(
              duration: _d,
              curve: _c,
              width: targetWidth,
              height: tileHeight,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(context.h(10)),
              ),
              // Clip so children never paint/measure outside the
              // currently-animating width — this is what kills the
              // overflow exception during the collapse transition.
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Icon: pinned at a fixed left inset when expanded,
                      // dead-centered in the square when collapsed.
                      Positioned(
                        left: expanded ? context.w(12) : null,
                        child: expanded
                            ? Icon(item.icon, size: context.h(20), color: color)
                            : SizedBox(
                                width: squareSide,
                                child: Icon(
                                  item.icon,
                                  size: context.h(20),
                                  color: color,
                                ),
                              ),
                      ),
                      Positioned(
                        left: context.w(44),
                        right: context.w(8),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: expanded ? 1.0 : 0.0,
                          child: Text(
                            item.label,
                            style: AppTextStyles.section(context).copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FooterTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool expanded;
  final VoidCallback onTap;
  final bool selected;

  const _FooterTile({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.onTap,
    this.selected = false,
  });

  static const Duration _d = Duration(milliseconds: 280);
  static const Curve _c = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.lightTextSecondary;
    final bg =
        selected ? AppColors.primary.withOpacity(0.15) : Colors.transparent;

    final tileHeight = context.h(42);
    final squareSide = tileHeight;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(6)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fullWidth = constraints.maxWidth;
          final targetWidth = expanded ? fullWidth : squareSide;

          return Center(
            child: AnimatedContainer(
              duration: _d,
              curve: _c,
              width: targetWidth,
              height: tileHeight,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(context.h(10)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Positioned(
                        left: expanded ? context.w(12) : null,
                        child: expanded
                            ? Icon(icon, size: context.h(20), color: color)
                            : SizedBox(
                                width: squareSide,
                                child: Icon(
                                  icon,
                                  size: context.h(20),
                                  color: color,
                                ),
                              ),
                      ),
                      Positioned(
                        left: context.w(44),
                        right: context.w(8),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: expanded ? 1.0 : 0.0,
                          child: Text(
                            label,
                            style: AppTextStyles.section(context)
                                .copyWith(color: color),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Logo with SVG + hard fallback so web CanvasKit decode errors never
/// take down the side nav.
class _NavLogo extends StatelessWidget {
  final double width;
  final double height;

  const _NavLogo({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final fallback = SizedBox(
      width: width,
      height: height,
      child: Icon(
        Icons.storefront_rounded,
        size: height * 0.85,
        color: Colors.black87,
      ),
    );

    try {
      return SizedBox(
        width: width,
        height: height,
        child: SvgPicture.asset(
          'assets/images/logo/rdx_logo_picture.svg',
          width: width,
          height: height,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(
            Colors.black,
            BlendMode.srcIn,
          ),
          placeholderBuilder: (_) => fallback,
        ),
      );
    } catch (_) {
      return fallback;
    }
  }
}
