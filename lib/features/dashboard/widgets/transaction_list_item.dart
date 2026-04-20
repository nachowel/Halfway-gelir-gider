import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/hi_fi/hi_fi_icon_tile.dart';
import '../../../shared/hi_fi/hi_fi_list_row.dart';

class TransactionListItemData {
  const TransactionListItemData({
    required this.title,
    required this.meta,
    required this.amount,
    required this.icon,
    required this.tone,
    required this.isIncome,
  });

  final String title;
  final String meta;
  final String amount;
  final IconData icon;
  final HiFiIconTileTone tone;
  final bool isIncome;
}

class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    required this.data,
    this.showDivider = true,
    this.onTap,
    super.key,
  });

  final TransactionListItemData data;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HiFiListRow(
      leading: HiFiIconTile(icon: data.icon, tone: data.tone),
      title: data.title,
      meta: data.meta,
      showDivider: showDivider,
      onTap: onTap,
      trailing: Text(
        data.amount,
        textAlign: TextAlign.right,
        style: AppTypography.numMd.copyWith(
          color: data.isIncome ? AppColors.income : AppColors.expense,
        ),
      ),
    );
  }
}
