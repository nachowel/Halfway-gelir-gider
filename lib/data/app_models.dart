import 'package:flutter/material.dart';

import '../shared/hi_fi/hi_fi_icon_tile.dart';

enum CategoryType { income, expense }

extension CategoryTypeX on CategoryType {
  String get dbValue => name;
  String get label => this == CategoryType.income ? 'Income' : 'Expense';
}

enum TransactionType { income, expense }

extension TransactionTypeX on TransactionType {
  String get dbValue => name;
}

enum PaymentMethodType { cash, card, bankTransfer, other }

extension PaymentMethodTypeX on PaymentMethodType {
  String get dbValue => switch (this) {
    PaymentMethodType.cash => 'cash',
    PaymentMethodType.card => 'card',
    PaymentMethodType.bankTransfer => 'bank_transfer',
    PaymentMethodType.other => 'other',
  };

  String get label => switch (this) {
    PaymentMethodType.cash => 'Cash',
    PaymentMethodType.card => 'Card',
    PaymentMethodType.bankTransfer => 'Transfer',
    PaymentMethodType.other => 'Other',
  };

  static PaymentMethodType fromDb(String value) => switch (value) {
    'cash' => PaymentMethodType.cash,
    'card' => PaymentMethodType.card,
    'bank_transfer' => PaymentMethodType.bankTransfer,
    _ => PaymentMethodType.other,
  };
}

enum SourcePlatformType { direct, uber, justEat, other }

extension SourcePlatformTypeX on SourcePlatformType {
  String get dbValue => switch (this) {
    SourcePlatformType.direct => 'direct',
    SourcePlatformType.uber => 'uber',
    SourcePlatformType.justEat => 'just_eat',
    SourcePlatformType.other => 'other',
  };

  String get label => switch (this) {
    SourcePlatformType.direct => 'Direct',
    SourcePlatformType.uber => 'Uber',
    SourcePlatformType.justEat => 'Just Eat',
    SourcePlatformType.other => 'Other',
  };

  static SourcePlatformType fromDb(String value) => switch (value) {
    'direct' => SourcePlatformType.direct,
    'uber' => SourcePlatformType.uber,
    'just_eat' => SourcePlatformType.justEat,
    _ => SourcePlatformType.other,
  };
}

enum RecurringFrequencyType { weekly, monthly, quarterly, yearly }

extension RecurringFrequencyTypeX on RecurringFrequencyType {
  String get dbValue => name;
  String get label => switch (this) {
    RecurringFrequencyType.weekly => 'Weekly',
    RecurringFrequencyType.monthly => 'Monthly',
    RecurringFrequencyType.quarterly => 'Quarterly',
    RecurringFrequencyType.yearly => 'Yearly',
  };

  static RecurringFrequencyType fromDb(String value) => switch (value) {
    'weekly' => RecurringFrequencyType.weekly,
    'monthly' => RecurringFrequencyType.monthly,
    'quarterly' => RecurringFrequencyType.quarterly,
    _ => RecurringFrequencyType.yearly,
  };
}

class AppAuthUser {
  const AppAuthUser({required this.id, required this.email});

  final String id;
  final String email;
}

class BusinessSettingsData {
  const BusinessSettingsData({
    required this.email,
    required this.businessName,
    required this.timezone,
    required this.currency,
    required this.weekStartsOn,
    required this.isBootstrapComplete,
  });

  final String email;
  final String businessName;
  final String timezone;
  final String currency;
  final int weekStartsOn;
  final bool isBootstrapComplete;
}

class CategoryData {
  const CategoryData({
    required this.id,
    required this.type,
    required this.name,
    required this.icon,
    required this.tone,
    required this.sortOrder,
    required this.isArchived,
    required this.entryCount,
    required this.monthlyTotalMinor,
  });

  final String id;
  final CategoryType type;
  final String name;
  final IconData icon;
  final HiFiIconTileTone tone;
  final int sortOrder;
  final bool isArchived;
  final int entryCount;
  final int monthlyTotalMinor;
}

