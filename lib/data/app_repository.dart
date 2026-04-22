import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/domain/category_model.dart' as domain_category;
import '../core/domain/monthly_summary.dart' as domain_monthly_summary;
import '../core/domain/recurring_model.dart' as domain_recurring;
import '../core/domain/reserve_planner.dart' as domain_reserve_planner;
import '../core/domain/supplier_model.dart' as domain_supplier;
import '../core/domain/transaction_model.dart' as domain_transaction;
import '../core/domain/types.dart' as domain;
import '../core/domain/weekly_summary.dart' as domain_weekly_summary;
import '../features/expense_detail/domain/expense_detail_models.dart';
import '../features/expense_detail/domain/expense_detail_service.dart';
import '../features/income_detail/domain/income_detail_models.dart';
import '../features/income_detail/domain/income_detail_service.dart';
import '../features/net_profit_detail/domain/net_profit_detail_models.dart';
import '../features/net_profit_detail/domain/net_profit_detail_service.dart';
import '../l10n/app_localizations.dart';
import 'local/outbox_repository.dart';
import 'sync/conflict_policy.dart';
import 'sync/sync_service.dart';
import '../shared/hi_fi/hi_fi_icon_tile.dart';
import 'app_models.dart';

class GiderRepository {
  GiderRepository(
    this._client, {
    OutboxRepository? outboxRepository,
    ConnectivityProbe? connectivityProbe,
    SyncService? syncService,
    SyncConflictPolicy? syncConflictPolicy,
    DateTime Function()? clock,
  }) : _outboxRepository = outboxRepository,
       _connectivityProbe = connectivityProbe,
       _syncService = syncService,
       _syncConflictPolicy = syncConflictPolicy ?? const SyncConflictPolicy(),
       _clock = clock ?? DateTime.now;

  final SupabaseClient _client;
  final OutboxRepository? _outboxRepository;
  final ConnectivityProbe? _connectivityProbe;
  final SyncService? _syncService;
  final SyncConflictPolicy _syncConflictPolicy;
  final DateTime Function() _clock;

