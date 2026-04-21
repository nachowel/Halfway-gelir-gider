import 'package:flutter/material.dart';

enum MonthlyReportsHealthState { empty, weak, moderate, strong }

enum MonthlyReportsInsightTone { neutral, brand, income, expense }

@immutable
class MonthlyReportsViewModel {
  const MonthlyReportsViewModel({
    required this.selectedMonth,
    required this.monthLabel,
    required this.yearLabel,
    required this.totalIncomeMinor,
    required this.totalExpensesMinor,
    required this.netProfitMinor,
    required this.previousMonthComparison,
    required this.health,
    required this.categoryBreakdownRows,
    required this.insights,
    required this.trendSeries,
    required this.dailySummary,
    required this.isEmpty,
    required this.hasCategoryData,
    required this.hasTrendData,
  });

  final DateTime selectedMonth;
  final String monthLabel;
  final String yearLabel;
  final int totalIncomeMinor;
  final int totalExpensesMinor;
  final int netProfitMinor;
  final MonthlyReportsComparison? previousMonthComparison;
  final MonthlyReportsHealth health;
  final List<MonthlyReportsCategoryRow> categoryBreakdownRows;
  final List<MonthlyReportsInsightItem> insights;
  final List<MonthlyReportsTrendPoint> trendSeries;
  final MonthlyReportsDailySummary dailySummary;
  final bool isEmpty;
  final bool hasCategoryData;
  final bool hasTrendData;

  bool get hasPreviousMonthComparison => previousMonthComparison != null;
}

@immutable
class MonthlyReportsComparison {
  const MonthlyReportsComparison({
    required this.previousNetMinor,
    required this.changeMinor,
    required this.percentageChange,
  });

  final int previousNetMinor;
  final int changeMinor;
  final double? percentageChange;

  bool get isPositiveChange => changeMinor > 0;
  bool get isNegativeChange => changeMinor < 0;
}

@immutable
class MonthlyReportsHealth {
  const MonthlyReportsHealth({
    required this.profitMarginPercent,
    required this.expenseRatioPercent,
    required this.label,
    required this.description,
    required this.state,
  });

  final double? profitMarginPercent;
  final double? expenseRatioPercent;
  final String label;
  final String description;
  final MonthlyReportsHealthState state;
}

@immutable
class MonthlyReportsCategoryRow {
  const MonthlyReportsCategoryRow({
    required this.categoryName,
    required this.amountMinor,
    required this.sharePercent,
    required this.shareFraction,
    required this.icon,
  });

  final String categoryName;
  final int amountMinor;
  final double sharePercent;
  final double shareFraction;
  final IconData icon;
}

@immutable
class MonthlyReportsInsightItem {
  const MonthlyReportsInsightItem({
    required this.title,
    required this.primary,
    required this.secondary,
    required this.tone,
    this.isEmpty = false,
  });

  final String title;
  final String primary;
  final String secondary;
  final MonthlyReportsInsightTone tone;
  final bool isEmpty;
}

@immutable
class MonthlyReportsTrendPoint {
  const MonthlyReportsTrendPoint({
    required this.monthStart,
    required this.monthLabel,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.netMinor,
    required this.incomeFraction,
    required this.expenseFraction,
    required this.isCurrentMonth,
  });

  final DateTime monthStart;
  final String monthLabel;
  final int incomeMinor;
  final int expenseMinor;
  final int netMinor;
  final double incomeFraction;
  final double expenseFraction;
  final bool isCurrentMonth;

  bool get hasActivity => incomeMinor > 0 || expenseMinor > 0;
}

@immutable
class MonthlyReportsDailySummary {
  const MonthlyReportsDailySummary({
    required this.bestDay,
    required this.worstDay,
    required this.averageDailyNetMinor,
    required this.calendarDayCount,
    required this.usesCalendarDays,
  });

  final MonthlyReportsDayMetric bestDay;
  final MonthlyReportsDayMetric worstDay;
  final int averageDailyNetMinor;
  final int calendarDayCount;
  final bool usesCalendarDays;
}

@immutable
class MonthlyReportsDayMetric {
  const MonthlyReportsDayMetric({
    required this.date,
    required this.netMinor,
    this.isEmpty = false,
  });

  final DateTime? date;
  final int netMinor;
  final bool isEmpty;
}
