import '../../../data/app_models.dart';
import '../../../l10n/app_locale.dart';
import '../../../l10n/app_localizations.dart';
import 'payee_analytics_models.dart';

class PayeeAnalyticsService {
  const PayeeAnalyticsService();

  PayeeRange resolveRange({
    required DateTime today,
    required PayeeAnalyticsQuery query,
  }) {
    final DateTime normalizedToday = DateTime(
      today.year,
      today.month,
      today.day,
    );

    switch (query.preset) {
      case PayeeRangePreset.thisWeek:
        final DateTime start = normalizedToday.subtract(
          Duration(days: normalizedToday.weekday - 1),
        );
        return PayeeRange(
          start: start,
          end: start.add(const Duration(days: 6)),
        );
      case PayeeRangePreset.lastWeek:
        final DateTime thisWeekStart = normalizedToday.subtract(
          Duration(days: normalizedToday.weekday - 1),
        );
        final DateTime start = thisWeekStart.subtract(const Duration(days: 7));
        return PayeeRange(
          start: start,
          end: start.add(const Duration(days: 6)),
        );
      case PayeeRangePreset.thisMonth:
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
        return PayeeRange(start: start, end: end);
      case PayeeRangePreset.lastMonth:
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
        return PayeeRange(start: start, end: end);
      case PayeeRangePreset.last3Weeks:
        final DateTime end = normalizedToday;
        final DateTime start = end.subtract(const Duration(days: 20));
        return PayeeRange(start: start, end: end);
      case PayeeRangePreset.last1Month:
        final DateTime end = normalizedToday;
        final DateTime start = end.subtract(const Duration(days: 29));
        return PayeeRange(start: start, end: end);
      case PayeeRangePreset.last2Months:
        final DateTime end = normalizedToday;
        final DateTime start = end.subtract(const Duration(days: 59));
        return PayeeRange(start: start, end: end);
      case PayeeRangePreset.thisYear:
        final DateTime start = DateTime(normalizedToday.year, 1, 1);
        final DateTime end = DateTime(normalizedToday.year, 12, 31);
        return PayeeRange(start: start, end: end);
      case PayeeRangePreset.lastYear:
        final DateTime start = DateTime(normalizedToday.year - 1, 1, 1);
        final DateTime end = DateTime(normalizedToday.year - 1, 12, 31);
        return PayeeRange(start: start, end: end);
      case PayeeRangePreset.custom:
        final DateTime start = query.customStart ?? normalizedToday;
        final DateTime end = query.customEnd ?? start;
        final DateTime normalizedStart = start.isBefore(end) ? start : end;
        final DateTime normalizedEnd = start.isBefore(end) ? end : start;
        return PayeeRange(start: normalizedStart, end: normalizedEnd);
    }
  }

  String rangeLabel(PayeeRange range, AppLocalizations strings) {
    if (range.start.year == range.end.year &&
        range.start.month == range.end.month &&
        range.start.day == range.end.day) {
      return strings.dayMonthYear(range.start);
    }
    if (range.start.year == range.end.year) {
      return '${strings.dayMonth(range.start)} – ${strings.dayMonth(range.end)} ${range.end.year}';
    }
    return '${strings.dayMonthYear(range.start)} – ${strings.dayMonthYear(range.end)}';
  }

  String presetLabel(PayeeRangePreset preset, AppLocalizations strings) {
    switch (preset) {
      case PayeeRangePreset.thisWeek:
        return strings.thisWeek;
      case PayeeRangePreset.lastWeek:
        return strings.lastWeek;
      case PayeeRangePreset.thisMonth:
        return strings.thisMonth;
      case PayeeRangePreset.lastMonth:
        return strings.lastMonth;
      case PayeeRangePreset.last3Weeks:
        return strings.last3Weeks;
      case PayeeRangePreset.last1Month:
        return strings.last1Month;
      case PayeeRangePreset.last2Months:
        return strings.last2Months;
      case PayeeRangePreset.thisYear:
        return strings.thisYear;
      case PayeeRangePreset.lastYear:
        return strings.lastYear;
      case PayeeRangePreset.custom:
        return strings.customRange;
    }
  }

  PayeeAnalyticsViewModel buildViewModel({
    required PayeeAnalyticsDataset dataset,
    required PayeeAnalyticsQuery query,
    required AppLocalizations strings,
    DateTime? now,
  }) {
    final DateTime today = now ?? DateTime.now();
    final PayeeRange range = resolveRange(today: today, query: query);
    final String label = rangeLabel(range, strings);

    final Map<String, _PayeeAccumulator> aggregates =
        <String, _PayeeAccumulator>{};
    int totalMinor = 0;

    for (final TransactionData transaction in dataset.transactions) {
      if (transaction.type != TransactionType.expense) {
        continue;
      }
      if (!range.contains(transaction.occurredOn)) {
        continue;
      }
      final _ResolvedPayee resolved = _resolvePayee(transaction);
      final _PayeeAccumulator acc = aggregates.putIfAbsent(
        resolved.key,
        () => _PayeeAccumulator(key: resolved.key),
      );
      acc.add(transaction, resolved);
      totalMinor += transaction.amountMinor;
    }

    final String normalizedQuery = query.searchQuery.trim().toLowerCase();
    final List<PayeeRow> allRows = aggregates.values
        .map((_PayeeAccumulator acc) => acc.toRow(strings))
        .toList();

    final List<PayeeRow> sortedRows = _applySort(allRows, query.sortOption);

    final List<PayeeRow> rows = sortedRows.where((PayeeRow row) {
      if (normalizedQuery.isEmpty) {
        return true;
      }
      return row.payeeName.toLowerCase().contains(normalizedQuery) ||
          row.primaryCategory.toLowerCase().contains(normalizedQuery);
    }).toList();

    final List<PayeeRow> topPayees = sortedRows.take(10).toList();

    final List<PayeeComparisonMetric> comparisons = _buildComparisons(
      dataset: dataset,
      today: today,
      strings: strings,
    );

    return PayeeAnalyticsViewModel(
      rows: rows,
      hasData: rows.isNotEmpty,
      dateLabel: label,
      totalMinor: totalMinor,
      topPayees: topPayees,
      comparisons: comparisons,
    );
  }