  static const int _dashboardRecentPreviewLimit = 4;
  static const int _dashboardUpcomingPreviewLimit = 3;
  static const String _transactionSelectBase =
      'id, type, occurred_on, amount_minor, currency, payment_method, '
      'source_platform, note, vendor, attachment_path, recurring_expense_id, '
      'supplier_id, created_at, category:categories(id, name, type)';
  static const String _transactionSelectWithSupplier =
      '$_transactionSelectBase, supplier:suppliers(id, name)';
  static final ExpenseDetailService _expenseDetailService =
      ExpenseDetailService();
  static final IncomeDetailService _incomeDetailService = IncomeDetailService();
  static final NetProfitDetailService _netProfitDetailService =
      NetProfitDetailService();

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
    await _client.auth.signUp(
      email: email,
      password: password,
      data: <String, dynamic>{
        if (businessName != null && businessName.trim().isNotEmpty)
          'full_name': businessName.trim(),
      },
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<BusinessSettingsData> fetchBusinessSettings() async {
    final User user = _user;
    final Map<String, dynamic>? profile = await _client
        .from('profiles')
        .select('email, full_name')
        .eq('id', user.id)
        .maybeSingle();
    final Map<String, dynamic>? settings = await _client
        .from('business_settings')
        .select('business_name, timezone, currency, week_starts_on')
        .eq('user_id', user.id)
        .maybeSingle();

    final String email = (profile?['email'] as String?) ?? user.email ?? '';
    final String? profileBusinessName = _normalizeOptionalText(
      profile?['full_name'] as String?,
    );
    final String? resolvedBusinessName = _normalizeOptionalText(
      settings?['business_name'] as String?,
    );
    final bool isBootstrapComplete = resolvedBusinessName != null;
    final String businessName =
        resolvedBusinessName ?? profileBusinessName ?? email.split('@').first;

    return BusinessSettingsData(
      email: email,
      businessName: businessName,
      timezone: (settings?['timezone'] as String?) ?? 'Europe/London',
      currency: (settings?['currency'] as String?) ?? 'GBP',
      weekStartsOn: (settings?['week_starts_on'] as int?) ?? 1,
      isBootstrapComplete: isBootstrapComplete,
    );
  }

  Future<void> updateBusinessName(String businessName) async {
    final User user = _user;
    final String trimmed = businessName.trim();
    final List<dynamic> updated = await _client
        .from('business_settings')
        .update(<String, dynamic>{'business_name': trimmed})
        .eq('user_id', user.id)
        .select('user_id');

    if (updated.isEmpty) {
      await _client.from('business_settings').upsert(<String, dynamic>{
        'user_id': user.id,
        'business_name': trimmed,
      }, onConflict: 'user_id');
    }
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

  Future<void> archiveCategory({required String id}) async {
    final String categoryId = domain.requireTrimmedText(id, 'category_id');
    await _client
        .from('categories')
        .update(<String, dynamic>{'is_archived': true})
        .eq('id', categoryId)
        .eq('user_id', _user.id);
  }

  Future<List<SupplierData>> fetchSuppliers({
    String? expenseCategoryId,
    bool includeArchived = false,
  }) async {
    var query = _client
        .from('suppliers')
        .select(
          'id, expense_category_id, name, notes, is_archived, sort_order, '
          'category:categories(id, name, type)',
        )
        .eq('user_id', _user.id);

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }
    if (expenseCategoryId != null) {
      query = query.eq('expense_category_id', expenseCategoryId);
    }

    final List<dynamic> rows = await query
        .order('sort_order', ascending: true)
        .order('created_at', ascending: true);

    return rows.map<SupplierData>((dynamic row) {
      final Map<String, dynamic>? category =
          row['category'] as Map<String, dynamic>?;
      return SupplierData(
        id: row['id'] as String,
        expenseCategoryId: row['expense_category_id'] as String,
        expenseCategoryName: (category?['name'] as String?) ?? '',
        name: row['name'] as String,
        sortOrder: (row['sort_order'] as int?) ?? 0,
        isArchived: row['is_archived'] as bool? ?? false,
        notes: row['notes'] as String?,
      );
    }).toList();
  }

  Future<SupplierData> saveSupplier({
    String? id,
    required SupplierDraft draft,
  }) async {
    final domain_supplier.SupplierModel supplier =
        domain_supplier.SupplierModel.fromPayload(
          id: id,
          expenseCategoryId: draft.expenseCategoryId,
          name: draft.name,
          notes: draft.notes,
        );

    await _ensureCategoryIsExpense(supplier.expenseCategoryId);
    await _ensureSupplierNameUnique(
      expenseCategoryId: supplier.expenseCategoryId,
      name: supplier.name,
      excludeId: supplier.id,
    );

    if (supplier.id == null) {
      final List<SupplierData> existing = await fetchSuppliers(
        expenseCategoryId: supplier.expenseCategoryId,
        includeArchived: true,
      );
      final Map<String, dynamic> inserted = await _client
          .from('suppliers')
          .insert(<String, dynamic>{
            'user_id': _user.id,
            'expense_category_id': supplier.expenseCategoryId,
            'name': supplier.name,
            'notes': supplier.notes,
            'sort_order': existing.length,
          })
          .select(
            'id, expense_category_id, name, notes, is_archived, sort_order, '
            'category:categories(id, name, type)',
          )
          .single();
      return _mapSupplier(inserted);
    }

    final Map<String, dynamic> updated = await _client
        .from('suppliers')
        .update(<String, dynamic>{
          'expense_category_id': supplier.expenseCategoryId,
          'name': supplier.name,
          'notes': supplier.notes,
        })
        .eq('id', supplier.id!)
        .eq('user_id', _user.id)
        .select(
          'id, expense_category_id, name, notes, is_archived, sort_order, '
          'category:categories(id, name, type)',
        )
        .single();
    return _mapSupplier(updated);
  }

  Future<void> archiveSupplier({required String id}) async {
    final String supplierId = domain.requireTrimmedText(id, 'supplier_id');
    await _client
        .from('suppliers')
        .update(<String, dynamic>{'is_archived': true})
        .eq('id', supplierId)
        .eq('user_id', _user.id);
  }

  Future<void> _ensureCategoryIsExpense(String categoryId) async {
    final Map<String, dynamic>? row = await _client
        .from('categories')
        .select('type, is_archived')
        .eq('id', categoryId)
        .eq('user_id', _user.id)
        .maybeSingle();

    if (row == null) {
      throw const domain.DomainValidationException(
        code: 'supplier.category_not_found',
        message: 'The selected category does not exist.',
      );
    }

    if ((row['type'] as String?) != 'expense') {
      throw const domain.DomainValidationException(
        code: 'supplier.category_type_invalid',
        message: 'Suppliers can only be attached to expense categories.',
      );
    }

    if (row['is_archived'] as bool? ?? false) {
      throw const domain.DomainValidationException(
        code: 'supplier.category_archived',
        message: 'Cannot create suppliers under an archived category.',
      );
    }
  }

  Future<void> _ensureSupplierNameUnique({
    required String expenseCategoryId,
    required String name,
    String? excludeId,
  }) async {
    var query = _client
        .from('suppliers')
        .select('id')
        .eq('user_id', _user.id)
        .eq('expense_category_id', expenseCategoryId)
        .eq('is_archived', false)
        .ilike('name', name);
    if (excludeId != null) {
      query = query.neq('id', excludeId);
    }
    final List<dynamic> rows = await query.limit(1);
    if (rows.isNotEmpty) {
      throw const domain.DomainValidationException(
        code: 'supplier.duplicate_name',
        message: 'A supplier with this name already exists in this category.',
      );
    }
  }

  SupplierData _mapSupplier(Map<String, dynamic> row) {
    final Map<String, dynamic>? category =
        row['category'] as Map<String, dynamic>?;
    return SupplierData(
      id: row['id'] as String,
      expenseCategoryId: row['expense_category_id'] as String,
      expenseCategoryName: (category?['name'] as String?) ?? '',
      name: row['name'] as String,
      sortOrder: (row['sort_order'] as int?) ?? 0,
      isArchived: row['is_archived'] as bool? ?? false,
      notes: row['notes'] as String?,
    );
  }

  Future<TransactionData?> fetchTransaction({required String id}) async {
    final Map<String, dynamic>? row = await _fetchTransactionRow(
      id: id,
      includeSupplier: true,
    );
    if (row == null) return null;
    return _mapTransaction(row);
  }

  Future<List<TransactionData>> fetchTransactions({
    TransactionType? type,
    PaymentMethodType? paymentMethod,
    DateTime? start,
    DateTime? end,
  }) async {
    await ensureSeedCategories();
    final List<dynamic> rows = await _fetchTransactionRows(
      includeSupplier: true,
      type: type,
      paymentMethod: paymentMethod,
      start: start,
      end: end,
    );

    return rows.map((dynamic row) => _mapTransaction(row)).toList();
  }

  Future<Map<String, dynamic>?> _fetchTransactionRow({
    required String id,
    required bool includeSupplier,
  }) async {
    try {
      return await _client
          .from('transactions')
          .select(
            includeSupplier
                ? _transactionSelectWithSupplier
                : _transactionSelectBase,
          )
          .eq('id', id)
          .eq('user_id', _user.id)
          .isFilter('deleted_at', null)
          .maybeSingle();
    } on PostgrestException catch (error) {
      if (includeSupplier && _isMissingSupplierRelationError(error)) {
        return _fetchTransactionRow(id: id, includeSupplier: false);
      }
      rethrow;
    }
  }

  Future<List<dynamic>> _fetchTransactionRows({
    required bool includeSupplier,
    TransactionType? type,
    PaymentMethodType? paymentMethod,
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      var query = _client
          .from('transactions')
          .select(
            includeSupplier
                ? _transactionSelectWithSupplier
                : _transactionSelectBase,
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

      return await query
          .order('occurred_on', ascending: false)
          .order('created_at', ascending: false);
    } on PostgrestException catch (error) {
      if (includeSupplier && _isMissingSupplierRelationError(error)) {
        return _fetchTransactionRows(
          includeSupplier: false,
          type: type,
          paymentMethod: paymentMethod,
          start: start,
          end: end,
        );
      }
      rethrow;
    }
  }

  bool _isMissingSupplierRelationError(PostgrestException error) {
    final String message = error.message.toLowerCase();
    final String details = '${error.details ?? ''}'.toLowerCase();
    final String code = (error.code ?? '').toLowerCase();
    final bool mentionsSupplierRelation =
        (message.contains('transactions') ||
            details.contains('transactions')) &&
        (message.contains('suppliers') || details.contains('suppliers')) &&
        (message.contains('relationship') ||
            details.contains('relationship') ||
            message.contains('schema cache') ||
            details.contains('schema cache'));
    return mentionsSupplierRelation ||
        code == 'pgrst200' ||
        code == 'pgrst201' ||
        code == 'pgrst204';
  }

  Future<void> createTransaction(EntryDraft draft) async {
    if (!_hasTransactionSyncLifecycle) {
      final String categoryType = await _fetchCategoryTypeValue(
        draft.categoryId,
      );
      final domain_transaction.TransactionModel transaction =
          _buildTransactionModel(draft: draft, categoryType: categoryType);
      await _createTransactionRemote(transaction);
      return;
    }

    final _ResolvedCategory category = await _fetchCategory(draft.categoryId);

    final QueuedCreateTransaction queued = await _outboxRepository!
        .queueCreateTransaction(
          draft: draft,
          categoryType: _categoryTypeFromDbValue(category.type),
          categoryName: category.name,
        );

    if (!await _isOnline()) {
      return;
    }

    await _syncService?.syncNow();
    await _ensureOutboxEntryCompleted(queued.outboxEntryId);
  }

  Future<void> updateTransaction({
    required String id,
    required EntryDraft draft,
  }) async {
    final String transactionId = domain.requireTrimmedText(
      id,
      'transaction_id',
    );

    if (!_hasTransactionSyncLifecycle) {
      final String categoryType = await _fetchCategoryTypeValue(
        draft.categoryId,
      );
      final domain_transaction.TransactionModel transaction =
          _buildTransactionModel(
            id: transactionId,
            draft: draft,
            categoryType: categoryType,
          );
      await _updateTransactionRemote(transaction);
      return;
    }

    final _ResolvedCategory category = await _fetchCategory(draft.categoryId);
    final domain_transaction.TransactionModel transaction =
        _buildTransactionModel(
          id: transactionId,
          draft: draft,
          categoryType: category.type,
        );

    if (await _isOnline()) {
      try {
        await _updateTransactionRemote(transaction);
        return;
      } catch (error, stackTrace) {
        if (!_shouldQueueRemoteFailure(error)) {
          Error.throwWithStackTrace(error, stackTrace);
        }
      }
    }

    await _outboxRepository!.queueUpdateTransaction(
      transactionId: transactionId,
      draft: draft,
      categoryType: _categoryTypeFromDbValue(category.type),
    );
  }

  Future<void> deleteTransaction({required String id}) async {
    final String transactionId = domain.requireTrimmedText(
      id,
      'transaction_id',
    );

    if (!_hasTransactionSyncLifecycle) {
      await _deleteTransactionRemote(transactionId);
      return;
    }

    if (await _isOnline()) {
      try {
        await _deleteTransactionRemote(transactionId);
        return;
      } catch (error, stackTrace) {
        if (!_shouldQueueRemoteFailure(error)) {
          Error.throwWithStackTrace(error, stackTrace);
        }
      }
    }

    await _outboxRepository!.queueDeleteTransaction(
      transactionId: transactionId,
    );
  }

  Future<DashboardSnapshot> fetchDashboardSnapshot(
    AppLocalizations strings,
  ) async {
    final DateTime today = _businessToday();
    final domain_weekly_summary.WeeklySummaryRange week = domain_weekly_summary
        .weeklySummaryRangeFor(today);
    final List<TransactionData> weekTransactions = await fetchTransactions(
      start: week.start,
      end: week.end,
    );
    final List<TransactionData> recentTransactions = await fetchTransactions();
    final List<RecurringExpenseData> recurringExpenses =
        await fetchRecurringExpenses();
    final List<RecurringUiItem> recurring = _buildRecurringUiItems(
      records: recurringExpenses,
      today: today,
      strings: strings,
    );
    final ReservePlannerSnapshot reservePlanner = _buildReservePlannerSnapshot(
      records: recurringExpenses,
      today: today,
    );
    final domain_weekly_summary.WeeklySummaryRange previousWeek = week.previous;
    final List<TransactionData> previousTransactions = await fetchTransactions(
      start: previousWeek.start,
      end: previousWeek.end,
    );
    final domain_weekly_summary.WeeklySummarySnapshot weeklySummary =
        domain_weekly_summary.buildWeeklySummary(
          today: today,
          currentWeekTransactions: weekTransactions.map(
            _toWeeklySummaryTransaction,
          ),
          previousWeekTransactions: previousTransactions.map(
            _toWeeklySummaryTransaction,
          ),
        );
    final List<TransactionData> sortedRecentTransactions =
        List<TransactionData>.from(recentTransactions)
          ..sort(_compareDashboardRecentTransactions);
    final List<RecurringUiItem> sortedRecurring =
        List<RecurringUiItem>.from(recurring)..sort(
          (RecurringUiItem a, RecurringUiItem b) =>
              a.record.nextDueOn.compareTo(b.record.nextDueOn),
        );

    return DashboardSnapshot(
      weekLabel: strings.dashboardWeekLabel(
        weeklySummary.range.start,
        weeklySummary.range.end,
      ),
      incomeMinor: weeklySummary.incomeMinor,
      expenseMinor: weeklySummary.expenseMinor,
      cashIncomeMinor: weeklySummary.cashIncomeMinor,
      cardIncomeMinor: weeklySummary.cardIncomeMinor,
      netDeltaMinor: weeklySummary.netDeltaMinor,
      reservePlanner: reservePlanner,
      recentTransactions: sortedRecentTransactions
          .take(_dashboardRecentPreviewLimit)
          .toList(),
      upcomingRecurring: sortedRecurring
          .take(_dashboardUpcomingPreviewLimit)
          .toList(),
    );
  }

  Future<MonthlyReportsDataset> fetchMonthlyReportsDataset(
    DateTime month, {
    int trendMonthCount = 6,
  }) async {
    final DateTime selectedMonth = DateTime(month.year, month.month, 1);
    final int resolvedTrendCount = trendMonthCount < 1 ? 1 : trendMonthCount;
    final DateTime rangeStart = DateTime(
      selectedMonth.year,
      selectedMonth.month - (resolvedTrendCount - 1),
      1,
    );
    final DateTime rangeEnd = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    );

    final List<TransactionData> transactions = await fetchTransactions(
      start: rangeStart,
      end: rangeEnd,
    );

    final Map<String, IconData> expenseCategoryIcons = <String, IconData>{};
    final Map<String, IconData> incomeCategoryIcons = <String, IconData>{};
    for (final TransactionData transaction in transactions) {
      final String categoryName = transaction.categoryName.trim();
      if (categoryName.isEmpty) {
        continue;
      }

      if (transaction.type == TransactionType.expense) {
        expenseCategoryIcons.putIfAbsent(
          categoryName,
          () => _iconForCategoryName(categoryName, CategoryType.expense),
        );
        continue;
      }

      incomeCategoryIcons.putIfAbsent(
        categoryName,
        () => _iconForCategoryName(categoryName, CategoryType.income),
      );
    }

    return MonthlyReportsDataset(
      selectedMonth: selectedMonth,
      trendMonthCount: resolvedTrendCount,
      transactions: transactions,
      expenseCategoryIcons: expenseCategoryIcons,
      incomeCategoryIcons: incomeCategoryIcons,
    );
  }

  Future<ReportsSnapshot> fetchReportsSnapshot(
    DateTime month,
    AppLocalizations strings,
  ) async {
    final domain_monthly_summary.MonthlySummaryRange range =
        domain_monthly_summary.monthlySummaryRangeFor(month);
    final List<TransactionData> transactions = await fetchTransactions(
      start: range.start,
      end: range.end,
    );

    final domain_monthly_summary.MonthlySummarySnapshot monthlySummary =
        domain_monthly_summary.buildMonthlySummary(
          month: month,
          transactions: transactions.map(_toMonthlySummaryTransaction),
        );

    final Map<String, IconData> icons = <String, IconData>{};
    for (final TransactionData transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        icons.putIfAbsent(
          transaction.categoryName,
          () => _iconForCategoryName(
            transaction.categoryName,
            CategoryType.expense,
          ),
        );
      }
    }

    final List<ReportBreakdownItem> breakdown = monthlySummary.categoryTotals
        .map((domain_monthly_summary.MonthlyCategoryTotal entry) {
          return ReportBreakdownItem(
            categoryName: entry.categoryName,
            amountMinor: entry.amountMinor,
            fraction: monthlySummary.totalExpenseMinor == 0
                ? 0
                : entry.amountMinor / monthlySummary.totalExpenseMinor,
            icon: icons[entry.categoryName] ?? Icons.receipt_long_rounded,
          );
        })
        .toList();

    return ReportsSnapshot(
      monthLabel: strings.monthLong(month),
      yearLabel: month.year.toString(),
      incomeMinor: monthlySummary.totalIncomeMinor,
      expenseMinor: monthlySummary.totalExpenseMinor,
      breakdown: breakdown,
    );
  }

