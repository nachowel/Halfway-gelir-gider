import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/app_models.dart';
import '../../../l10n/app_localizations.dart';
import 'monthly_reports_models.dart';

class MonthlyReportsService {
  static final NumberFormat _moneyFormatter = NumberFormat.currency(
    locale: 'en_GB',
    symbol: '£',
    decimalDigits: 0,
  );

  MonthlyReportsViewModel buildViewModel(
    MonthlyReportsDataset dataset,
    AppLocalizations strings,
  ) {
    final DateTime selectedMonth = _monthStart(dataset.selectedMonth);
    final _MonthAggregate current = _aggregateMonth(
      dataset.transactions,
      selectedMonth,
      strings,
    );
    final DateTime previousMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month - 1,
      1,
    );
    final _MonthAggregate previous = _aggregateMonth(
      dataset.transactions,
      previousMonth,
      strings,
    );

    final List<MonthlyReportsCategoryRow> categoryRows =
        current.expenseByCategory.map((MapEntry<String, int> entry) {
          return MonthlyReportsCategoryRow(
            categoryName: strings.systemCategoryName(entry.key),
            amountMinor: entry.value,
            sharePercent: current.expenseMinor == 0
                ? 0
                : (entry.value / current.expenseMinor) * 100,
            shareFraction: current.expenseMinor == 0
                ? 0
                : entry.value / current.expenseMinor,
            icon:
                dataset.expenseCategoryIcons[entry.key] ??
                dataset.incomeCategoryIcons[entry.key] ??
                _fallbackIcon,
          );
        }).toList()..sort(_compareCategoryRows);

    final MonthlyReportsComparison? comparison = previous.hasActivity
        ? MonthlyReportsComparison(
            previousNetMinor: previous.netMinor,
            changeMinor: current.netMinor - previous.netMinor,
            percentageChange: previous.netMinor == 0
                ? null
                : ((current.netMinor - previous.netMinor) /
                          previous.netMinor.abs()) *
                      100,
          )
        : null;

    final List<MonthlyReportsTrendPoint> trendSeries = _buildTrendSeries(
      transactions: dataset.transactions,
      selectedMonth: selectedMonth,
      trendMonthCount: dataset.trendMonthCount,
      strings: strings,
    );

