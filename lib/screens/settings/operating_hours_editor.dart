import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/buttons/rdx_toggle_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../providers/settings_provider.dart';

class OperatingHoursEditor extends ConsumerStatefulWidget {
  const OperatingHoursEditor({super.key});

  @override
  ConsumerState<OperatingHoursEditor> createState() =>
      _OperatingHoursEditorState();
}

class _OperatingHoursEditorState extends ConsumerState<OperatingHoursEditor> {
  late String _weekdaysOpen;
  late String _weekdaysClose;
  late String _weekendsOpen;
  late String _weekendsClose;
  late bool _weekdaysEnabled;
  late bool _weekendsEnabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _weekdaysOpen = _to12h(settings.weekdays.open, true);
    _weekdaysClose = _to12h(settings.weekdays.close, false);
    _weekendsOpen = _to12h(settings.weekends.open, true);
    _weekendsClose = _to12h(settings.weekends.close, false);
    _weekdaysEnabled = settings.weekdays.isOpen;
    _weekendsEnabled = settings.weekends.isOpen;
  }

  String _to12h(String value, bool opening) {
    final cleaned = value.trim().toUpperCase();
    final isPm = cleaned.endsWith('PM');
    final isAm = cleaned.endsWith('AM');
    final numeric = isPm || isAm
        ? cleaned.substring(0, cleaned.length - 2).trim()
        : cleaned;
    final parts = numeric.split(':');
    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    if (isPm && hour != 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final suffix = opening ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $suffix';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await ref.read(settingsProvider).saveOperatingHours(
          weekdaysHours: OperatingHours(
            open: _weekdaysOpen,
            close: _weekdaysClose,
            isOpen: _weekdaysEnabled,
          ),
          weekendsHours: OperatingHours(
            open: _weekendsOpen,
            close: _weekendsClose,
            isOpen: _weekendsEnabled,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              ok ? 'Operating hours saved' : 'Failed to save operating hours')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        _HoursRow(
          label: 'Weekdays',
          openText: _weekdaysOpen,
          closeText: _weekdaysClose,
          isOpen: _weekdaysEnabled,
          colors: colors,
          onChanged: (value) => setState(() => _weekdaysEnabled = value),
          onOpenChanged: (value) => setState(() => _weekdaysOpen = value),
          onCloseChanged: (value) => setState(() => _weekdaysClose = value),
        ),
        _HoursRow(
          label: 'Weekends',
          openText: _weekendsOpen,
          closeText: _weekendsClose,
          isOpen: _weekendsEnabled,
          colors: colors,
          onChanged: (value) => setState(() => _weekendsEnabled = value),
          onOpenChanged: (value) => setState(() => _weekendsOpen = value),
          onCloseChanged: (value) => setState(() => _weekendsClose = value),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: RdxActionButton(
            label: 'Save hours',
            isPrimary: true,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
            minWidth: context.w(120),
          ),
        ),
      ],
    );
  }
}

class _HHMMInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    if (digits.length >= 2) {
      var hour = int.tryParse(digits.substring(0, 2)) ?? 1;
      if (hour < 1) hour = 1;
      if (hour > 12) hour = 12;
      digits = hour.toString().padLeft(2, '0') + digits.substring(2);
    }
    if (digits.length >= 4) {
      var minute = int.tryParse(digits.substring(2, 4)) ?? 0;
      if (minute > 59) minute = 59;
      digits = digits.substring(0, 2) + minute.toString().padLeft(2, '0');
    }
    final text = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}:${digits.substring(2)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _HoursRow extends StatelessWidget {
  final String label;
  final String openText;
  final String closeText;
  final bool isOpen;
  final AppColorScheme colors;
  final ValueChanged<bool> onChanged;
  final ValueChanged<String> onOpenChanged;
  final ValueChanged<String> onCloseChanged;

  const _HoursRow({
    required this.label,
    required this.openText,
    required this.closeText,
    required this.isOpen,
    required this.colors,
    required this.onChanged,
    required this.onOpenChanged,
    required this.onCloseChanged,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    final times = Row(
      children: [
        Expanded(
            child: _ProfileTime(
                text: openText,
                opening: true,
                colors: colors,
                onChanged: onOpenChanged)),
        SizedBox(width: context.w(12)),
        Expanded(
            child: _ProfileTime(
                text: closeText,
                opening: false,
                colors: colors,
                onChanged: onCloseChanged)),
      ],
    );
    final toggle = RdxToggleButton(value: isOpen, onChanged: onChanged);
    final title = Row(
      children: [
        Expanded(
            child: Text(label,
                style: AppTextStyles.bodySecondary(context)
                    .copyWith(color: colors.textSecondary))),
        toggle,
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [title, const SizedBox(height: 8), times])
          : Row(children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: AppTextStyles.bodySecondary(context)
                      .copyWith(color: colors.textSecondary),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: context.w(420)),
                    child: times,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: toggle,
                ),
              ),
            ]),
    );
  }
}

class _ProfileTime extends StatefulWidget {
  final String text;
  final bool opening;
  final AppColorScheme colors;
  final ValueChanged<String> onChanged;

  const _ProfileTime(
      {required this.text,
      required this.opening,
      required this.colors,
      required this.onChanged});

  @override
  State<_ProfileTime> createState() => _ProfileTimeState();
}

class _ProfileTimeState extends State<_ProfileTime> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text.split(' ').first);
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _editing) _commit();
  }

  void _commit() {
    final digits = _controller.text.replaceAll(':', '');
    final fallback = widget.text.split(' ').first.replaceAll(':', '');
    final padded = (digits.isEmpty ? fallback : digits).padRight(4, '0');
    var hour = int.tryParse(padded.substring(0, 2)) ?? 1;
    if (hour < 1) hour = 1;
    if (hour > 12) hour = 12;
    final minute = int.tryParse(padded.substring(2, 4)) ?? 0;
    final value =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} ${widget.opening ? 'AM' : 'PM'}';
    _controller.text = value;
    setState(() => _editing = false);
    widget.onChanged(value);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = BoxDecoration(
      color: widget.colors.background,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: widget.colors.border),
    );
    if (_editing) {
      return Container(
        height: 38,
        alignment: Alignment.center,
        decoration: box,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 5,
          inputFormatters: [_HHMMInputFormatter()],
          style: AppTextStyles.section(context)
              .copyWith(color: widget.colors.textPrimary),
          decoration: InputDecoration(
              isCollapsed: true,
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero),
          onSubmitted: (_) => _commit(),
        ),
      );
    }
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      onTap: () {
        setState(() => _editing = true);
        _controller.text = widget.text.split(' ').first;
        _controller.selection =
            TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _focusNode.requestFocus());
      },
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: box,
        child: Text(widget.text,
            style: AppTextStyles.section(context)
                .copyWith(color: widget.colors.textSecondary)),
      ),
    );
  }
}
