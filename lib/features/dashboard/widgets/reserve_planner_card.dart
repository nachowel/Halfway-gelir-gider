import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/app_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';

class ReservePlannerCard extends StatelessWidget {
  const ReservePlannerCard({required this.snapshot, super.key});

  final ReservePlannerSnapshot snapshot;

  String _fmt(int minor) {
    final int pounds = minor ~/ 100;
    final int pence = minor % 100;
    return '£$pounds.${pence.toString().padLeft(2, '0')}';
  }

  String _dueLabel(AppLocalizations strings, ReservePlannerItem item) {
    if (item.daysUntilDue == 0) return strings.dueNow;
    if (item.daysUntilDue <= 7) return strings.dueThisWeek;
    return strings.dueInWeeks(item.weeksUntilDue);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final List<ReservePlannerItem> previewItems = snapshot.items
        .take(3)
        .toList();

    return HiFiCard.compact(
      variant: HiFiCardVariant.mint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.reservePlanner.toUpperCase(),
                      style: AppTypography.eye,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _fmt(snapshot.totalSuggestedWeeklyReserveMinor),
                      style: AppTypography.numLg.copyWith(
                        color: AppColors.brandStrong,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.savings_outlined,
                size: 18,
                color: AppColors.brand,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            snapshot.eligibleItemCount == 0
                ? strings.noRecurringBillsIncludedYet
                : strings.reservePlannerSuggestion,
            style: AppTypography.meta.copyWith(color: AppColors.inkSoft),
          ),
          if (previewItems.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            for (int i = 0; i < previewItems.length; i++) ...<Widget>[
              _ReservePreviewRow(
                title: previewItems[i].name,
                meta: _dueLabel(strings, previewItems[i]),
                amount: _fmt(previewItems[i].suggestedWeeklyReserveMinor),
              ),
              if (i != previewItems.length - 1)
                const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReservePreviewRow extends StatelessWidget {
  const _ReservePreviewRow({
    required this.title,
    required this.meta,
    required this.amount,
  });

  final String title;
  final String meta;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: AppTypography.body),
              const SizedBox(height: 2),
              Text(meta, style: AppTypography.meta),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          amount,
          style: AppTypography.numSm.copyWith(color: AppColors.brandStrong),
        ),
      ],
    );
  }
}