  List<PayeeComparisonMetric> _buildComparisons({
    required PayeeAnalyticsDataset dataset,
    required DateTime today,
    required AppLocalizations strings,
  }) {
    final PayeeRange thisWeekRange = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisWeek),
    );
    final PayeeRange lastWeekRange = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.lastWeek),
    );
    final PayeeRange thisMonthRange = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
    );
    final PayeeRange lastMonthRange = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.lastMonth),
    );
    final PayeeRange thisYearRange = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisYear),
    );
    final PayeeRange lastYearRange = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.lastYear),
    );

    int sumRange(PayeeRange r) {
      int total = 0;
      for (final TransactionData t in dataset.transactions) {
        if (t.type != TransactionType.expense) continue;
        if (r.contains(t.occurredOn)) {
          total += t.amountMinor;
        }
      }
      return total;
    }

    final int thisWeek = sumRange(thisWeekRange);
    final int lastWeek = sumRange(lastWeekRange);
    final int thisMonth = sumRange(thisMonthRange);
    final int lastMonth = sumRange(lastMonthRange);
    final int thisYear = sumRange(thisYearRange);
    final int lastYear = sumRange(lastYearRange);

    return <PayeeComparisonMetric>[
      PayeeComparisonMetric(
        label: strings.thisWeekVsLastWeek,
        currentLabel: strings.thisWeek,
        previousLabel: strings.lastWeek,
        currentMinor: thisWeek,
        previousMinor: lastWeek,
        differenceMinor: thisWeek - lastWeek,
        percentChange: _percentChange(thisWeek, lastWeek),
      ),
      PayeeComparisonMetric(
        label: strings.thisMonthVsLastMonth,
        currentLabel: strings.thisMonth,
        previousLabel: strings.lastMonth,
        currentMinor: thisMonth,
        previousMinor: lastMonth,
        differenceMinor: thisMonth - lastMonth,
        percentChange: _percentChange(thisMonth, lastMonth),
      ),
      PayeeComparisonMetric(
        label: strings.thisYearVsLastYear,
        currentLabel: strings.thisYear,
        previousLabel: strings.lastYear,
        currentMinor: thisYear,
        previousMinor: lastYear,
        differenceMinor: thisYear - lastYear,
        percentChange: _percentChange(thisYear, lastYear),
      ),
    ];
  }

  double? _percentChange(int current, int previous) {
    if (previous == 0) {
      return null;
    }
    return ((current - previous) / previous.abs()) * 100;
  }

  PayeeDetailViewModel buildDetailViewModel({
    required PayeeAnalyticsDataset dataset,
    required String payeeKey,
    required AppLocalizations strings,
    DateTime? now,
  }) {
    final DateTime today = now ?? DateTime.now();
    final String? displayLabel = _reverseLookupPayeeName(dataset, payeeKey);

    int lifetimeMinor = 0;
    int count = 0;
    int paidThisWeekMinor = 0;
    int paidLastWeekMinor = 0;
    int paidThisMonthMinor = 0;
    int paidLastMonthMinor = 0;
    int paidLast3WeeksMinor = 0;
    int paidLast1MonthMinor = 0;
    int paidLast2MonthsMinor = 0;
    int paidThisYearMinor = 0;
    int paidLastYearMinor = 0;

    final List<PayeeDetailTransaction> history = <PayeeDetailTransaction>[];

    final PayeeRange rangeThisWeek = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisWeek),
    );
    final PayeeRange rangeLastWeek = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.lastWeek),
    );
    final PayeeRange rangeThisMonth = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
    );
    final PayeeRange rangeLastMonth = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.lastMonth),
    );
    final PayeeRange rangeLast3Weeks = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.last3Weeks),
    );
    final PayeeRange rangeLast1Month = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.last1Month),
    );
    final PayeeRange rangeLast2Months = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.last2Months),
    );
    final PayeeRange rangeThisYear = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisYear),
    );
    final PayeeRange rangeLastYear = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.lastYear),
    );

    for (final TransactionData transaction in dataset.transactions) {
      if (transaction.type != TransactionType.expense) {
        continue;
      }
      final _ResolvedPayee resolved = _resolvePayee(transaction);
      if (resolved.key != payeeKey) {
        continue;
      }
      lifetimeMinor += transaction.amountMinor;
      count++;
      if (rangeThisWeek.contains(transaction.occurredOn)) {
        paidThisWeekMinor += transaction.amountMinor;
      }
      if (rangeLastWeek.contains(transaction.occurredOn)) {
        paidLastWeekMinor += transaction.amountMinor;
      }
      if (rangeThisMonth.contains(transaction.occurredOn)) {
        paidThisMonthMinor += transaction.amountMinor;
      }
      if (rangeLastMonth.contains(transaction.occurredOn)) {
        paidLastMonthMinor += transaction.amountMinor;
      }
      if (rangeLast3Weeks.contains(transaction.occurredOn)) {
        paidLast3WeeksMinor += transaction.amountMinor;
      }
      if (rangeLast1Month.contains(transaction.occurredOn)) {
        paidLast1MonthMinor += transaction.amountMinor;
      }
      if (rangeLast2Months.contains(transaction.occurredOn)) {
        paidLast2MonthsMinor += transaction.amountMinor;
      }
      if (rangeThisYear.contains(transaction.occurredOn)) {
        paidThisYearMinor += transaction.amountMinor;
      }
      if (rangeLastYear.contains(transaction.occurredOn)) {
        paidLastYearMinor += transaction.amountMinor;
      }
      history.add(
        PayeeDetailTransaction(
          id: transaction.id,
          occurredOn: transaction.occurredOn,
          categoryName: strings.systemCategoryName(transaction.categoryName),
          amountMinor: transaction.amountMinor,
          paymentMethod: transaction.paymentMethod,
          note: transaction.note,
          payeeName: resolved.displayLabel ?? strings.unknownPayee,
        ),
      );
    }

    history.sort((PayeeDetailTransaction a, PayeeDetailTransaction b) {
      final int dateCompare = b.occurredOn.compareTo(a.occurredOn);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return a.id.compareTo(b.id);
    });

    final List<PayeeSummaryTile> tiles = <PayeeSummaryTile>[
      PayeeSummaryTile(
        label: strings.paidThisWeek,
        totalMinor: paidThisWeekMinor,
      ),
      PayeeSummaryTile(
        label: strings.paidLastWeek,
        totalMinor: paidLastWeekMinor,
      ),
      PayeeSummaryTile(
        label: strings.paidThisMonth,
        totalMinor: paidThisMonthMinor,
      ),
      PayeeSummaryTile(
        label: strings.paidLastMonth,
        totalMinor: paidLastMonthMinor,
      ),
      PayeeSummaryTile(
        label: strings.paidLast3Weeks,
        totalMinor: paidLast3WeeksMinor,
      ),
      PayeeSummaryTile(
        label: strings.paidLast1Month,
        totalMinor: paidLast1MonthMinor,
      ),
      PayeeSummaryTile(
        label: strings.paidLast2Months,
        totalMinor: paidLast2MonthsMinor,
      ),
      PayeeSummaryTile(
        label: strings.paidThisYear,
        totalMinor: paidThisYearMinor,
      ),
      PayeeSummaryTile(
        label: strings.paidLastYear,
        totalMinor: paidLastYearMinor,
      ),
    ];

    final PayeeDetailMetrics metricsData = _buildMetrics(
      history,
      lifetimeMinor,
      count,
    );

    final SupplierScorecard scorecard = buildScorecard(
      dataset: dataset,
      payeeKey: payeeKey,
      today: today,
    );

    final SupplierTrendAnalysis trendAnalysis = buildTrendAnalysis(
      dataset: dataset,
      payeeKey: payeeKey,
      today: today,
    );

    final PurchaseFrequency frequency = buildPurchaseFrequency(
      dataset: dataset,
      payeeKey: payeeKey,
      today: today,
    );

    final List<BiggestPurchase> biggestPurchases = buildBiggestPurchases(
      dataset: dataset,
      payeeKey: payeeKey,
      strings: strings,
    );

    final SpendingDistribution distribution = buildSpendingDistribution(
      dataset: dataset,
      payeeKey: payeeKey,
      today: today,
    );

    final List<MonthlyHistoryPoint> monthlyHistory = buildMonthlyHistory24(
      dataset: dataset,
      payeeKey: payeeKey,
      today: today,
      strings: strings,
    );

    final List<SupplierAlert> alerts = buildAlerts(
      dataset: dataset,
      payeeKey: payeeKey,
      scorecard: scorecard,
      trendAnalysis: trendAnalysis,
      frequency: frequency,
      lifetimeTotal: lifetimeMinor,
      transactionCount: count,
      averagePayment: metricsData.averagePaymentMinor,
      largestPayment: metricsData.largestPaymentMinor,
      today: today,
      strings: strings,
    );

    return PayeeDetailViewModel(
      payeeName: displayLabel ?? strings.unknownPayee,
      lifetimeTotalMinor: lifetimeMinor,
      transactionCount: count,
      summaryTiles: tiles,
      transactions: history,
      metrics: metricsData,
      categoryBreakdown: _buildCategoryBreakdown(
        history,
        lifetimeMinor,
        strings,
      ),
      weeklyTrend: _buildWeeklyTrend(dataset, payeeKey, today),
      monthlyTrend: _buildMonthlyTrend(dataset, payeeKey, today, strings),
      scorecard: scorecard,
      trendAnalysis: trendAnalysis,
      purchaseFrequency: frequency,
      biggestPurchases: biggestPurchases,
      spendingDistribution: distribution,
      monthlyHistory: monthlyHistory,
      alerts: alerts,
    );
  }

  PayeeDetailMetrics _buildMetrics(
    List<PayeeDetailTransaction> history,
    int lifetimeMinor,
    int count,
  ) {
    if (history.isEmpty) {
      return const PayeeDetailMetrics(
        lifetimeTotalMinor: 0,
        transactionCount: 0,
        averagePaymentMinor: 0,
        largestPaymentMinor: 0,
        smallestPaymentMinor: 0,
        averageDaysBetween: null,
      );
    }

    int largest = history.first.amountMinor;
    int smallest = history.first.amountMinor;
    for (final PayeeDetailTransaction t in history) {
      if (t.amountMinor > largest) largest = t.amountMinor;
      if (t.amountMinor < smallest) smallest = t.amountMinor;
    }

    final int avg = (lifetimeMinor / count).round();

    double? avgDays;
    if (history.length >= 2) {
      final List<PayeeDetailTransaction> sorted =
          List<PayeeDetailTransaction>.from(history)..sort(
            (PayeeDetailTransaction a, PayeeDetailTransaction b) =>
                a.occurredOn.compareTo(b.occurredOn),
          );
      int totalDays = 0;
      for (int i = 1; i < sorted.length; i++) {
        totalDays += sorted[i].occurredOn
            .difference(sorted[i - 1].occurredOn)
            .inDays;
      }
      avgDays = totalDays / (sorted.length - 1);
    }

    return PayeeDetailMetrics(
      lifetimeTotalMinor: lifetimeMinor,
      transactionCount: count,
      averagePaymentMinor: avg,
      largestPaymentMinor: largest,
      smallestPaymentMinor: smallest,
      averageDaysBetween: avgDays,
    );
  }

  List<PayeeCategoryBreakdown> _buildCategoryBreakdown(
    List<PayeeDetailTransaction> history,
    int lifetimeMinor,
    AppLocalizations strings,
  ) {
    final Map<String, _CategoryAcc> cats = <String, _CategoryAcc>{};
    for (final PayeeDetailTransaction t in history) {
      final _CategoryAcc acc = cats.putIfAbsent(
        t.categoryName,
        () => _CategoryAcc(categoryName: t.categoryName),
      );
      acc.totalMinor += t.amountMinor;
      acc.count++;
    }
    final List<PayeeCategoryBreakdown> result =
        cats.values.map((_CategoryAcc acc) {
          return PayeeCategoryBreakdown(
            categoryName: acc.categoryName,
            amountMinor: acc.totalMinor,
            sharePercent: lifetimeMinor == 0
                ? 0
                : (acc.totalMinor / lifetimeMinor) * 100,
            transactionCount: acc.count,
          );
        }).toList()..sort(
          (PayeeCategoryBreakdown a, PayeeCategoryBreakdown b) =>
              b.amountMinor.compareTo(a.amountMinor),
        );
    return result;
  }

  List<PayeeTrendPoint> _buildWeeklyTrend(
    PayeeAnalyticsDataset dataset,
    String payeeKey,
    DateTime today,
  ) {
    final List<PayeeTrendPoint> points = <PayeeTrendPoint>[];
    final DateTime normalizedToday = DateTime(
      today.year,
      today.month,
      today.day,
    );
    final DateTime thisWeekStart = normalizedToday.subtract(
      Duration(days: normalizedToday.weekday - 1),
    );

    for (int i = 11; i >= 0; i--) {
      final DateTime weekStart = thisWeekStart.subtract(Duration(days: 7 * i));
      final DateTime weekEnd = weekStart.add(const Duration(days: 6));
      final PayeeRange range = PayeeRange(start: weekStart, end: weekEnd);
      int total = 0;
      int count = 0;
      for (final TransactionData t in dataset.transactions) {
        if (t.type != TransactionType.expense) continue;
        final _ResolvedPayee resolved = _resolvePayee(t);
        if (resolved.key != payeeKey) continue;
        if (range.contains(t.occurredOn)) {
          total += t.amountMinor;
          count++;
        }
      }
      points.add(
        PayeeTrendPoint(
          label: 'W${weekStart.month}/${weekStart.day}',
          start: weekStart,
          end: weekEnd,
          totalMinor: total,
          transactionCount: count,
        ),
      );
    }
    return points;
  }

  List<PayeeTrendPoint> _buildMonthlyTrend(
    PayeeAnalyticsDataset dataset,
    String payeeKey,
    DateTime today,
    AppLocalizations strings,
  ) {
    final List<PayeeTrendPoint> points = <PayeeTrendPoint>[];
    final DateTime thisMonthStart = DateTime(today.year, today.month, 1);

    for (int i = 11; i >= 0; i--) {
      final DateTime monthStart = DateTime(
        thisMonthStart.year,
        thisMonthStart.month - i,
        1,
      );
      final DateTime monthEnd = DateTime(
        monthStart.year,
        monthStart.month + 1,
        0,
      );
      final PayeeRange range = PayeeRange(start: monthStart, end: monthEnd);
      int total = 0;
      int count = 0;
      for (final TransactionData t in dataset.transactions) {
        if (t.type != TransactionType.expense) continue;
        final _ResolvedPayee resolved = _resolvePayee(t);
        if (resolved.key != payeeKey) continue;
        if (range.contains(t.occurredOn)) {
          total += t.amountMinor;
          count++;
        }
      }
      points.add(
        PayeeTrendPoint(
          label: strings.monthShort(monthStart),
          start: monthStart,
          end: monthEnd,
          totalMinor: total,
          transactionCount: count,
        ),
      );
    }
    return points;
  }

  List<PayeeRow> _applySort(List<PayeeRow> rows, SupplierSortOption option) {
    final List<PayeeRow> copy = List<PayeeRow>.from(rows);
    switch (option) {
      case SupplierSortOption.highestSpend:
        copy.sort((a, b) {
          final c = b.totalMinor.compareTo(a.totalMinor);
          return c != 0
              ? c
              : a.payeeName.toLowerCase().compareTo(b.payeeName.toLowerCase());
        });
      case SupplierSortOption.lowestSpend:
        copy.sort((a, b) {
          final c = a.totalMinor.compareTo(b.totalMinor);
          return c != 0
              ? c
              : a.payeeName.toLowerCase().compareTo(b.payeeName.toLowerCase());
        });
      case SupplierSortOption.mostTransactions:
        copy.sort((a, b) {
          final c = b.transactionCount.compareTo(a.transactionCount);
          return c != 0
              ? c
              : a.payeeName.toLowerCase().compareTo(b.payeeName.toLowerCase());
        });
      case SupplierSortOption.leastTransactions:
        copy.sort((a, b) {
          final c = a.transactionCount.compareTo(b.transactionCount);
          return c != 0
              ? c
              : a.payeeName.toLowerCase().compareTo(b.payeeName.toLowerCase());
        });
      case SupplierSortOption.recentlyUsed:
        copy.sort((a, b) {
          final c = b.lastPaymentDate.compareTo(a.lastPaymentDate);
          return c != 0
              ? c
              : a.payeeName.toLowerCase().compareTo(b.payeeName.toLowerCase());
        });
      case SupplierSortOption.longestInactive:
        copy.sort((a, b) {
          final c = a.lastPaymentDate.compareTo(b.lastPaymentDate);
          return c != 0
              ? c
              : a.payeeName.toLowerCase().compareTo(b.payeeName.toLowerCase());
        });
      case SupplierSortOption.alphabetical:
        copy.sort(
          (a, b) =>
              a.payeeName.toLowerCase().compareTo(b.payeeName.toLowerCase()),
        );
    }
    return copy;
  }

  String sortOptionLabel(SupplierSortOption option, AppLocalizations strings) {
    switch (option) {
      case SupplierSortOption.highestSpend:
        return strings.sortHighestSpend;
      case SupplierSortOption.lowestSpend:
        return strings.sortLowestSpend;
      case SupplierSortOption.mostTransactions:
        return strings.sortMostTransactions;
      case SupplierSortOption.leastTransactions:
        return strings.sortLeastTransactions;
      case SupplierSortOption.recentlyUsed:
        return strings.sortRecentlyUsed;
      case SupplierSortOption.longestInactive:
        return strings.sortLongestInactive;
      case SupplierSortOption.alphabetical:
        return strings.sortAlphabetical;
    }
  }

  SupplierScorecard buildScorecard({
    required PayeeAnalyticsDataset dataset,
    required String payeeKey,
    required DateTime today,
  }) {
    final DateTime normalizedToday = DateTime(
      today.year,
      today.month,
      today.day,
    );
    final PayeeRange thisYearR = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisYear),
    );
    final PayeeRange lastYearR = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.lastYear),
    );
    final PayeeRange thisMonthR = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
    );
    final PayeeRange lastMonthR = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.lastMonth),
    );

    int lifetime = 0;
    int thisYear = 0;
    int lastYear = 0;
    int thisMonth = 0;
    int lastMonth = 0;
    int count = 0;
    DateTime? firstDate;
    DateTime? lastDate;

    for (final TransactionData t in dataset.transactions) {
      if (t.type != TransactionType.expense) continue;
      final _ResolvedPayee resolved = _resolvePayee(t);
      if (resolved.key != payeeKey) continue;
      lifetime += t.amountMinor;
      count++;
      final DateTime day = DateTime(
        t.occurredOn.year,
        t.occurredOn.month,
        t.occurredOn.day,
      );
      if (firstDate == null || day.isBefore(firstDate)) firstDate = day;
      if (lastDate == null || day.isAfter(lastDate)) lastDate = day;
      if (thisYearR.contains(t.occurredOn)) thisYear += t.amountMinor;
      if (lastYearR.contains(t.occurredOn)) lastYear += t.amountMinor;
      if (thisMonthR.contains(t.occurredOn)) thisMonth += t.amountMinor;
      if (lastMonthR.contains(t.occurredOn)) lastMonth += t.amountMinor;
    }

    final int daysSinceLast = lastDate == null
        ? 0
        : normalizedToday.difference(lastDate).inDays;
    final int monthsActive = firstDate == null
        ? 0
        : _monthsBetween(firstDate, normalizedToday);
    final int avgMonthly = monthsActive > 0
        ? (lifetime / monthsActive).round()
        : 0;
    final int weeksActive = firstDate == null
        ? 0
        : (normalizedToday.difference(firstDate).inDays ~/ 7).clamp(1, 99999);
    final int avgWeekly = weeksActive > 0
        ? (lifetime / weeksActive).round()
        : 0;

    return SupplierScorecard(
      lifetimeSpendMinor: lifetime,
      thisYearMinor: thisYear,
      lastYearMinor: lastYear,
      thisMonthMinor: thisMonth,
      lastMonthMinor: lastMonth,
      averageMonthlySpendMinor: avgMonthly,
      averageWeeklySpendMinor: avgWeekly,
      transactionCount: count,
      firstPurchaseDate: firstDate,
      lastPurchaseDate: lastDate,
      daysSinceLastPurchase: daysSinceLast,
    );
  }

  int _monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month) + 1;
  }

  SupplierTrendAnalysis buildTrendAnalysis({
    required PayeeAnalyticsDataset dataset,
    required String payeeKey,
    required DateTime today,
  }) {
    final monthly = _buildMonthlyTrend(
      dataset,
      payeeKey,
      today,
      AppLocalizations(AppLocale.en),
    );
    final weekly = _buildWeeklyTrend(dataset, payeeKey, today);

    final TrendDirection monthlyDir = _detectTrend(monthly);
    final TrendDirection weeklyDir = _detectTrend(weekly);

    final int m3Total = monthly.length >= 3
        ? monthly[monthly.length - 3].totalMinor +
              monthly[monthly.length - 2].totalMinor +
              monthly[monthly.length - 1].totalMinor
        : monthly.fold(0, (sum, p) => sum + p.totalMinor);
    final int m3Avg = monthly.length >= 3
        ? (m3Total / 3).round()
        : (monthly.isEmpty ? 0 : (m3Total / monthly.length).round());

    final PayeeRange thisYearR = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisYear),
    );
    final PayeeRange lastYearR = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.lastYear),
    );
    int thisYearTotal = 0;
    int lastYearTotal = 0;
    for (final TransactionData t in dataset.transactions) {
      if (t.type != TransactionType.expense) continue;
      if (_resolvePayee(t).key != payeeKey) continue;
      if (thisYearR.contains(t.occurredOn)) thisYearTotal += t.amountMinor;
      if (lastYearR.contains(t.occurredOn)) lastYearTotal += t.amountMinor;
    }
    final double? yoyChange = _percentChange(thisYearTotal, lastYearTotal);

    return SupplierTrendAnalysis(
      monthlyDirection: monthlyDir,
      weeklyDirection: weeklyDir,
      threeMonthMovingAverageMinor: m3Avg,
      yearOverYearPercentChange: yoyChange,
    );
  }

  TrendDirection _detectTrend(List<PayeeTrendPoint> points) {
    if (points.length < 3) return TrendDirection.insufficient;
    final int n = points.length;
    final int recent = points[n - 1].totalMinor + points[n - 2].totalMinor;
    final int earlier =
        points[n - 3].totalMinor + (n >= 4 ? points[n - 4].totalMinor : 0);
    if (recent == 0 && earlier == 0) return TrendDirection.stable;
    if (earlier == 0 && recent > 0) {
      final int nonZeroCount = points.where((p) => p.totalMinor > 0).length;
      if (nonZeroCount < 3) return TrendDirection.insufficient;
      return TrendDirection.increasing;
    }
    if (recent == 0 && earlier > 0) {
      final int nonZeroCount = points.where((p) => p.totalMinor > 0).length;
      if (nonZeroCount < 3) return TrendDirection.insufficient;
      return TrendDirection.decreasing;
    }
    final double ratio = recent / earlier;
    if (ratio > 1.15) return TrendDirection.increasing;
    if (ratio < 0.85) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  PurchaseFrequency buildPurchaseFrequency({
    required PayeeAnalyticsDataset dataset,
    required String payeeKey,
    required DateTime today,
  }) {
    final DateTime normalizedToday = DateTime(
      today.year,
      today.month,
      today.day,
    );
    final List<DateTime> dates = <DateTime>[];
    for (final TransactionData t in dataset.transactions) {
      if (t.type != TransactionType.expense) continue;
      if (_resolvePayee(t).key != payeeKey) continue;
      dates.add(
        DateTime(t.occurredOn.year, t.occurredOn.month, t.occurredOn.day),
      );
    }
    dates.sort();

    if (dates.length < 2) {
      return PurchaseFrequency(
        averageDaysBetween: null,
        expectedNextPurchaseDate: null,
        isOverdue: false,
        daysOverdue: 0,
      );
    }

    int totalDays = 0;
    for (int i = 1; i < dates.length; i++) {
      totalDays += dates[i].difference(dates[i - 1]).inDays;
    }
    final double avg = totalDays / (dates.length - 1);
    final DateTime lastDate = dates.last;
    final DateTime expectedNext = lastDate.add(Duration(days: avg.round()));
    final bool overdue = normalizedToday.isAfter(expectedNext);
    final int daysOverdue = overdue
        ? normalizedToday.difference(expectedNext).inDays
        : 0;

    return PurchaseFrequency(
      averageDaysBetween: avg,
      expectedNextPurchaseDate: expectedNext,
      isOverdue: overdue,
      daysOverdue: daysOverdue,
    );
  }

  List<BiggestPurchase> buildBiggestPurchases({
    required PayeeAnalyticsDataset dataset,
    required String payeeKey,
    required AppLocalizations strings,
  }) {
    final List<BiggestPurchase> purchases = <BiggestPurchase>[];
    for (final TransactionData t in dataset.transactions) {
      if (t.type != TransactionType.expense) continue;
      if (_resolvePayee(t).key != payeeKey) continue;
      purchases.add(
        BiggestPurchase(
          date: t.occurredOn,
          amountMinor: t.amountMinor,
          categoryName: strings.systemCategoryName(t.categoryName),
          note: t.note,
        ),
      );
    }
    purchases.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
    return purchases.take(10).toList();
  }

  SpendingDistribution buildSpendingDistribution({
    required PayeeAnalyticsDataset dataset,
    required String payeeKey,
    required DateTime today,
  }) {
    final DateTime normalizedToday = DateTime(
      today.year,
      today.month,
      today.day,
    );
    final PayeeRange thisWeekR = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisWeek),
    );
    final PayeeRange lastWeekR = resolveRange(
      today: today,
      query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.lastWeek),
    );
    final DateTime last30Start = normalizedToday.subtract(
      const Duration(days: 29),
    );
    final DateTime last90Start = normalizedToday.subtract(
      const Duration(days: 89),
    );
    final DateTime last12MonthsStart = DateTime(
      normalizedToday.year,
      normalizedToday.month - 11,
      1,
    );

    int thisWeek = 0;
    int lastWeek = 0;
    int last30 = 0;
    int last90 = 0;
    int last12 = 0;
    int lifetime = 0;

    for (final TransactionData t in dataset.transactions) {
      if (t.type != TransactionType.expense) continue;
      if (_resolvePayee(t).key != payeeKey) continue;
      final DateTime day = DateTime(
        t.occurredOn.year,
        t.occurredOn.month,
        t.occurredOn.day,
      );
      lifetime += t.amountMinor;
      if (thisWeekR.contains(t.occurredOn)) {
        thisWeek += t.amountMinor;
      }
      if (lastWeekR.contains(t.occurredOn)) {
        lastWeek += t.amountMinor;
      }
      if (!day.isBefore(last30Start) && !day.isAfter(normalizedToday)) {
        last30 += t.amountMinor;
      }
      if (!day.isBefore(last90Start) && !day.isAfter(normalizedToday)) {
        last90 += t.amountMinor;
      }
      if (!day.isBefore(last12MonthsStart) && !day.isAfter(normalizedToday)) {
        last12 += t.amountMinor;
      }
    }

    return SpendingDistribution(
      thisWeekMinor: thisWeek,
      lastWeekMinor: lastWeek,
      last30DaysMinor: last30,
      last90DaysMinor: last90,
      last12MonthsMinor: last12,
      lifetimeMinor: lifetime,
    );
  }

  List<MonthlyHistoryPoint> buildMonthlyHistory24({
    required PayeeAnalyticsDataset dataset,
    required String payeeKey,
    required DateTime today,
    required AppLocalizations strings,
  }) {
    final List<MonthlyHistoryPoint> points = <MonthlyHistoryPoint>[];
    final DateTime thisMonthStart = DateTime(today.year, today.month, 1);

    for (int i = 23; i >= 0; i--) {
      final DateTime monthStart = DateTime(
        thisMonthStart.year,
        thisMonthStart.month - i,
        1,
      );
      final DateTime monthEnd = DateTime(
        monthStart.year,
        monthStart.month + 1,
        0,
      );
      final PayeeRange range = PayeeRange(start: monthStart, end: monthEnd);
      int total = 0;
      int count = 0;
      for (final TransactionData t in dataset.transactions) {
        if (t.type != TransactionType.expense) continue;
        if (_resolvePayee(t).key != payeeKey) continue;
        if (range.contains(t.occurredOn)) {
          total += t.amountMinor;
          count++;
        }
      }
      points.add(
        MonthlyHistoryPoint(
          monthStart: monthStart,
          label: strings.monthShort(monthStart),
          totalMinor: total,
          transactionCount: count,
        ),
      );
    }
    return points;
  }

  List<SupplierAlert> buildAlerts({
    required PayeeAnalyticsDataset dataset,
    required String payeeKey,
    required SupplierScorecard scorecard,
    required SupplierTrendAnalysis trendAnalysis,
    required PurchaseFrequency frequency,
    required int lifetimeTotal,
    required int transactionCount,
    required int averagePayment,
    required int largestPayment,
    required DateTime today,
    required AppLocalizations strings,
  }) {
    final List<SupplierAlert> alerts = <SupplierAlert>[];

    if (scorecard.lastPurchaseDate != null &&
        scorecard.daysSinceLastPurchase >= 30) {
      alerts.add(
        SupplierAlert(
          message: strings.alertInactivity(scorecard.daysSinceLastPurchase),
          type: SupplierAlertType.inactivity,
        ),
      );
    }

    if (trendAnalysis.monthlyDirection == TrendDirection.increasing &&
        scorecard.thisMonthMinor > 0 &&
        scorecard.lastMonthMinor > 0) {
      final double? pct = _percentChange(
        scorecard.thisMonthMinor,
        scorecard.lastMonthMinor,
      );
      if (pct != null && pct > 10) {
        alerts.add(
          SupplierAlert(
            message: strings.alertSpendingIncrease(pct.round()),
            type: SupplierAlertType.spendingIncrease,
          ),
        );
      }
    }

    if (scorecard.thisMonthMinor > 0 &&
        scorecard.thisMonthMinor >= largestPayment * 3 &&
        scorecard.thisMonthMinor > averagePayment * 2) {
      alerts.add(
        SupplierAlert(
          message: strings.alertLargePayment,
          type: SupplierAlertType.largePayment,
        ),
      );
    }

    final int highestMonth = _findHighestMonth(dataset, payeeKey, today);
    if (scorecard.thisMonthMinor > 0 &&
        scorecard.thisMonthMinor >= highestMonth) {
      alerts.add(
        SupplierAlert(
          message: strings.alertHighestMonth,
          type: SupplierAlertType.highestMonth,
        ),
      );
    }

    if (averagePayment > 0 && largestPayment > averagePayment * 4) {
      alerts.add(
        SupplierAlert(
          message: strings.alertAverageIncrease,
          type: SupplierAlertType.averageIncrease,
        ),
      );
    }

    if (frequency.isOverdue && frequency.daysOverdue > 0) {
      alerts.add(
        SupplierAlert(
          message: strings.alertPurchaseOverdue(frequency.daysOverdue),
          type: SupplierAlertType.inactivity,
        ),
      );
    }

    return alerts;
  }

  int _findHighestMonth(
    PayeeAnalyticsDataset dataset,
    String payeeKey,
    DateTime today,
  ) {
    final history = buildMonthlyHistory24(
      dataset: dataset,
      payeeKey: payeeKey,
      today: today,
      strings: AppLocalizations(AppLocale.en),
    );
    int highest = 0;
    for (final p in history) {
      if (p.totalMinor > highest) highest = p.totalMinor;
    }
    return highest;
  }

  _ResolvedPayee _resolvePayee(TransactionData transaction) {
    final String? supplierName = _normalize(transaction.supplierName);
    if (supplierName != null) {
      return _ResolvedPayee(
        key: _payeeKey(supplierName),
        displayLabel: transaction.supplierName!.trim(),
      );
    }
    final String? vendor = _normalize(transaction.vendor);
    if (vendor != null) {
      return _ResolvedPayee(
        key: _payeeKey(vendor),
        displayLabel: transaction.vendor!.trim(),
      );
    }
    final String? staffName = _normalize(transaction.staffName);
    if (staffName != null) {
      return _ResolvedPayee(
        key: _payeeKey(staffName),
        displayLabel: transaction.staffName!.trim(),
      );
    }
    return _ResolvedPayee(key: 'unknown', displayLabel: null);
  }

  String? _normalize(String? raw) {
    if (raw == null) {
      return null;
    }
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String _payeeKey(String name) {
    final RegExp spaces = RegExp(r'\s+');
    return name.toLowerCase().replaceAll(spaces, ' ').trim();
  }

  String? _reverseLookupPayeeName(
    PayeeAnalyticsDataset dataset,
    String payeeKey,
  ) {
    for (final TransactionData transaction in dataset.transactions) {
      if (transaction.type != TransactionType.expense) {
        continue;
      }
      final _ResolvedPayee resolved = _resolvePayee(transaction);
      if (resolved.key == payeeKey) {
        return resolved.displayLabel;
      }
    }
    return null;
  }
}

