import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_icon_tile.dart';

class UpcomingPaymentItemData {
  const UpcomingPaymentItemData({
    required this.title,
    required this.meta,
    required this.amount,
    required this.icon,
    this.tone = HiFiIconTileTone.amber,
  });

  final String title;
  final String meta;
  final String amount;
  final IconData icon;
  final HiFiIconTileTone tone;
}

class UpcomingPaymentItem extends StatelessWidget {
  const UpcomingPaymentItem({required this.data, this.onTap, super.key});

  final UpcomingPaymentItemData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          HiFiIconTile(icon: data.icon, tone: data.tone),
          const SizedBox(width: AppSpacing.smTight),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.title,
                  style: AppTypography.ttl.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(data.meta, style: AppTypography.meta),
              ],
            ),
          ),
          Text(
            data.amount,
            style: AppTypography.numMd.copyWith(color: AppColors.expense),
          ),
        ],
      ),
    );
  }
}
