import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/hi_fi/hi_fi_bar.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_hero_card.dart';
import '../../../shared/hi_fi/hi_fi_icon_tile.dart';
import '../../../shared/hi_fi/hi_fi_pill.dart';
import '../../../shared/hi_fi/hi_fi_spark.dart';

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
        _NetHeroCard(),
        SizedBox(height: AppSpacing.sm),
        _IncomeExpensesRow(),
        SizedBox(height: AppSpacing.sm),
        _CashCardSplit(),
        SizedBox(height: AppSpacing.md),
        _UpcomingHeader(),
        SizedBox(height: AppSpacing.xs),
        _UpcomingRow(),
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

class _NetHeroCard extends StatelessWidget {
  const _NetHeroCard();

  @override
  Widget build(BuildContext context) {
    return HiFiHeroCard(
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'NET PROFIT',
                style: AppTypography.eye.copyWith(color: AppColors.heroEye),
              ),
              const SizedBox(height: 6),
              Text(
                '£1,284',
                style: AppTypography.numXxl.copyWith(color: AppColors.heroInk),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  const HiFiPill(
                    label: '£212',
                    tone: HiFiPillTone.income,
                    leading: Icon(Icons.arrow_upward_rounded),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'vs last week',
                    style: AppTypography.bodySoft.copyWith(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.smTight),
              const HiFiSpark(
                values: <double>[0.36, 0.54, 0.42, 0.68, 0.58, 0.82, 0.92],
                tone: HiFiSparkTone.income,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeExpensesRow extends StatelessWidget {
  const _IncomeExpensesRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: HiFiCard.compact(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Income', style: AppTypography.lbl),
                const SizedBox(height: 6),
                Text(
                  '£3,420',
                  style: AppTypography.numLg.copyWith(color: AppColors.income),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.smTight),
        Expanded(
          child: HiFiCard.compact(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Expenses', style: AppTypography.lbl),
                const SizedBox(height: 6),
                Text(
                  '£2,136',
                  style: AppTypography.numLg.copyWith(color: AppColors.expense),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CashCardSplit extends StatelessWidget {
  const _CashCardSplit();

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
                child: _CashCardCell(
                  icon: Icons.payments_outlined,
                  label: 'CASH',
                  value: '£1,240',
                ),
              ),
              Expanded(
                flex: 14,
                child: _CashCardCell(
                  icon: Icons.credit_card_rounded,
                  label: 'CARD',
                  value: '£2,180',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smTight),
          const HiFiBar(value: 0.36, tone: HiFiBarTone.brand),
        ],
      ),
    );
  }
}

class _CashCardCell extends StatelessWidget {
  const _CashCardCell({
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

class _UpcomingHeader extends StatelessWidget {
  const _UpcomingHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Upcoming', style: AppTypography.h2),
        Text('SEE ALL', style: AppTypography.eye),
      ],
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow();

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Row(
        children: <Widget>[
          const HiFiIconTile(
            icon: Icons.home_rounded,
            tone: HiFiIconTileTone.amber,
          ),
          const SizedBox(width: AppSpacing.smTight),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Rent', style: AppTypography.ttl.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text('Fri 18 Apr · in 2 days', style: AppTypography.meta),
              ],
            ),
          ),
          Text(
            '£850',
            style: AppTypography.numMd.copyWith(color: AppColors.expense),
          ),
        ],
      ),
    );
  }
}
