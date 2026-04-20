import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_icon_tile.dart';
import '../../../shared/hi_fi/hi_fi_section_header.dart';
import '../widgets/summary_cards.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/upcoming_payment_item.dart';

/// Dashboard — locked to hi-fi variant A "Net-first hero".
/// Source: `.agent/design-reference/gider-hi-fi.html` lines ~473-553.
///
/// Composition (top → bottom), spacing values taken from inline styles:
///   1. eyebrow date (mono) + h1 "This week" with italic brand "week"
///   2. highlight amber card: "Net profit" eye label, num-xxl value,
///      income pill + "vs last week", 7-bar income spark
///   3. two compact stat cards (Income / Expenses), num-lg values
///   4. compact card: "Cash / card" eye split, two numeric columns,
///      brand gradient progress bar
///   5. h2 "Upcoming" + "see all" eye
///   6. compact card row: amber icon · Rent · meta · expense amount
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const HeroSummaryCardData _heroData = HeroSummaryCardData(
    eyebrow: 'Net profit',
    value: '£1,284',
    deltaValue: '£212',
    deltaLabel: 'vs last week',
    sparkValues: <double>[0.36, 0.54, 0.42, 0.68, 0.58, 0.82, 0.92],
  );

  static const List<SummaryMetricCardData> _summaryMetrics =
      <SummaryMetricCardData>[
        SummaryMetricCardData(
          label: 'Income',
          value: '£3,420',
          tone: SummaryMetricTone.income,
        ),
        SummaryMetricCardData(
          label: 'Expenses',
          value: '£2,136',
          tone: SummaryMetricTone.expense,
        ),
      ];

  static const CashSplitSummaryCardData _cashSplitData =
      CashSplitSummaryCardData(
        cashValue: '£1,240',
        cardValue: '£2,180',
        progress: 0.36,
      );

  static const List<UpcomingPaymentItemData> _upcomingPayments =
      <UpcomingPaymentItemData>[
        UpcomingPaymentItemData(
          title: 'Rent',
          meta: 'Fri 18 Apr · in 2 days',
          amount: '£850',
          icon: Icons.home_rounded,
        ),
        UpcomingPaymentItemData(
          title: 'Electricity',
          meta: 'Sun 20 Apr · in 4 days',
          amount: '£124',
          icon: Icons.bolt_rounded,
        ),
      ];

  static const List<TransactionListItemData> _recentTransactions =
      <TransactionListItemData>[
        TransactionListItemData(
          title: 'Uber Eats payout',
          meta: 'Food sales · Card',
          amount: '£186',
          icon: Icons.arrow_upward_rounded,
          tone: HiFiIconTileTone.income,
          isIncome: true,
        ),
        TransactionListItemData(
          title: 'Shell fuel',
          meta: 'Fuel · Card',
          amount: '£42',
          icon: Icons.local_gas_station_rounded,
          tone: HiFiIconTileTone.expense,
          isIncome: false,
        ),
        TransactionListItemData(
          title: 'Walk-in sales',
          meta: 'Food sales · Cash',
          amount: '£320',
          icon: Icons.storefront_rounded,
          tone: HiFiIconTileTone.income,
          isIncome: true,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenSide,
        AppSpacing.xs,
        AppSpacing.screenSide,
        // leave space for floating nav + fab sitting above
        120,
      ),
      children: const <Widget>[
        _DashboardHeader(),
        SizedBox(height: AppSpacing.md),
        HeroSummaryCard(data: _heroData),
        SizedBox(height: AppSpacing.sm),
        _SummaryMetricsRow(),
        SizedBox(height: AppSpacing.sm),
        CashSplitSummaryCard(data: _cashSplitData),
        SizedBox(height: AppSpacing.md),
        _UpcomingSection(),
        SizedBox(height: AppSpacing.md),
        _RecentSection(),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('MON 14 → SUN 20 APR', style: AppTypography.eye),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: AppTypography.h1,
                  children: <InlineSpan>[
                    const TextSpan(text: 'This '),
                    TextSpan(
                      text: 'week',
                      style: AppTypography.h1.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const HiFiIconTile(
          icon: Icons.notifications_none_rounded,
          tone: HiFiIconTileTone.brand,
          shape: HiFiIconTileShape.circle,
        ),
      ],
    );
  }
}

class _SummaryMetricsRow extends StatelessWidget {
  const _SummaryMetricsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SummaryMetricCard(data: DashboardScreen._summaryMetrics[0]),
        ),
        const SizedBox(width: AppSpacing.smTight),
        Expanded(
          child: SummaryMetricCard(data: DashboardScreen._summaryMetrics[1]),
        ),
      ],
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const HiFiSectionHeader.title(left: 'Upcoming', right: 'See all'),
        const SizedBox(height: AppSpacing.xs),
        for (
          int index = 0;
          index < DashboardScreen._upcomingPayments.length;
          index++
        ) ...<Widget>[
          UpcomingPaymentItem(data: DashboardScreen._upcomingPayments[index]),
          if (index != DashboardScreen._upcomingPayments.length - 1)
            const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _RecentSection extends StatelessWidget {
  const _RecentSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const HiFiSectionHeader.title(left: 'Recent', right: 'See all'),
        const SizedBox(height: AppSpacing.xs),
        HiFiCard.flush(
          child: Column(
            children: <Widget>[
              for (
                int index = 0;
                index < DashboardScreen._recentTransactions.length;
                index++
              )
                TransactionListItem(
                  data: DashboardScreen._recentTransactions[index],
                  showDivider:
                      index != DashboardScreen._recentTransactions.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
