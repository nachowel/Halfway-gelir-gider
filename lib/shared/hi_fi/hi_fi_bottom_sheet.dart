import 'package:flutter/material.dart';

import '../widgets/app_sheet.dart';

/// Warm rounded bottom sheet surface extracted from hi-fi `.sheet`.
/// Used for modal flows that must keep the same border, radius, handle, and
/// soft upward shadow without falling back to generic Material sheets.
class HiFiBottomSheet extends StatelessWidget {
  const HiFiBottomSheet({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 12, 18, 22),
    this.showHandle = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    return AppSheet(padding: padding, showHandle: showHandle, child: child);
  }
}
