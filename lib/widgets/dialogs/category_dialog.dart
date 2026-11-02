import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_text_field.dart';

/// Shared entry dialog for Category / Preparation / Regionality / Tag.
///
/// When [enableSubItems] is true (or when any of the subcategory-related
/// params are provided), the dialog shows a single subcategory text field
/// plus an Add button. Subcategories are collected one-by-one into a chip
/// list with no hard upper limit — the user can add as many as they need.
///
/// When subcategory params are omitted the dialog is a simple name form
/// (used for preparation, regionality, and tags).
class CategoryEntryDialog<T> extends StatefulWidget {
  final String title;
  final String? editTitle;
  final String nameLabel;
  final String nameHint;
  final int nameMaxLength;
  final String? description;
  final String? initialName;
  final List<String> initialSubItems;
  final int? maxSubItems;
  final String? subItemsLabel;
  final String Function(int index)? subItemHintBuilder;

  /// Optional label for the primary action button (defaults to "Save").
  final String? saveButtonLabel;
  final Future<T> Function(String name, List<String> subNames) onSave;

  const CategoryEntryDialog({
    super.key,
    required this.title,
    this.editTitle,
    required this.nameLabel,
    required this.nameHint,
    this.nameMaxLength = 20,
    this.description,
    this.initialName,
    this.initialSubItems = const [],
    this.maxSubItems,
    this.subItemsLabel,
    this.subItemHintBuilder,
    this.saveButtonLabel,
    required this.onSave,
  });

  /// Convenience launcher. Returns the value produced by [onSave], or
  /// `null` if the user cancelled.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? editTitle,
    required String nameLabel,
    required String nameHint,
    int nameMaxLength = 20,
    String? description,
    String? initialName,
    List<String> initialSubItems = const [],
    int? maxSubItems,
    String? subItemsLabel,
    String Function(int index)? subItemHintBuilder,
    String? saveButtonLabel,
    required Future<T> Function(String name, List<String> subNames) onSave,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CategoryEntryDialog<T>(
        title: title,
        editTitle: editTitle,
        nameLabel: nameLabel,
        nameHint: nameHint,
        nameMaxLength: nameMaxLength,
        description: description,
        initialName: initialName,
        initialSubItems: initialSubItems,
        maxSubItems: maxSubItems,
        subItemsLabel: subItemsLabel,
        subItemHintBuilder: subItemHintBuilder,
        saveButtonLabel: saveButtonLabel,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CategoryEntryDialog<T>> createState() => _CategoryEntryDialogState<T>();
}

class _CategoryEntryDialogState<T> extends State<CategoryEntryDialog<T>> {
  late final TextEditingController _nameController;
  final TextEditingController _subItemController = TextEditingController();
  late final List<String> _subItems;
  bool _saving = false;
  String? _error;

  /// True when this dialog is being used for categories (sub-items UI).
  /// Driven by whether any subcategory-related param was passed so callers
  /// that only need a name field stay unaffected.
  bool get _showSubItems =>
      widget.subItemsLabel != null ||
      widget.subItemHintBuilder != null ||
      widget.initialSubItems.isNotEmpty ||
      widget.maxSubItems != null;

  bool get _isEditing =>
      widget.initialName != null && widget.initialName!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _subItems = List<String>.from(
      widget.initialSubItems.map((s) => s.trim()).where((s) => s.isNotEmpty),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subItemController.dispose();
    super.dispose();
  }

  void _addSubItem() {
    final value = _subItemController.text.trim();
    if (value.isEmpty) return;

    // Soft optional cap only if a caller still passes maxSubItems.
    if (widget.maxSubItems != null && _subItems.length >= widget.maxSubItems!) {
      setState(() {
        _error = 'You can add at most ${widget.maxSubItems} subcategories.';
      });
      return;
    }

    if (_subItems.any((s) => s.toLowerCase() == value.toLowerCase())) {
      _subItemController.clear();
      return;
    }

    setState(() {
      _subItems.add(value);
      _subItemController.clear();
      _error = null;
    });
  }

