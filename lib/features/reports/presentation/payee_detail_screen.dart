import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_section_header.dart';
import '../../../shared/layout/mobile_scaffold.dart';
import '../../../shared/widgets/app_button.dart';
import '../domain/payee_analytics_models.dart';

class PayeeDetailScreen extends ConsumerWidget {
  const PayeeDetailScreen({required this.payeeKey, super.key});

  final String payeeKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = context.strings;
    final AsyncValue<PayeeDetailViewModel> asyncDetail = ref.watch(
      payeeDetailProvider(payeeKey),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: MobileScaffold(
        child: asyncDetail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _DetailErrorState(
            message: strings.reportsLoadError,
            onBack: () => _back(context),
          ),
          data: (PayeeDetailViewModel detail) =>
              _PayeeDetailBody(detail: detail, onBack: () => _back(context)),
        ),
      ),
    );
  }

  void _back(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.go('/reports');
  }
}

class _PayeeDetailBody extends StatelessWidget {
  const _PayeeDetailBody({required this.detail, required this.onBack});

  final PayeeDetailViewModel detail;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenSide,
          AppSpacing.sm,
          AppSpacing.screenSide,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          _PayeeDetailHeader(
            payeeName: detail.payeeName,
            onBack: onBack,
          ),
          const SizedBox(height: AppSpacing.md),
          _LifetimeCard(detail: detail),
          const SizedBox(height: AppSpacing.md),
          _MetricsCard(metrics: detail.metrics),
          const SizedBox(height: AppSpacing.lg),
          HiFiSectionHeader.eye(left: strings.supplierScorecard),
          const SizedBox(height: AppSpacing.sm),
          _ScorecardCard(scorecard: detail.scorecard),
          const SizedBox(height: AppSpacing.lg),
          HiFiSectionHeader.eye(left: strings.spendingTrends),
          const SizedBox(height: AppSpacing.sm),
          _TrendAnalysisCard(analysis: detail.trendAnalysis),
          const SizedBox(height: AppSpacing.lg),
          HiFiSectionHeader.eye(left: strings.purchaseFrequency),
          const SizedBox(height: AppSpacing.sm),
          _FrequencyCard(frequency: detail.purchaseFrequency),
          const SizedBox(height: AppSpacing.lg),
          if (detail.alerts.isNotEmpty) ...<Widget>[
            HiFiSectionHeader.eye(left: strings.supplierAlerts),
            const SizedBox(height: AppSpacing.sm),
            _AlertsCard(alerts: detail.alerts),
            const SizedBox(height: AppSpacing.lg),
          ],
          HiFiSectionHeader.eye(left: strings.payeeAnalytics),
          const SizedBox(height: AppSpacing.sm),
          _SummaryGrid(tiles: detail.summaryTiles),
          const SizedBox(height: AppSpacing.lg),
          HiFiSectionHeader.eye(left: strings.spendingDistribution),
          const SizedBox(height: AppSpacing.sm),
          _DistributionCard(distribution: detail.spendingDistribution),
          const SizedBox(height: AppSpacing.lg),
          HiFiSectionHeader.eye(left: strings.payeeCategoryBreakdown),
          const SizedBox(height: AppSpacing.sm),
          if (detail.categoryBreakdown.isEmpty)
            const _NoTransactionsState()
          else
            _CategoryBreakdownList(items: detail.categoryBreakdown),
          const SizedBox(height: AppSpacing.lg),
          HiFiSectionHeader.eye(left: strings.biggestPurchases),
          const SizedBox(height: AppSpacing.sm),
          if (detail.biggestPurchases.isEmpty)
            const _NoTransactionsState()
          else
            _BiggestPurchasesList(items: detail.biggestPurchases),
          const SizedBox(height: AppSpacing.lg),
          HiFiSectionHeader.eye(left: strings.weeklyTrend),
          const SizedBox(height: AppSpacing.sm),
          _TrendList(points: detail.weeklyTrend),
          const SizedBox(height: AppSpacing.lg),
          HiFiSectionHeader.eye(left: strings.payeeMonthlyTrend),
          const SizedBox(height: AppSpacing.sm),
          _TrendList(points: detail.monthlyTrend),
          const SizedBox(height: AppSpacing.lg),
          HiFiSectionHeader.eye(left: strings.monthlyHistory),
          const SizedBox(height: AppSpacing.sm),
          _MonthlyHistoryList(points: detail.monthlyHistory),
          const SizedBox(height: AppSpacing.lg),
          HiFiSectionHeader.eye(left: strings.paidThisYear),
          const SizedBox(height: AppSpacing.sm),
          if (detail.transactions.isEmpty)
            const _NoTransactionsState()
          else
            _TransactionList(
              transactions: detail.transactions,
            ),
        ],
      ),
    );
  }
}

