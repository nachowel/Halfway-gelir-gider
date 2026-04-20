import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/hi_fi/hi_fi_bar.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_hero_card.dart';
import '../../../shared/hi_fi/hi_fi_pill.dart';
import '../../../shared/hi_fi/hi_fi_spark.dart';

class HeroSummaryCardData {
  const HeroSummaryCardData({
    required this.eyebrow,
    required this.value,
    required this.deltaValue,
    required this.deltaLabel,
    required this.sparkValues,
  });

  final String eyebrow;
  final String value;
  final String deltaValue;
  final String deltaLabel;
  final List<double> sparkValues;
}

enum SummaryMetricTone { neutral, income, expense }

class SummaryMetricCardData {
  const SummaryMetricCardData({
    required this.label,
    required this.value,
    this.tone = SummaryMetricTone.neutral,
  });

  final String label;
  final String value;
  final SummaryMetricTone tone;
}

class CashSplitSummaryCardData {
  const CashSplitSummaryCardData({
    required this.cashValue,
    required this.cardValue,
    required this.progress,
  });

  final String cashValue;
  final String cardValue;
  final double progress;
}

class HeroSummaryCard extends StatelessWidget {
  const HeroSummaryCard({required this.data, super.key});

  final HeroSummaryCardData data;

  @override
  Widget build(BuildContext context) {
    return HiFiHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            data.eyebrow.toUpperCase(),
            style: AppTypography.eye.copyWith(color: AppColors.heroEye),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: AppTypography.numXxl.copyWith(color: AppColors.heroInk),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              HiFiPill(
                label: data.deltaValue,
                tone: HiFiPillTone.income,
                leading: const Icon(Icons.arrow_upward_rounded),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                data.deltaLabel,
                style: AppTypography.bodySoft.copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smTight),
          HiFiSpark(values: data.sparkValues, tone: HiFiSparkTone.income),
        ],
      ),
    );
  }
}

class SummaryMetricCard extends StatelessWidget {
  const SummaryMetricCard({required this.data, super.key});

  final SummaryMetricCardData data;

  Color get _valueColor {
    switch (data.tone) {
      case SummaryMetricTone.neutral:
        return AppColors.ink;
      case SummaryMetricTone.income:
        return AppColors.income;
      case SummaryMetricTone.expense:
        return AppColors.expense;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(data.label, style: AppTypography.lbl),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: AppTypography.numLg.copyWith(color: _valueColor),
          ),
        ],
      ),
    );
  }
}

class CashSplitSummaryCard extends StatelessWidget {
  const CashSplitSummaryCard({required this.data, super.key});

  final CashSplitSummaryCardData data;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Cash / card', style: AppTypography.lbl),
              Text('INCOME SPLIT', style: AppTypography.eye),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 10,
                child: _CashSplitCell(
                  icon: Icons.payments_outlined,
                  label: 'CASH',
                  value: data.cashValue,
                ),
              ),
              Expanded(
                flex: 14,
                child: _CashSplitCell(
                  icon: Icons.credit_card_rounded,
                  label: 'CARD',
                  value: data.cardValue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smTight),
          HiFiBar(value: data.progress, tone: HiFiBarTone.brand),
        ],
      ),
    );
  }
}

class _CashSplitCell extends StatelessWidget {
  const _CashSplitCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 12, color: AppColors.brand),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.eye),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.numMd),
      ],
    );
  }
}