class TransactionData {
  const TransactionData({
    required this.id,
    required this.type,
    required this.occurredOn,
    required this.amountMinor,
    required this.categoryId,
    required this.categoryName,
    required this.paymentMethod,
    required this.createdAt,
    this.sourcePlatform,
    this.note,
    this.vendor,
    this.attachmentPath,
    this.recurringExpenseId,
  });

  final String id;
  final TransactionType type;
  final DateTime occurredOn;
  final int amountMinor;
  final String categoryId;
  final String categoryName;
  final PaymentMethodType paymentMethod;
  final DateTime createdAt;
  final SourcePlatformType? sourcePlatform;
  final String? note;
  final String? vendor;
  final String? attachmentPath;
  final String? recurringExpenseId;
}

class RecurringExpenseData {
  const RecurringExpenseData({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.amountMinor,
    required this.frequency,
    required this.nextDueOn,
    required this.reminderDaysBefore,
    required this.reserveEnabled,
    required this.isActive,
    this.defaultPaymentMethod,
    this.note,
  });

  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final int amountMinor;
  final RecurringFrequencyType frequency;
  final DateTime nextDueOn;
  final int reminderDaysBefore;
  final bool reserveEnabled;
  final bool isActive;
  final PaymentMethodType? defaultPaymentMethod;
  final String? note;
}

enum RecurringUiStatus { late, soon, later }

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.weekLabel,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.cashIncomeMinor,
    required this.cardIncomeMinor,
    required this.netDeltaMinor,
    required this.recentTransactions,
    required this.upcomingRecurring,
  });

  final String weekLabel;
  final int incomeMinor;
  final int expenseMinor;
  final int cashIncomeMinor;
  final int cardIncomeMinor;
  final int netDeltaMinor;
  final List<TransactionData> recentTransactions;
  final List<RecurringUiItem> upcomingRecurring;

  int get netMinor => incomeMinor - expenseMinor;
}

class ReportsSnapshot {
  const ReportsSnapshot({
    required this.monthLabel,
    required this.yearLabel,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.breakdown,
  });

  final String monthLabel;
  final String yearLabel;
  final int incomeMinor;
  final int expenseMinor;
  final List<ReportBreakdownItem> breakdown;

  int get netMinor => incomeMinor - expenseMinor;
}

class ReportBreakdownItem {
  const ReportBreakdownItem({
    required this.categoryName,
    required this.amountMinor,
    required this.fraction,
    required this.icon,
  });

  final String categoryName;
  final int amountMinor;
  final double fraction;
  final IconData icon;
}

class RecurringUiItem {
  const RecurringUiItem({
    required this.record,
    required this.status,
    required this.statusLabel,
    required this.frequencyMeta,
    required this.icon,
  });

  final RecurringExpenseData record;
  final RecurringUiStatus status;
  final String statusLabel;
  final String frequencyMeta;
  final IconData icon;
}

class RecurringSummarySnapshot {
  const RecurringSummarySnapshot({
    required this.totalMinor,
    required this.paidMinor,
  });

  final int totalMinor;
  final int paidMinor;

  int get remainingMinor => totalMinor - paidMinor;
}

class EntryDraft {
  const EntryDraft({
    required this.type,
    required this.occurredOn,
    required this.amountMinor,
    required this.categoryId,
    required this.paymentMethod,
    this.sourcePlatform,
    this.note,
    this.vendor,
    this.attachmentPath,
  });

  final TransactionType type;
  final DateTime occurredOn;
  final int amountMinor;
  final String categoryId;
  final PaymentMethodType paymentMethod;
  final SourcePlatformType? sourcePlatform;
  final String? note;
  final String? vendor;
  final String? attachmentPath;
}

class RecurringDraft {
  const RecurringDraft({
    required this.name,
    required this.categoryId,
    required this.amountMinor,
    required this.frequency,
    required this.nextDueOn,
    this.reminderDaysBefore = 3,
    this.defaultPaymentMethod,
    this.note,
  });

  final String name;
  final String categoryId;
  final int amountMinor;
  final RecurringFrequencyType frequency;
  final DateTime nextDueOn;
  final int reminderDaysBefore;
  final PaymentMethodType? defaultPaymentMethod;
  final String? note;
}