  void _removeSubItem(String name) {
    setState(() {
      _subItems.remove(name);
      _error = null;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a name.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final result = await widget.onSave(name, List<String>.from(_subItems));
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e is StateError || e is ArgumentError
            ? e
                .toString()
                .replaceFirst(RegExp(r'^(StateError|ArgumentError): '), '')
            : 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final dialogTitle =
        _isEditing ? (widget.editTitle ?? widget.title) : widget.title;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.h(12)),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.w(24),
        vertical: context.h(24),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.w(420)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.w(20),
            context.h(18),
            context.w(20),
            context.h(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                dialogTitle,
                style: AppTextStyles.section(context)
                    .copyWith(color: colors.textPrimary),
              ),
              if (widget.description != null &&
                  widget.description!.trim().isNotEmpty) ...[
                SizedBox(height: context.h(6)),
                Text(
                  widget.description!,
                  style: AppTextStyles.bodyTertiary(context)
                      .copyWith(color: colors.textSecondary),
                ),
              ],
              SizedBox(height: context.h(16)),
              RdxTextField(
                controller: _nameController,
                maxLength: widget.nameMaxLength,
                label: widget.nameLabel,
                hint: widget.nameHint,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              if (_showSubItems) ...[
                SizedBox(height: context.h(16)),
                Text(
                  widget.subItemsLabel ?? 'Subcategories (optional)',
                  style: AppTextStyles.bodySecondary(context)
                      .copyWith(color: colors.textMuted),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  _subItems.isEmpty
                      ? 'Add one at a time — no limit.'
                      : '${_subItems.length} subcategor'
                          '${_subItems.length == 1 ? 'y' : 'ies'} added',
                  style: AppTextStyles.bodyTertiary(context)
                      .copyWith(color: colors.textMuted),
                ),
                SizedBox(height: context.h(8)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RdxTextField(
                        controller: _subItemController,
                        maxLength: 20,
                        hint: widget.subItemHintBuilder != null
                            ? widget.subItemHintBuilder!(_subItems.length)
                            : 'Add a subcategory and press Add',
                        onSubmitted: (_) => _addSubItem(),
                      ),
                    ),
                    SizedBox(width: context.w(8)),
                    Padding(
                      padding: EdgeInsets.only(top: context.h(0)),
                      child: RdxActionButton(
                        label: 'Add',
                        onPressed: _addSubItem,
                        isPrimary: true,
                        height: context.h(35),
                        minWidth: context.w(60),
                      ),
                    ),
                  ],
                ),
                if (_subItems.isNotEmpty) ...[
                  SizedBox(height: context.h(10)),
                  Wrap(
                    spacing: context.w(8),
                    runSpacing: context.h(8),
                    children: [
                      for (final name in _subItems)
                        _SubItemChip(
                          label: name,
                          colors: colors,
                          onDeleted: () => _removeSubItem(name),
                        ),
                    ],
                  ),
                ],
              ],
              if (_error != null) ...[
                SizedBox(height: context.h(10)),
                Text(
                  _error!,
                  style: AppTextStyles.bodyTertiary(context)
                      .copyWith(color: AppColors.danger),
                ),
              ],
              SizedBox(height: context.h(18)),
              Row(
                children: [
                  Expanded(
                    child: RdxActionButton(
                      label: 'Cancel',
                      isPrimary: false,
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: context.w(10)),
                  Expanded(
                    child: widget.saveButtonLabel != null
                        ? RdxActionButton(
                            label: widget.saveButtonLabel!,
                            isPrimary: true,
                            isLoading: _saving,
                            onPressed: _saving ? null : _submit,
                          )
                        : RdxActionButton.save(
                            isLoading: _saving,
                            onPressed: _submit,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubItemChip extends StatelessWidget {
  final String label;
  final AppColorScheme colors;
  final VoidCallback onDeleted;

  const _SubItemChip({
    required this.label,
    required this.colors,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: context.w(9),
        right: context.w(4),
        top: context.h(5),
        bottom: context.h(5),
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyTertiary(context),
          ),
          SizedBox(width: context.w(4)),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(context.h(10)),
            child: Padding(
              padding: EdgeInsets.all(context.h(2)),
              child: Icon(
                Icons.close_rounded,
                size: context.h(14),
                color: colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
