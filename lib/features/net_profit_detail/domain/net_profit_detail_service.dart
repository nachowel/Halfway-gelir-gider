import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import 'net_profit_detail_models.dart';

class NetProfitDetailService {
  static final DateFormat _weekdayShortFormatter = DateFormat('EEE');
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_GB',
    symbol: '£',
    decimalDigits: 2,
  );

  NetProfitDetailRange resolveRange({
    required DateTime today,
    required NetProfitDetailQuery query,
    required AppLocalizations strings,
  }) {
    final DateTime normalizedToday = _atStartOfDay(today);

    switch (query.preset) {
      case NetProfitDetailRangePreset.thisWeek:
        final DateTime start = normalizedToday.subtract(
          Duration(days: normalizedToday.weekday - 1),
        );
        final DateTime end = start.add(const Duration(days: 6));
        return NetProfitDetailRange(
          start: start,
          end: end,
          label: strings.rangeLabel(start, end),
        );
      case NetProfitDetailRangePreset.lastWeek:
        final DateTime thisWeekStart = normalizedToday.subtract(
          Duration(days: normalizedToday.weekday - 1),
        );
        final DateTime start = thisWeekStart.subtract(const Duration(days: 7));
        final DateTime end = start.add(const Duration(days: 6));
        return NetProfitDetailRange(
          start: start,
          end: end,
          label: strings.rangeLabel(start, end),
        );
      case NetProfitDetailRangePreset.thisMonth:
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
        return NetProfitDetailRange(
          start: start,
          end: end,
          label: strings.rangeLabel(start, end),
        );
      case NetProfitDetailRangePreset.lastMonth:
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
        return NetProfitDetailRange(
          start: start,
          end: end,
          label: strings.rangeLabel(start, end),
        );
      case NetProfitDetailRangePreset.custom:
        final DateTime start = _atStartOfDay(
          query.customStart ?? normalizedToday,
        );
        final DateTime end = _atStartOfDay(query.customEnd ?? start);
        final DateTime normalizedStart = start.isBefore(end) ? start : end;
        final DateTime normalizedEnd = end.isAfter(start) ? end : start;
        return NetProfitDetailRange(
          start: normalizedStart,
          end: normalizedEnd,
          label: strings.rangeLabel(normalizedStart, normalizedEnd),
        );
    }
  }

  NetProfitDetailViewModel buildViewModel({
    required NetProfitDetailQuery query,
    required NetProfitDetailRange range,
    required Iterable<NetProfitDetailTransaction> transactions,
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

    for (final NetProfitDetailTransaction transaction in transactions) {
      final DateTime day = _atStartOfDay(transaction.occurredOn);
      final _DailyAccumulator current = byDay[day] ?? const _DailyAccumulator();
      byDay[day] = switch (transaction.type) {
        NetProfitTransactionType.income => current.copyWith(
          incomeMinor: current.incomeMinor + transaction.amountMinor,
        ),
        NetProfitTransactionType.expense => current.copyWith(
          expenseMinor: current.expenseMinor + transaction.amountMinor,
        ),
      };
    }

    final List<NetProfitChartPoint> dailyProfitSeries = <NetProfitChartPoint>[
      for (final MapEntry<DateTime, _DailyAccumulator> entry in byDay.entries)
        NetProfitChartPoint(
          date: entry.key,
          incomeMinor: entry.value.incomeMinor,
          expenseMinor: entry.value.expenseMinor,
        ),
    ];

    final List<NetProfitBreakdownRow> breakdownRows = dailyProfitSeries
        .map(
          (NetProfitChartPoint point) => NetProfitBreakdownRow(
            date: point.date,
            incomeMinor: point.incomeMinor,
            expenseMinor: point.expenseMinor,
          ),
        )
        .toList();

    final int incomeMinor = dailyProfitSeries.fold<int>(
      0,
      (int sum, NetProfitChartPoint point) => sum + point.incomeMinor,
    );
    final int expenseMinor = dailyProfitSeries.fold<int>(
      0,
      (int sum, NetProfitChartPoint point) => sum + point.expenseMinor,
    );
    final int netProfitMinor = incomeMinor - expenseMinor;
    final double marginPercent = incomeMinor == 0
        ? 0
        : (netProfitMinor / incomeMinor) * 100;
    final double expenseRatioPercent = incomeMinor == 0
        ? (expenseMinor == 0 ? 0 : 100)
        : (expenseMinor / incomeMinor) * 100;

    final NetProfitChartPoint? bestDay = _findExtremeDay(
      dailyProfitSeries,
      best: true,
    );
    final NetProfitChartPoint? worstDay = _findExtremeDay(
      dailyProfitSeries,
      best: false,
    );

    return NetProfitDetailViewModel(
      query: query,
      selectedRangeLabel: range.label,
      rangeStart: range.start,
      rangeEnd: range.end,
      netProfitMinor: netProfitMinor,
      incomeMinor: incomeMinor,
      expenseMinor: expenseMinor,
      marginPercent: marginPercent,
      health: _buildHealth(
        marginPercent: marginPercent,
        incomeMinor: incomeMinor,
        strings: strings,
      ),
      comparison: _buildComparison(
        incomeMinor: incomeMinor,
        expenseMinor: expenseMinor,
        expenseRatioPercent: expenseRatioPercent,
        strings: strings,
      ),
      dailyProfitSeries: dailyProfitSeries,
      breakdownRows: breakdownRows,
      kpis: _buildKpis(
        netProfitMinor: netProfitMinor,
        incomeMinor: incomeMinor,
        expenseMinor: expenseMinor,
        strings: strings,
      ),
      bestDayInsight: _buildBestDayInsight(bestDay, strings),
      worstDayInsight: _buildWorstDayInsight(worstDay, strings),
      averageDailyProfitInsight: _buildAverageProfitInsight(
        totalProfitMinor: netProfitMinor,
        dayCount: range.dayCount,
        strings: strings,
      ),
      showExpensePressureWarning: incomeMinor > 0 && expenseRatioPercent > 70,
      expensePressureMessage: incomeMinor > 0 && expenseRatioPercent > 70
          ? strings.expensePressureMessage
          : null,
      isEmpty: incomeMinor == 0 && expenseMinor == 0,
      hasDisabledChartState: incomeMinor == 0 && expenseMinor == 0,
    );
  }

  NetProfitHealth _buildHealth({
    required double marginPercent,
    required int incomeMinor,
    required AppLocalizations strings,
  }) {
    if (incomeMinor == 0) {
      return NetProfitHealth(
        marginPercent: 0,
        label: strings.noMarginYet,
        description: strings.marginAppearsWithIncome,
      );
    }

    if (marginPercent < 10) {
      return NetProfitHealth(
        marginPercent: marginPercent,
        label: strings.weak,
        description: strings.weakMarginDescription,
      );
    }
    if (marginPercent <= 25) {
      return NetProfitHealth(
        marginPercent: marginPercent,
        label: strings.moderate,
        description: strings.moderateMarginDescription,
      );
    }
    return NetProfitHealth(
      marginPercent: marginPercent,
      label: strings.strong,
      description: strings.strongMarginDescription,
    );
  }

  NetProfitComparison _buildComparison({
    required int incomeMinor,
    required int expenseMinor,
    required double expenseRatioPercent,
    required AppLocalizations strings,
  }) {
    final String message;
    if (incomeMinor == 0 && expenseMinor == 0) {
      message = strings.noActivitySelectedRange;
    } else if (incomeMinor == 0) {
      message = strings.expensesNotCoveredYet;
    } else {
      message = strings.expensesEatingPercent(expenseRatioPercent.round());
    }

    return NetProfitComparison(
      incomeMinor: incomeMinor,
      expenseMinor: expenseMinor,
      expenseRatioPercent: expenseRatioPercent,
      message: message,
    );
  }

  List<NetProfitKpi> _buildKpis({
    required int netProfitMinor,
    required int incomeMinor,
    required int expenseMinor,
    required AppLocalizations strings,
  }) {
    return <NetProfitKpi>[
      NetProfitKpi(
        title: strings.netProfit,
        primary: _formatCurrency(netProfitMinor),
        secondary: strings.incomeMinusExpenses,
        isEmpty: incomeMinor == 0 && expenseMinor == 0,
      ),
      NetProfitKpi(
        title: strings.totalIncome,
        primary: _formatCurrency(incomeMinor),
        secondary: strings.selectedRange,
        isEmpty: incomeMinor == 0,
      ),
      NetProfitKpi(
        title: strings.totalExpenses,
        primary: _formatCurrency(expenseMinor),
        secondary: strings.selectedRange,
        isEmpty: expenseMinor == 0,
      ),
    ];
  }

  NetProfitInsight _buildBestDayInsight(
    NetProfitChartPoint? bestDay,
    AppLocalizations strings,
  ) {
    if (bestDay == null) {
      return NetProfitInsight(
        title: strings.bestDay,
        primary: strings.noProfitYet,
        secondary: strings.selectedRangeIsEmpty,
        isEmpty: true,
      );
    }

    return NetProfitInsight(
      title: strings.bestDay,
      primary: _weekdayShortFormatter.format(bestDay.date),
      secondary: _formatCurrency(bestDay.profitMinor),
    );
  }

  NetProfitInsight _buildWorstDayInsight(
    NetProfitChartPoint? worstDay,
    AppLocalizations strings,
  ) {
    if (worstDay == null) {
      return NetProfitInsight(
        title: strings.worstDay,
        primary: strings.noLossYet,
        secondary: strings.selectedRangeIsEmpty,
        isEmpty: true,
      );
    }

    return NetProfitInsight(
      title: strings.worstDay,
      primary: _weekdayShortFormatter.format(worstDay.date),
      secondary: _formatCurrency(worstDay.profitMinor),
    );
  }

  NetProfitInsight _buildAverageProfitInsight({
    required int totalProfitMinor,
    required int dayCount,
    required AppLocalizations strings,
  }) {
    final double averageMinor = dayCount == 0 ? 0 : totalProfitMinor / dayCount;
    return NetProfitInsight(
      title: strings.averageDailyProfit,
      primary: _formatCurrency(averageMinor.round()),
      secondary: strings.acrossDays(dayCount),
      isEmpty: totalProfitMinor == 0,
    );
  }

  NetProfitChartPoint? _findExtremeDay(
    List<NetProfitChartPoint> series, {
    required bool best,
  }) {
    NetProfitChartPoint? winner;
    for (final NetProfitChartPoint point in series) {
      if (winner == null) {
        winner = point;
        continue;
      }
      final bool shouldReplace = best
          ? point.profitMinor > winner.profitMinor ||
                (point.profitMinor == winner.profitMinor &&
                    point.date.isBefore(winner.date))
          : point.profitMinor < winner.profitMinor ||
                (point.profitMinor == winner.profitMinor &&
                    point.date.isBefore(winner.date));
      if (shouldReplace) {
        winner = point;
      }
    }

    final bool allZero = series.every((NetProfitChartPoint point) {
      return point.incomeMinor == 0 && point.expenseMinor == 0;
    });
    if (allZero) {
      return null;
    }
    return winner;
  }

  double niceAxisMax(double rawMax) {
    if (rawMax <= 0) {
      return 100;
    }
    final double desired = rawMax * 1.15;
    final double exponent = math
        .pow(10, (math.log(desired) / math.ln10).floor())
        .toDouble();
    final double normalized = desired / exponent;
    final double multiplier = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;
    return multiplier * exponent;
  }

  DateTime _atStartOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _formatCurrency(int amountMinor) {
    return _currencyFormatter.format(amountMinor / 100);
  }
}

class _DailyAccumulator {
  const _DailyAccumulator({this.incomeMinor = 0, this.expenseMinor = 0});

  final int incomeMinor;
  final int expenseMinor;

  _DailyAccumulator copyWith({int? incomeMinor, int? expenseMinor}) {
    return _DailyAccumulator(
      incomeMinor: incomeMinor ?? this.incomeMinor,
      expenseMinor: expenseMinor ?? this.expenseMinor,
    );
  }
}
