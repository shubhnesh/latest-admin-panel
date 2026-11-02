import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';

class RdxToggleButton extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double? width;
  final double? height;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool enabled;

  const RdxToggleButton({
    super.key,
    required this.value,
    required this.onChanged,
    this.width,
    this.height,
    this.activeColor,
    this.inactiveColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final toggleWidth = width ?? context.w(30).clamp(28.0, 30.0);
    final toggleHeight = height ?? context.h(16).clamp(12.0, 16.0);
    final inset = context.h(1).clamp(0.75, 1.0);
    final thumbSize = toggleHeight - inset * 2;
    final active = activeColor ?? AppColors.primary;
    final inactive = inactiveColor ?? colors.textMuted;
    final currentColor = enabled && value ? active : inactive;

    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(toggleHeight),
      child: Container(
        width: toggleWidth,
        height: toggleHeight,
        padding: EdgeInsets.all(inset),
        decoration: BoxDecoration(
          color: currentColor.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(toggleHeight),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment:
              enabled && value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              color: currentColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
