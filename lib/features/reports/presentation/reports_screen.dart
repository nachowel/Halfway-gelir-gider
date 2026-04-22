import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/app_models.dart';
import '../../../features/reports/domain/monthly_reports_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/hi_fi/hi_fi_bar.dart';
import '../../../shared/hi_fi/hi_fi_bottom_sheet.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_pill.dart';
import '../../../shared/hi_fi/hi_fi_section_header.dart';
import '../../../shared/overlay/app_overlay.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_GB',
    symbol: '£',
    decimalDigits: 2,
  );
  static final NumberFormat _compactCurrencyFormatter =
      NumberFormat.compactCurrency(
        locale: 'en_GB',
        symbol: '£',
        decimalDigits: 1,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = context.strings;
    final AsyncValue<MonthlyReportsViewModel> snapshotAsync = ref.watch(
      reportsSnapshotProvider,
    );

    return snapshotAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _ReportsErrorState(),
      data: (MonthlyReportsViewModel report) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenSide,
          AppSpacing.xs,
          AppSpacing.screenSide,
          120,
        ),
        children: <Widget>[
          _ReportsHeader(
            report: report,
            onMonthTap: () async {
              final DateTime? selectedMonth = await _showMonthPicker(
                context,
                report.selectedMonth,
              );
              if (selectedMonth == null || !context.mounted) {
                return;
              }
              ref.read(selectedReportsMonthProvider.notifier).state =
                  selectedMonth;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _StatementCard(report: report),
          const SizedBox(height: AppSpacing.sm),
          _HealthCard(health: report.health),
          const SizedBox(height: AppSpacing.lg),
          HiFiSectionHeader.eye(left: strings.topInsights),
          const SizedBox(height: AppSpacing.sm),
          _InsightsList(items: report.insights),
          const SizedBox(height: AppSpacing.lg),
          HiFiSectionHeader.eye(left: strings.categoryExpenses),
          const SizedBox(height: AppSpacing.sm),
          if (!report.hasCategoryData)
            const _EmptyBreakdownState()
          else
            _BreakdownList(
              items: report.categoryBreakdownRows,
              selectedMonth: report.selectedMonth,
            ),
          const SizedBox(height: AppSpacing.lg),
          HiFiSectionHeader.eye(left: strings.supplierBreakdown),
          const SizedBox(height: AppSpacing.sm),
          if (!report.hasSupplierData)
            const _EmptySupplierBreakdownState()
          else
            _SupplierBreakdownList(
              items: report.supplierBreakdownRows,
              selectedMonth: report.selectedMonth,
            ),
          const SizedBox(height: AppSpacing.lg),
          HiFiSectionHeader.eye(left: strings.monthlyTrend),
          const SizedBox(height: AppSpacing.sm),
          if (!report.hasTrendData)
            const _EmptyTrendState()
          else
            _TrendCard(series: report.trendSeries),
          const SizedBox(height: AppSpacing.lg),
          HiFiSectionHeader.eye(left: strings.dailySummary),
          const SizedBox(height: AppSpacing.sm),
          _DailySummaryCard(summary: report.dailySummary),
        ],
      ),
    );
  }

  static Future<DateTime?> _showMonthPicker(
    BuildContext context,
    DateTime selectedMonth,
  ) {
    int displayedYear = selectedMonth.year;
    return showAppModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x7A15282B),
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final double screenHeight = MediaQuery.sizeOf(context).height;
            final double maxSheetHeight = screenHeight * 0.74;
            return _MonthPickerSheet(
              maxHeight: maxSheetHeight,
              displayedYear: displayedYear,
              selectedMonth: selectedMonth,
              onPreviousYear: () {
                setModalState(() {
                  displayedYear -= 1;
                });
              },
              onNextYear: () {
                setModalState(() {
                  displayedYear += 1;
                });
              },
              onSelectMonth: (int monthIndex) {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pop(DateTime(displayedYear, monthIndex, 1));
              },
            );
          },
        );
      },
    );
  }

  static String _formatCurrency(int amountMinor) {
    return _currencyFormatter.format(amountMinor / 100);
  }

  static String _formatCompactCurrency(int amountMinor) {
    return _compactCurrencyFormatter.format(amountMinor / 100);
  }

  static String _formatSignedCurrency(int amountMinor) {
    final String prefix = amountMinor > 0 ? '+' : '';
    return '$prefix${_formatCurrency(amountMinor)}';
  }

  static String _formatPercent(double? value) {
    if (value == null || !value.isFinite) {
      return '—';
    }
    final double rounded = (value * 10).round() / 10;
    final bool useDecimal =
        rounded.abs() < 10 && rounded != rounded.roundToDouble();
    final String label = useDecimal
        ? rounded.toStringAsFixed(1)
        : rounded.round().toString();
    return '$label%';
  }

  static String _formatDayLabel(AppLocalizations strings, DateTime? date) {
    if (date == null) {
      return strings.noActiveDay;
    }
    return strings.dayMonth(date);
  }

  static Color _netColor(int amountMinor) {
    if (amountMinor > 0) {
      return AppColors.income;
    }
    if (amountMinor < 0) {
      return AppColors.expense;
    }
    return AppColors.inkSoft;
  }

  static HiFiPillTone _healthTone(MonthlyReportsHealthState state) {
    switch (state) {
      case MonthlyReportsHealthState.empty:
        return HiFiPillTone.neutral;
      case MonthlyReportsHealthState.weak:
        return HiFiPillTone.expense;
      case MonthlyReportsHealthState.moderate:
        return HiFiPillTone.amber;
      case MonthlyReportsHealthState.strong:
        return HiFiPillTone.income;
    }
  }

  static Color _insightColor(MonthlyReportsInsightTone tone) {
    switch (tone) {
      case MonthlyReportsInsightTone.neutral:
        return AppColors.ink;
      case MonthlyReportsInsightTone.brand:
        return AppColors.brand;
      case MonthlyReportsInsightTone.income:
        return AppColors.income;
      case MonthlyReportsInsightTone.expense:
        return AppColors.expense;
    }
  }
}