  Future<IncomeDetailViewModel> fetchIncomeDetail(
    IncomeDetailQuery query,
    AppLocalizations strings,
  ) async {
    final DateTime today = _businessToday();
    final IncomeDetailRange range = _incomeDetailService.resolveRange(
      today: today,
      query: query,
      strings: strings,
    );
    final List<TransactionData> transactions = await fetchTransactions(
      type: TransactionType.income,
      start: range.start,
      end: range.end,
    );

    return _incomeDetailService.buildViewModel(
      query: query,
      range: range,
      transactions: transactions.map(_toIncomeDetailTransaction),
      strings: strings,
    );
  }

  Future<ExpenseDetailViewModel> fetchExpenseDetail(
    ExpenseDetailQuery query,
    AppLocalizations strings,
  ) async {
    final DateTime today = _businessToday();
    final ExpenseDetailRange range = _expenseDetailService.resolveRange(
      today: today,
      query: query,
      strings: strings,
    );
    final List<TransactionData> transactions = await fetchTransactions(
      type: TransactionType.expense,
      start: range.start,
      end: range.end,
    );

    return _expenseDetailService.buildViewModel(
      query: query,
      range: range,
      transactions: transactions.map(_toExpenseDetailTransaction),
      strings: strings,
    );
  }

  Future<NetProfitDetailViewModel> fetchNetProfitDetail(
    NetProfitDetailQuery query,
    AppLocalizations strings,
  ) async {
    final DateTime today = _businessToday();
    final NetProfitDetailRange range = _netProfitDetailService.resolveRange(
      today: today,
      query: query,
      strings: strings,
    );
    final List<TransactionData> transactions = await fetchTransactions(
      start: range.start,
      end: range.end,
    );

    return _netProfitDetailService.buildViewModel(
      query: query,
      range: range,
      transactions: transactions.map(_toNetProfitDetailTransaction),
      strings: strings,
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
          reserveEnabled: draft.reserveEnabled,
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

  Future<void> updateRecurringExpense({
    required String id,
    required RecurringDraft draft,
  }) async {
    final String categoryType = await _fetchCategoryTypeValue(draft.categoryId);
    final domain_recurring.RecurringModel recurring =
        domain_recurring.RecurringModel.fromPayload(
          id: id,
          name: draft.name,
          categoryId: draft.categoryId,
          categoryType: categoryType,
          amountMinor: draft.amountMinor,
          currency: 'GBP',
          frequency: draft.frequency.dbValue,
          nextDueOn: draft.nextDueOn,
          reminderDaysBefore: draft.reminderDaysBefore,
          defaultPaymentMethod: draft.defaultPaymentMethod?.dbValue,
          reserveEnabled: draft.reserveEnabled,
          isActive: true,
          note: draft.note,
        );
    await _client
        .from('recurring_expenses')
        .update(<String, dynamic>{
          'name': recurring.name,
          'category_id': recurring.categoryId,
          'amount_minor': recurring.amount.value,
          'currency': recurring.currency.code,
          'frequency': recurring.frequency.dbValue,
          'next_due_on': recurring.nextDueOn.iso8601Date,
          'reminder_days_before': recurring.reminderDaysBefore,
          'default_payment_method': recurring.defaultPaymentMethod?.dbValue,
          'reserve_enabled': recurring.reserveEnabled,
          'note': recurring.note,
        })
        .eq('id', id)
        .eq('user_id', _user.id);
  }

  Future<void> deactivateRecurringExpense({required String id}) async {
    final String recurringId = domain.requireTrimmedText(id, 'recurring_id');
    await _client
        .from('recurring_expenses')
        .update(<String, dynamic>{'is_active': false})
        .eq('id', recurringId)
        .eq('user_id', _user.id);
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

  Future<List<RecurringUiItem>> fetchRecurringUiItems(
    AppLocalizations strings,
  ) async {
    final DateTime today = _businessToday();
    final List<RecurringExpenseData> records = await fetchRecurringExpenses();
    return _buildRecurringUiItems(
      records: records,
      today: today,
      strings: strings,
    );
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

  List<RecurringUiItem> _buildRecurringUiItems({
    required List<RecurringExpenseData> records,
    required DateTime today,
    required AppLocalizations strings,
  }) {
    final List<RecurringUiItem> items =
        records.map((RecurringExpenseData record) {
          final int diffDays = record.nextDueOn.difference(today).inDays;
          final RecurringUiStatus status = diffDays < 0
              ? RecurringUiStatus.late
              : diffDays <= record.reminderDaysBefore
              ? RecurringUiStatus.soon
              : RecurringUiStatus.later;
          return RecurringUiItem(
            record: record,
            status: status,
            statusLabel: strings.recurringStatusLabel(status, diffDays),
            frequencyMeta: strings.recurringFrequencyMeta(
              status,
              record.frequency,
              record.nextDueOn,
              diffDays,
            ),
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

  ReservePlannerSnapshot _buildReservePlannerSnapshot({
    required List<RecurringExpenseData> records,
    required DateTime today,
  }) {
    final domain_reserve_planner.ReservePlannerComputation computation =
        domain_reserve_planner.buildReservePlanner(
          today: today,
          recurringExpenses: records.map((RecurringExpenseData record) {
            return domain_reserve_planner.ReservePlannerRecurringExpense(
              id: record.id,
              name: record.name,
              amountMinor: record.amountMinor,
              frequency: _toDomainRecurringFrequencyType(record.frequency),
              nextDueOn: record.nextDueOn,
              isActive: record.isActive,
              reserveEnabled: record.reserveEnabled,
            );
          }),
        );

    return ReservePlannerSnapshot(
      totalSuggestedWeeklyReserveMinor:
          computation.totalSuggestedWeeklyReserveMinor,
      eligibleItemCount: computation.items.length,
      items: computation.items
          .map(
            (domain_reserve_planner.ReservePlannerSuggestionItem item) =>
                ReservePlannerItem(
                  id: item.id,
                  name: item.name,
                  amountMinor: item.amountMinor,
                  frequency: _toUiRecurringFrequencyType(item.frequency),
                  nextDueOn: item.nextDueOn,
                  daysUntilDue: item.daysUntilDue,
                  weeksUntilDue: item.weeksUntilDue,
                  suggestedWeeklyReserveMinor: item.suggestedWeeklyReserveMinor,
                ),
          )
          .toList(),
    );
  }

  TransactionData _mapTransaction(dynamic row) {
    final Map<String, dynamic> category =
        row['category'] as Map<String, dynamic>;
    final Map<String, dynamic>? supplier =
        row['supplier'] as Map<String, dynamic>?;
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
      supplierId: (row['supplier_id'] as String?) ?? supplier?['id'] as String?,
      supplierName: supplier?['name'] as String?,
      attachmentPath: transaction.attachmentPath,
      recurringExpenseId: transaction.recurringExpenseId,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  domain_weekly_summary.WeeklySummaryTransaction _toWeeklySummaryTransaction(
    TransactionData transaction,
  ) {
    return domain_weekly_summary.WeeklySummaryTransaction(
      type: _toDomainTransactionType(transaction.type),
      paymentMethod: _toDomainPaymentMethodType(transaction.paymentMethod),
      amountMinor: transaction.amountMinor,
    );
  }

  domain_monthly_summary.MonthlySummaryTransaction _toMonthlySummaryTransaction(
    TransactionData transaction,
  ) {
    return domain_monthly_summary.MonthlySummaryTransaction(
      type: _toDomainTransactionType(transaction.type),
      amountMinor: transaction.amountMinor,
      categoryName: transaction.categoryName,
    );
  }

  Future<_ResolvedCategory> _fetchCategory(String categoryId) async {
    final Map<String, dynamic>? row = await _client
        .from('categories')
        .select('type, name')
        .eq('id', categoryId)
        .eq('user_id', _user.id)
        .maybeSingle();

    if (row == null) {
      throw const domain.DomainValidationException(
        code: 'category.not_found',
        message: 'Category must exist for the current user.',
      );
    }

    return _ResolvedCategory(
      type: row['type'] as String,
      name: row['name'] as String,
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
      throw domain.DomainValidationException(
        code: 'transaction.category_not_found',
        message: 'The selected category no longer exists.',
      );
    }

    return row['type'] as String;
  }

  bool get _hasTransactionSyncLifecycle =>
      _outboxRepository != null && _connectivityProbe != null;

  Future<bool> _isOnline() async {
    final ConnectivityProbe? probe = _connectivityProbe;
    if (probe == null) {
      return true;
    }
    return probe.isOnline();
  }

  bool _shouldQueueRemoteFailure(Object error) {
    if (error is AuthException) {
      return false;
    }

    final SyncFailureDecision decision = _syncConflictPolicy.classify(error);
    return decision.type == SyncFailureType.retryable;
  }

  Future<void> _ensureOutboxEntryCompleted(String entryId) async {
    final OutboxRepository? outboxRepository = _outboxRepository;
    if (outboxRepository == null) {
      return;
    }

    final entry = await outboxRepository.findOutboxEntry(entryId);
    if (entry == null) {
      throw Exception('Transaction sync entry was not found.');
    }

    if (entry.status == OutboxEntryStatus.completed.name) {
      return;
    }

    if (entry.lastError == 'Authentication required') {
      throw const AuthException('Authentication required');
    }

    throw Exception(
      entry.lastError ??
          (entry.nextRetryAt != null
              ? 'Transaction sync is still pending.'
              : 'Transaction sync did not complete.'),
    );
  }

  domain_transaction.TransactionModel _buildTransactionModel({
    String? id,
    required EntryDraft draft,
    required String categoryType,
  }) {
    return domain_transaction.TransactionModel.fromPayload(
      id: id,
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
      supplierId: draft.supplierId,
      attachmentPath: draft.attachmentPath,
    );
  }

  Future<void> _createTransactionRemote(
    domain_transaction.TransactionModel transaction,
  ) async {
    final bool isIncome = transaction.type == domain.TransactionType.income;
    if (isIncome) {
      debugPrint('INCOME_SUPABASE_INSERT_STARTED');
    }

    try {
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
        'supplier_id': transaction.supplierId,
        'attachment_path': transaction.attachmentPath,
      });

      if (isIncome) {
        debugPrint('INCOME_SUPABASE_INSERT_SUCCESS');
      }
    } catch (error) {
      if (isIncome) {
        debugPrint('INCOME_SUPABASE_INSERT_ERROR: $error');
      }
      rethrow;
    }
  }

  Future<void> _updateTransactionRemote(
    domain_transaction.TransactionModel transaction,
  ) {
    return _client
        .from('transactions')
        .update(<String, dynamic>{
          'type': transaction.type.dbValue,
          'occurred_on': transaction.occurredOn.iso8601Date,
          'amount_minor': transaction.amount.value,
          'currency': transaction.currency.code,
          'category_id': transaction.categoryId,
          'payment_method': transaction.paymentMethod.dbValue,
          'source_platform': transaction.sourcePlatform?.dbValue,
          'note': transaction.note,
          'vendor': transaction.vendor,
          'supplier_id': transaction.supplierId,
          'attachment_path': transaction.attachmentPath,
        })
        .eq('id', transaction.id!)
        .eq('user_id', _user.id);
  }

  Future<void> _deleteTransactionRemote(String transactionId) {
    return _client
        .from('transactions')
        .update(<String, dynamic>{
          'deleted_at': _clock().toUtc().toIso8601String(),
        })
        .eq('id', transactionId)
        .eq('user_id', _user.id);
  }

  CategoryType _categoryTypeFromDbValue(String value) {
    return switch (value) {
      'income' => CategoryType.income,
      _ => CategoryType.expense,
    };
  }

  DateTime _businessToday() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
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

  int _compareDashboardRecentTransactions(
    TransactionData a,
    TransactionData b,
  ) {
    final int occurredOnComparison = b.occurredOn.compareTo(a.occurredOn);
    if (occurredOnComparison != 0) {
      return occurredOnComparison;
    }
    return b.createdAt.compareTo(a.createdAt);
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

  domain.TransactionType _toDomainTransactionType(TransactionType type) =>
      domain.TransactionTypeX.fromDbValue(type.dbValue);

  PaymentMethodType _toUiPaymentMethodType(domain.PaymentMethodType type) =>
      switch (type) {
        domain.PaymentMethodType.cash => PaymentMethodType.cash,
        domain.PaymentMethodType.card => PaymentMethodType.card,
        domain.PaymentMethodType.bankTransfer => PaymentMethodType.bankTransfer,
        domain.PaymentMethodType.other => PaymentMethodType.other,
      };

  domain.PaymentMethodType _toDomainPaymentMethodType(PaymentMethodType type) =>
      domain.PaymentMethodTypeX.fromDbValue(type.dbValue);

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

  domain.RecurringFrequencyType _toDomainRecurringFrequencyType(
    RecurringFrequencyType type,
  ) => domain.RecurringFrequencyTypeX.fromDbValue(type.dbValue);

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

  IncomeDetailTransaction _toIncomeDetailTransaction(
    TransactionData transaction,
  ) {
    return IncomeDetailTransaction(
      occurredOn: transaction.occurredOn,
      amountMinor: transaction.amountMinor,
      paymentMethod: switch (transaction.paymentMethod) {
        PaymentMethodType.cash => IncomeDetailPaymentMethod.cash,
        PaymentMethodType.card => IncomeDetailPaymentMethod.card,
        PaymentMethodType.bankTransfer => IncomeDetailPaymentMethod.other,
        PaymentMethodType.other => IncomeDetailPaymentMethod.other,
      },
    );
  }

  ExpenseDetailTransaction _toExpenseDetailTransaction(
    TransactionData transaction,
  ) {
    return ExpenseDetailTransaction(
      occurredOn: transaction.occurredOn,
      amountMinor: transaction.amountMinor,
      categoryName: transaction.categoryName,
      paymentMethod: switch (transaction.paymentMethod) {
        PaymentMethodType.cash => ExpenseDetailPaymentMethod.cash,
        PaymentMethodType.card => ExpenseDetailPaymentMethod.card,
        PaymentMethodType.bankTransfer => ExpenseDetailPaymentMethod.other,
        PaymentMethodType.other => ExpenseDetailPaymentMethod.other,
      },
    );
  }

  NetProfitDetailTransaction _toNetProfitDetailTransaction(
    TransactionData transaction,
  ) {
    return NetProfitDetailTransaction(
      occurredOn: transaction.occurredOn,
      amountMinor: transaction.amountMinor,
      type: switch (transaction.type) {
        TransactionType.income => NetProfitTransactionType.income,
        TransactionType.expense => NetProfitTransactionType.expense,
      },
    );
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

class _ResolvedCategory {
  const _ResolvedCategory({required this.type, required this.name});

  final String type;
  final String name;
}
