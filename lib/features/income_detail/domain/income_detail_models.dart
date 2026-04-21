import 'package:flutter/material.dart';

int _inclusiveDayCount(DateTime start, DateTime end) {
  final DateTime utcStart = DateTime.utc(start.year, start.month, start.day);
  final DateTime utcEnd = DateTime.utc(end.year, end.month, end.day);
  return utcEnd.difference(utcStart).inDays + 1;
}

enum IncomeDetailRangePreset {
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  custom,
}

extension IncomeDetailRangePresetX on IncomeDetailRangePreset {
  String get label => switch (this) {
    IncomeDetailRangePreset.thisWeek => 'This week',
    IncomeDetailRangePreset.lastWeek => 'Last week',
    IncomeDetailRangePreset.thisMonth => 'This month',
    IncomeDetailRangePreset.lastMonth => 'Last month',
    IncomeDetailRangePreset.custom => 'Custom',
  };
}

@immutable
class IncomeDetailQuery {
  const IncomeDetailQuery({
    required this.preset,
    this.customStart,
    this.customEnd,
  });

  const IncomeDetailQuery.thisWeek()
    : this(preset: IncomeDetailRangePreset.thisWeek);

  const IncomeDetailQuery.lastWeek()
    : this(preset: IncomeDetailRangePreset.lastWeek);

  const IncomeDetailQuery.thisMonth()
    : this(preset: IncomeDetailRangePreset.thisMonth);

  const IncomeDetailQuery.lastMonth()
    : this(preset: IncomeDetailRangePreset.lastMonth);

  const IncomeDetailQuery.custom({
    required DateTime start,
    required DateTime end,
  }) : this(
         preset: IncomeDetailRangePreset.custom,
         customStart: start,
         customEnd: end,
       );

  final IncomeDetailRangePreset preset;
  final DateTime? customStart;
  final DateTime? customEnd;

  @override
  bool operator ==(Object other) {
    return other is IncomeDetailQuery &&
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
    final DateTime normalizedA = DateUtils.dateOnly(a);
    final DateTime normalizedB = DateUtils.dateOnly(b);
    return normalizedA == normalizedB;
  }
}

@immutable
class IncomeDetailRange {
  const IncomeDetailRange({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;

  int get dayCount => _inclusiveDayCount(start, end);

  DateTimeRange get asDateTimeRange => DateTimeRange(start: start, end: end);

  IncomeDetailRange get previousPeriod {
    final int spanDays = dayCount;
    final DateTime previousEnd = DateTime(
      start.year,
      start.month,
      start.day - 1,
    );
    final DateTime previousStart = DateTime(
      previousEnd.year,
      previousEnd.month,
      previousEnd.day - (spanDays - 1),
    );
    return IncomeDetailRange(start: previousStart, end: previousEnd, label: '');
  }
}

@immutable
class IncomeDetailTransaction {
  const IncomeDetailTransaction({
    required this.occurredOn,
    required this.amountMinor,
    required this.paymentMethod,
  });

  final DateTime occurredOn;
  final int amountMinor;
  final IncomeDetailPaymentMethod paymentMethod;
}

enum IncomeDetailPaymentMethod { cash, card, other }

@immutable
class IncomeDetailChartPoint {
  const IncomeDetailChartPoint({
    required this.date,
    required this.cashMinor,
    required this.cardMinor,
  });

  final DateTime date;
  final int cashMinor;
  final int cardMinor;

  int get totalMinor => cashMinor + cardMinor;
}

@immutable
class IncomeDetailBreakdownRow {
  const IncomeDetailBreakdownRow({
    required this.date,
    required this.cashMinor,
    required this.cardMinor,
  });

  final DateTime date;
  final int cashMinor;
  final int cardMinor;

  int get totalMinor => cashMinor + cardMinor;
}

@immutable
class IncomeDetailInsight {
  const IncomeDetailInsight({
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
class IncomeDetailViewModel {
  const IncomeDetailViewModel({
    required this.query,
    required this.selectedRangeLabel,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalIncomeMinor,
    required this.cashIncomeMinor,
    required this.cardIncomeMinor,
    required this.cashSharePercent,
    required this.cardSharePercent,
    required this.chartSeries,
    required this.breakdownRows,
    required this.highestDayInsight,
    required this.averagePerDayInsight,
    required this.bestPaymentMixInsight,
    required this.isEmpty,
    required this.hasDisabledChartState,
  });

  final IncomeDetailQuery query;
  final String selectedRangeLabel;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final int totalIncomeMinor;
  final int cashIncomeMinor;
  final int cardIncomeMinor;
  final double cashSharePercent;
  final double cardSharePercent;
  final List<IncomeDetailChartPoint> chartSeries;
  final List<IncomeDetailBreakdownRow> breakdownRows;
  final IncomeDetailInsight highestDayInsight;
  final IncomeDetailInsight averagePerDayInsight;
  final IncomeDetailInsight bestPaymentMixInsight;
  final bool isEmpty;
  final bool hasDisabledChartState;

  int get dayCount => _inclusiveDayCount(rangeStart, rangeEnd);
}