class _MonthPickerSheet extends StatelessWidget {
  const _MonthPickerSheet({
    required this.maxHeight,
    required this.displayedYear,
    required this.selectedMonth,
    required this.onPreviousYear,
    required this.onNextYear,
    required this.onSelectMonth,
  });

  final double maxHeight;
  final int displayedYear;
  final DateTime selectedMonth;
  final VoidCallback onPreviousYear;
  final VoidCallback onNextYear;
  final ValueChanged<int> onSelectMonth;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiBottomSheet(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: ConstrainedBox(
        key: const Key('reports-month-sheet'),
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double chipWidth =
                (constraints.maxWidth - (AppSpacing.sm * 2)) / 3;
            return SingleChildScrollView(
              key: const Key('reports-month-grid'),
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    strings.selectMonth.toUpperCase(),
                    style: AppTypography.eye,
                  ),
                  const SizedBox(height: 4),
                  Text(strings.monthlyOverview, style: AppTypography.bodySoft),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      _PickerStepButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: onPreviousYear,
                      ),
                      Expanded(
                        child: Text(
                          displayedYear.toString(),
                          textAlign: TextAlign.center,
                          style: AppTypography.h2,
                        ),
                      ),
                      _PickerStepButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: onNextYear,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (int monthIndex = 1; monthIndex <= 12; monthIndex++)
                        SizedBox(
                          width: chipWidth,
                          child: _MonthChoiceChip(
                            label: strings.monthLong(
                              DateTime(displayedYear, monthIndex, 1),
                            ),
                            meta: strings.monthShort(
                              DateTime(displayedYear, monthIndex, 1),
                            ),
                            selected:
                                displayedYear == selectedMonth.year &&
                                monthIndex == selectedMonth.month,
                            onTap: () => onSelectMonth(monthIndex),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader({required this.report, required this.onMonthTap});

  final MonthlyReportsViewModel report;
  final VoidCallback onMonthTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(strings.reports.toUpperCase(), style: AppTypography.eye),
            _MonthPill(label: report.monthLabel, onTap: onMonthTap),
          ],
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: AppTypography.h1,
            children: <InlineSpan>[
              TextSpan(text: '${report.monthLabel} '),
              TextSpan(
                text: report.yearLabel,
                style: AppTypography.h1.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(strings.monthlyProfitLoss, style: AppTypography.lbl),
      ],
    );
  }
}

class _MonthPill extends StatelessWidget {
  const _MonthPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('reports-month-selector'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
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
                size: 14,
                color: AppColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard({required this.report});

  final MonthlyReportsViewModel report;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final MonthlyReportsComparison? comparison = report.previousMonthComparison;
    final Color comparisonColor = comparison == null
        ? AppColors.inkSoft
        : ReportsScreen._netColor(comparison.changeMinor);

    return HiFiCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _StatementRow(
            label: strings.incomeUpper,
            value: ReportsScreen._formatCurrency(report.totalIncomeMinor),
            color: AppColors.income,
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          _StatementRow(
            label: strings.expensesUpper,
            value: ReportsScreen._formatCurrency(report.totalExpensesMinor),
            color: AppColors.expense,
          ),
          const SizedBox(height: 12),
          Container(height: 2, color: AppColors.ink.withAlpha(230)),
          const SizedBox(height: 10),
          Text(
            strings.netProfitLoss,
            style: AppTypography.h2.copyWith(
              fontSize: 18,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                ReportsScreen._formatCurrency(report.netProfitMinor),
                style: AppTypography.numXl.copyWith(
                  color: ReportsScreen._netColor(report.netProfitMinor),
                ),
              ),
            ),
          ),
          if (comparison != null) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface2.withAlpha(180),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(strings.vsLastMonth, style: AppTypography.eye),
                        const SizedBox(height: 4),
                        Text(
                          ReportsScreen._formatSignedCurrency(
                            comparison.changeMinor,
                          ),
                          style: AppTypography.numSm.copyWith(
                            color: comparisonColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (comparison.percentageChange != null)
                    HiFiPill(
                      label: ReportsScreen._formatPercent(
                        comparison.percentageChange,
                      ),
                      tone: comparison.isPositiveChange
                          ? HiFiPillTone.income
                          : comparison.isNegativeChange
                          ? HiFiPillTone.expense
                          : HiFiPillTone.neutral,
                    ),
                ],
              ),
            ),
          ],
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
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: Text(label, style: AppTypography.eye)),
        const SizedBox(width: 12),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: AppTypography.numLg.copyWith(color: color),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.health});

  final MonthlyReportsHealth health;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _HealthMetric(
                  label: strings.profitMargin,
                  value: ReportsScreen._formatPercent(
                    health.profitMarginPercent,
                  ),
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HealthMetric(
                  label: strings.expenseRatio,
                  value: ReportsScreen._formatPercent(
                    health.expenseRatioPercent,
                  ),
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              HiFiPill(
                label: health.label,
                tone: ReportsScreen._healthTone(health.state),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(health.description, style: AppTypography.bodySoft),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  const _HealthMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2.withAlpha(170),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppTypography.eye),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.numMd.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _InsightsList extends StatelessWidget {
  const _InsightsList({required this.items});

  final List<MonthlyReportsInsightItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int index = 0; index < items.length; index++) ...<Widget>[
          _InsightCard(item: items[index]),
          if (index != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.item});

  final MonthlyReportsInsightItem item;

  @override
  Widget build(BuildContext context) {
    final Color accent = ReportsScreen._insightColor(item.tone);
    return HiFiCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(item.title.toUpperCase(), style: AppTypography.eye),
          const SizedBox(height: 6),
          Text(
            item.primary,
            style: AppTypography.h2.copyWith(
              fontSize: 18,
              color: item.isEmpty ? AppColors.inkSoft : accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(item.secondary, style: AppTypography.bodySoft),
        ],
      ),
    );
  }
}

