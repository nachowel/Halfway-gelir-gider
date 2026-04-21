import 'package:flutter/material.dart';

int _inclusiveDayCount(DateTime start, DateTime end) {
  final DateTime utcStart = DateTime.utc(start.year, start.month, start.day);
  final DateTime utcEnd = DateTime.utc(end.year, end.month, end.day);
  return utcEnd.difference(utcStart).inDays + 1;
}

enum ExpenseDetailRangePreset {
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  custom,
}

extension ExpenseDetailRangePresetX on ExpenseDetailRangePreset {
  String get label => switch (this) {
    ExpenseDetailRangePreset.thisWeek => 'This week',
    ExpenseDetailRangePreset.lastWeek => 'Last week',
    ExpenseDetailRangePreset.thisMonth => 'This month',
    ExpenseDetailRangePreset.lastMonth => 'Last month',
    ExpenseDetailRangePreset.custom => 'Custom',
  };
}

@immutable
class ExpenseDetailQuery {
  const ExpenseDetailQuery({
    required this.preset,
    this.customStart,
    this.customEnd,
  });

  const ExpenseDetailQuery.thisWeek()
    : this(preset: ExpenseDetailRangePreset.thisWeek);

  const ExpenseDetailQuery.lastWeek()
    : this(preset: ExpenseDetailRangePreset.lastWeek);

  const ExpenseDetailQuery.thisMonth()
    : this(preset: ExpenseDetailRangePreset.thisMonth);

  const ExpenseDetailQuery.lastMonth()
    : this(preset: ExpenseDetailRangePreset.lastMonth);

  const ExpenseDetailQuery.custom({
    required DateTime start,
    required DateTime end,
  }) : this(
         preset: ExpenseDetailRangePreset.custom,
         customStart: start,
         customEnd: end,
       );

  final ExpenseDetailRangePreset preset;
  final DateTime? customStart;
  final DateTime? customEnd;

  @override
  bool operator ==(Object other) {
    return other is ExpenseDetailQuery &&
        other.preset == preset &&
        _sameDay(other.customStart, customStart) &&
        _sameDay(other.customEnd, customEnd);
  }

  @override
  int get hashCode => Object.hash(
    preset,
    customStart == null ? null : DateUtils.dateOnly(customStart!),
    customEnd == null ? null : DateUtils.dateOnly(customEnd!),
  );

  static bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return a == b;
    }
    return DateUtils.dateOnly(a) == DateUtils.dateOnly(b);
  }
}

@immutable
class ExpenseDetailRange {
  const ExpenseDetailRange({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;

  int get dayCount => _inclusiveDayCount(start, end);

  DateTimeRange get asDateTimeRange => DateTimeRange(start: start, end: end);
}

enum ExpenseDetailPaymentMethod { cash, card, other }

@immutable
class ExpenseDetailTransaction {
  const ExpenseDetailTransaction({
    required this.occurredOn,
    required this.amountMinor,
    required this.categoryName,
    required this.paymentMethod,
  });

  final DateTime occurredOn;
  final int amountMinor;
  final String categoryName;
  final ExpenseDetailPaymentMethod paymentMethod;
}

@immutable
class ExpenseDetailChartPoint {
  const ExpenseDetailChartPoint({
    required this.date,
    required this.totalMinor,
    required this.cashMinor,
    required this.cardMinor,
    required this.otherMinor,
  });

  final DateTime date;
  final int totalMinor;
  final int cashMinor;
  final int cardMinor;
  final int otherMinor;
}

@immutable
class ExpenseCategoryBreakdownRow {
  const ExpenseCategoryBreakdownRow({
    required this.categoryName,
    required this.totalMinor,
    required this.sharePercent,
    required this.transactionCount,
  });

  final String categoryName;
  final int totalMinor;
  final double sharePercent;
  final int transactionCount;
}

@immutable
class ExpenseDailyBreakdownRow {
  const ExpenseDailyBreakdownRow({
    required this.date,
    required this.totalMinor,
    required this.cashMinor,
    required this.cardMinor,
    required this.otherMinor,
  });

  final DateTime date;
  final int totalMinor;
  final int cashMinor;
  final int cardMinor;
  final int otherMinor;
}

@immutable
class ExpenseCompositionItem {
  const ExpenseCompositionItem({
    required this.label,
    required this.percent,
    required this.amountMinor,
    this.isPlaceholder = false,
  });

  final String label;
  final double percent;
  final int amountMinor;
  final bool isPlaceholder;
}

@immutable
class ExpenseKpiDescriptor {
  const ExpenseKpiDescriptor({
    required this.title,
    required this.primary,
    required this.secondary,
    this.isEmpty = false,
  });

  final String title;
  final String primary;
  final String secondary;
  final bool isEmpty;
}

@immutable
class ExpenseDetailInsight {
  const ExpenseDetailInsight({
    required this.title,
    required this.primary,
    required this.secondary,
    this.isEmpty = false,
  });

  final String title;
  final String primary;
  final String secondary;
  final bool isEmpty;
}

@immutable
class ExpenseDetailViewModel {
  const ExpenseDetailViewModel({
    required this.query,
    required this.selectedRangeLabel,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalExpensesMinor,
    required this.cashExpensesMinor,
    required this.cardExpensesMinor,
    required this.topCategoryName,
    required this.topCategoryMinor,
    required this.largestDayDate,
    required this.largestDayMinor,
    required this.kpis,
    required this.compositionItems,
    required this.chartSeries,
    required this.categoryBreakdownRows,
    required this.dailyBreakdownRows,
    required this.averagePerDayInsight,
    required this.highestSpendDayInsight,
    required this.topCategoryInsight,
    required this.warningInsightMessage,
    required this.isEmpty,
    required this.hasDisabledChartState,
  });

  final ExpenseDetailQuery query;
  final String selectedRangeLabel;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final int totalExpensesMinor;
  final int cashExpensesMinor;
  final int cardExpensesMinor;
  final String? topCategoryName;
  final int topCategoryMinor;
  final DateTime? largestDayDate;
  final int largestDayMinor;
  final List<ExpenseKpiDescriptor> kpis;
  final List<ExpenseCompositionItem> compositionItems;
  final List<ExpenseDetailChartPoint> chartSeries;
  final List<ExpenseCategoryBreakdownRow> categoryBreakdownRows;
  final List<ExpenseDailyBreakdownRow> dailyBreakdownRows;
  final ExpenseDetailInsight averagePerDayInsight;
  final ExpenseDetailInsight highestSpendDayInsight;
  final ExpenseDetailInsight topCategoryInsight;
  final String? warningInsightMessage;
  final bool isEmpty;
  final bool hasDisabledChartState;

  int get dayCount => _inclusiveDayCount(rangeStart, rangeEnd);
}
