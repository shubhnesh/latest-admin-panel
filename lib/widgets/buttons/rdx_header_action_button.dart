import 'package:flutter/material.dart';

import '../../core/utils/responsive_size.dart';
import 'rdx_action_button.dart';

class RdxHeaderActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  const RdxHeaderActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final width = context.w(160).clamp(120.0, 160.0);
    final height = context.h(40).clamp(34.0, 40.0);

    return Tooltip(
      message: label,
      child: SizedBox(
        width: width,
        height: height,
        child: RdxActionButton(
          label: label,
          leadingIcon: icon,
          onPressed: onPressed,
          height: height,
        ),
      ),
    );
  }
}