class _BreakdownList extends StatelessWidget {
  const _BreakdownList({
    required this.items,
    required this.selectedMonth,
  });

  final List<MonthlyReportsCategoryRow> items;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int index = 0; index < items.length; index++) ...<Widget>[
          _ExpenseCategoryRow(
            item: items[index],
            selectedMonth: selectedMonth,
          ),
          if (index != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ExpenseCategoryRow extends StatelessWidget {
  const _ExpenseCategoryRow({
    required this.item,
    required this.selectedMonth,
  });

  final MonthlyReportsCategoryRow item;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCategoryDetailSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: HiFiCard.compact(
          elevation: HiFiCardElevation.none,
          border: Border.all(color: AppColors.borderSoft),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(item.icon, size: 14, color: AppColors.expense),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.categoryName,
                      style: AppTypography.body.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        ReportsScreen._formatCurrency(item.amountMinor),
                        style: AppTypography.numSm,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ReportsScreen._formatPercent(item.sharePercent),
                        style: AppTypography.meta.copyWith(
                          color: AppColors.expenseInk,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              HiFiBar(value: item.shareFraction, tone: HiFiBarTone.expense),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategoryDetailSheet(BuildContext context) {
    showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final AppLocalizations strings = sheetContext.strings;
        return HiFiBottomSheet(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
            ),
            child: Consumer(
              builder: (BuildContext _, WidgetRef ref, Widget? __) {
                final AsyncValue<MonthlyReportsDataset> datasetAsync = ref.watch(
                  reportsDatasetProvider,
                );
                return datasetAsync.when(
                  loading:
                      () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  error: (_, __) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(strings.reportsLoadError),
                  ),
                  data: (MonthlyReportsDataset dataset) {
                    final List<MonthlyReportsCategorySupplierRow> rows = ref
                        .read(reportsServiceProvider)
                        .buildCategorySupplierRows(
                          dataset,
                          item.categoryName,
                          selectedMonth,
                          strings,
                        );
                    if (rows.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          strings.noSuppliersThisMonth,
                          style: AppTypography.bodySoft,
                        ),
                      );
                    }
                    final List<MonthlyReportsCategorySupplierRow> topRows =
                        rows.take(5).toList();
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            item.categoryName,
                            style: AppTypography.h2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.topSuppliersThisMonth,
                            style: AppTypography.bodySoft,
                          ),
                          const SizedBox(height: 16),
                          for (
                            int i = 0;
                            i < topRows.length;
                            i++
                          ) ...<Widget>[
                            _CategorySupplierRow(item: topRows[i]),
                            if (i != topRows.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CategorySupplierRow extends StatelessWidget {
  const _CategorySupplierRow({required this.item});

  final MonthlyReportsCategorySupplierRow item;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      elevation: HiFiCardElevation.none,
      border: Border.all(color: AppColors.borderSoft),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              item.supplierLabel,
              style: AppTypography.body.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                ReportsScreen._formatCurrency(item.amountMinor),
                style: AppTypography.numSm,
              ),
              const SizedBox(height: 2),
              Text(
                ReportsScreen._formatPercent(item.sharePercent),
                style: AppTypography.meta.copyWith(
                  color: AppColors.expenseInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.series});

  final List<MonthlyReportsTrendPoint> series;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Column(
        children: <Widget>[
          for (int index = 0; index < series.length; index++) ...<Widget>[
            _TrendRow(point: series[index]),
            if (index != series.length - 1) ...<Widget>[
              const SizedBox(height: 12),
              const Divider(color: AppColors.borderSoft, height: 1),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.point});

  final MonthlyReportsTrendPoint point;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              point.monthLabel,
              style: AppTypography.body.copyWith(
                color: point.isCurrentMonth
                    ? AppColors.brandStrong
                    : AppColors.ink,
              ),
            ),
            const Spacer(),
            Text(
              ReportsScreen._formatSignedCurrency(point.netMinor),
              style: AppTypography.delta.copyWith(
                color: ReportsScreen._netColor(point.netMinor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _TrendMetricRow(
          label: strings.inShort,
          tone: HiFiBarTone.income,
          fraction: point.incomeFraction,
          amount: ReportsScreen._formatCompactCurrency(point.incomeMinor),
          amountColor: AppColors.income,
        ),
        const SizedBox(height: 6),
        _TrendMetricRow(
          label: strings.outShort,
          tone: HiFiBarTone.expense,
          fraction: point.expenseFraction,
          amount: ReportsScreen._formatCompactCurrency(point.expenseMinor),
          amountColor: AppColors.expense,
        ),
      ],
    );
  }
}

class _TrendMetricRow extends StatelessWidget {
  const _TrendMetricRow({
    required this.label,
    required this.tone,
    required this.fraction,
    required this.amount,
    required this.amountColor,
  });

  final String label;
  final HiFiBarTone tone;
  final double fraction;
  final String amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 26, child: Text(label, style: AppTypography.eye)),
        Expanded(
          child: HiFiBar(value: fraction, tone: tone),
        ),
        const SizedBox(width: 8),
        Text(amount, style: AppTypography.delta.copyWith(color: amountColor)),
      ],
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({required this.summary});

  final MonthlyReportsDailySummary summary;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.compact(
      child: Column(
        children: <Widget>[
          _DailySummaryRow(
            label: strings.bestDay,
            primary: summary.bestDay.isEmpty
                ? strings.noActiveDay
                : ReportsScreen._formatDayLabel(strings, summary.bestDay.date),
            value: summary.bestDay.isEmpty
                ? '—'
                : ReportsScreen._formatSignedCurrency(summary.bestDay.netMinor),
            valueColor: summary.bestDay.isEmpty
                ? AppColors.inkSoft
                : ReportsScreen._netColor(summary.bestDay.netMinor),
            secondary: strings.activeDaysOnly,
          ),
          const Divider(color: AppColors.borderSoft, height: 20),
          _DailySummaryRow(
            label: strings.worstDay,
            primary: summary.worstDay.isEmpty
                ? strings.noActiveDay
                : ReportsScreen._formatDayLabel(strings, summary.worstDay.date),
            value: summary.worstDay.isEmpty
                ? '—'
                : ReportsScreen._formatSignedCurrency(
                    summary.worstDay.netMinor,
                  ),
            valueColor: summary.worstDay.isEmpty
                ? AppColors.inkSoft
                : ReportsScreen._netColor(summary.worstDay.netMinor),
            secondary: strings.activeDaysOnly,
          ),
          const Divider(color: AppColors.borderSoft, height: 20),
          _DailySummaryRow(
            label: strings.averageDailyNet,
            primary: ReportsScreen._formatSignedCurrency(
              summary.averageDailyNetMinor,
            ),
            value: strings.acrossDays(summary.calendarDayCount),
            valueColor: ReportsScreen._netColor(summary.averageDailyNetMinor),
            secondary: summary.usesCalendarDays
                ? strings.acrossCalendarDays
                : strings.acrossActiveDays,
          ),
        ],
      ),
    );
  }
}

class _DailySummaryRow extends StatelessWidget {
  const _DailySummaryRow({
    required this.label,
    required this.primary,
    required this.value,
    required this.valueColor,
    required this.secondary,
  });

  final String label;
  final String primary;
  final String value;
  final Color valueColor;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label.toUpperCase(), style: AppTypography.eye),
              const SizedBox(height: 4),
              Text(primary, style: AppTypography.body),
              const SizedBox(height: 2),
              Text(secondary, style: AppTypography.bodySoft),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: AppTypography.numSm.copyWith(color: valueColor),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}

class _PickerStepButton extends StatelessWidget {
  const _PickerStepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 18, color: AppColors.inkSoft),
        ),
      ),
    );
  }
}

