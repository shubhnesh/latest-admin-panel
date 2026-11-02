import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../buttons/rdx_action_button.dart';

class RdxDeleteDialog extends StatelessWidget {
  /// Main dialog title.
  final String title;

  /// Name/title of the item being deleted.
  final String itemName;

  /// Optional custom content displayed inside the item summary section.
  ///
  /// The caller decides what to show here:
  /// category, metrics, description, dates, etc.
  final List<Widget> itemDetails;

  /// Warning heading.
  final String? warningTitle;

  /// Warning message.
  final String warningMessage;

  /// Text displayed on the delete button.
  final String deleteButtonLabel;

  /// Text displayed on the cancel button.
  final String cancelButtonLabel;

  /// Dialog maximum width.
  final double? maxWidth;

  /// Dialog padding.
  final EdgeInsetsGeometry? padding;

  /// Whether the close button should be shown.
  final bool showCloseButton;

  /// Whether the item summary container should be shown.
  final bool showItemSummary;

  /// Whether the warning section should be shown.
  final bool showWarning;

  /// Optional custom warning icon.
  final IconData warningIcon;

  const RdxDeleteDialog({
    super.key,
    required this.title,
    required this.itemName,
    required this.warningMessage,
    this.itemDetails = const [],
    this.warningTitle = 'IRREVERSIBLE ACTION',
    this.deleteButtonLabel = 'Delete',
    this.cancelButtonLabel = 'Cancel',
    this.maxWidth,
    this.padding,
    this.showCloseButton = true,
    this.showItemSummary = true,
    this.showWarning = true,
    this.warningIcon = Icons.warning_amber_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.h(14)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? context.w(420),
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.all(context.h(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showItemSummary) _buildItemSummary(context),
              if (showWarning) ...[
                SizedBox(height: context.h(14)),
                _buildWarning(context),
              ],
              SizedBox(height: context.h(20)),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildHeader(BuildContext context) {
  //   final colors = AppColors.of(context);

  //   return Row(
  //     children: [
  //       Expanded(
  //         child: Text(
  //           title,
  //           style: AppTextStyles.section(context),
  //         ),
  //       ),
  //       if (showCloseButton)
  //         IconButton(
  //           icon: Icon(
  //             Icons.close,
  //             size: context.h(20),
  //             color: colors.textMuted,
  //           ),
  //           onPressed: () => Navigator.of(context).pop(false),
  //           padding: EdgeInsets.zero,
  //           constraints: BoxConstraints(
  //             minWidth: context.w(30),
  //             minHeight: context.h(30),
  //           ),
  //         ),
  //     ],
  //   );
  // }

  Widget _buildItemSummary(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  itemName,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (itemDetails.isNotEmpty) ...[
            SizedBox(height: context.h(5)),
            ..._buildDetails(context),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDetails(BuildContext context) {
    final widgets = <Widget>[];

    for (int i = 0; i < itemDetails.length; i++) {
      widgets.add(itemDetails[i]);

      if (i < itemDetails.length - 1) {
        widgets.add(
          SizedBox(height: context.h(10)),
        );
      }
    }

    return widgets;
  }

  Widget _buildWarning(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.h(12)),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warningIcon,
            color: AppColors.danger,
            size: context.h(20),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (warningTitle != null)
                  Text(
                    warningTitle!,
                    style: AppTextStyles.label(context).copyWith(
                      color: AppColors.danger,
                      letterSpacing: 0.5,
                    ),
                  ),
                if (warningTitle != null) SizedBox(height: context.h(4)),
                Text(
                  warningMessage,
                  style: AppTextStyles.body(context).copyWith(
                    color: AppColors.danger,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 420;
    final cancel = RdxActionButton.discard(
      label: cancelButtonLabel,
      onPressed: () => Navigator.of(context).pop(false),
    );
    final delete = RdxActionButton(
      label: deleteButtonLabel,
      onPressed: () => Navigator.of(context).pop(true),
      isPrimary: true,
      iconSize: context.h(18),
      backgroundColor: AppColors.danger,
      textColor: Colors.white,
      iconColor: Colors.white,
    );
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          delete,
          SizedBox(height: context.h(10)),
          cancel,
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        cancel,
        SizedBox(width: context.w(10)),
        delete,
      ],
    );
  }
}

/// Generic metric/detail widget used inside reusable dialogs.
class RdxDeleteMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? labelColor;
  final TextStyle? valueStyle;

  const RdxDeleteMetric({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.labelColor,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: context.h(13),
                color: labelColor ?? colors.textMuted,
              ),
              SizedBox(width: context.w(5)),
            ],
            Text(
              label,
              style: AppTextStyles.label(context).copyWith(
                color: labelColor ?? colors.textMuted,
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(2)),
        Text(
          value,
          style: valueStyle ?? AppTextStyles.body(context),
        ),
      ],
    );
  }
}
