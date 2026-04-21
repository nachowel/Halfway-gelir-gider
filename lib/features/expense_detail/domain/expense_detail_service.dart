import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import 'expense_detail_models.dart';

class ExpenseDetailService {
  static final DateFormat _weekdayShortFormatter = DateFormat('EEE');
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_GB',
    symbol: '£',
    decimalDigits: 2,
  );

  ExpenseDetailRange resolveRange({
    required DateTime today,
    required ExpenseDetailQuery query,
    required AppLocalizations strings,
  }) {
    final DateTime normalizedToday = _atStartOfDay(today);

    switch (query.preset) {
      case ExpenseDetailRangePreset.thisWeek:
        final DateTime start = normalizedToday.subtract(
          Duration(days: normalizedToday.weekday - 1),
        );
        final DateTime end = start.add(const Duration(days: 6));
        return ExpenseDetailRange(
          start: start,
          end: end,
          label: strings.rangeLabel(start, end),
        );
      case ExpenseDetailRangePreset.lastWeek:
        final DateTime thisWeekStart = normalizedToday.subtract(
          Duration(days: normalizedToday.weekday - 1),
        );
        final DateTime start = thisWeekStart.subtract(const Duration(days: 7));
        final DateTime end = start.add(const Duration(days: 6));
        return ExpenseDetailRange(
          start: start,
          end: end,
          label: strings.rangeLabel(start, end),
        );
      case ExpenseDetailRangePreset.thisMonth:
        final DateTime start = DateTime(
          normalizedToday.year,
          normalizedToday.month,
          1,
        );
        final DateTime end = DateTime(
          normalizedToday.year,
          normalizedToday.month + 1,
          0,
        );
        return ExpenseDetailRange(
          start: start,
          end: end,
          label: strings.rangeLabel(start, end),
        );
      case ExpenseDetailRangePreset.lastMonth:
        final DateTime start = DateTime(
          normalizedToday.year,
          normalizedToday.month - 1,
          1,
        );
        final DateTime end = DateTime(
          normalizedToday.year,
          normalizedToday.month,
          0,
        );
        return ExpenseDetailRange(
          start: start,
          end: end,
          label: strings.rangeLabel(start, end),
        );
      case ExpenseDetailRangePreset.custom:
        final DateTime start = _atStartOfDay(
          query.customStart ?? normalizedToday,
        );
        final DateTime end = _atStartOfDay(query.customEnd ?? start);
        final DateTime normalizedStart = start.isBefore(end) ? start : end;
        final DateTime normalizedEnd = end.isAfter(start) ? end : start;
        return ExpenseDetailRange(
          start: normalizedStart,
          end: normalizedEnd,
          label: strings.rangeLabel(normalizedStart, normalizedEnd),
        );
    }
  }

  ExpenseDetailViewModel buildViewModel({
    required ExpenseDetailQuery query,
    required ExpenseDetailRange range,
    required Iterable<ExpenseDetailTransaction> transactions,
    required AppLocalizations strings,
  }) {
    final Map<DateTime, _DailyAccumulator> byDay =
        <DateTime, _DailyAccumulator>{
          for (int offset = 0; offset < range.dayCount; offset++)
            DateTime(
              range.start.year,
              range.start.month,
              range.start.day + offset,
            ): const _DailyAccumulator(),
        };
    final Map<String, _CategoryAccumulator> categoryTotals =
        <String, _CategoryAccumulator>{};

    for (final ExpenseDetailTransaction transaction in transactions) {
      final DateTime day = _atStartOfDay(transaction.occurredOn);
      final _DailyAccumulator currentDay =
          byDay[day] ?? const _DailyAccumulator();
      byDay[day] = currentDay.add(
        amountMinor: transaction.amountMinor,
        method: transaction.paymentMethod,
      );

      final String categoryName = transaction.categoryName.trim().isEmpty
          ? strings.uncategorized
          : strings.systemCategoryName(transaction.categoryName.trim());
      final _CategoryAccumulator currentCategory =
          categoryTotals[categoryName] ?? const _CategoryAccumulator();
      categoryTotals[categoryName] = currentCategory.add(
        transaction.amountMinor,
      );
    }

    final List<ExpenseDetailChartPoint> chartSeries = <ExpenseDetailChartPoint>[
      for (final MapEntry<DateTime, _DailyAccumulator> entry in byDay.entries)
        ExpenseDetailChartPoint(
          date: entry.key,
          totalMinor: entry.value.totalMinor,
          cashMinor: entry.value.cashMinor,
          cardMinor: entry.value.cardMinor,
          otherMinor: entry.value.otherMinor,
        ),
    ];

    final List<ExpenseDailyBreakdownRow> dailyBreakdownRows = chartSeries
        .map(
          (ExpenseDetailChartPoint point) => ExpenseDailyBreakdownRow(
            date: point.date,
            totalMinor: point.totalMinor,
            cashMinor: point.cashMinor,
            cardMinor: point.cardMinor,
            otherMinor: point.otherMinor,
          ),
        )
        .toList();

    final int totalExpensesMinor = chartSeries.fold<int>(
      0,
      (int sum, ExpenseDetailChartPoint point) => sum + point.totalMinor,
    );
    final int cashExpensesMinor = chartSeries.fold<int>(
      0,
      (int sum, ExpenseDetailChartPoint point) => sum + point.cashMinor,
    );
    final int cardExpensesMinor = chartSeries.fold<int>(
      0,
      (int sum, ExpenseDetailChartPoint point) => sum + point.cardMinor,
    );

    final List<ExpenseCategoryBreakdownRow> categoryBreakdownRows =
        categoryTotals.entries.map((
          MapEntry<String, _CategoryAccumulator> entry,
        ) {
          final double sharePercent = totalExpensesMinor == 0
              ? 0
              : (entry.value.totalMinor / totalExpensesMinor) * 100;
          return ExpenseCategoryBreakdownRow(
            categoryName: entry.key,
            totalMinor: entry.value.totalMinor,
            sharePercent: sharePercent,
            transactionCount: entry.value.transactionCount,
          );
        }).toList()..sort(_compareCategoryRows);

    final ExpenseCategoryBreakdownRow? topCategory = categoryBreakdownRows
        .cast<ExpenseCategoryBreakdownRow?>()
        .firstWhere(
          (ExpenseCategoryBreakdownRow? row) => row != null,
          orElse: () => null,
        );

    final ExpenseDetailChartPoint? largestDay = _findLargestDay(chartSeries);

    return ExpenseDetailViewModel(
      query: query,
      selectedRangeLabel: range.label,
      rangeStart: range.start,
      rangeEnd: range.end,
      totalExpensesMinor: totalExpensesMinor,
      cashExpensesMinor: cashExpensesMinor,
      cardExpensesMinor: cardExpensesMinor,
      topCategoryName: topCategory?.categoryName,
      topCategoryMinor: topCategory?.totalMinor ?? 0,
      largestDayDate: largestDay?.date,
      largestDayMinor: largestDay?.totalMinor ?? 0,
      kpis: _buildKpis(
        totalExpensesMinor: totalExpensesMinor,
        topCategory: topCategory,
        largestDay: largestDay,
        strings: strings,
      ),
      compositionItems: _buildCompositionItems(
        totalExpensesMinor: totalExpensesMinor,
        categoryRows: categoryBreakdownRows,
        strings: strings,
      ),
      chartSeries: chartSeries,
      categoryBreakdownRows: categoryBreakdownRows,
      dailyBreakdownRows: dailyBreakdownRows,
      averagePerDayInsight: _buildAveragePerDayInsight(
        totalExpensesMinor: totalExpensesMinor,
        dayCount: range.dayCount,
        strings: strings,
      ),
      highestSpendDayInsight: _buildHighestSpendDayInsight(largestDay, strings),
      topCategoryInsight: _buildTopCategoryInsight(topCategory, strings),
      warningInsightMessage: _buildWarningInsight(
        totalExpensesMinor: totalExpensesMinor,
        topCategory: topCategory,
        strings: strings,
      ),
      isEmpty: totalExpensesMinor == 0,
      hasDisabledChartState: totalExpensesMinor == 0,
    );
  }

  List<ExpenseKpiDescriptor> _buildKpis({
    required int totalExpensesMinor,
    required ExpenseCategoryBreakdownRow? topCategory,
    required ExpenseDetailChartPoint? largestDay,
    required AppLocalizations strings,
  }) {
    return <ExpenseKpiDescriptor>[
      ExpenseKpiDescriptor(
        title: strings.totalExpenses,
        primary: _formatCurrency(totalExpensesMinor),
        secondary: strings.selectedRange,
        isEmpty: totalExpensesMinor == 0,
      ),
      ExpenseKpiDescriptor(
        title: strings.highestCategory,
        primary: topCategory?.categoryName ?? strings.noCategoryYet,
        secondary: _formatCurrency(topCategory?.totalMinor ?? 0),
        isEmpty: topCategory == null,
      ),
      ExpenseKpiDescriptor(
        title: strings.largestDay,
        primary: largestDay == null
            ? strings.noSpendYet
            : _weekdayShortFormatter.format(largestDay.date),
        secondary: _formatCurrency(largestDay?.totalMinor ?? 0),
        isEmpty: largestDay == null,
      ),
    ];
  }

  List<ExpenseCompositionItem> _buildCompositionItems({
    required int totalExpensesMinor,
    required List<ExpenseCategoryBreakdownRow> categoryRows,
    required AppLocalizations strings,
  }) {
    if (categoryRows.isEmpty || totalExpensesMinor == 0) {
      return <ExpenseCompositionItem>[
        ExpenseCompositionItem(
          label: strings.noCategoryYet,
          percent: 0,
          amountMinor: 0,
          isPlaceholder: true,
        ),
        ExpenseCompositionItem(
          label: strings.noCategoryYet,
          percent: 0,
          amountMinor: 0,
          isPlaceholder: true,
        ),
      ];
    }

    final List<ExpenseCompositionItem> items = categoryRows.take(2).map((
      ExpenseCategoryBreakdownRow row,
    ) {
      return ExpenseCompositionItem(
        label: row.categoryName,
        percent: row.sharePercent,
        amountMinor: row.totalMinor,
      );
    }).toList();

    while (items.length < 2) {
      items.add(
        ExpenseCompositionItem(
          label: strings.noSecondCategory,
          percent: 0,
          amountMinor: 0,
          isPlaceholder: true,
        ),
      );
    }

    return items;
  }

  ExpenseDetailInsight _buildAveragePerDayInsight({
    required int totalExpensesMinor,
    required int dayCount,
    required AppLocalizations strings,
  }) {
    final double averageMinor = dayCount == 0
        ? 0
        : totalExpensesMinor / dayCount;
    return ExpenseDetailInsight(
      title: strings.averagePerDay,
      primary: _formatCurrency(averageMinor.round()),
      secondary: strings.acrossDays(dayCount),
      isEmpty: totalExpensesMinor == 0,
    );
  }

  ExpenseDetailInsight _buildHighestSpendDayInsight(
    ExpenseDetailChartPoint? largestDay,
    AppLocalizations strings,
  ) {
    if (largestDay == null) {
      return ExpenseDetailInsight(
        title: strings.highestSpendDay,
        primary: strings.noSpendYet,
        secondary: strings.selectedRangeIsEmpty,
        isEmpty: true,
      );
    }
    return ExpenseDetailInsight(
      title: strings.highestSpendDay,
      primary: _weekdayShortFormatter.format(largestDay.date),
      secondary: _formatCurrency(largestDay.totalMinor),
    );
  }

  ExpenseDetailInsight _buildTopCategoryInsight(
    ExpenseCategoryBreakdownRow? topCategory,
    AppLocalizations strings,
  ) {
    if (topCategory == null) {
      return ExpenseDetailInsight(
        title: strings.topCategory,
        primary: strings.noCategoryYet,
        secondary: strings.noExpensesInRange,
        isEmpty: true,
      );
    }
    return ExpenseDetailInsight(
      title: strings.topCategory,
      primary: topCategory.categoryName,
      secondary: _formatCurrency(topCategory.totalMinor),
    );
  }

  String? _buildWarningInsight({
    required int totalExpensesMinor,
    required ExpenseCategoryBreakdownRow? topCategory,
    required AppLocalizations strings,
  }) {
    if (totalExpensesMinor == 0 || topCategory == null) {
      return null;
    }
    if (topCategory.sharePercent < 60) {
      return null;
    }
    return strings.mostSpendingOneCategory;
  }

  ExpenseDetailChartPoint? _findLargestDay(
    List<ExpenseDetailChartPoint> chartSeries,
  ) {
    ExpenseDetailChartPoint? winner;
    for (final ExpenseDetailChartPoint point in chartSeries) {
      if (point.totalMinor == 0) {
        continue;
      }
      if (winner == null ||
          point.totalMinor > winner.totalMinor ||
          (point.totalMinor == winner.totalMinor &&
              point.date.isBefore(winner.date))) {
        winner = point;
      }
    }
    return winner;
  }

  int _compareCategoryRows(
    ExpenseCategoryBreakdownRow a,
    ExpenseCategoryBreakdownRow b,
  ) {
    final int amountCompare = b.totalMinor.compareTo(a.totalMinor);
    if (amountCompare != 0) {
      return amountCompare;
    }
    return a.categoryName.toLowerCase().compareTo(b.categoryName.toLowerCase());
  }

  DateTime _atStartOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _formatCurrency(int amountMinor) {
    return _currencyFormatter.format(amountMinor / 100);
  }
}

