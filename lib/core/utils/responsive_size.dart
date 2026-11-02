import 'package:flutter/material.dart';

/// Responsive sizing utilities for the RDX Admin app.
///
/// Breakpoints:
/// - mobile:  < 600
/// - tablet:  600 – 1099
/// - desktop: ≥ 1100
///
/// Use [isNarrow] for "stack into a column" decisions (anything under 900).
/// Use [useBottomNav] to switch from side rail to bottom navigation.
class Responsive {
  Responsive._();

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1100;
  static const double narrowBreakpoint = 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// True when the layout should collapse into a single column (phone + small tablet).
  static bool isNarrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < narrowBreakpoint;

  /// Use bottom navigation instead of side rail (phones and tablets < 1100).
  static bool useBottomNav(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tabletBreakpoint;

  /// Grid column count for card grids (menu, coupons, etc.).
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 480) return 1;
    if (width < 700) return 2;
    if (width < 1100) return 3;
    return 4;
  }

  /// How many stat cards to show per row.
  /// Prefer keeping cards in the same row when space allows.
  static int statColumns(BuildContext context, {int max = 5}) {
    final width = MediaQuery.sizeOf(context).width;
    int cols;
    if (width < 360) {
      cols = 1;
    } else if (width < 520) {
      cols = 2;
    } else if (width < 780) {
      cols = 3;
    } else if (width < 1100) {
      cols = 4;
    } else {
      cols = 5;
    }
    return cols.clamp(1, max);
  }

  /// Horizontal page inset that scales with width.
  static double pageHorizontal(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 400) return 10;
    if (width < 600) return 12;
    if (width < 1100) return 20;
    return 32;
  }

  /// Standard page padding. Optional [top] / [bottom] overrides.
  static EdgeInsets pagePadding(
    BuildContext context, {
    double? top,
    double? bottom,
  }) {
    final horizontal = pageHorizontal(context);
    return EdgeInsets.fromLTRB(
      horizontal,
      top ?? 16,
      horizontal,
      bottom ?? 16,
    );
  }

  /// Padding used by search toolbars.
  static EdgeInsets toolbarPadding(BuildContext context) {
    final horizontal = pageHorizontal(context);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 10);
  }

  /// Bottom nav bar height (includes safe area consideration by caller).
  static double bottomNavHeight(BuildContext context) {
    return context.h(48).clamp(44.0, 56.0);
  }

  /// Builds a responsive row that becomes a column on narrow screens.
  /// Each child is expanded equally when in a row.
  static Widget adaptiveRow({
    required BuildContext context,
    required List<Widget> children,
    double spacing = 12,
    double runSpacing = 12,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    bool forceColumn = false,
  }) {
    final narrow = forceColumn || isNarrow(context);
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: runSpacing),
            children[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  /// Same as [adaptiveRow] but children keep their intrinsic width (not Expanded).
  static Widget adaptiveRowIntrinsic({
    required BuildContext context,
    required List<Widget> children,
    double spacing = 12,
    double runSpacing = 12,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    bool forceColumn = false,
  }) {
    final narrow = forceColumn || isNarrow(context);
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: runSpacing),
            children[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          children[i],
        ],
      ],
    );
  }

  /// Lays out [children] in a grid that keeps as many items per row as possible
  /// without overflow. Ideal for stat cards.
  static Widget adaptiveStatGrid({
    required BuildContext context,
    required List<Widget> children,
    int? maxColumns,
    double spacing = 12,
    double runSpacing = 12,
  }) {
    final cols = statColumns(context, max: maxColumns ?? children.length);
    if (cols >= children.length) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              Expanded(child: children[i]),
            ],
          ],
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += cols) {
      final end = (i + cols).clamp(0, children.length);
      final slice = children.sublist(i, end);
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < slice.length; j++) ...[
                if (j > 0) SizedBox(width: spacing),
                Expanded(child: slice[j]),
              ],
              for (var j = slice.length; j < cols; j++) ...[
                SizedBox(width: spacing),
                const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: runSpacing),
          rows[i],
        ],
      ],
    );
  }
}

extension ResponsiveContext on BuildContext {
  /// Scale a design-width value to the current screen width.
  /// Design reference width = 1440. Clamped more tightly on very small screens.
  double w(double size) {
    final screenWidth = MediaQuery.sizeOf(this).width;
    final scale = (screenWidth / 1440).clamp(0.55, 1.25);
    return size * scale;
  }

  /// Scale a design-height value to the current screen height.
  /// Design reference height = 900.
  double h(double size) {
    final screenHeight = MediaQuery.sizeOf(this).height;
    final scale = (screenHeight / 900).clamp(0.55, 1.25);
    return size * scale;
  }

  /// Convenience alias for [Responsive.pagePadding].
  EdgeInsets defaultScreenPadding() => Responsive.pagePadding(this);

  bool get isNarrow => Responsive.isNarrow(this);
  bool get isMobile => Responsive.isMobile(this);
  bool get isDesktop => Responsive.isDesktop(this);
  bool get useBottomNav => Responsive.useBottomNav(this);

  /// Scaled font size that stays readable on small screens.
  double sp(double size) {
    final screenWidth = MediaQuery.sizeOf(this).width;
    final scale = (screenWidth / 1440).clamp(0.75, 1.15);
    return size * scale;
  }
}