class _ResolvedPayee {
  const _ResolvedPayee({required this.key, required this.displayLabel});

  final String key;
  final String? displayLabel;
}

class _PayeeAccumulator {
  _PayeeAccumulator({required this.key});

  final String key;
  String? displayLabel;
  int totalMinor = 0;
  int count = 0;
  DateTime? lastPaymentDate;
  final Map<String, int> _categoryTotals = <String, int>{};
  String? _primaryCategory;
  final Map<String, int> _categoryCounts = <String, int>{};

  void add(TransactionData transaction, _ResolvedPayee resolved) {
    displayLabel ??= resolved.displayLabel;
    totalMinor += transaction.amountMinor;
    count++;
    if (lastPaymentDate == null ||
        transaction.occurredOn.isAfter(lastPaymentDate!)) {
      lastPaymentDate = DateTime(
        transaction.occurredOn.year,
        transaction.occurredOn.month,
        transaction.occurredOn.day,
      );
    }
    final String categoryName = transaction.categoryName.trim();
    if (categoryName.isEmpty) {
      return;
    }
    _categoryTotals[categoryName] =
        (_categoryTotals[categoryName] ?? 0) + transaction.amountMinor;
    _categoryCounts[categoryName] = (_categoryCounts[categoryName] ?? 0) + 1;
  }

  String get primaryCategory {
    if (_primaryCategory != null) {
      return _primaryCategory!;
    }
    String? best;
    int bestAmount = -1;
    for (final MapEntry<String, int> entry in _categoryTotals.entries) {
      if (entry.value > bestAmount) {
        bestAmount = entry.value;
        best = entry.key;
      }
    }
    _primaryCategory = best ?? '';
    return _primaryCategory!;
  }

  PayeeRow toRow(AppLocalizations strings) {
    return PayeeRow(
      payeeKey: key,
      payeeName: displayLabel ?? strings.unknownPayee,
      totalMinor: totalMinor,
      transactionCount: count,
      lastPaymentDate:
          lastPaymentDate ?? DateTime.fromMillisecondsSinceEpoch(0),
      primaryCategory: strings.systemCategoryName(primaryCategory),
    );
  }
}

class _CategoryAcc {
  _CategoryAcc({required this.categoryName});

  final String categoryName;
  int totalMinor = 0;
  int count = 0;
}
