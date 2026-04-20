import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

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
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: AppDurations.fast,
        curve: AppEasing.standard,
        padding: EdgeInsets.fromLTRB(10, 0, 10, keyboardInset + 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheetTop),
              bottom: Radius.circular(AppRadius.sheetBottom),
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x2609282B),
                offset: Offset(0, -10),
                blurRadius: 40,
              ),
            ],
          ),
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (showHandle)
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0x2E15282B),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
