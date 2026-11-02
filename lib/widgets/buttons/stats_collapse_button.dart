import 'package:flutter/material.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';

import '../../core/theme/app_colors.dart';

/// Circular collapse/expand toggle, themed identically to [AppBackButton]
/// (same size, same surface/hover treatment). Shows a down chevron when
/// the stat cards are collapsed (tap to expand) and an up chevron when
/// they're expanded (tap to collapse).
class StatsCollapseButton extends StatefulWidget {
  final bool collapsed;
  final VoidCallback onPressed;

  const StatsCollapseButton({
    super.key,
    required this.collapsed,
    required this.onPressed,
  });

  @override
  State<StatsCollapseButton> createState() => _StatsCollapseButtonState();
}

class _StatsCollapseButtonState extends State<StatsCollapseButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Tooltip(
      message: widget.collapsed ? 'Show stats' : 'Hide stats',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: context.h(36),
            height: context.h(36),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hovering ? AppColors.primary : colors.surface,
              // border: Border.all(
              //   color: AppColors.primary,
              //   width: 1.5,
              // ),
            ),
            child: Center(
              child: Icon(
                widget.collapsed
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                size: context.h(22).clamp(16.0, 26.0),
                color:
                    _hovering ? AppColors.surface : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
