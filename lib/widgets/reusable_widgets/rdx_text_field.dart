import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';

class RdxTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? initialValue;
  final int maxLines;
  final int? minLines;
  final int maxLength;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? prefixText;
  final String? counterText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  /// Controls keyboard auto-capitalization.
  /// Defaults to [TextCapitalization.sentences] so the first letter starts
  /// capital; the user can still type lowercase if they want.
  final TextCapitalization textCapitalization;

  const RdxTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.maxLines = 1,
    this.minLines,
    required this.maxLength,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.suffixIcon,
    this.prefixIcon,
    this.prefixText,
    this.counterText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.textInputAction,
    this.focusNode,
    this.textCapitalization = TextCapitalization.sentences,
  })  : assert(maxLines > 0),
        assert(minLines == null || minLines > 0),
        assert(minLines == null || minLines <= maxLines);

  /// Shared sizing constants with [RdxDropdown] trigger.
  static double verticalPad(BuildContext context) =>
      context.h(17).clamp(9.0, 17.0);

  static double horizontalPad(BuildContext context) =>
      context.w(12).clamp(8.0, 12.0);

  static double fontSize(BuildContext context) =>
      context.h(14).clamp(12.0, 14.0);

  static double textFontSize(BuildContext context) =>
      context.h(16).clamp(12.0, 16.0);

  /// Exact outer height of a single-line field / dropdown trigger.
  static double singleLineHeight(BuildContext context) {
    final fs = fontSize(context);
    final vp = verticalPad(context);
    const lineHeightFactor = 1.2;
    // text line + top/bottom padding + 1px border top/bottom
    return (fs * lineHeightFactor) + (vp * 2) + 2;
  }

  @override
  State<RdxTextField> createState() => _RdxTextFieldState();
}

class _RdxTextFieldState extends State<RdxTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    widget.controller?.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    widget.controller?.removeListener(_handleTextChange);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() => setState(() {});

  void _handleTextChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isMultiline = widget.maxLines > 1;
    final effectiveMinLines =
        isMultiline ? (widget.minLines ?? widget.maxLines) : 1;
    final hasText = widget.controller?.text.isNotEmpty == true ||
        (widget.controller == null && widget.initialValue?.isNotEmpty == true);

    final hPad = RdxTextField.horizontalPad(context);
    final vPad = RdxTextField.verticalPad(context);
    final fs = RdxTextField.fontSize(context);
    final textFontSize = RdxTextField.textFontSize(context);
    final radius = BorderRadius.circular(context.h(8).clamp(6.0, 8.0));
    const lineHeightFactor = 1.2;

    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.border, width: 1),
    );
    final fieldHeight = isMultiline
        ? (fs * lineHeightFactor * widget.maxLines) + (vPad * 2) + 2
        : RdxTextField.singleLineHeight(context);
    final field = SizedBox(
      height: fieldHeight,
      child: TextFormField(
        controller: widget.controller,
        initialValue: widget.controller == null ? widget.initialValue : null,
        // Cap visible lines; overflow scrolls inside the field.
        maxLines: isMultiline ? widget.maxLines : 1,
        minLines: isMultiline ? effectiveMinLines : 1,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType ??
            (isMultiline ? TextInputType.multiline : TextInputType.text),
        obscureText: widget.obscureText,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        onTap: widget.onTap,
        validator: widget.validator,
        inputFormatters: widget.inputFormatters,
        textInputAction: widget.textInputAction ??
            (isMultiline ? TextInputAction.newline : TextInputAction.done),
        textCapitalization: widget.textCapitalization,
        focusNode: _focusNode,
        textAlignVertical:
            isMultiline ? TextAlignVertical.top : TextAlignVertical.center,
        style: AppTextStyles.bodySecondary(context)
            .copyWith(fontSize: textFontSize),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTextStyles.bodySecondary(context)
              .copyWith(color: colors.textMuted, fontSize: textFontSize),
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          prefixText: widget.prefixText,
          prefixStyle: AppTextStyles.bodySecondary(context).copyWith(
            fontSize: textFontSize,
          ),
          counterText: widget.counterText ?? '',
          filled: true,
          fillColor: _focusNode.hasFocus || hasText
              ? Colors.white
              : colors.surfaceVariant,
          hoverColor: Colors.transparent,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: hPad,
            vertical: vPad,
          ),
          border: border,
          enabledBorder: border,
          disabledBorder: border,
          focusedBorder: border,
          errorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: AppColors.danger, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
          ),
        ),
      ),
    );

    if (widget.label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label!,
          style: AppTextStyles.bodySecondary(context)
              .copyWith(color: colors.textMuted),
        ),
        SizedBox(height: context.h(6).clamp(4.0, 6.0)),
        field,
      ],
    );
  }
}