class _PayeeDetailHeader extends StatelessWidget {
  const _PayeeDetailHeader({required this.payeeName, required this.onBack});

  final String payeeName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Row(
      children: <Widget>[
        InkWell(
          key: const ValueKey<String>('payee-detail-back-button'),
          onTap: onBack,
          borderRadius: BorderRadius.circular(999),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 24,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            payeeName,
            style: AppTypography.h1.copyWith(fontSize: 24),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        InkWell(
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: Text(
                    strings.payeeDetailTitle,
                    style: AppTypography.h2,
                  ),
                  content: Text(
                    strings.payeeDetailTitle,
                    style: AppTypography.bodySoft,
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(strings.close),
                    ),
                  ],
                );
              },
            );
          },
          borderRadius: BorderRadius.circular(999),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.info_outline_rounded,
              size: 24,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.metrics});

  final PayeeDetailMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.compact(
      child: Column(
        children: <Widget>[
          _MetricRow(
            label: strings.averagePayment,
            value: strings.currencyMinor(metrics.averagePaymentMinor),
          ),
          const Divider(color: AppColors.borderSoft, height: 20),
          _MetricRow(
            label: strings.largestPayment,
            value: strings.currencyMinor(metrics.largestPaymentMinor),
          ),
          const Divider(color: AppColors.borderSoft, height: 20),
          _MetricRow(
            label: strings.smallestPayment,
            value: strings.currencyMinor(metrics.smallestPaymentMinor),
          ),
          const Divider(color: AppColors.borderSoft, height: 20),
          _MetricRow(
            label: strings.avgDaysBetween,
            value: metrics.averageDaysBetween == null
                ? '—'
                : metrics.averageDaysBetween!.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: AppTypography.eye)),
        Text(value, style: AppTypography.numSm.copyWith(color: AppColors.ink)),
      ],
    );
  }
}

class _CategoryBreakdownList extends StatelessWidget {
  const _CategoryBreakdownList({required this.items});

  final List<PayeeCategoryBreakdown> items;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.flush(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          items[i].categoryName,
                          style: AppTypography.body
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${strings.formatPercent(items[i].sharePercent)} · ${strings.entriesCount(items[i].transactionCount)}',
                          style: AppTypography.meta,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    strings.currencyMinor(items[i].amountMinor),
                    style: AppTypography.numSm
                        .copyWith(color: AppColors.expense),
                  ),
                ],
              ),
            ),
            if (i != items.length - 1)
              const Divider(color: AppColors.borderSoft, height: 1),
          ],
        ],
      ),
    );
  }
}

class _TrendList extends StatelessWidget {
  const _TrendList({required this.points});

  final List<PayeeTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.compact(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < points.length; i++) ...<Widget>[
            Row(
              children: <Widget>[
                SizedBox(
                  width: 80,
                  child: Text(
                    points[i].label,
                    style: AppTypography.meta,
                  ),
                ),
                Expanded(
                  child: Text(
                    points[i].totalMinor > 0
                        ? strings.currencyMinor(points[i].totalMinor)
                        : '—',
                    style: AppTypography.numSm.copyWith(
                      color: points[i].totalMinor > 0
                          ? AppColors.expense
                          : AppColors.inkFade,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            if (i != points.length - 1)
              const Divider(color: AppColors.borderSoft, height: 12),
          ],
        ],
      ),
    );
  }
}

class _ScorecardCard extends StatelessWidget {
  const _ScorecardCard({required this.scorecard});