    return MonthlyReportsViewModel(
      selectedMonth: selectedMonth,
      monthLabel: strings.monthLong(selectedMonth),
      yearLabel: selectedMonth.year.toString(),
      totalIncomeMinor: current.incomeMinor,
      totalExpensesMinor: current.expenseMinor,
      netProfitMinor: current.netMinor,
      previousMonthComparison: comparison,
      health: _buildHealth(current, strings),
      categoryBreakdownRows: categoryRows,
      insights: _buildInsights(current, strings),
      trendSeries: trendSeries,
      dailySummary: _buildDailySummary(
        selectedMonth: selectedMonth,
        current: current,
        strings: strings,
      ),
      isEmpty: !current.hasActivity,
      hasCategoryData: categoryRows.isNotEmpty,
      hasTrendData: trendSeries.any((MonthlyReportsTrendPoint point) {
        return point.hasActivity;
      }),
    );
  }

  List<MonthlyReportsTrendPoint> _buildTrendSeries({
    required Iterable<TransactionData> transactions,
    required DateTime selectedMonth,
    required int trendMonthCount,
    required AppLocalizations strings,
  }) {
    final int resolvedCount = math.max(1, math.min(trendMonthCount, 6));
    final List<_MonthAggregate> months = <_MonthAggregate>[
      for (int offset = resolvedCount - 1; offset >= 0; offset--)
        _aggregateMonth(
          transactions,
          DateTime(selectedMonth.year, selectedMonth.month - offset, 1),
          strings,
        ),
    ];

    final int maxMinor = months.fold<int>(0, (
      int currentMax,
      _MonthAggregate month,
    ) {
      return math.max(
        currentMax,
        math.max(month.incomeMinor, month.expenseMinor),
      );
    });

    return months.map((_MonthAggregate month) {
      return MonthlyReportsTrendPoint(
        monthStart: month.monthStart,
        monthLabel: strings.monthShort(month.monthStart),
        incomeMinor: month.incomeMinor,
        expenseMinor: month.expenseMinor,
        netMinor: month.netMinor,
        incomeFraction: maxMinor == 0 ? 0 : month.incomeMinor / maxMinor,
        expenseFraction: maxMinor == 0 ? 0 : month.expenseMinor / maxMinor,
        isCurrentMonth: _isSameMonth(month.monthStart, selectedMonth),
      );
    }).toList();
  }

  MonthlyReportsHealth _buildHealth(
    _MonthAggregate current,
    AppLocalizations strings,
  ) {
    if (!current.hasActivity) {
      return MonthlyReportsHealth(
        profitMarginPercent: null,
        expenseRatioPercent: null,
        label: strings.noActivity,
        description: strings.startRecordingMonth,
        state: MonthlyReportsHealthState.empty,
      );
    }

    if (current.incomeMinor == 0) {
      return MonthlyReportsHealth(
        profitMarginPercent: null,
        expenseRatioPercent: null,
        label: strings.weak,
        description: strings.expensesNotCoveredYet,
        state: MonthlyReportsHealthState.weak,
      );
    }

    final double profitMarginPercent =
        (current.netMinor / current.incomeMinor) * 100;
    final double expenseRatioPercent =
        (current.expenseMinor / current.incomeMinor) * 100;

    if (current.netMinor <= 0 || profitMarginPercent < 10) {
      return MonthlyReportsHealth(
        profitMarginPercent: profitMarginPercent,
        expenseRatioPercent: expenseRatioPercent,
        label: strings.weak,
        description: strings.costsTooCloseToIncome,
        state: MonthlyReportsHealthState.weak,
      );
    }
    if (profitMarginPercent <= 25) {
      return MonthlyReportsHealth(
        profitMarginPercent: profitMarginPercent,
        expenseRatioPercent: expenseRatioPercent,
        label: strings.moderate,
        description: strings.monthPositiveButTight,
        state: MonthlyReportsHealthState.moderate,
      );
    }
    return MonthlyReportsHealth(
      profitMarginPercent: profitMarginPercent,
      expenseRatioPercent: expenseRatioPercent,
      label: strings.strong,
      description: strings.incomeAheadOfCosts,
      state: MonthlyReportsHealthState.strong,
    );
  }

  List<MonthlyReportsInsightItem> _buildInsights(
    _MonthAggregate current,
    AppLocalizations strings,
  ) {
    final MonthlyReportsInsightItem topExpense = _buildTopExpenseInsight(
      current,
      strings,
    );
    final MonthlyReportsInsightItem incomeOrExpenseDay =
        _buildIncomeOrExpenseDayInsight(current, strings);
    final MonthlyReportsInsightItem netRange = _buildNetRangeInsight(
      current,
      strings,
    );

    return <MonthlyReportsInsightItem>[
      topExpense,
      incomeOrExpenseDay,
      netRange,
    ];
  }

  MonthlyReportsInsightItem _buildTopExpenseInsight(
    _MonthAggregate current,
    AppLocalizations strings,
  ) {
    if (current.expenseByCategory.isEmpty) {
      return MonthlyReportsInsightItem(
        title: strings.topExpense,
        primary: strings.noExpenseYet,
        secondary: strings.noCategoriesThisMonth,
        tone: MonthlyReportsInsightTone.expense,
        isEmpty: true,
      );
    }

    final MapEntry<String, int> winner = current.expenseByCategory.first;
    final double sharePercent = current.expenseMinor == 0
        ? 0
        : (winner.value / current.expenseMinor) * 100;

    return MonthlyReportsInsightItem(
      title: strings.topExpense,
      primary: strings.systemCategoryName(winner.key),
      secondary:
          '${_formatMoney(winner.value)} · ${_formatPercent(sharePercent)}',
      tone: MonthlyReportsInsightTone.expense,
    );
  }

  MonthlyReportsInsightItem _buildIncomeOrExpenseDayInsight(
    _MonthAggregate current,
    AppLocalizations strings,
  ) {
    if (current.incomeByBucket.isNotEmpty) {
      final MapEntry<String, int> winner = current.incomeByBucket.first;
      return MonthlyReportsInsightItem(
        title: strings.topIncomeStream,
        primary: winner.key,
        secondary: _formatMoney(winner.value),
        tone: MonthlyReportsInsightTone.income,
      );
    }

    final _DayStat? highestExpenseDay = current.highestExpenseDay;
    if (highestExpenseDay == null) {
      return MonthlyReportsInsightItem(
        title: strings.highestExpenseDay,
        primary: strings.noSpendYet,
        secondary: strings.noExpenseDaysThisMonth,
        tone: MonthlyReportsInsightTone.expense,
        isEmpty: true,
      );
    }

    return MonthlyReportsInsightItem(
      title: strings.highestExpenseDay,
      primary: _formatDayLabel(highestExpenseDay.date, strings),
      secondary: _formatMoney(highestExpenseDay.valueMinor),
      tone: MonthlyReportsInsightTone.expense,
    );
  }

  MonthlyReportsInsightItem _buildNetRangeInsight(
    _MonthAggregate current,
    AppLocalizations strings,
  ) {
    final _DayStat? bestDay = current.bestNetDay;
    final _DayStat? worstDay = current.worstNetDay;
    if (bestDay == null || worstDay == null) {
      return MonthlyReportsInsightItem(
        title: strings.netDayRange,
        primary: strings.noNetDayYet,
        secondary: strings.activeDaysAppearOnceEntriesAdded,
        tone: MonthlyReportsInsightTone.brand,
        isEmpty: true,
      );
    }

    return MonthlyReportsInsightItem(
      title: strings.netDayRange,
      primary: strings.bestWorstRangePrimary(
        _formatDayLabel(bestDay.date, strings),
        _formatSignedMoney(bestDay.valueMinor),
      ),
      secondary: strings.bestWorstRangeSecondary(
        _formatDayLabel(worstDay.date, strings),
        _formatSignedMoney(worstDay.valueMinor),
      ),
      tone: MonthlyReportsInsightTone.brand,
    );
  }

  MonthlyReportsDailySummary _buildDailySummary({
    required DateTime selectedMonth,
    required _MonthAggregate current,
    required AppLocalizations strings,
  }) {
    final int calendarDayCount = _daysInMonth(selectedMonth);
    final int averageDailyNetMinor = calendarDayCount == 0
        ? 0
        : (current.netMinor / calendarDayCount).round();

    return MonthlyReportsDailySummary(
      bestDay: current.bestNetDay == null
          ? const MonthlyReportsDayMetric(
              date: null,
              netMinor: 0,
              isEmpty: true,
            )
          : MonthlyReportsDayMetric(
              date: current.bestNetDay!.date,
              netMinor: current.bestNetDay!.valueMinor,
            ),
      worstDay: current.worstNetDay == null
          ? const MonthlyReportsDayMetric(
              date: null,
              netMinor: 0,
              isEmpty: true,
            )
          : MonthlyReportsDayMetric(
              date: current.worstNetDay!.date,
              netMinor: current.worstNetDay!.valueMinor,
            ),
      averageDailyNetMinor: averageDailyNetMinor,
      calendarDayCount: calendarDayCount,
      usesCalendarDays: true,
    );
  }

  _MonthAggregate _aggregateMonth(
    Iterable<TransactionData> transactions,
    DateTime month,
    AppLocalizations strings,
  ) {
    final DateTime monthStart = _monthStart(month);
    final Map<String, int> expenseByCategory = <String, int>{};
    final Map<String, int> incomeByBucket = <String, int>{};
    final Map<DateTime, _DayAccumulator> daily = <DateTime, _DayAccumulator>{};
    int incomeMinor = 0;
    int expenseMinor = 0;

    for (final TransactionData transaction in transactions) {
      if (!_isSameMonth(transaction.occurredOn, monthStart)) {
        continue;
      }

      final DateTime day = DateTime(
        transaction.occurredOn.year,
        transaction.occurredOn.month,
        transaction.occurredOn.day,
      );
      final _DayAccumulator currentDay = daily[day] ?? const _DayAccumulator();

      switch (transaction.type) {
        case TransactionType.income:
          incomeMinor += transaction.amountMinor;
          daily[day] = currentDay.copyWith(
            incomeMinor: currentDay.incomeMinor + transaction.amountMinor,
          );
          final String bucket = _incomeBucketLabel(transaction, strings);
          incomeByBucket[bucket] =
              (incomeByBucket[bucket] ?? 0) + transaction.amountMinor;
          break;
        case TransactionType.expense:
          expenseMinor += transaction.amountMinor;
          daily[day] = currentDay.copyWith(
            expenseMinor: currentDay.expenseMinor + transaction.amountMinor,
          );
          final String categoryName = _normalizedLabel(
            strings.systemCategoryName(transaction.categoryName),
            fallback: strings.uncategorized,
          );
          expenseByCategory[categoryName] =
              (expenseByCategory[categoryName] ?? 0) + transaction.amountMinor;
          break;
      }
    }

    final List<MapEntry<String, int>> sortedExpenseByCategory =
        expenseByCategory.entries.toList()..sort(_compareNamedTotals);
    final List<MapEntry<String, int>> sortedIncomeByBucket =
        incomeByBucket.entries.toList()..sort(_compareNamedTotals);

    _DayStat? bestNetDay;
    _DayStat? worstNetDay;
    _DayStat? highestExpenseDay;
    for (final MapEntry<DateTime, _DayAccumulator> entry in daily.entries) {
      final _DayStat netDay = _DayStat(
        date: entry.key,
        valueMinor: entry.value.netMinor,
      );
      if (bestNetDay == null ||
          netDay.valueMinor > bestNetDay.valueMinor ||
          (netDay.valueMinor == bestNetDay.valueMinor &&
              netDay.date.isBefore(bestNetDay.date))) {
        bestNetDay = netDay;
      }
      if (worstNetDay == null ||
          netDay.valueMinor < worstNetDay.valueMinor ||
          (netDay.valueMinor == worstNetDay.valueMinor &&
              netDay.date.isBefore(worstNetDay.date))) {
        worstNetDay = netDay;
      }

      if (entry.value.expenseMinor > 0) {
        final _DayStat expenseDay = _DayStat(
          date: entry.key,
          valueMinor: entry.value.expenseMinor,
        );
        if (highestExpenseDay == null ||
            expenseDay.valueMinor > highestExpenseDay.valueMinor ||
            (expenseDay.valueMinor == highestExpenseDay.valueMinor &&
                expenseDay.date.isBefore(highestExpenseDay.date))) {
          highestExpenseDay = expenseDay;
        }
      }
    }

    return _MonthAggregate(
      monthStart: monthStart,
      incomeMinor: incomeMinor,
      expenseMinor: expenseMinor,
      expenseByCategory: sortedExpenseByCategory,
      incomeByBucket: sortedIncomeByBucket,
      bestNetDay: bestNetDay,
      worstNetDay: worstNetDay,
      highestExpenseDay: highestExpenseDay,
    );
  }

  int _compareCategoryRows(
    MonthlyReportsCategoryRow a,
    MonthlyReportsCategoryRow b,
  ) {
    final int amountCompare = b.amountMinor.compareTo(a.amountMinor);
    if (amountCompare != 0) {
      return amountCompare;
    }
    return a.categoryName.toLowerCase().compareTo(b.categoryName.toLowerCase());
  }

  int _compareNamedTotals(MapEntry<String, int> a, MapEntry<String, int> b) {
    final int amountCompare = b.value.compareTo(a.value);
    if (amountCompare != 0) {
      return amountCompare;
    }
    return a.key.toLowerCase().compareTo(b.key.toLowerCase());
  }

  String _incomeBucketLabel(
    TransactionData transaction,
    AppLocalizations strings,
  ) {
    if (transaction.sourcePlatform != null) {
      return strings.sourcePlatformLabel(transaction.sourcePlatform!);
    }
    return _normalizedLabel(
      strings.systemCategoryName(transaction.categoryName),
      fallback: strings.systemCategoryName('Other income'),
    );
  }

  DateTime _monthStart(DateTime value) => DateTime(value.year, value.month, 1);

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  int _daysInMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }

  String _normalizedLabel(String value, {required String fallback}) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    return trimmed;
  }

  String _formatDayLabel(DateTime date, AppLocalizations strings) {
    return strings.dayMonth(date);
  }

  String _formatMoney(int amountMinor) {
    return _moneyFormatter.format(amountMinor / 100);
  }

  String _formatSignedMoney(int amountMinor) {
    final String prefix = amountMinor > 0 ? '+' : '';
    return '$prefix${_formatMoney(amountMinor)}';
  }

  String _formatPercent(double value) {
    final double rounded = (value * 10).round() / 10;
    final bool useDecimal =
        rounded.abs() < 10 && rounded != rounded.roundToDouble();
    return useDecimal
        ? '${rounded.toStringAsFixed(1)}%'
        : '${rounded.round()}%';
  }
}

