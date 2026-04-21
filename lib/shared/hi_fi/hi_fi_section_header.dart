import 'package:flutter/material.dart';

import '../../app/theme/app_typography.dart';

/// Section header pattern used across hi-fi screens.
///   left: either an h2 Fraunces title or a mono eyebrow label
///   right: optional mono eye action (e.g. "SEE ALL")
///
/// Use [HiFiSectionHeader.title] for h2-style headers (Dashboard "Upcoming")
/// and [HiFiSectionHeader.eye] for category / metadata eyebrows used
/// in Reports and Recurring.
class HiFiSectionHeader extends StatelessWidget {
  const HiFiSectionHeader.title({
    required this.left,
    this.right,
    this.onRightTap,
    this.actionKey,
    super.key,
  }) : _eyebrow = false;

  const HiFiSectionHeader.eye({
    required this.left,
    this.right,
    this.onRightTap,
    this.actionKey,
    super.key,
  }) : _eyebrow = true;

  final String left;
  final String? right;
  final VoidCallback? onRightTap;
  final Key? actionKey;
  final bool _eyebrow;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          _eyebrow ? left.toUpperCase() : left,
          style: _eyebrow ? AppTypography.eye : AppTypography.h2,
        ),
        if (right != null && onRightTap != null)
          TextButton(
            key: actionKey,
            onPressed: onRightTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppTypography.eye.color,
            ),
            child: Text(right!.toUpperCase(), style: AppTypography.eye),
          ),
      ],
    );
  }
}