class _MonthChoiceChip extends StatelessWidget {
  const _MonthChoiceChip({
    required this.label,
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String meta;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('reports-month-$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppEasing.standard,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandSoft : AppColors.surface2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.delta.copyWith(
                  color: selected ? AppColors.brandStrong : AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                textAlign: TextAlign.center,
                style: AppTypography.meta.copyWith(
                  fontSize: 10,
                  color: selected ? AppColors.brandStrong : AppColors.inkFade,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupplierBreakdownList extends StatelessWidget {
  const _SupplierBreakdownList({
    required this.items,
    required this.selectedMonth,
  });

  final List<MonthlyReportsSupplierRow> items;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int index = 0; index < items.length; index++) ...<Widget>[
          _SupplierRow(
            item: items[index],
            selectedMonth: selectedMonth,
          ),
          if (index != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SupplierRow extends StatelessWidget {
  const _SupplierRow({
    required this.item,
    required this.selectedMonth,
  });

  final MonthlyReportsSupplierRow item;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openSupplierDetailSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: HiFiCard.compact(
          elevation: HiFiCardElevation.none,
          border: Border.all(color: AppColors.borderSoft),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.supplierLabel,
                      style: AppTypography.body.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        ReportsScreen._formatCurrency(item.amountMinor),
                        style: AppTypography.numSm,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ReportsScreen._formatPercent(item.sharePercent),
                        style: AppTypography.meta.copyWith(
                          color: AppColors.expenseInk,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              HiFiBar(value: item.shareFraction, tone: HiFiBarTone.expense),
            ],
          ),
        ),
      ),
    );
  }

  void _openSupplierDetailSheet(BuildContext context) {
    showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final AppLocalizations strings = sheetContext.strings;
        return HiFiBottomSheet(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
            ),
            child: Consumer(
              builder: (BuildContext _, WidgetRef ref, Widget? __) {
                final AsyncValue<MonthlyReportsDataset> datasetAsync = ref.watch(
                  reportsDatasetProvider,
                );
                return datasetAsync.when(
                  loading:
                      () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  error: (_, __) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(strings.reportsLoadError),
                  ),
                  data: (MonthlyReportsDataset dataset) {
                    final List<SupplierMonthSpendRow> rows = ref
                        .read(reportsServiceProvider)
                        .buildSupplierTrendRows(
                          dataset,
                          item.supplierKey,
                          selectedMonth,
                          strings,
                        );
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            item.categoryContext == null
                                ? item.supplierLabel
                                : '${item.supplierLabel} · ${item.categoryContext}',
                            style: AppTypography.h2,
                          ),
                          const SizedBox(height: 16),
                          for (int i = 0; i < rows.length; i++) ...<Widget>[
                            _SupplierMonthRow(item: rows[i]),
                            if (i != rows.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SupplierMonthRow extends StatelessWidget {
  const _SupplierMonthRow({required this.item});

  final SupplierMonthSpendRow item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(item.monthLabel, style: AppTypography.body),
        ),
        Text(
          ReportsScreen._formatCurrency(item.totalMinor),
          style: AppTypography.numSm.copyWith(
            color:
                item.totalMinor > 0
                    ? AppColors.expense
                    : AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _EmptySupplierBreakdownState extends StatelessWidget {
  const _EmptySupplierBreakdownState();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.noSuppliersThisMonth, style: AppTypography.bodySoft),
        ],
      ),
    );
  }
}

class _EmptyBreakdownState extends StatelessWidget {
  const _EmptyBreakdownState();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.noExpenseCategoriesYet, style: AppTypography.h2),
          const SizedBox(height: 6),
          Text(strings.addExpensesForPressure, style: AppTypography.bodySoft),
        ],
      ),
    );
  }
}

class _EmptyTrendState extends StatelessWidget {
  const _EmptyTrendState();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.noMonthlyTrendYet, style: AppTypography.h2),
          const SizedBox(height: 6),
          Text(strings.recentMonthsAppear, style: AppTypography.bodySoft),
        ],
      ),
    );
  }
}

class _ReportsErrorState extends StatelessWidget {
  const _ReportsErrorState();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenSide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(strings.reportsLoadError, style: AppTypography.h2),
            const SizedBox(height: 8),
            Text(
              strings.checkConnectionAndTryAgain,
              style: AppTypography.bodySoft,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
