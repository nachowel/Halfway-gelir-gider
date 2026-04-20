import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_report_bar_row.dart';
import '../../../shared/hi_fi/hi_fi_section_header.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenSide,
        AppSpacing.xs,
        AppSpacing.screenSide,
        120,
      ),
      children: const <Widget>[
        _ReportsHeader(),
        SizedBox(height: AppSpacing.md),
        _StatementCard(),
        SizedBox(height: AppSpacing.lg),
        HiFiSectionHeader.eye(left: 'Category · expenses', right: 'See all'),
        SizedBox(height: AppSpacing.sm),
        _BreakdownList(),
      ],
    );
  }
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('REPORTS', style: AppTypography.eye),
            const _MonthPill(label: 'April'),
          ],
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: AppTypography.h1,
            children: <InlineSpan>[
              const TextSpan(text: 'Nisan '),
              TextSpan(
                text: '2026',
                style: AppTypography.h1.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('Monthly profit & loss', style: AppTypography.lbl),
      ],
    );
  }
}

class _MonthPill extends StatelessWidget {
  const _MonthPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.delta.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 13,
            color: AppColors.inkSoft,
          ),
        ],
      ),
    );
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard();

  @override
  Widget build(BuildContext context) {
    return HiFiCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        children: <Widget>[
          const _StatementRow(
            label: 'INCOME',
            value: '£14,820',
            color: AppColors.income,
            large: true,
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          const _StatementRow(
            label: 'EXPENSES',
            value: '£9,140',
            color: AppColors.expense,
            large: true,
          ),
          const SizedBox(height: 10),
          Container(height: 2, color: AppColors.ink.withAlpha(230)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Net',
                style: AppTypography.h2.copyWith(
                  fontSize: 18,
                  color: AppColors.ink,
                ),
              ),
              Text('£5,680', style: AppTypography.numXl),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatementRow extends StatelessWidget {
  const _StatementRow({
    required this.label,
    required this.value,
    required this.color,
    this.large = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: AppTypography.eye),
        Text(
          value,
          style: (large ? AppTypography.numLg : AppTypography.numMd).copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}

class _BreakdownList extends StatelessWidget {
  const _BreakdownList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        HiFiReportBarRow(
          icon: Icons.home_rounded,
          label: 'Rent',
          amount: '£3,400',
          fraction: 0.78,
        ),
        SizedBox(height: 10),
        HiFiReportBarRow(
          icon: Icons.storefront_rounded,
          label: 'Supplies',
          amount: '£2,120',
          fraction: 0.52,
        ),
        SizedBox(height: 10),
        HiFiReportBarRow(
          icon: Icons.local_gas_station_rounded,
          label: 'Fuel',
          amount: '£1,380',
          fraction: 0.38,
        ),
        SizedBox(height: 10),
        HiFiReportBarRow(
          icon: Icons.bolt_rounded,
          label: 'Utilities',
          amount: '£890',
          fraction: 0.24,
        ),
      ],
    );
  }
}