  final SupplierScorecard scorecard;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.compact(
      child: Column(
        children: <Widget>[
          _ScorecardRow(label: strings.lifetimeSpend, value: strings.currencyMinor(scorecard.lifetimeSpendMinor)),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(label: strings.thisYear, value: strings.currencyMinor(scorecard.thisYearMinor)),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(label: strings.lastYear, value: strings.currencyMinor(scorecard.lastYearMinor)),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(label: strings.thisMonth, value: strings.currencyMinor(scorecard.thisMonthMinor)),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(label: strings.lastMonth, value: strings.currencyMinor(scorecard.lastMonthMinor)),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(label: strings.avgMonthlySpend, value: strings.currencyMinor(scorecard.averageMonthlySpendMinor)),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(label: strings.avgWeeklySpend, value: strings.currencyMinor(scorecard.averageWeeklySpendMinor)),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(label: strings.payeeTransactionCount, value: scorecard.transactionCount.toString()),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(
            label: strings.firstPurchase,
            value: scorecard.firstPurchaseDate == null ? '—' : strings.dayMonth(scorecard.firstPurchaseDate!),
          ),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(
            label: strings.lastPurchase,
            value: scorecard.lastPurchaseDate == null ? '—' : strings.dayMonth(scorecard.lastPurchaseDate!),
          ),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(label: strings.daysSinceLast, value: scorecard.daysSinceLastPurchase.toString()),
        ],
      ),
    );
  }
}

class _ScorecardRow extends StatelessWidget {
  const _ScorecardRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: AppTypography.eye)),
        Text(value, style: AppTypography.numSm.copyWith(color: AppColors.ink)),
      ],
    );
  }
}

class _TrendAnalysisCard extends StatelessWidget {
  const _TrendAnalysisCard({required this.analysis});

  final SupplierTrendAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final String monthlyLabel = _trendLabel(analysis.monthlyDirection, strings);
    final String weeklyLabel = _trendLabel(analysis.weeklyDirection, strings);
    return HiFiCard.compact(
      child: Column(
        children: <Widget>[
          _ScorecardRow(label: strings.monthlyTrend.isEmpty ? 'Monthly' : 'Monthly', value: monthlyLabel),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(label: 'Weekly', value: weeklyLabel),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(label: strings.movingAverage3Month, value: strings.currencyMinor(analysis.threeMonthMovingAverageMinor)),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(
            label: strings.yearOverYear,
            value: analysis.yearOverYearPercentChange == null
                ? '—'
                : strings.formatPercent(analysis.yearOverYearPercentChange),
          ),
        ],
      ),
    );
  }

  String _trendLabel(TrendDirection dir, AppLocalizations strings) {
    switch (dir) {
      case TrendDirection.increasing:
        return strings.trendIncreasing;
      case TrendDirection.stable:
        return strings.trendStable;
      case TrendDirection.decreasing:
        return strings.trendDecreasing;
      case TrendDirection.insufficient:
        return strings.trendInsufficient;
    }
  }
}

class _FrequencyCard extends StatelessWidget {
  const _FrequencyCard({required this.frequency});

  final PurchaseFrequency frequency;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.compact(
      child: Column(
        children: <Widget>[
          _ScorecardRow(
            label: strings.avgDaysBetween,
            value: frequency.averageDaysBetween == null
                ? '—'
                : frequency.averageDaysBetween!.toStringAsFixed(1),
          ),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(
            label: strings.expectedNextPurchase,
            value: frequency.expectedNextPurchaseDate == null
                ? '—'
                : strings.dayMonth(frequency.expectedNextPurchaseDate!),
          ),
          if (frequency.isOverdue) ...<Widget>[
            const Divider(color: AppColors.borderSoft, height: 20),
            _ScorecardRow(
              label: strings.purchaseOverdue,
              value: strings.alertPurchaseOverdue(frequency.daysOverdue),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.alerts});

  final List<SupplierAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < alerts.length; i++) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.brand,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alerts[i].message,
                    style: AppTypography.bodySoft,
                  ),
                ),
              ],
            ),
            if (i != alerts.length - 1)
              const Divider(color: AppColors.borderSoft, height: 16),
          ],
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.distribution});

  final SpendingDistribution distribution;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.compact(
      child: Column(
        children: <Widget>[
          _ScorecardRow(label: strings.thisWeek, value: strings.currencyMinor(distribution.thisWeekMinor)),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(label: strings.lastWeek, value: strings.currencyMinor(distribution.lastWeekMinor)),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(label: strings.last1Month, value: strings.currencyMinor(distribution.last30DaysMinor)),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(label: strings.last2Months, value: strings.currencyMinor(distribution.last90DaysMinor)),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(label: strings.thisYear, value: strings.currencyMinor(distribution.last12MonthsMinor)),
          const Divider(color: AppColors.borderSoft, height: 20),
          _ScorecardRow(label: strings.lifetimeSpend, value: strings.currencyMinor(distribution.lifetimeMinor)),
        ],
      ),
    );
  }
}

