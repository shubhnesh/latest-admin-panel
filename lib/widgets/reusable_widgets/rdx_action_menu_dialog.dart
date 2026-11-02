import 'package:flutter/material.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';

class RdxActionMenuItem {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool enabled;

  const RdxActionMenuItem({
    this.icon,
    this.title,
    this.subtitle,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
    this.onTap,
    this.enabled = true,
  });
}

class RdxActionMenuDialog extends StatelessWidget {
  final List<RdxActionMenuItem> items;

  /// Optional title.
  /// If null, no title is shown.
  final String? title;

  /// Optional subtitle.
  /// If null, no subtitle is shown.
  final String? subtitle;

  /// Global top-left position of the widget
  /// that opened this menu.
  final Offset? position;

  /// Optional maximum width.
  ///
  /// The actual width remains content-driven.
  final double? maxWidth;

  /// Optional maximum height. If null, the menu grows to fit its content
  /// with no scrolling. Only pass this if you explicitly want the menu
  /// capped (e.g. a very long list of items) — in that case wrap the
  /// content in your own scroll view via a custom item list, since this
  /// widget no longer scrolls internally.
  final double? maxHeight;

  /// Padding around the complete menu.
  /// NOTE: default value below can't call context.h()/context.w() since
  /// default parameter values must be compile-time constants — it's
  /// scaled at the point of use in build() instead.
  final EdgeInsetsGeometry contentPadding;

  /// Padding inside each action item.
  /// Same note as [contentPadding] — scaled at point of use.
  final EdgeInsetsGeometry itemPadding;

  final bool showCloseButton;
  final bool showDivider;

  final Color? backgroundColor;
  final Color? barrierColor;

  final double borderRadius;
  final double elevation;

  /// Distance between the three-dot button
  /// and the action menu.
  final double gap;

