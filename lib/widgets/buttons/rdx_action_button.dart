import 'package:flutter/material.dart';

import 'package:rdx_admin/core/theme/text_styles.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';

/// Single form action button for Save / Discard footers.
///
/// Icons and colors are optional and can be customized by the screen.
class RdxActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final bool enabled;
  final double? height;
  final double? minWidth;

  // Optional icons.
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? iconSize;

  // Optional colors.
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final Color? borderColor;

  // Optional disabled colors.
  final Color? disabledBackgroundColor;
  final Color? disabledTextColor;
  final Color? disabledIconColor;

  const RdxActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.enabled = true,
    this.height,
    this.minWidth,
    this.leadingIcon,
    this.trailingIcon,
    this.iconSize,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.borderColor,
    this.disabledBackgroundColor,
    this.disabledTextColor,
    this.disabledIconColor,
  });

  const RdxActionButton.save({
    super.key,
    this.label = 'Done',
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.height,
    this.minWidth,
    this.leadingIcon,
    this.trailingIcon,
    this.iconSize,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.borderColor,
    this.disabledBackgroundColor,
    this.disabledTextColor,
    this.disabledIconColor,
  }) : isPrimary = true;

  const RdxActionButton.discard({
    super.key,
    this.label = 'Discard',
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.height,
    this.minWidth,
    this.leadingIcon,
    this.trailingIcon,
    this.iconSize,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.borderColor,
    this.disabledBackgroundColor,
    this.disabledTextColor,
    this.disabledIconColor,
  }) : isPrimary = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final btnHeight = height ?? context.h(40).clamp(32.0, 40.0);

    // Keep primary actions on-brand and secondary actions visually neutral.
    final defaultTextColor = isPrimary ? Colors.white : colors.textPrimary;

    final resolvedTextColor = textColor ?? defaultTextColor;

    final resolvedIconColor = iconColor ?? resolvedTextColor;

    final resolvedBackgroundColor = backgroundColor ??
        (isPrimary ? AppColors.primary : const Color(0xFFF1F2F4));

    final resolvedBorderColor =
        borderColor ?? (isPrimary ? Colors.transparent : colors.border);

    final resolvedDisabledBackgroundColor = disabledBackgroundColor ??
        (isPrimary ? const Color(0xFFE0E0E0) : const Color(0xFFF5F5F5));

    final resolvedDisabledTextColor = disabledTextColor ??
        (isPrimary
            ? const Color(0xFF757575)
            : colors.textPrimary.withAlpha(120));
    final resolvedDisabledIconColor =
        disabledIconColor ?? resolvedDisabledTextColor;
    final isDisabled = !enabled || isLoading || onPressed == null;
    final effectiveTextColor =
        isDisabled ? resolvedDisabledTextColor : resolvedTextColor;
    final effectiveIconColor =
        isDisabled ? resolvedDisabledIconColor : resolvedIconColor;

    final textStyle =
        AppTextStyles.section(context).copyWith(color: effectiveTextColor);

    final child = isLoading
        ? SizedBox(
            height: context.h(18).clamp(14.0, 18.0),
            width: context.h(18).clamp(14.0, 18.0),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: effectiveIconColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: (iconSize ?? context.h(24)).clamp(14.0, 24.0),
                  color: effectiveIconColor,
                ),
                SizedBox(width: context.w(8).clamp(5.0, 8.0)),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
              ),
              if (trailingIcon != null) ...[
                SizedBox(width: context.w(8).clamp(5.0, 8.0)),
                Icon(
                  trailingIcon,
                  size: (iconSize ?? context.h(24)).clamp(14.0, 24.0),
                  color: effectiveIconColor,
                ),
              ],
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(context.h(8)),
    );

    if (isPrimary) {
      return SizedBox(
        height: btnHeight,
        width: minWidth,
        child: ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: resolvedBackgroundColor,
            foregroundColor: resolvedTextColor,
            disabledBackgroundColor: resolvedDisabledBackgroundColor,
            disabledForegroundColor: resolvedDisabledTextColor,
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: context.w(16).clamp(10.0, 16.0),
            ),
            shape: shape,
            minimumSize: Size(
              minWidth ?? 0,
              btnHeight,
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      height: btnHeight,
      width: minWidth,
      child: OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: resolvedBackgroundColor,
          foregroundColor: resolvedTextColor,
          disabledBackgroundColor: resolvedDisabledBackgroundColor,
          disabledForegroundColor: resolvedDisabledTextColor,
          side: BorderSide(
            color: resolvedBorderColor,
            width: 1,
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: context.w(16).clamp(10.0, 16.0),
          ),
          shape: shape,
          minimumSize: Size(
            minWidth ?? 0,
            btnHeight,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: child,
      ),
    );
  }
}