class _BiggestPurchasesList extends StatelessWidget {
  const _BiggestPurchasesList({required this.items});

  final List<BiggestPurchase> items;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.flush(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          strings.dayMonthShortWeekday(items[i].date),
                          style: AppTypography.ttl,
                        ),
                        const SizedBox(height: 4),
                        Text(items[i].categoryName, style: AppTypography.bodySoft),
                        if (items[i].note != null && items[i].note!.trim().isNotEmpty)
                          Text(items[i].note!, style: AppTypography.meta),
                      ],
                    ),
                  ),
                  Text(
                    strings.currencyMinor(items[i].amountMinor),
                    style: AppTypography.numSm.copyWith(color: AppColors.expense),
                  ),
                ],
              ),
            ),
            if (i != items.length - 1)
              const Divider(color: AppColors.borderSoft, height: 1),
          ],
        ],
      ),
    );
  }
}

class _MonthlyHistoryList extends StatelessWidget {
  const _MonthlyHistoryList({required this.points});

  final List<MonthlyHistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.compact(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < points.length; i++) ...<Widget>[
            Row(
              children: <Widget>[
                SizedBox(
                  width: 80,
                  child: Text(points[i].label, style: AppTypography.meta),
                ),
                Expanded(
                  child: Text(
                    points[i].totalMinor > 0
                        ? strings.currencyMinor(points[i].totalMinor)
                        : '—',
                    style: AppTypography.numSm.copyWith(
                      color: points[i].totalMinor > 0 ? AppColors.expense : AppColors.inkFade,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${points[i].transactionCount}',
                  style: AppTypography.meta,
                ),
              ],
            ),
            if (i != points.length - 1)
              const Divider(color: AppColors.borderSoft, height: 12),
          ],
        ],
      ),
    );
  }
}

class _LifetimeCard extends StatelessWidget {
  const _LifetimeCard({required this.detail});

  final PayeeDetailViewModel detail;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.compact(
      child: Row(
        children: <Widget>[
          Expanded(
            child: _LifetimeMetric(
              label: strings.lifetimeTotal,
              value: strings.currencyMinor(detail.lifetimeTotalMinor),
              color: AppColors.expense,
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: AppColors.borderSoft,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          Expanded(
            child: _LifetimeMetric(
              label: strings.payeeTransactionCount,
              value: detail.transactionCount.toString(),
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifetimeMetric extends StatelessWidget {
  const _LifetimeMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTypography.lbl),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTypography.numLg.copyWith(color: color, fontSize: 22),
          ),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.tiles});

  final List<PayeeSummaryTile> tiles;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.6,
      children: <Widget>[
        for (final PayeeSummaryTile tile in tiles) _SummaryTile(tile: tile),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.tile});

  final PayeeSummaryTile tile;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            tile.label,
            style: AppTypography.eye,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              strings.currencyMinor(tile.totalMinor),
              style: AppTypography.numSm.copyWith(
                color: tile.totalMinor > 0
                    ? AppColors.expense
                    : AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.transactions});

  final List<PayeeDetailTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.flush(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < transactions.length; i++) ...<Widget>[
            _TransactionTile(transaction: transactions[i]),
            if (i != transactions.length - 1)
              const Divider(color: AppColors.borderSoft, height: 1),
          ],
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final PayeeDetailTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings.dayMonthShortWeekday(transaction.occurredOn),
                  style: AppTypography.ttl,
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.categoryName,
                  style: AppTypography.bodySoft,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (transaction.note != null &&
                    transaction.note!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    transaction.note!,
                    style: AppTypography.meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  strings.paymentMethodLabel(transaction.paymentMethod),
                  style: AppTypography.meta,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            strings.currencyMinor(transaction.amountMinor),
            style: AppTypography.numSm.copyWith(color: AppColors.expense),
          ),
        ],
      ),
    );
  }
}

class _NoTransactionsState extends StatelessWidget {
  const _NoTransactionsState();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.compact(
      child: Text(
        strings.payeeNoTransactions,
        style: AppTypography.bodySoft,
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenSide),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(message, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: context.strings.close,
                onPressed: onBack,
                expanded: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