  const RdxActionMenuDialog({
    super.key,
    required this.items,
    this.title,
    this.subtitle,
    this.position,
    this.maxWidth,
    this.maxHeight,
    this.contentPadding = const EdgeInsets.all(5),
    this.itemPadding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 8,
    ),
    this.showCloseButton = false,
    this.showDivider = false,
    this.backgroundColor,
    this.barrierColor = Colors.transparent,
    this.borderRadius = 9,
    this.elevation = 8,
    this.gap = 4,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final menu = IntrinsicWidth(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: context.w(0),
          maxWidth: maxWidth ?? context.w(90),
          // No forced small default anymore — let the menu grow to fit
          // its content. Only clamp if the caller explicitly passes one.
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: Material(
          color: backgroundColor ?? colors.surface,
          elevation: context.h(elevation),
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(context.w(borderRadius)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: contentPadding is EdgeInsets
                ? EdgeInsets.fromLTRB(
                    context.w((contentPadding as EdgeInsets).left),
                    context.h((contentPadding as EdgeInsets).top),
                    context.w((contentPadding as EdgeInsets).right),
                    context.h((contentPadding as EdgeInsets).bottom),
                  )
                : contentPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null || subtitle != null || showCloseButton)
                  _buildHeader(context),
                if ((title != null || subtitle != null || showCloseButton) &&
                    showDivider)
                  Divider(
                    height: context.h(1),
                    color: colors.divider,
                  ),
                ..._buildItems(context),
              ],
            ),
          ),
        ),
      ),
    );

    // If no position is supplied, behave like a normal
    // centered dialog.
    if (position == null) {
      return Center(
        child: menu,
      );
    }

    // When position is supplied, position the menu
    // relative to the three-dot button.
    return CustomSingleChildLayout(
      delegate: _RdxActionMenuPositionDelegate(
        position: position!,
        screenSize: MediaQuery.sizeOf(context),
        margin: context.w(8),
        gap: context.w(gap),
      ),
      child: menu,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(7),
        context.h(5),
        context.w(4),
        context.h(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || subtitle != null)
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.section(context),
                    ),
                  if (subtitle != null) ...[
                    SizedBox(height: context.h(2)),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label(context).copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (showCloseButton) ...[
            SizedBox(width: context.w(8)),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(context.w(6)),
              child: SizedBox(
                width: context.w(28),
                height: context.h(28),
                child: Icon(
                  Icons.close,
                  size: context.w(18),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    final widgets = <Widget>[];

    for (int index = 0; index < items.length; index++) {
      final item = items[index];

      widgets.add(
        _RdxActionMenuTile(
          item: item,
          padding: itemPadding is EdgeInsets
              ? EdgeInsets.symmetric(
                  horizontal: context.w((itemPadding as EdgeInsets).horizontal / 2),
                  vertical: context.h((itemPadding as EdgeInsets).vertical / 2),
                )
              : itemPadding,
          onTap: () {
            if (!item.enabled) return;

            Navigator.of(context).pop();
            item.onTap?.call();
          },
        ),
      );

      if (showDivider && index < items.length - 1) {
        widgets.add(
          Divider(
            height: context.h(1),
            color: AppColors.of(context).divider,
          ),
        );
      }
    }

    return widgets;
  }
}

class _RdxActionMenuPositionDelegate extends SingleChildLayoutDelegate {
  final Offset position;
  final Size screenSize;
  final double margin;
  final double gap;

  const _RdxActionMenuPositionDelegate({
    required this.position,
    required this.screenSize,
    required this.margin,
    required this.gap,
  });

  // NOTE: SingleChildLayoutDelegate has no BuildContext, so margin/gap
  // arrive here already pre-scaled by context.w()/context.h() from the
  // caller in build() above. The 0s below are true zero constraints
  // (no minimum size), not real "measurements", so there's nothing to
  // scale — scaling zero is still zero.
  @override
  BoxConstraints getConstraintsForChild(
    BoxConstraints constraints,
  ) {
    return BoxConstraints(
      minWidth: 0,
      minHeight: 0,
      maxWidth: screenSize.width - (margin * 2),
      maxHeight: screenSize.height - (margin * 2),
    );
  }

  @override
  Offset getPositionForChild(
    Size size,
    Size childSize,
  ) {
    // ------------------------------------------------------------
    // OPEN TO THE LEFT OF THE THREE-DOT BUTTON
    // ------------------------------------------------------------
    double left = position.dx - childSize.width - gap;

    // Vertically center the popup with the three-dot button.
    double top = position.dy;

    // ------------------------------------------------------------
    // KEEP INSIDE LEFT EDGE
    // ------------------------------------------------------------
    if (left < margin) {
      left = margin;
    }

    // ------------------------------------------------------------
    // KEEP INSIDE RIGHT EDGE
    // ------------------------------------------------------------
    if (left + childSize.width > screenSize.width - margin) {
      left = screenSize.width - childSize.width - margin;
    }

    // ------------------------------------------------------------
    // KEEP INSIDE TOP EDGE
    // ------------------------------------------------------------
    if (top < margin) {
      top = margin;
    }

    // ------------------------------------------------------------
    // KEEP INSIDE BOTTOM EDGE
    // ------------------------------------------------------------
    if (top + childSize.height > screenSize.height - margin) {
      top = screenSize.height - childSize.height - margin;
    }

    return Offset(left, top);
  }

  @override
  bool shouldRelayout(
    _RdxActionMenuPositionDelegate oldDelegate,
  ) {
    return oldDelegate.position != position ||
        oldDelegate.screenSize != screenSize ||
        oldDelegate.gap != gap;
  }
}

class _RdxActionMenuTile extends StatelessWidget {
  final RdxActionMenuItem item;
  final EdgeInsetsGeometry padding;
  final VoidCallback onTap;

  const _RdxActionMenuTile({
    required this.item,
    required this.padding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final textColor = item.enabled
        ? (item.textColor ?? colors.textPrimary)
        : colors.textMuted;

    final iconColor = item.enabled
        ? (item.iconColor ?? colors.textSecondary)
        : colors.textMuted;

    return Material(
      color: item.backgroundColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(context.w(7)),
      child: InkWell(
        onTap: item.enabled ? onTap : null,
        borderRadius: BorderRadius.circular(context.w(7)),
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: context.w(17),
                  color: iconColor,
                ),
                SizedBox(width: context.w(9)),
              ],
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.title != null)
                      Text(
                        item.title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label(context)
                            .copyWith(color: textColor),
                      ),
                    if (item.subtitle != null) ...[
                      SizedBox(height: context.h(2)),
                      Text(
                        item.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label(
                          context,
                        ).copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}