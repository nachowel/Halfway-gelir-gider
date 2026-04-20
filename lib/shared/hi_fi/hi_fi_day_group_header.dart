import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';

/// Day group strip from hi-fi Transactions variant A:
///   background: rgba(14,107,111,0.08)  (brand @ 8%)
///   padding: 6px 12px
///   radius: 10px
///   left eye in brand, right num-xs in income/expense color
class HiFiDayGroupHeader extends StatelessWidget {
  const HiFiDayGroupHeader({
    required this.label,
    required this.net,
    this.positive = true,
    super.key,
  });

  final String label;
  final String net;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[Color(0x220E6B6F), Color(0x120E6B6F)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: const Color(0x1F0E6B6F)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08FFF9EC),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: AppTypography.eye.copyWith(color: AppColors.brand),
          ),
          Text(
            net,
            style: AppTypography.numXs.copyWith(
              color: positive ? AppColors.income : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}
