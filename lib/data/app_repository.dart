import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/domain/category_model.dart' as domain_category;
import '../core/domain/recurring_model.dart' as domain_recurring;
import '../core/domain/transaction_model.dart' as domain_transaction;
import '../core/domain/types.dart' as domain;
import '../shared/hi_fi/hi_fi_icon_tile.dart';
import 'app_models.dart';

class GiderRepository {
  GiderRepository(this._client);

  final SupabaseClient _client;

  User get _user {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Authentication required');
    }
    return user;
  }

  static const List<_SeedCategory> _incomeSeeds = <_SeedCategory>[
    _SeedCategory(
      'Cash Sales',
      Icons.storefront_rounded,
      HiFiIconTileTone.income,
    ),
    _SeedCategory(
      'Card Sales',
      Icons.payments_rounded,
      HiFiIconTileTone.income,
    ),
    _SeedCategory(
      'Uber Settlement',
      Icons.directions_car_filled_rounded,
      HiFiIconTileTone.income,
    ),
    _SeedCategory(
      'Just Eat Settlement',
      Icons.delivery_dining_rounded,
      HiFiIconTileTone.income,
    ),
    _SeedCategory(
      'Other Income',
      Icons.work_outline_rounded,
      HiFiIconTileTone.income,
    ),
  ];

  static const List<_SeedCategory> _expenseSeeds = <_SeedCategory>[
    _SeedCategory('Rent', Icons.home_rounded, HiFiIconTileTone.expense),
    _SeedCategory('Utilities', Icons.bolt_rounded, HiFiIconTileTone.expense),
    _SeedCategory('Internet', Icons.wifi_rounded, HiFiIconTileTone.expense),
    _SeedCategory(
      'Stock Purchase',
      Icons.inventory_2_outlined,
      HiFiIconTileTone.expense,
    ),
    _SeedCategory(
      'Supplies',
      Icons.shopping_bag_outlined,
      HiFiIconTileTone.expense,
    ),
    _SeedCategory(
      'Maintenance',
      Icons.build_circle_outlined,
      HiFiIconTileTone.expense,
    ),
    _SeedCategory(
      'Delivery/Transport',
      Icons.local_shipping_outlined,
      HiFiIconTileTone.expense,
    ),
    _SeedCategory(
      'Other Expense',
      Icons.receipt_long_rounded,
      HiFiIconTileTone.expense,
    ),
  ];

  Future<void> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? businessName,
  }) async {
    final AuthResponse response = await _client.auth.signUp(
      email: email,
      password: password,
      data: <String, dynamic>{
        if (businessName != null && businessName.trim().isNotEmpty)
          'full_name': businessName.trim(),
      },
    );

    if (businessName != null &&
        businessName.trim().isNotEmpty &&
        response.user != null &&
        response.session != null) {
      await _client.from('business_settings').upsert(<String, dynamic>{
        'user_id': response.user!.id,
        'business_name': businessName.trim(),
      });
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<BusinessSettingsData> fetchBusinessSettings() async {
    final User user = _user;
    final Map<String, dynamic>? profile = await _client
        .from('profiles')
        .select('email, full_name')
        .eq('id', user.id)
        .maybeSingle();
    Map<String, dynamic>? settings = await _client
        .from('business_settings')
        .select('business_name, timezone, currency, week_starts_on')
        .eq('user_id', user.id)
        .maybeSingle();

    final String email = (profile?['email'] as String?) ?? user.email ?? '';
    final String? profileBusinessName = _normalizeOptionalText(
      profile?['full_name'] as String?,
    );
    final String? savedBusinessName = _normalizeOptionalText(
      settings?['business_name'] as String?,
    );

    if (settings == null ||
        (savedBusinessName == null && profileBusinessName != null)) {
      await _client.from('business_settings').upsert(<String, dynamic>{
        'user_id': user.id,
        if (profileBusinessName != null) 'business_name': profileBusinessName,
      });
      settings = <String, dynamic>{
        'business_name': profileBusinessName ?? savedBusinessName,
        'timezone': settings?['timezone'] ?? 'Europe/London',
        'currency': settings?['currency'] ?? 'GBP',
        'week_starts_on': settings?['week_starts_on'] ?? 1,
      };
    }

    final String? resolvedBusinessName = _normalizeOptionalText(
      settings['business_name'] as String?,
    );
    final bool isBootstrapComplete = resolvedBusinessName != null;
    final String businessName =
        resolvedBusinessName ?? profileBusinessName ?? email.split('@').first;

    return BusinessSettingsData(
      email: email,
      businessName: businessName,
      timezone: (settings['timezone'] as String?) ?? 'Europe/London',
      currency: (settings['currency'] as String?) ?? 'GBP',
      weekStartsOn: (settings['week_starts_on'] as int?) ?? 1,
      isBootstrapComplete: isBootstrapComplete,
    );
  }

  Future<void> updateBusinessName(String businessName) async {
    final User user = _user;
    await _client.from('business_settings').upsert(<String, dynamic>{
      'user_id': user.id,
      'business_name': businessName.trim(),
    });
  }

  Future<void> ensureSeedCategories() async {
    final User user = _user;
    final List<dynamic> current = await _client
        .from('categories')
        .select('id, type, name')
        .eq('user_id', user.id);
    if (current.isEmpty) {
      final List<Map<String, dynamic>> seedRows = <Map<String, dynamic>>[
        for (int i = 0; i < _incomeSeeds.length; i++)
          <String, dynamic>{
            'user_id': user.id,
            'type': CategoryType.income.dbValue,
            'name': _incomeSeeds[i].name,
            'icon': _incomeSeeds[i].iconName,
            'color_token': 'income',
            'sort_order': i,
          },
        for (int i = 0; i < _expenseSeeds.length; i++)
          <String, dynamic>{
            'user_id': user.id,
            'type': CategoryType.expense.dbValue,
            'name': _expenseSeeds[i].name,
            'icon': _expenseSeeds[i].iconName,
            'color_token': 'expense',
            'sort_order': i,
          },
      ];
      await _client.from('categories').insert(seedRows);
      return;
    }

    final Set<String> names = current
        .map((dynamic row) => '${row['type']}:${row['name']}'.toLowerCase())
        .toSet();
    final List<Map<String, dynamic>> missing = <Map<String, dynamic>>[];
    for (int i = 0; i < _incomeSeeds.length; i++) {
      final _SeedCategory seed = _incomeSeeds[i];
      if (!names.contains('income:${seed.name}'.toLowerCase())) {
        missing.add(<String, dynamic>{
          'user_id': user.id,
          'type': CategoryType.income.dbValue,
          'name': seed.name,
          'icon': seed.iconName,
          'color_token': 'income',
          'sort_order': i,
        });
      }
    }
    for (int i = 0; i < _expenseSeeds.length; i++) {
      final _SeedCategory seed = _expenseSeeds[i];
      if (!names.contains('expense:${seed.name}'.toLowerCase())) {
        missing.add(<String, dynamic>{
          'user_id': user.id,
          'type': CategoryType.expense.dbValue,
          'name': seed.name,
          'icon': seed.iconName,
          'color_token': 'expense',
          'sort_order': i,
        });
      }
    }
    if (missing.isNotEmpty) {
      await _client.from('categories').insert(missing);
    }
  }

  Future<List<CategoryData>> fetchCategories(CategoryType type) async {
    await ensureSeedCategories();
    final DateTimeRange month = _monthRange(_businessToday());
    final List<dynamic> rows = await _client
        .from('categories')
        .select('id, type, name, icon, color_token, is_archived, sort_order')
        .eq('user_id', _user.id)
        .eq('type', type.dbValue)
        .eq('is_archived', false)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: true);

    final List<dynamic> txRows = await _client
        .from('transactions')
        .select('category_id, amount_minor')
        .eq('user_id', _user.id)
        .eq('type', type.dbValue)
        .isFilter('deleted_at', null)
        .gte('occurred_on', _isoDate(month.start))
        .lte('occurred_on', _isoDate(month.end));

    final Map<String, int> counts = <String, int>{};
    final Map<String, int> totals = <String, int>{};
    for (final dynamic row in txRows) {
      final String categoryId = row['category_id'] as String;
      counts[categoryId] = (counts[categoryId] ?? 0) + 1;
      totals[categoryId] =
          (totals[categoryId] ?? 0) + (row['amount_minor'] as int);
    }

    return rows.map((dynamic row) {
      final String name = row['name'] as String;
      final _SeedCategory? fallback = _seedForName(type, name);
      final domain_category.CategoryModel category =
          domain_category.CategoryModel.fromPayload(
            id: row['id'] as String,
            type: row['type'] as String,
            name: name,
            icon: (row['icon'] as String?) ?? fallback?.iconName,
            colorToken: row['color_token'] as String?,
            sortOrder: (row['sort_order'] as int?) ?? 0,
            isArchived: row['is_archived'] as bool? ?? false,
          );
      final HiFiIconTileTone tone = category.type == domain.CategoryType.income
          ? HiFiIconTileTone.income
          : HiFiIconTileTone.expense;
      return CategoryData(
        id: category.id!,
        type: _toUiCategoryType(category.type),
        name: category.name,
        icon: _iconFromName(category.icon ?? fallback?.iconName),
        tone: tone,
        sortOrder: category.sortOrder,
        isArchived: category.isArchived,
        entryCount: counts[row['id']] ?? 0,
        monthlyTotalMinor: totals[row['id']] ?? 0,
      );
    }).toList();
  }

  Future<void> saveCategory({
    String? id,
    required CategoryType type,
    required String name,
  }) async {
    if (id == null) {
      final List<CategoryData> existing = await fetchCategories(type);
      final domain_category.CategoryModel category =
          domain_category.CategoryModel.fromPayload(
            type: type.dbValue,
            name: name,
            icon: _defaultIconForType(type),
            colorToken: type == CategoryType.income ? 'income' : 'expense',
            sortOrder: existing.length,
          );
      await _client.from('categories').insert(<String, dynamic>{
        'user_id': _user.id,
        'type': category.type.dbValue,
        'name': category.name,
        'icon': category.icon,
        'color_token': category.colorToken,
        'sort_order': category.sortOrder,
      });
    } else {
      final domain_category.CategoryModel category = domain_category
          .CategoryModel.fromPayload(id: id, type: type.dbValue, name: name);
      await _client
          .from('categories')
          .update(<String, dynamic>{'name': category.name})
          .eq('id', category.id!)
          .eq('user_id', _user.id);
    }
  }

  Future<List<TransactionData>> fetchTransactions({
    TransactionType? type,
    PaymentMethodType? paymentMethod,
    DateTime? start,
    DateTime? end,
  }) async {
    await ensureSeedCategories();
    var query = _client
        .from('transactions')
        .select(
          'id, type, occurred_on, amount_minor, currency, payment_method, source_platform, '
          'note, vendor, attachment_path, recurring_expense_id, created_at, '
          'category:categories(id, name, type)',
        )
        .eq('user_id', _user.id)
        .isFilter('deleted_at', null);

    if (type != null) {
      query = query.eq('type', type.dbValue);
    }
    if (paymentMethod != null) {
      query = query.eq('payment_method', paymentMethod.dbValue);
    }
    if (start != null) {
      query = query.gte('occurred_on', _isoDate(start));
    }
    if (end != null) {
      query = query.lte('occurred_on', _isoDate(end));
    }

    final List<dynamic> rows = await query
        .order('occurred_on', ascending: false)
        .order('created_at', ascending: false);

    return rows.map((dynamic row) => _mapTransaction(row)).toList();
  }

  Future<void> createTransaction(EntryDraft draft) async {
    final String categoryType = await _fetchCategoryTypeValue(draft.categoryId);
    final domain_transaction.TransactionModel transaction =
        domain_transaction.TransactionModel.fromPayload(
          type: draft.type.dbValue,
          occurredOn: draft.occurredOn,
          amountMinor: draft.amountMinor,
          currency: 'GBP',
          categoryId: draft.categoryId,
          categoryType: categoryType,
          paymentMethod: draft.paymentMethod.dbValue,
          sourcePlatform: draft.sourcePlatform?.dbValue,
          note: draft.note,
          vendor: draft.vendor,
          attachmentPath: draft.attachmentPath,
        );
    await _client.from('transactions').insert(<String, dynamic>{
      'user_id': _user.id,
      'type': transaction.type.dbValue,
      'occurred_on': transaction.occurredOn.iso8601Date,
      'amount_minor': transaction.amount.value,
      'currency': transaction.currency.code,
      'category_id': transaction.categoryId,
      'payment_method': transaction.paymentMethod.dbValue,
      'source_platform': transaction.sourcePlatform?.dbValue,
      'note': transaction.note,
      'vendor': transaction.vendor,
      'attachment_path': transaction.attachmentPath,
    });
  }

  Future<DashboardSnapshot> fetchDashboardSnapshot() async {
    final DateTime today = _businessToday();
    final DateTimeRange week = _weekRange(today);
    final List<TransactionData> weekTransactions = await fetchTransactions(
      start: week.start,
      end: week.end,
    );
    final List<TransactionData> recentTransactions = await fetchTransactions();
    final List<RecurringUiItem> recurring = await fetchRecurringUiItems();

    int incomeMinor = 0;
    int expenseMinor = 0;
    int cashIncomeMinor = 0;
    int cardIncomeMinor = 0;

    for (final TransactionData transaction in weekTransactions) {
      if (transaction.type == TransactionType.income) {
        incomeMinor += transaction.amountMinor;
        if (transaction.paymentMethod == PaymentMethodType.cash) {
          cashIncomeMinor += transaction.amountMinor;
        }
        if (transaction.paymentMethod == PaymentMethodType.card) {
          cardIncomeMinor += transaction.amountMinor;
        }
      } else {
        expenseMinor += transaction.amountMinor;
      }
    }

    final DateTimeRange previousWeek = DateTimeRange(
      start: week.start.subtract(const Duration(days: 7)),
      end: week.end.subtract(const Duration(days: 7)),
    );
    final List<TransactionData> previousTransactions = await fetchTransactions(
      start: previousWeek.start,
      end: previousWeek.end,
    );
    int previousNet = 0;
    for (final TransactionData transaction in previousTransactions) {
      previousNet += transaction.type == TransactionType.income
          ? transaction.amountMinor
          : -transaction.amountMinor;
    }

    final int currentNet = incomeMinor - expenseMinor;
    return DashboardSnapshot(
      weekLabel:
          '${_formatShortWeekday(week.start)} ${week.start.day} → '
          '${_formatShortWeekday(week.end)} ${week.end.day} ${_formatUpperMonth(week.end)}',
      incomeMinor: incomeMinor,
      expenseMinor: expenseMinor,
      cashIncomeMinor: cashIncomeMinor,
      cardIncomeMinor: cardIncomeMinor,
      netDeltaMinor: currentNet - previousNet,
      recentTransactions: recentTransactions.take(5).toList(),
      upcomingRecurring: recurring.take(5).toList(),
    );
  }

  Future<ReportsSnapshot> fetchReportsSnapshot(DateTime month) async {
    final DateTimeRange range = _monthRange(month);
    final List<TransactionData> transactions = await fetchTransactions(
      start: range.start,
      end: range.end,
    );

    int incomeMinor = 0;
    int expenseMinor = 0;
    final Map<String, int> expenseByCategory = <String, int>{};
    final Map<String, IconData> icons = <String, IconData>{};
    for (final TransactionData transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        incomeMinor += transaction.amountMinor;
      } else {
        expenseMinor += transaction.amountMinor;
        expenseByCategory[transaction.categoryName] =
            (expenseByCategory[transaction.categoryName] ?? 0) +
            transaction.amountMinor;
        icons.putIfAbsent(
          transaction.categoryName,
          () => _iconForCategoryName(
            transaction.categoryName,
            CategoryType.expense,
          ),
        );
      }
    }

    final List<MapEntry<String, int>> sorted =
        expenseByCategory.entries.toList()..sort(
          (MapEntry<String, int> a, MapEntry<String, int> b) =>
              b.value.compareTo(a.value),
        );

    final List<ReportBreakdownItem> breakdown = sorted.map((
      MapEntry<String, int> entry,
    ) {
      return ReportBreakdownItem(
        categoryName: entry.key,
        amountMinor: entry.value,
        fraction: expenseMinor == 0 ? 0 : entry.value / expenseMinor,
        icon: icons[entry.key] ?? Icons.receipt_long_rounded,
      );
    }).toList();

    return ReportsSnapshot(
      monthLabel: _turkishMonth(month.month),
      yearLabel: month.year.toString(),
      incomeMinor: incomeMinor,
      expenseMinor: expenseMinor,
      breakdown: breakdown,
    );
  }

  Future<List<RecurringExpenseData>> fetchRecurringExpenses() async {
    await ensureSeedCategories();
    final List<dynamic> rows = await _client
        .from('recurring_expenses')
        .select(
          'id, name, category_id, amount_minor, currency, frequency, next_due_on, reminder_days_before, '
          'default_payment_method, reserve_enabled, is_active, note, category:categories(id, name, type)',
        )
        .eq('user_id', _user.id)
        .eq('is_active', true)
        .order('next_due_on', ascending: true)
        .order('created_at', ascending: true);

    return rows.map((dynamic row) {
      final Map<String, dynamic> category =
          row['category'] as Map<String, dynamic>;
      final domain_recurring.RecurringModel recurring =
          domain_recurring.RecurringModel.fromPayload(
            id: row['id'] as String,
            name: row['name'] as String,
            categoryId: row['category_id'] as String,
            categoryType: category['type'] as String,
            amountMinor: row['amount_minor'] as int,
            currency: (row['currency'] as String?) ?? 'GBP',
            frequency: row['frequency'] as String,
            nextDueOn: DateTime.parse(row['next_due_on'] as String),
            reminderDaysBefore: row['reminder_days_before'] as int? ?? 3,
            defaultPaymentMethod: row['default_payment_method'] as String?,
            reserveEnabled: row['reserve_enabled'] as bool? ?? false,
            isActive: row['is_active'] as bool? ?? true,
            note: row['note'] as String?,
          );
      return RecurringExpenseData(
        id: recurring.id!,
        name: recurring.name,
        categoryId: recurring.categoryId,
        categoryName: category['name'] as String,
        amountMinor: recurring.amount.value,
        frequency: _toUiRecurringFrequencyType(recurring.frequency),
        nextDueOn: recurring.nextDueOn.value,
        reminderDaysBefore: recurring.reminderDaysBefore,
        reserveEnabled: recurring.reserveEnabled,
        isActive: recurring.isActive,
        defaultPaymentMethod: recurring.defaultPaymentMethod == null
            ? null
            : _toUiPaymentMethodType(recurring.defaultPaymentMethod!),
        note: recurring.note,
      );
    }).toList();
  }

  Future<void> createRecurringExpense(RecurringDraft draft) async {
    final String categoryType = await _fetchCategoryTypeValue(draft.categoryId);
    final domain_recurring.RecurringModel recurring =
        domain_recurring.RecurringModel.fromPayload(
          name: draft.name,
          categoryId: draft.categoryId,
          categoryType: categoryType,
          amountMinor: draft.amountMinor,
          currency: 'GBP',
          frequency: draft.frequency.dbValue,
          nextDueOn: draft.nextDueOn,
          reminderDaysBefore: draft.reminderDaysBefore,
          defaultPaymentMethod: draft.defaultPaymentMethod?.dbValue,
          reserveEnabled: false,
          isActive: true,
          note: draft.note,
        );
    await _client.from('recurring_expenses').insert(<String, dynamic>{
      'user_id': _user.id,
      'name': recurring.name,
      'category_id': recurring.categoryId,
      'amount_minor': recurring.amount.value,
      'currency': recurring.currency.code,
      'frequency': recurring.frequency.dbValue,
      'next_due_on': recurring.nextDueOn.iso8601Date,
      'reminder_days_before': recurring.reminderDaysBefore,
      'default_payment_method': recurring.defaultPaymentMethod?.dbValue,
      'reserve_enabled': recurring.reserveEnabled,
      'is_active': recurring.isActive,
      'note': recurring.note,
    });
  }

  Future<void> markRecurringPaid({
    required String recurringExpenseId,
    required DateTime paidOn,
    required int amountMinor,
    required PaymentMethodType method,
  }) async {
    domain.MinorAmount(amountMinor);
    await _client.rpc(
      'mark_recurring_expense_paid',
      params: <String, dynamic>{
        'p_recurring_expense_id': recurringExpenseId,
        'p_paid_on': _isoDate(paidOn),
        'p_amount_minor': amountMinor,
        'p_payment_method': method.dbValue,
      },
    );
  }

  Future<List<RecurringUiItem>> fetchRecurringUiItems() async {
    final DateTime today = _businessToday();
    final List<RecurringExpenseData> records = await fetchRecurringExpenses();
    final List<RecurringUiItem> items =
        records.map((RecurringExpenseData record) {
          final int diffDays = record.nextDueOn.difference(today).inDays;
          final RecurringUiStatus status = diffDays < 0
              ? RecurringUiStatus.late
              : diffDays <= record.reminderDaysBefore
              ? RecurringUiStatus.soon
              : RecurringUiStatus.later;
          final String frequencyMeta = switch (status) {
            RecurringUiStatus.late =>
              'Every ${record.frequency.label.toLowerCase()} · was due ${_formatShortDate(record.nextDueOn)}',
            RecurringUiStatus.soon =>
              'Every ${record.frequency.label.toLowerCase()} · ${_formatShortWeekday(record.nextDueOn)} ${record.nextDueOn.day} ${_formatUpperMonth(record.nextDueOn)}',
            RecurringUiStatus.later =>
              'In $diffDays days · ${_formatShortWeekday(record.nextDueOn)} ${record.nextDueOn.day}',
          };
          final String statusLabel = switch (status) {
            RecurringUiStatus.late => 'Late · ${diffDays.abs()}d',
            RecurringUiStatus.soon =>
              diffDays == 0 ? 'Today' : 'In $diffDays days',
            RecurringUiStatus.later => 'Later',
          };
          return RecurringUiItem(
            record: record,
            status: status,
            statusLabel: statusLabel,
            frequencyMeta: frequencyMeta,
            icon: _iconForCategoryName(
              record.categoryName,
              CategoryType.expense,
            ),
          );
        }).toList()..sort((RecurringUiItem a, RecurringUiItem b) {
          int weight(RecurringUiStatus status) => switch (status) {
            RecurringUiStatus.late => 0,
            RecurringUiStatus.soon => 1,
            RecurringUiStatus.later => 2,
          };
          final int statusComparison = weight(
            a.status,
          ).compareTo(weight(b.status));
          if (statusComparison != 0) return statusComparison;
          return a.record.nextDueOn.compareTo(b.record.nextDueOn);
        });
    return items;
  }

  Future<RecurringSummarySnapshot> fetchRecurringSummary(DateTime month) async {
    final DateTimeRange range = _monthRange(month);
    final List<RecurringExpenseData> recurring = await fetchRecurringExpenses();
    final int totalMinor = recurring
        .where(
          (RecurringExpenseData item) =>
              item.nextDueOn.month == month.month &&
              item.nextDueOn.year == month.year,
        )
        .fold<int>(
          0,
          (int sum, RecurringExpenseData item) => sum + item.amountMinor,
        );

    final List<TransactionData> recurringPayments = await fetchTransactions(
      type: TransactionType.expense,
      start: range.start,
      end: range.end,
    );
    final int paidMinor = recurringPayments
        .where((TransactionData tx) => tx.recurringExpenseId != null)
        .fold<int>(0, (int sum, TransactionData tx) => sum + tx.amountMinor);

    return RecurringSummarySnapshot(
      totalMinor: totalMinor,
      paidMinor: paidMinor,
    );
  }

  TransactionData _mapTransaction(dynamic row) {
    final Map<String, dynamic> category =
        row['category'] as Map<String, dynamic>;
    final domain_transaction.TransactionModel transaction =
        domain_transaction.TransactionModel.fromPayload(
          id: row['id'] as String,
          type: row['type'] as String,
          occurredOn: DateTime.parse(row['occurred_on'] as String),
          amountMinor: row['amount_minor'] as int,
          currency: (row['currency'] as String?) ?? 'GBP',
          categoryId: category['id'] as String,
          categoryType: category['type'] as String,
          paymentMethod: row['payment_method'] as String,
          sourcePlatform: row['source_platform'] as String?,
          note: row['note'] as String?,
          vendor: row['vendor'] as String?,
          attachmentPath: row['attachment_path'] as String?,
          recurringExpenseId: row['recurring_expense_id'] as String?,
        );
    return TransactionData(
      id: transaction.id!,
      type: _toUiTransactionType(transaction.type),
      occurredOn: transaction.occurredOn.value,
      amountMinor: transaction.amount.value,
      categoryId: transaction.categoryId,
      categoryName: category['name'] as String,
      paymentMethod: _toUiPaymentMethodType(transaction.paymentMethod),
      sourcePlatform: transaction.sourcePlatform == null
          ? null
          : _toUiSourcePlatformType(transaction.sourcePlatform!),
      note: transaction.note,
      vendor: transaction.vendor,
      attachmentPath: transaction.attachmentPath,
      recurringExpenseId: transaction.recurringExpenseId,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Future<String> _fetchCategoryTypeValue(String categoryId) async {
    final Map<String, dynamic>? row = await _client
        .from('categories')
        .select('type')
        .eq('id', categoryId)
        .eq('user_id', _user.id)
        .maybeSingle();

    if (row == null) {
      throw const domain.DomainValidationException(
        code: 'category.not_found',
        message: 'Category must exist for the current user.',
      );
    }

    return row['type'] as String;
  }

  DateTime _businessToday() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTimeRange _weekRange(DateTime date) {
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    final DateTime start = normalized.subtract(
      Duration(days: normalized.weekday - 1),
    );
    final DateTime end = start.add(const Duration(days: 6));
    return DateTimeRange(start: start, end: end);
  }

  DateTimeRange _monthRange(DateTime date) {
    final DateTime start = DateTime(date.year, date.month, 1);
    final DateTime end = DateTime(date.year, date.month + 1, 0);
    return DateTimeRange(start: start, end: end);
  }

  String _isoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  String? _normalizeOptionalText(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String _formatShortWeekday(DateTime date) {
    const List<String> weekdays = <String>[
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];
    return weekdays[date.weekday - 1];
  }

  String _formatUpperMonth(DateTime date) {
    const List<String> months = <String>[
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[date.month - 1];
  }

  String _formatShortDate(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _turkishMonth(int month) {
    const List<String> months = <String>[
      'Ocak',
      'Subat',
      'Mart',
      'Nisan',
      'Mayis',
      'Haziran',
      'Temmuz',
      'Agustos',
      'Eylul',
      'Ekim',
      'Kasim',
      'Aralik',
    ];
    return months[month - 1];
  }

  _SeedCategory? _seedForName(CategoryType type, String name) {
    final List<_SeedCategory> seeds = type == CategoryType.income
        ? _incomeSeeds
        : _expenseSeeds;
    for (final _SeedCategory seed in seeds) {
      if (seed.name.toLowerCase() == name.toLowerCase()) return seed;
    }
    return null;
  }

  String _defaultIconForType(CategoryType type) =>
      type == CategoryType.income ? 'payments_outlined' : 'sell_outlined';

  CategoryType _toUiCategoryType(domain.CategoryType type) => switch (type) {
    domain.CategoryType.income => CategoryType.income,
    domain.CategoryType.expense => CategoryType.expense,
  };

  TransactionType _toUiTransactionType(domain.TransactionType type) =>
      switch (type) {
        domain.TransactionType.income => TransactionType.income,
        domain.TransactionType.expense => TransactionType.expense,
      };

  PaymentMethodType _toUiPaymentMethodType(domain.PaymentMethodType type) =>
      switch (type) {
        domain.PaymentMethodType.cash => PaymentMethodType.cash,
        domain.PaymentMethodType.card => PaymentMethodType.card,
        domain.PaymentMethodType.bankTransfer => PaymentMethodType.bankTransfer,
        domain.PaymentMethodType.other => PaymentMethodType.other,
      };

  SourcePlatformType _toUiSourcePlatformType(domain.SourcePlatformType type) =>
      switch (type) {
        domain.SourcePlatformType.direct => SourcePlatformType.direct,
        domain.SourcePlatformType.uber => SourcePlatformType.uber,
        domain.SourcePlatformType.justEat => SourcePlatformType.justEat,
        domain.SourcePlatformType.other => SourcePlatformType.other,
      };

  RecurringFrequencyType _toUiRecurringFrequencyType(
    domain.RecurringFrequencyType type,
  ) => switch (type) {
    domain.RecurringFrequencyType.weekly => RecurringFrequencyType.weekly,
    domain.RecurringFrequencyType.monthly => RecurringFrequencyType.monthly,
    domain.RecurringFrequencyType.quarterly => RecurringFrequencyType.quarterly,
    domain.RecurringFrequencyType.yearly => RecurringFrequencyType.yearly,
  };

  IconData _iconForCategoryName(String name, CategoryType type) {
    return _seedForName(type, name)?.icon ??
        _iconFromName(_defaultIconForType(type));
  }

  IconData _iconFromName(String? iconName) {
    switch (iconName) {
      case 'storefront_rounded':
        return Icons.storefront_rounded;
      case 'payments_rounded':
        return Icons.payments_rounded;
      case 'directions_car_filled_rounded':
        return Icons.directions_car_filled_rounded;
      case 'delivery_dining_rounded':
        return Icons.delivery_dining_rounded;
      case 'work_outline_rounded':
        return Icons.work_outline_rounded;
      case 'home_rounded':
        return Icons.home_rounded;
      case 'bolt_rounded':
        return Icons.bolt_rounded;
      case 'wifi_rounded':
        return Icons.wifi_rounded;
      case 'inventory_2_outlined':
        return Icons.inventory_2_outlined;
      case 'shopping_bag_outlined':
        return Icons.shopping_bag_outlined;
      case 'build_circle_outlined':
        return Icons.build_circle_outlined;
      case 'local_shipping_outlined':
        return Icons.local_shipping_outlined;
      case 'receipt_long_rounded':
        return Icons.receipt_long_rounded;
      case 'sell_outlined':
        return Icons.sell_outlined;
      case 'payments_outlined':
        return Icons.payments_outlined;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}

class _SeedCategory {
  const _SeedCategory(this.name, this.icon, this.tone);

  final String name;
  final IconData icon;
  final HiFiIconTileTone tone;

  String get iconName => switch (icon) {
    Icons.storefront_rounded => 'storefront_rounded',
    Icons.payments_rounded => 'payments_rounded',
    Icons.directions_car_filled_rounded => 'directions_car_filled_rounded',
    Icons.delivery_dining_rounded => 'delivery_dining_rounded',
    Icons.work_outline_rounded => 'work_outline_rounded',
    Icons.home_rounded => 'home_rounded',
    Icons.bolt_rounded => 'bolt_rounded',
    Icons.wifi_rounded => 'wifi_rounded',
    Icons.inventory_2_outlined => 'inventory_2_outlined',
    Icons.shopping_bag_outlined => 'shopping_bag_outlined',
    Icons.build_circle_outlined => 'build_circle_outlined',
    Icons.local_shipping_outlined => 'local_shipping_outlined',
    _ => 'receipt_long_rounded',
  };
}