class _MonthAggregate {
  const _MonthAggregate({
    required this.monthStart,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.expenseByCategory,
    required this.incomeByBucket,
    required this.bestNetDay,
    required this.worstNetDay,
    required this.highestExpenseDay,
  });

  final DateTime monthStart;
  final int incomeMinor;
  final int expenseMinor;
  final List<MapEntry<String, int>> expenseByCategory;
  final List<MapEntry<String, int>> incomeByBucket;
  final _DayStat? bestNetDay;
  final _DayStat? worstNetDay;
  final _DayStat? highestExpenseDay;

  int get netMinor => incomeMinor - expenseMinor;
  bool get hasActivity => incomeMinor > 0 || expenseMinor > 0;
}

class _DayAccumulator {
  const _DayAccumulator({this.incomeMinor = 0, this.expenseMinor = 0});

  final int incomeMinor;
  final int expenseMinor;

  int get netMinor => incomeMinor - expenseMinor;

  _DayAccumulator copyWith({int? incomeMinor, int? expenseMinor}) {
    return _DayAccumulator(
      incomeMinor: incomeMinor ?? this.incomeMinor,
      expenseMinor: expenseMinor ?? this.expenseMinor,
    );
  }
}

class _DayStat {
  const _DayStat({required this.date, required this.valueMinor});

  final DateTime date;
  final int valueMinor;
}

const IconData _fallbackIcon = Icons.receipt_long_rounded;
