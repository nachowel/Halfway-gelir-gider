import 'package:flutter/material.dart';

int _inclusiveDayCount(DateTime start, DateTime end) {
  final DateTime utcStart = DateTime.utc(start.year, start.month, start.day);
  final DateTime utcEnd = DateTime.utc(end.year, end.month, end.day);
  return utcEnd.difference(utcStart).inDays + 1;
}

enum NetProfitDetailRangePreset {
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  custom,
}

extension NetProfitDetailRangePresetX on NetProfitDetailRangePreset {
  String get label => switch (this) {
    NetProfitDetailRangePreset.thisWeek => 'This week',
    NetProfitDetailRangePreset.lastWeek => 'Last week',
    NetProfitDetailRangePreset.thisMonth => 'This month',
    NetProfitDetailRangePreset.lastMonth => 'Last month',
    NetProfitDetailRangePreset.custom => 'Custom',
  };
}

@immutable
class NetProfitDetailQuery {
  const NetProfitDetailQuery({
    required this.preset,
    this.customStart,
    this.customEnd,
  });

  const NetProfitDetailQuery.thisWeek()
    : this(preset: NetProfitDetailRangePreset.thisWeek);

  const NetProfitDetailQuery.lastWeek()
    : this(preset: NetProfitDetailRangePreset.lastWeek);

  const NetProfitDetailQuery.thisMonth()
    : this(preset: NetProfitDetailRangePreset.thisMonth);

  const NetProfitDetailQuery.lastMonth()
    : this(preset: NetProfitDetailRangePreset.lastMonth);

  const NetProfitDetailQuery.custom({
    required DateTime start,
    required DateTime end,
  }) : this(
         preset: NetProfitDetailRangePreset.custom,
         customStart: start,
         customEnd: end,
       );

  final NetProfitDetailRangePreset preset;
  final DateTime? customStart;
  final DateTime? customEnd;

  @override
  bool operator ==(Object other) {
    return other is NetProfitDetailQuery &&
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
class NetProfitDetailRange {
  const NetProfitDetailRange({
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

enum NetProfitTransactionType { income, expense }

@immutable
class NetProfitDetailTransaction {
  const NetProfitDetailTransaction({
    required this.occurredOn,
    required this.amountMinor,
    required this.type,
  });

  final DateTime occurredOn;
  final int amountMinor;
  final NetProfitTransactionType type;
}

@immutable
class NetProfitChartPoint {
  const NetProfitChartPoint({
    required this.date,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final DateTime date;
  final int incomeMinor;
  final int expenseMinor;

  int get profitMinor => incomeMinor - expenseMinor;
}

@immutable
class NetProfitBreakdownRow {
  const NetProfitBreakdownRow({
    required this.date,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final DateTime date;
  final int incomeMinor;
  final int expenseMinor;

  int get profitMinor => incomeMinor - expenseMinor;
}

@immutable
class NetProfitKpi {
  const NetProfitKpi({
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
class NetProfitHealth {
  const NetProfitHealth({
    required this.marginPercent,
    required this.label,
    required this.description,
  });

  final double marginPercent;
  final String label;
  final String description;
}

@immutable
class NetProfitComparison {
  const NetProfitComparison({
    required this.incomeMinor,
    required this.expenseMinor,
    required this.expenseRatioPercent,
    required this.message,
  });

  final int incomeMinor;
  final int expenseMinor;
  final double expenseRatioPercent;
  final String message;
}

@immutable
class NetProfitInsight {
  const NetProfitInsight({
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
class NetProfitDetailViewModel {
  const NetProfitDetailViewModel({
    required this.query,
    required this.selectedRangeLabel,
    required this.rangeStart,
    required this.rangeEnd,
    required this.netProfitMinor,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.marginPercent,
    required this.health,
    required this.comparison,
    required this.dailyProfitSeries,
    required this.breakdownRows,
    required this.kpis,
    required this.bestDayInsight,
    required this.worstDayInsight,
    required this.averageDailyProfitInsight,
    required this.showExpensePressureWarning,
    required this.expensePressureMessage,
    required this.isEmpty,
    required this.hasDisabledChartState,
  });

  final NetProfitDetailQuery query;
  final String selectedRangeLabel;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final int netProfitMinor;
  final int incomeMinor;
  final int expenseMinor;
  final double marginPercent;
  final NetProfitHealth health;
  final NetProfitComparison comparison;
  final List<NetProfitChartPoint> dailyProfitSeries;
  final List<NetProfitBreakdownRow> breakdownRows;
  final List<NetProfitKpi> kpis;
  final NetProfitInsight bestDayInsight;
  final NetProfitInsight worstDayInsight;
  final NetProfitInsight averageDailyProfitInsight;
  final bool showExpensePressureWarning;
  final String? expensePressureMessage;
  final bool isEmpty;
  final bool hasDisabledChartState;

  int get dayCount => _inclusiveDayCount(rangeStart, rangeEnd);
}
