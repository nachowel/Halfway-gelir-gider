import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';
import 'hi_fi_card.dart';
import 'hi_fi_pill.dart';

class HiFiSettingsGroupRowData {
  const HiFiSettingsGroupRowData({
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
}

class HiFiSettingsGroup extends StatelessWidget {
  const HiFiSettingsGroup({required this.title, required this.rows, super.key});

  final String title;
  final List<HiFiSettingsGroupRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title.toUpperCase(), style: AppTypography.eye),
        const SizedBox(height: AppSpacing.xs),
        HiFiCard.flush(
          child: Column(
            children: <Widget>[
              for (int i = 0; i < rows.length; i++)
                _SettingsRow(row: rows[i], showDivider: i != rows.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.row, required this.showDivider});

  final HiFiSettingsGroupRowData row;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final Widget child = Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.borderSoft))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              row.label,
              style: AppTypography.body.copyWith(
                color: row.destructive ? AppColors.expense : AppColors.ink,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (row.trailing != null)
            row.trailing!
          else if (row.value != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  row.value!,
                  style: AppTypography.bodySoft.copyWith(fontSize: 13),
                ),
                if (row.onTap != null) ...<Widget>[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.inkFade,
                  ),
                ],
              ],
            )
          else if (row.onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.inkFade,
            ),
        ],
      ),
    );

    if (row.onTap == null) {
      return child;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: row.onTap, child: child),
    );
  }
}

class HiFiReadonlyPillValue extends StatelessWidget {
  const HiFiReadonlyPillValue({
    required this.label,
    this.tone = HiFiPillTone.ghost,
    super.key,
  });

  final String label;
  final HiFiPillTone tone;

  @override
  Widget build(BuildContext context) {
    return HiFiPill(label: label, tone: tone);
  }
}
