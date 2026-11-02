import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';

class RdxTableColumn {
  /// Design width in logical px. Used as a hard floor for horizontal overflow.
  final double minWidth;

  /// Share of leftover space after min widths are applied.
  final double flex;

  final String title;
  final Alignment alignment;

  const RdxTableColumn({
    required this.title,
    required this.minWidth,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
  });
}

class RdxTable extends StatefulWidget {
  final List<RdxTableColumn> columns;
  final List<List<Widget>> rows;
  final Widget? footer;
  final bool showFooter;
  final bool showRowDividers;
  final ValueChanged<int>? onRowTap;

  const RdxTable({
    super.key,
    required this.columns,
    required this.rows,
    this.footer,
    this.showFooter = false,
    this.showRowDividers = true,
    this.onRowTap,
  });

  @override
  State<RdxTable> createState() => _RdxTableState();
}

class _RdxTableState extends State<RdxTable> {
  final ScrollController _hController = ScrollController();

  @override
  void dispose() {
    _hController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isMobile = Responsive.isMobile(context);
    final isNarrow = Responsive.isNarrow(context);

    final hPad = isMobile
        ? context.w(10)
        : isNarrow
            ? context.w(12)
            : context.w(16);
    final headerHeight = isMobile ? context.h(40) : context.h(46);
    final rowMinHeight = isMobile ? context.h(56) : context.h(68);
    final rowVPad = isMobile ? context.h(8) : context.h(10);
    final radius = context.h(14);
    final gap = isMobile
        ? 10.0
        : isNarrow
            ? 12.0
            : 14.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        // Hard min width from design values (not aggressively scaled down).
        // This is what creates real horizontal overflow on phones/tablets.
        final widths = _columnWidths(context, maxW, gap, hPad);
        final contentW = widths.fold<double>(0, (s, w) => s + w) +
            gap * (widget.columns.length - 1) +
            hPad * 2;

        final tableW = contentW < maxW ? maxW : contentW;
        final canScrollH = tableW > maxW + 1;

        // Prefer bounded height from parent (Expanded / SliverFillRemaining).
        final tableH = maxH.isFinite && maxH > 0 ? maxH : context.h(420);

        final body = SizedBox(
          width: tableW,
          height: tableH,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, colors, widths, gap, hPad, headerHeight),
              Divider(height: 1, thickness: 1, color: colors.divider),
              Expanded(
                child: widget.rows.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        itemCount: widget.rows.length,
                        itemBuilder: (context, index) {
                          return _row(
                            context,
                            colors,
                            widget.rows[index],
                            index,
                            widths,
                            gap,
                            hPad,
                            rowMinHeight,
                            rowVPad,
                          );
                        },
                      ),
              ),
              if (widget.showFooter && widget.footer != null) ...[
                Divider(height: 1, thickness: 1, color: colors.divider),
                widget.footer!,
              ],
            ],
          ),
        );

        return Container(
          width: double.infinity,
          height: tableH,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.hardEdge,
          // Horizontal drag recognizer so parent vertical scroll does not win.
          child: ScrollConfiguration(
            behavior: const _HScrollBehavior(),
            child: Scrollbar(
              controller: _hController,
              thumbVisibility: canScrollH,
              trackVisibility: false,
              thickness: canScrollH ? 6 : 0,
              radius: const Radius.circular(8),
              notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _hController,
                scrollDirection: Axis.horizontal,
                physics: canScrollH
                    ? const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      )
                    : const NeverScrollableScrollPhysics(),
                child: body,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Column widths: at least design minWidth (lightly scaled), then flex extra.
  List<double> _columnWidths(
    BuildContext context,
    double maxW,
    double gap,
    double hPad,
  ) {
    final n = widget.columns.length;
    final gaps = n > 1 ? gap * (n - 1) : 0.0;

    // Floor: use design minWidth with only light scale — never crush so hard
    // that 7 inventory columns fit on a 360px screen without scrolling.
    final mins = widget.columns.map((c) {
      final scaled = context.w(c.minWidth);
      // Keep a solid floor from the design token itself.
      return scaled < c.minWidth * 0.85 ? c.minWidth * 0.85 : scaled;
    }).toList();

    final minTotal = mins.fold<double>(0, (s, w) => s + w) + gaps + hPad * 2;

    // If viewport is wider than mins, distribute extra by flex.
    if (maxW > minTotal) {
      final extra = maxW - minTotal;
      final flexSum =
          widget.columns.fold<double>(0, (s, c) => s + c.flex);
      if (flexSum <= 0) return mins;
      return [
        for (int i = 0; i < n; i++)
          mins[i] + extra * (widget.columns[i].flex / flexSum),
      ];
    }

    // Viewport narrower → keep mins (table will scroll horizontally).
    return mins;
  }

  TextStyle _headerStyle(BuildContext context, AppColorScheme colors) {
    final isMobile = Responsive.isMobile(context);
    final isNarrow = Responsive.isNarrow(context);
    final size = isMobile
        ? context.h(11).clamp(10.0, 12.0)
        : isNarrow
            ? context.h(12).clamp(11.0, 13.0)
            : context.h(13).clamp(12.0, 14.0);

    return AppTextStyles.label(context).copyWith(
      color: colors.textMuted,
      fontWeight: FontWeight.w600,
      fontSize: size,
      letterSpacing: 0.3,
    );
  }

  Widget _header(
    BuildContext context,
    AppColorScheme colors,
    List<double> widths,
    double gap,
    double hPad,
    double height,
  ) {
    final style = _headerStyle(context, colors);

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: hPad),
      color: colors.surfaceVariant.withValues(alpha: 0.35),
      child: Row(
        children: [
          for (int i = 0; i < widget.columns.length; i++) ...[
            SizedBox(
              width: widths[i],
              child: Align(
                alignment: widget.columns[i].alignment,
                child: Text(
                  widget.columns[i].title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            ),
            if (i != widget.columns.length - 1) SizedBox(width: gap),
          ],
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    AppColorScheme colors,
    List<Widget> cells,
    int rowIndex,
    List<double> widths,
    double gap,
    double hPad,
    double minHeight,
    double vPad,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onRowTap == null ? null : () => widget.onRowTap!(rowIndex),
        mouseCursor: widget.onRowTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        hoverColor: colors.surfaceVariant.withValues(alpha: 0.35),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: colors.surface,
            border: widget.showRowDividers
                ? Border(bottom: BorderSide(color: colors.divider))
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < widget.columns.length; i++) ...[
                SizedBox(
                  width: widths[i],
                  child: Align(
                    alignment: widget.columns[i].alignment,
                    child: cells.length > i ? cells[i] : const SizedBox.shrink(),
                  ),
                ),
                if (i != widget.columns.length - 1) SizedBox(width: gap),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Allows drag + mouse-wheel/trackpad horizontal scrolling inside a
/// vertical parent scroll view (CustomScrollView / ListView).
class _HScrollBehavior extends MaterialScrollBehavior {
  const _HScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class RdxTableActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const RdxTableActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final size = Responsive.isMobile(context) ? context.w(28) : context.w(32);
    final iconSize =
        Responsive.isMobile(context) ? context.h(20) : context.h(22);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(context.h(6)),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Icon(icon, size: iconSize, color: colors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

class RdxTableMoreButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final double? size;
  final double? iconSize;
  final Color? iconColor;
  final Color? hoverColor;

  const RdxTableMoreButton({
    super.key,
    this.tooltip = 'More',
    this.onPressed,
    this.icon = Icons.more_vert_rounded,
    this.size,
    this.iconSize,
    this.iconColor,
    this.hoverColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final resolvedSize =
        size ?? (Responsive.isMobile(context) ? context.w(28) : context.w(32));
    final resolvedIconSize = iconSize ??
        (Responsive.isMobile(context) ? context.h(18) : context.h(20));

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(context.h(6)),
          hoverColor: hoverColor ?? colors.surfaceVariant,
          child: SizedBox(
            width: resolvedSize,
            height: resolvedSize,
            child: Center(
              child: Icon(
                icon,
                size: resolvedIconSize,
                color: iconColor ?? colors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}