class _DailyAccumulator {
  const _DailyAccumulator({
    this.totalMinor = 0,
    this.cashMinor = 0,
    this.cardMinor = 0,
    this.otherMinor = 0,
  });

  final int totalMinor;
  final int cashMinor;
  final int cardMinor;
  final int otherMinor;

  _DailyAccumulator add({
    required int amountMinor,
    required ExpenseDetailPaymentMethod method,
  }) {
    return switch (method) {
      ExpenseDetailPaymentMethod.cash => _DailyAccumulator(
        totalMinor: totalMinor + amountMinor,
        cashMinor: cashMinor + amountMinor,
        cardMinor: cardMinor,
        otherMinor: otherMinor,
      ),
      ExpenseDetailPaymentMethod.card => _DailyAccumulator(
        totalMinor: totalMinor + amountMinor,
        cashMinor: cashMinor,
        cardMinor: cardMinor + amountMinor,
        otherMinor: otherMinor,
      ),
      ExpenseDetailPaymentMethod.other => _DailyAccumulator(
        totalMinor: totalMinor + amountMinor,
        cashMinor: cashMinor,
        cardMinor: cardMinor,
        otherMinor: otherMinor + amountMinor,
      ),
    };
  }
}

class _CategoryAccumulator {
  const _CategoryAccumulator({this.totalMinor = 0, this.transactionCount = 0});

  final int totalMinor;
  final int transactionCount;

  _CategoryAccumulator add(int amountMinor) {
    return _CategoryAccumulator(
      totalMinor: totalMinor + amountMinor,
      transactionCount: transactionCount + 1,
    );
  }
}
