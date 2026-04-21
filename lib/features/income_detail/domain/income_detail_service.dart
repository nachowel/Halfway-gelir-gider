import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import 'income_detail_models.dart';

class IncomeDetailService {
  static final DateFormat _weekdayShortFormatter = DateFormat('EEE');
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_GB',
    symbol: '£',
    decimalDigits: 2,
  );

  IncomeDetailRange resolveRange({
    required DateTime today,
    required IncomeDetailQuery query,
    required AppLocalizations strings,
  }) {
    final DateTime normalizedToday = _atStartOfDay(today);

    switch (query.preset) {
      case IncomeDetailRangePreset.thisWeek:
        final DateTime start = normalizedToday.subtract(
          Duration(days: normalizedToday.weekday - 1),
        );
        final DateTime end = start.add(const Duration(days: 6));
        return IncomeDetailRange(
          start: start,
          end: end,
          label: strings.rangeLabel(start, end),
        );
      case IncomeDetailRangePreset.lastWeek:
        final DateTime thisWeekStart = normalizedToday.subtract(
          Duration(days: normalizedToday.weekday - 1),
        );
        final DateTime start = thisWeekStart.subtract(const Duration(days: 7));
        final DateTime end = start.add(const Duration(days: 6));
        return IncomeDetailRange(
          start: start,
          end: end,
          label: strings.rangeLabel(start, end),
        );
      case IncomeDetailRangePreset.thisMonth:
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
        return IncomeDetailRange(
          start: start,
          end: end,
          label: strings.rangeLabel(start, end),
        );
      case IncomeDetailRangePreset.lastMonth:
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
        return IncomeDetailRange(
          start: start,
          end: end,
          label: strings.rangeLabel(start, end),
        );
      case IncomeDetailRangePreset.custom:
        final DateTime start = _atStartOfDay(
          query.customStart ?? normalizedToday,
        );
        final DateTime end = _atStartOfDay(query.customEnd ?? start);
        final DateTime normalizedStart = start.isBefore(end) ? start : end;
        final DateTime normalizedEnd = end.isAfter(start) ? end : start;
        return IncomeDetailRange(
          start: normalizedStart,
          end: normalizedEnd,
          label: strings.rangeLabel(normalizedStart, normalizedEnd),
        );
    }
  }

  IncomeDetailViewModel buildViewModel({
    required IncomeDetailQuery query,
    required IncomeDetailRange range,
    required Iterable<IncomeDetailTransaction> transactions,
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

    for (final IncomeDetailTransaction transaction in transactions) {
      final DateTime day = _atStartOfDay(transaction.occurredOn);
      final _DailyAccumulator current = byDay[day] ?? const _DailyAccumulator();
      switch (transaction.paymentMethod) {
        case IncomeDetailPaymentMethod.cash:
          byDay[day] = current.copyWith(
            cashMinor: current.cashMinor + transaction.amountMinor,
          );
          break;
        case IncomeDetailPaymentMethod.card:
          byDay[day] = current.copyWith(
            cardMinor: current.cardMinor + transaction.amountMinor,
          );
          break;
        case IncomeDetailPaymentMethod.other:
          break;
      }
    }

    final List<IncomeDetailChartPoint> chartSeries = <IncomeDetailChartPoint>[
      for (final MapEntry<DateTime, _DailyAccumulator> entry in byDay.entries)
        IncomeDetailChartPoint(
          date: entry.key,
          cashMinor: entry.value.cashMinor,
          cardMinor: entry.value.cardMinor,
        ),
    ];

    final List<IncomeDetailBreakdownRow> breakdownRows = chartSeries
        .map(
          (IncomeDetailChartPoint point) => IncomeDetailBreakdownRow(
            date: point.date,
            cashMinor: point.cashMinor,
            cardMinor: point.cardMinor,
          ),
        )
        .toList();

    final int cashIncomeMinor = chartSeries.fold<int>(
      0,
      (int sum, IncomeDetailChartPoint point) => sum + point.cashMinor,
    );
    final int cardIncomeMinor = chartSeries.fold<int>(
      0,
      (int sum, IncomeDetailChartPoint point) => sum + point.cardMinor,
    );
    final int totalIncomeMinor = cashIncomeMinor + cardIncomeMinor;
    final double cashSharePercent = totalIncomeMinor == 0
        ? 0
        : (cashIncomeMinor / totalIncomeMinor) * 100;
    final double cardSharePercent = totalIncomeMinor == 0
        ? 0
        : (cardIncomeMinor / totalIncomeMinor) * 100;

    return IncomeDetailViewModel(
      query: query,
      selectedRangeLabel: range.label,
      rangeStart: range.start,
      rangeEnd: range.end,
      totalIncomeMinor: totalIncomeMinor,
      cashIncomeMinor: cashIncomeMinor,
      cardIncomeMinor: cardIncomeMinor,
      cashSharePercent: cashSharePercent,
      cardSharePercent: cardSharePercent,
      chartSeries: chartSeries,
      breakdownRows: breakdownRows,
      highestDayInsight: _buildHighestDayInsight(chartSeries, strings),
      averagePerDayInsight: _buildAveragePerDayInsight(
        totalIncomeMinor: totalIncomeMinor,
        dayCount: range.dayCount,
        strings: strings,
      ),
      bestPaymentMixInsight: _buildBestMixInsight(chartSeries, strings),
      isEmpty: totalIncomeMinor == 0,
      hasDisabledChartState: totalIncomeMinor == 0,
    );
  }

  IncomeDetailInsight _buildHighestDayInsight(
    List<IncomeDetailChartPoint> chartSeries,
    AppLocalizations strings,
  ) {
    IncomeDetailChartPoint? winner;
    for (final IncomeDetailChartPoint point in chartSeries) {
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

    if (winner == null) {
      return IncomeDetailInsight(
        title: strings.highestDay,
        primary: strings.noIncomeYet,
        secondary: strings.selectedRangeIsEmpty,
        isEmpty: true,
      );
    }

    return IncomeDetailInsight(
      title: strings.highestDay,
      primary: _weekdayShortFormatter.format(winner.date),
      secondary: _formatCurrency(winner.totalMinor),
    );
  }

  IncomeDetailInsight _buildAveragePerDayInsight({
    required int totalIncomeMinor,
    required int dayCount,
    required AppLocalizations strings,
  }) {
    final double averageMinor = dayCount == 0 ? 0 : totalIncomeMinor / dayCount;
    return IncomeDetailInsight(
      title: strings.averagePerDay,
      primary: _formatCurrency(averageMinor.round()),
      secondary: strings.acrossDays(dayCount),
      isEmpty: totalIncomeMinor == 0,
    );
  }

  IncomeDetailInsight _buildBestMixInsight(
    List<IncomeDetailChartPoint> chartSeries,
    AppLocalizations strings,
  ) {
    IncomeDetailChartPoint? winner;
    double winnerRatio = -1;

    for (final IncomeDetailChartPoint point in chartSeries) {
      if (point.totalMinor == 0) {
        continue;
      }
      final double ratio = point.cashMinor / point.totalMinor;
      if (winner == null ||
          ratio > winnerRatio ||
          (ratio == winnerRatio && point.totalMinor > winner.totalMinor) ||
          (ratio == winnerRatio &&
              point.totalMinor == winner.totalMinor &&
              point.date.isBefore(winner.date))) {
        winner = point;
        winnerRatio = ratio;
      }
    }

    if (winner == null) {
      return IncomeDetailInsight(
        title: strings.bestMixCash,
        primary: strings.noPaymentMixYet,
        secondary: strings.noIncomeDaysInRange,
        isEmpty: true,
      );
    }

    final int ratioPercent = (winnerRatio * 100).round();
    return IncomeDetailInsight(
      title: strings.bestMixCash,
      primary: _weekdayShortFormatter.format(winner.date),
      secondary: strings.cashPercent(ratioPercent),
    );
  }

  DateTime _atStartOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _formatCurrency(int amountMinor) {
    return _currencyFormatter.format(amountMinor / 100);
  }
}

class _DailyAccumulator {
  const _DailyAccumulator({this.cashMinor = 0, this.cardMinor = 0});

  final int cashMinor;
  final int cardMinor;

  _DailyAccumulator copyWith({int? cashMinor, int? cardMinor}) {
    return _DailyAccumulator(
      cashMinor: cashMinor ?? this.cashMinor,
      cardMinor: cardMinor ?? this.cardMinor,
    );
  }
}
