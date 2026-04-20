import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';
import 'hi_fi_bar.dart';

/// Report category row from hi-fi Reports variant A:
///   line 1: icon (13px, expense color) + label · right num-sm amount
///   line 2: expense-gradient bar, width bound to percent of largest
///   10px bottom margin between rows (handled by caller)
class HiFiReportBarRow extends StatelessWidget {
  const HiFiReportBarRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.fraction,
    this.tone = HiFiBarTone.expense,
    super.key,
  });

  final IconData icon;
  final String label;
  final String amount;

  /// 0..1 bar fill fraction relative to the largest category in the list.
  final double fraction;
  final HiFiBarTone tone;

  Color get _iconColor {
    switch (tone) {
      case HiFiBarTone.expense:
        return AppColors.expense;
      case HiFiBarTone.income:
        return AppColors.income;
      case HiFiBarTone.brand:
        return AppColors.brand;
      case HiFiBarTone.amber:
        return AppColors.amber;
      case HiFiBarTone.ink:
        return AppColors.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 13, color: _iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  color: AppColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(amount, style: AppTypography.numSm),
          ],
        ),
        const SizedBox(height: 4),
        HiFiBar(value: fraction, tone: tone),
      ],
    );
  }
}
