import 'package:flutter/material.dart';

import '../../../data/app_models.dart';

enum PayeeRangePreset {
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  last3Weeks,
  last1Month,
  last2Months,
  thisYear,
  lastYear,
  custom,
}

enum SupplierSortOption {
  highestSpend,
  lowestSpend,
  mostTransactions,
  leastTransactions,
  recentlyUsed,
  longestInactive,
  alphabetical,
}

@immutable
class PayeeAnalyticsQuery {
  const PayeeAnalyticsQuery({
    this.preset = PayeeRangePreset.thisMonth,
    this.customStart,
    this.customEnd,
    this.searchQuery = '',
    this.sortOption = SupplierSortOption.highestSpend,
  });

  final PayeeRangePreset preset;
  final DateTime? customStart;
  final DateTime? customEnd;
  final String searchQuery;
  final SupplierSortOption sortOption;

  PayeeAnalyticsQuery copyWith({
    PayeeRangePreset? preset,
    Object? customStart = _unset,
    Object? customEnd = _unset,
    String? searchQuery,
    SupplierSortOption? sortOption,
  }) {
    return PayeeAnalyticsQuery(
      preset: preset ?? this.preset,
      customStart: identical(customStart, _unset)
          ? this.customStart
          : customStart as DateTime?,
      customEnd: identical(customEnd, _unset)
          ? this.customEnd
          : customEnd as DateTime?,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

@immutable
class PayeeRange {
  const PayeeRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  bool contains(DateTime occurredOn) {
    final DateTime day = DateTime(occurredOn.year, occurredOn.month, occurredOn.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}

@immutable
class PayeeAnalyticsDataset {
  const PayeeAnalyticsDataset({
    required this.transactions,
    required this.expenseCategoryIcons,
  });

  final List<TransactionData> transactions;
  final Map<String, IconData> expenseCategoryIcons;
}

@immutable
class PayeeRow {
  const PayeeRow({
    required this.payeeKey,
    required this.payeeName,
    required this.totalMinor,
    required this.transactionCount,
    required this.lastPaymentDate,
    required this.primaryCategory,
  });

  final String payeeKey;
  final String payeeName;
  final int totalMinor;
  final int transactionCount;
  final DateTime lastPaymentDate;
  final String primaryCategory;
}

@immutable
class PayeeSummaryTile {
  const PayeeSummaryTile({
    required this.label,
    required this.totalMinor,
    this.sharePercent,
  });

  final String label;
  final int totalMinor;
  final double? sharePercent;
}

@immutable
class PayeeDetailTransaction {
  const PayeeDetailTransaction({
    required this.id,
    required this.occurredOn,
    required this.categoryName,
    required this.amountMinor,
    required this.paymentMethod,
    required this.note,
    required this.payeeName,
  });

  final String id;
  final DateTime occurredOn;
  final String categoryName;
  final int amountMinor;
  final PaymentMethodType paymentMethod;
  final String? note;
  final String payeeName;
}

@immutable
class PayeeDetailViewModel {
  const PayeeDetailViewModel({
    required this.payeeName,
    required this.lifetimeTotalMinor,
    required this.transactionCount,
    required this.summaryTiles,
    required this.transactions,
    required this.metrics,
    required this.categoryBreakdown,
    required this.weeklyTrend,
    required this.monthlyTrend,
    required this.scorecard,
    required this.trendAnalysis,
    required this.purchaseFrequency,
    required this.biggestPurchases,
    required this.spendingDistribution,
    required this.monthlyHistory,
    required this.alerts,
  });

  final String payeeName;
  final int lifetimeTotalMinor;
  final int transactionCount;
  final List<PayeeSummaryTile> summaryTiles;
  final List<PayeeDetailTransaction> transactions;
  final PayeeDetailMetrics metrics;
  final List<PayeeCategoryBreakdown> categoryBreakdown;
  final List<PayeeTrendPoint> weeklyTrend;
  final List<PayeeTrendPoint> monthlyTrend;
  final SupplierScorecard scorecard;
  final SupplierTrendAnalysis trendAnalysis;
  final PurchaseFrequency purchaseFrequency;
  final List<BiggestPurchase> biggestPurchases;
  final SpendingDistribution spendingDistribution;
  final List<MonthlyHistoryPoint> monthlyHistory;
  final List<SupplierAlert> alerts;
}

@immutable
class PayeeComparisonMetric {
  const PayeeComparisonMetric({
    required this.label,
    required this.currentLabel,
    required this.previousLabel,
    required this.currentMinor,
    required this.previousMinor,
    required this.differenceMinor,
    required this.percentChange,
  });

  final String label;
  final String currentLabel;
  final String previousLabel;
  final int currentMinor;
  final int previousMinor;
  final int differenceMinor;
  final double? percentChange;
}

@immutable
class PayeeAnalyticsViewModel {
  const PayeeAnalyticsViewModel({
    required this.rows,
    required this.hasData,
    required this.dateLabel,
    required this.totalMinor,
    required this.topPayees,
    required this.comparisons,
  });

  final List<PayeeRow> rows;
  final bool hasData;
  final String dateLabel;
  final int totalMinor;
  final List<PayeeRow> topPayees;
  final List<PayeeComparisonMetric> comparisons;
}

@immutable
class PayeeDetailMetrics {
  const PayeeDetailMetrics({
    required this.lifetimeTotalMinor,
    required this.transactionCount,
    required this.averagePaymentMinor,
    required this.largestPaymentMinor,
    required this.smallestPaymentMinor,
    required this.averageDaysBetween,
  });

  final int lifetimeTotalMinor;
  final int transactionCount;
  final int averagePaymentMinor;
  final int largestPaymentMinor;
  final int smallestPaymentMinor;
  final double? averageDaysBetween;
}

@immutable
class PayeeCategoryBreakdown {
  const PayeeCategoryBreakdown({
    required this.categoryName,
    required this.amountMinor,
    required this.sharePercent,
    required this.transactionCount,
  });

  final String categoryName;
  final int amountMinor;
  final double sharePercent;
  final int transactionCount;
}

@immutable
class PayeeTrendPoint {
  const PayeeTrendPoint({
    required this.label,
    required this.start,
    required this.end,
    required this.totalMinor,
    required this.transactionCount,
  });

  final String label;
  final DateTime start;
  final DateTime end;
  final int totalMinor;
  final int transactionCount;
}

enum TrendDirection { increasing, stable, decreasing, insufficient }

@immutable
class SupplierScorecard {
  const SupplierScorecard({
    required this.lifetimeSpendMinor,
    required this.thisYearMinor,
    required this.lastYearMinor,
    required this.thisMonthMinor,
    required this.lastMonthMinor,
    required this.averageMonthlySpendMinor,
    required this.averageWeeklySpendMinor,
    required this.transactionCount,
    required this.firstPurchaseDate,
    required this.lastPurchaseDate,
    required this.daysSinceLastPurchase,
  });

  final int lifetimeSpendMinor;
  final int thisYearMinor;
  final int lastYearMinor;
  final int thisMonthMinor;
  final int lastMonthMinor;
  final int averageMonthlySpendMinor;
  final int averageWeeklySpendMinor;
  final int transactionCount;
  final DateTime? firstPurchaseDate;
  final DateTime? lastPurchaseDate;
  final int daysSinceLastPurchase;
}

@immutable
class SupplierTrendAnalysis {
  const SupplierTrendAnalysis({
    required this.monthlyDirection,
    required this.weeklyDirection,
    required this.threeMonthMovingAverageMinor,
    required this.yearOverYearPercentChange,
  });

  final TrendDirection monthlyDirection;
  final TrendDirection weeklyDirection;
  final int threeMonthMovingAverageMinor;
  final double? yearOverYearPercentChange;
}

@immutable
class PurchaseFrequency {
  const PurchaseFrequency({
    required this.averageDaysBetween,
    required this.expectedNextPurchaseDate,
    required this.isOverdue,
    required this.daysOverdue,
  });

  final double? averageDaysBetween;
  final DateTime? expectedNextPurchaseDate;
  final bool isOverdue;
  final int daysOverdue;
}

@immutable
class SupplierAlert {
  const SupplierAlert({
    required this.message,
    required this.type,
  });

  final String message;
  final SupplierAlertType type;
}

enum SupplierAlertType { inactivity, spendingIncrease, largePayment, highestMonth, averageIncrease }

@immutable
class MonthlyHistoryPoint {
  const MonthlyHistoryPoint({
    required this.monthStart,
    required this.label,
    required this.totalMinor,
    required this.transactionCount,
  });

  final DateTime monthStart;
  final String label;
  final int totalMinor;
  final int transactionCount;
}

@immutable
class SpendingDistribution {
  const SpendingDistribution({
    required this.thisWeekMinor,
    required this.lastWeekMinor,
    required this.last30DaysMinor,
    required this.last90DaysMinor,
    required this.last12MonthsMinor,
    required this.lifetimeMinor,
  });

  final int thisWeekMinor;
  final int lastWeekMinor;
  final int last30DaysMinor;
  final int last90DaysMinor;
  final int last12MonthsMinor;
  final int lifetimeMinor;
}

@immutable
class BiggestPurchase {
  const BiggestPurchase({
    required this.date,
    required this.amountMinor,
    required this.categoryName,
    required this.note,
  });

  final DateTime date;
  final int amountMinor;
  final String categoryName;
  final String? note;
}

const Object _unset = Object();
