import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import 'rdx_text_field.dart';

/// Shared search field used across Inventory, Menu, Coupons, and elsewhere.
///
/// Default outer height matches Inventory (`context.h(40)`). Text and hint
/// are vertically centered in every size (same technique as [RdxTextField]).
class RdxSearchBar extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  final VoidCallback? onClear;

  final double? width;
  final double? height;

  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  final Widget? leading;
  final Widget? trailing;

  final bool enabled;
  final bool readOnly;
  final bool autofocus;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;

  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? hintColor;

  final double borderRadius;
  final double borderWidth;

  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  final bool showClearButton;

  /// Canonical height used by Inventory and every other screen.
  static double standardHeight(BuildContext context) =>
      context.h(40).clamp(32.0, 48.0);

  const RdxSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.leading,
    this.trailing,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction = TextInputAction.search,
    this.keyboardType,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.hintColor,
    this.borderRadius = 10,
    this.borderWidth = 1,
    this.textStyle,
    this.hintStyle,
    this.showClearButton = true,
  });

  @override
  State<RdxSearchBar> createState() => _RdxSearchBarState();
}

/// Shared page toolbar: search + optional trailing actions.
/// Always uses [RdxSearchBar.standardHeight] so Menu/Coupons match Inventory.
class RdxSearchToolbar extends StatelessWidget implements PreferredSizeWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final List<Widget> actions;
  final EdgeInsetsGeometry? padding;

  const RdxSearchToolbar({
    super.key,
    this.hintText = 'Search...',
    this.controller,
    this.onChanged,
    this.actions = const [],
    this.padding,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 480;
    final searchHeight = RdxSearchBar.standardHeight(context);
    final search = RdxSearchBar(
      height: searchHeight,
      hintText: hintText,
      controller: controller,
      onChanged: onChanged,
    );

    if (narrow && actions.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          search,
          SizedBox(height: context.h(10)),
          Wrap(
            spacing: context.w(10),
            runSpacing: context.h(8),
            alignment: WrapAlignment.end,
            children: [
              for (final action in actions)
                SizedBox(height: searchHeight, child: action),
            ],
          ),
        ],
      );
    }

    return SizedBox(
      height: searchHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: search),
          for (final action in actions) ...[
            SizedBox(width: context.w(14)),
            SizedBox(height: searchHeight, child: action),
          ],
        ],
      ),
    );
  }
}

class _RdxSearchBarState extends State<RdxSearchBar> {
  late final TextEditingController _internalController;
  late final FocusNode _internalFocusNode;

  bool _ownsController = false;
  bool _ownsFocusNode = false;

  TextEditingController get _controller =>
      widget.controller ?? _internalController;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      _internalController = TextEditingController();
      _ownsController = true;
    } else {
      _internalController = widget.controller!;
    }

    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
      _ownsFocusNode = true;
    } else {
      _internalFocusNode = widget.focusNode!;
    }

    _controller.addListener(_controllerListener);
    _focusNode.addListener(_focusListener);
  }

  @override
  void dispose() {
    _controller.removeListener(_controllerListener);
    _focusNode.removeListener(_focusListener);

    if (_ownsController) {
      _internalController.dispose();
    }

    if (_ownsFocusNode) {
      _internalFocusNode.dispose();
    }

    super.dispose();
  }

  void _controllerListener() {
    if (mounted) setState(() {});
  }

  void _focusListener() {
    if (mounted) setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = _controller.text.isNotEmpty;
    final colors = AppColors.of(context);

    final double effectiveHeight =
        (widget.height ?? RdxSearchBar.standardHeight(context))
            .clamp(32.0, 56.0);

    // Same text style family as RdxTextField
    // height: 1.0 prevents the previous 1.2 line-height from pushing text up
    final textStyle = widget.textStyle ??
        AppTextStyles.label(context).copyWith(
          fontSize: RdxTextField.textFontSize(context),
          color: widget.textColor ?? colors.textPrimary,
          height: 1.0,
        );
    final hintStyle = widget.hintStyle ??
        AppTextStyles.label(context).copyWith(
          fontSize: RdxTextField.textFontSize(context),
          color: widget.hintColor ?? colors.textMuted,
          height: 1.0,
        );

    final double fontSize =
        textStyle.fontSize ?? RdxTextField.fontSize(context);

    return SizedBox(
      width: widget.width,
      height: effectiveHeight,
      child: Container(
        margin: widget.margin,
        padding: widget.padding ??
            EdgeInsets.symmetric(
              horizontal: RdxTextField.horizontalPad(context),
            ),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(
            context.h(8).clamp(6.0, 8.0),
          ),
          border: Border.all(
            color: widget.borderColor ?? colors.border,
            width: widget.borderWidth,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            widget.leading ??
                Icon(
                  Icons.search_rounded,
                  size: context.h(20).clamp(14.0, 20.0),
                  color: widget.hintColor ?? colors.textMuted,
                ),
            SizedBox(width: context.w(8)),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                readOnly: widget.readOnly,
                autofocus: widget.autofocus,
                textInputAction: widget.textInputAction,
                keyboardType: widget.keyboardType,
                maxLines: 1,
                textAlignVertical: TextAlignVertical.center,
                style: textStyle,
                cursorColor: AppColors.primary,
                cursorHeight: fontSize * 1.1,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: hintStyle,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  filled: true,
                  fillColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (widget.showClearButton && hasText)
              GestureDetector(
                onTap: _clear,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.only(left: context.w(6)),
                  child: Icon(
                    Icons.close_rounded,
                    size: context.h(18).clamp(14.0, 18.0),
                    color: colors.textMuted,
                  ),
                ),
              ),
            if (widget.trailing != null) ...[
              SizedBox(width: context.w(6)),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
