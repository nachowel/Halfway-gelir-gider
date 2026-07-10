import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../../../data/app_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../transactions/domain/transaction_subtitle.dart';
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
            ): _DailyAccumulator(),
        };
    final Map<String, int> incomePaymentTotals = <String, int>{};
    final Map<String, int> expensePaymentTotals = <String, int>{};
    final Map<String, _ExpenseCategoryAccumulator> expenseCategories =
        <String, _ExpenseCategoryAccumulator>{};
    final Map<String, _IncomeSourceAccumulator> incomeSources =
        <String, _IncomeSourceAccumulator>{};

    for (final NetProfitDetailTransaction transaction in transactions) {
      final DateTime day = _atStartOfDay(transaction.occurredOn);
      final _DailyAccumulator? current = byDay[day];
      if (current == null) {
        continue;
      }

      final NetProfitTransactionRow row = _buildTransactionRow(
        transaction,
        strings,
      );
      switch (transaction.type) {
        case NetProfitTransactionType.income:
          current.incomeMinor += transaction.amountMinor;
          if (transaction.paymentMethod == PaymentMethodType.cash) {
            current.cashIncomeMinor += transaction.amountMinor;
          } else if (transaction.paymentMethod == PaymentMethodType.card) {
            current.cardIncomeMinor += transaction.amountMinor;
          }
          current.incomeTransactions.add(row);

          final String paymentLabel = _incomePaymentLabel(transaction, strings);
          incomePaymentTotals[paymentLabel] =
              (incomePaymentTotals[paymentLabel] ?? 0) +
              transaction.amountMinor;
          final String sourceLabel = _incomeSourceLabel(transaction, strings);
          incomeSources
              .putIfAbsent(
                sourceLabel,
                () => _IncomeSourceAccumulator(sourceLabel),
              )
              .add(day, transaction.amountMinor);
        case NetProfitTransactionType.expense:
          current.expenseMinor += transaction.amountMinor;
          current.expenseTransactions.add(row);

          final String paymentLabel =
              '${strings.paymentMethodLabel(transaction.paymentMethod)} expenses';
          expensePaymentTotals[paymentLabel] =
              (expensePaymentTotals[paymentLabel] ?? 0) +
              transaction.amountMinor;
          expenseCategories
              .putIfAbsent(
                transaction.categoryName,
                () => _ExpenseCategoryAccumulator(transaction.categoryName),
              )
              .add(row);
      }
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
    final List<NetProfitDailyBreakdown> dailyBreakdowns =
        <NetProfitDailyBreakdown>[
          for (final MapEntry<DateTime, _DailyAccumulator> entry
              in byDay.entries)
            NetProfitDailyBreakdown(
              date: entry.key,
              incomeMinor: entry.value.incomeMinor,
              expenseMinor: entry.value.expenseMinor,
              cashIncomeMinor: entry.value.cashIncomeMinor,
              cardIncomeMinor: entry.value.cardIncomeMinor,
              incomeTransactions: List<NetProfitTransactionRow>.unmodifiable(
                entry.value.incomeTransactions,
              ),
              expenseTransactions: List<NetProfitTransactionRow>.unmodifiable(
                entry.value.expenseTransactions,
              ),
            ),
        ];

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
      incomePaymentBreakdowns:
          _orderedPaymentBreakdowns(incomePaymentTotals, <String>[
            strings.paymentMethodLabel(PaymentMethodType.cash),
            strings.paymentMethodLabel(PaymentMethodType.card),
            strings.sourcePlatformLabel(SourcePlatformType.uber),
            strings.sourcePlatformLabel(SourcePlatformType.justEat),
            strings.paymentMethodLabel(PaymentMethodType.other),
          ]),
      expensePaymentBreakdowns: _orderedPaymentBreakdowns(expensePaymentTotals, <
        String
      >[
        '${strings.paymentMethodLabel(PaymentMethodType.cash)} expenses',
        '${strings.paymentMethodLabel(PaymentMethodType.card)} expenses',
        '${strings.paymentMethodLabel(PaymentMethodType.bankTransfer)} expenses',
        '${strings.paymentMethodLabel(PaymentMethodType.other)} expenses',
      ]),
      dailyBreakdowns: dailyBreakdowns,
      expenseCategoryBreakdowns: _expenseCategoryBreakdowns(expenseCategories),
      incomeSourceBreakdowns: _incomeSourceBreakdowns(incomeSources, <String>[
        'Cash Sales',
        'Card Sales',
        strings.sourcePlatformLabel(SourcePlatformType.uber),
        strings.sourcePlatformLabel(SourcePlatformType.justEat),
        strings.paymentMethodLabel(PaymentMethodType.other),
      ]),
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

  List<NetProfitPaymentBreakdown> _orderedPaymentBreakdowns(
    Map<String, int> totals,
    List<String> order,
  ) {
    final List<NetProfitPaymentBreakdown> rows = <NetProfitPaymentBreakdown>[
      for (final String label in order)
        if ((totals[label] ?? 0) > 0)
          NetProfitPaymentBreakdown(label: label, amountMinor: totals[label]!),
    ];
    final Set<String> orderedLabels = order.toSet();
    final List<MapEntry<String, int>> extras =
        totals.entries.where((MapEntry<String, int> entry) {
          return entry.value > 0 && !orderedLabels.contains(entry.key);
        }).toList()..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
          final int amount = b.value.compareTo(a.value);
          if (amount != 0) return amount;
          return a.key.compareTo(b.key);
        });
    rows.addAll(
      extras.map(
        (MapEntry<String, int> entry) => NetProfitPaymentBreakdown(
          label: entry.key,
          amountMinor: entry.value,
        ),
      ),
    );
    return rows;
  }

  List<NetProfitExpenseCategoryBreakdown> _expenseCategoryBreakdowns(
    Map<String, _ExpenseCategoryAccumulator> categories,
  ) {
    final List<_ExpenseCategoryAccumulator> values = categories.values.toList()
      ..sort((_ExpenseCategoryAccumulator a, _ExpenseCategoryAccumulator b) {
        final int amount = b.amountMinor.compareTo(a.amountMinor);
        if (amount != 0) return amount;
        return a.categoryName.compareTo(b.categoryName);
      });
    return <NetProfitExpenseCategoryBreakdown>[
      for (final _ExpenseCategoryAccumulator value in values)
        NetProfitExpenseCategoryBreakdown(
          categoryName: value.categoryName,
          amountMinor: value.amountMinor,
          transactions: List<NetProfitTransactionRow>.unmodifiable(
            value.transactions,
          ),
        ),
    ];
  }

  List<NetProfitIncomeSourceBreakdown> _incomeSourceBreakdowns(
    Map<String, _IncomeSourceAccumulator> sources,
    List<String> order,
  ) {
    final List<_IncomeSourceAccumulator> values = sources.values.toList()
      ..sort((_IncomeSourceAccumulator a, _IncomeSourceAccumulator b) {
        final int aOrder = order.indexOf(a.label);
        final int bOrder = order.indexOf(b.label);
        if (aOrder != -1 || bOrder != -1) {
          return (aOrder == -1 ? order.length : aOrder).compareTo(
            bOrder == -1 ? order.length : bOrder,
          );
        }
        return a.label.compareTo(b.label);
      });
    return <NetProfitIncomeSourceBreakdown>[
      for (final _IncomeSourceAccumulator value in values)
        NetProfitIncomeSourceBreakdown(
          label: value.label,
          amountMinor: value.amountMinor,
          days: value.orderedDays,
        ),
    ];
  }

  NetProfitTransactionRow _buildTransactionRow(
    NetProfitDetailTransaction transaction,
    AppLocalizations strings,
  ) {
    final TransactionData data = TransactionData(
      id: '',
      type: transaction.type == NetProfitTransactionType.income
          ? TransactionType.income
          : TransactionType.expense,
      occurredOn: transaction.occurredOn,
      amountMinor: transaction.amountMinor,
      categoryId: '',
      categoryName: transaction.categoryName,
      paymentMethod: transaction.paymentMethod,
      createdAt: transaction.occurredOn,
      sourcePlatform: transaction.sourcePlatform,
      note: transaction.note,
      vendor: transaction.vendor,
      supplierId: transaction.supplierId,
      supplierName: transaction.supplierName,
      staffName: transaction.staffName,
    );
    return NetProfitTransactionRow(
      date: _atStartOfDay(transaction.occurredOn),
      title: buildTransactionTitle(data),
      subtitle: buildTransactionSubtitle(
        transaction: data,
        paymentLabel: strings.paymentMethodLabel,
        sourcePlatformLabel: strings.sourcePlatformLabel,
      ),
      amountMinor: transaction.amountMinor,
      paymentMethod: transaction.paymentMethod,
    );
  }

  String _incomePaymentLabel(
    NetProfitDetailTransaction transaction,
    AppLocalizations strings,
  ) {
    return switch (transaction.sourcePlatform) {
      SourcePlatformType.uber => strings.sourcePlatformLabel(
        SourcePlatformType.uber,
      ),
      SourcePlatformType.justEat => strings.sourcePlatformLabel(
        SourcePlatformType.justEat,
      ),
      _ => switch (transaction.paymentMethod) {
        PaymentMethodType.cash => strings.paymentMethodLabel(
          PaymentMethodType.cash,
        ),
        PaymentMethodType.card => strings.paymentMethodLabel(
          PaymentMethodType.card,
        ),
        _ => strings.paymentMethodLabel(PaymentMethodType.other),
      },
    };
  }

  String _incomeSourceLabel(
    NetProfitDetailTransaction transaction,
    AppLocalizations strings,
  ) {
    return switch (transaction.sourcePlatform) {
      SourcePlatformType.uber => strings.sourcePlatformLabel(
        SourcePlatformType.uber,
      ),
      SourcePlatformType.justEat => strings.sourcePlatformLabel(
        SourcePlatformType.justEat,
      ),
      _ =>
        transaction.categoryName.trim().isEmpty
            ? strings.paymentMethodLabel(PaymentMethodType.other)
            : transaction.categoryName.trim(),
    };
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
  int incomeMinor = 0;
  int expenseMinor = 0;
  int cashIncomeMinor = 0;
  int cardIncomeMinor = 0;
  final List<NetProfitTransactionRow> incomeTransactions =
      <NetProfitTransactionRow>[];
  final List<NetProfitTransactionRow> expenseTransactions =
      <NetProfitTransactionRow>[];
}

class _ExpenseCategoryAccumulator {
  _ExpenseCategoryAccumulator(this.categoryName);

  final String categoryName;
  int amountMinor = 0;
  final List<NetProfitTransactionRow> transactions =
      <NetProfitTransactionRow>[];

  void add(NetProfitTransactionRow row) {
    amountMinor += row.amountMinor;
    transactions.add(row);
  }
}

class _IncomeSourceAccumulator {
  _IncomeSourceAccumulator(this.label);

  final String label;
  int amountMinor = 0;
  final Map<DateTime, int> _days = <DateTime, int>{};

  void add(DateTime date, int amount) {
    amountMinor += amount;
    _days[date] = (_days[date] ?? 0) + amount;
  }

  List<NetProfitIncomeSourceDayBreakdown> get orderedDays {
    final List<MapEntry<DateTime, int>> entries = _days.entries.toList()
      ..sort((MapEntry<DateTime, int> a, MapEntry<DateTime, int> b) {
        return a.key.compareTo(b.key);
      });
    return <NetProfitIncomeSourceDayBreakdown>[
      for (final MapEntry<DateTime, int> entry in entries)
        NetProfitIncomeSourceDayBreakdown(
          date: entry.key,
          amountMinor: entry.value,
        ),
    ];
  }
}
