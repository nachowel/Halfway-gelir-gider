import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/app_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/hi_fi/hi_fi_bottom_sheet.dart';
import '../../../shared/hi_fi/hi_fi_day_group_header.dart';
import '../../../shared/hi_fi/hi_fi_filter_chip.dart';
import '../../../shared/hi_fi/hi_fi_icon_tile.dart';
import '../../../shared/hi_fi/hi_fi_list_row.dart';
import '../../../shared/overlay/app_overlay.dart';
import '../../../shared/widgets/app_button.dart';

const Object _unset = Object();

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({
    this.enableSearch = true,
    this.enableFilter = true,
    super.key,
  });

  final bool enableSearch;
  final bool enableFilter;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  int _selectedFilter = 0;
  bool _searchOpen = false;
  String _searchQuery = '';
  _TransactionAdvancedFilter _advancedFilter =
      const _TransactionAdvancedFilter();

  static const List<TransactionsFilter> _filters = <TransactionsFilter>[
    TransactionsFilter.thisWeek,
    TransactionsFilter.all,
    TransactionsFilter.expense,
    TransactionsFilter.income,
    TransactionsFilter.card,
    TransactionsFilter.cash,
  ];

  TransactionsFilter get _currentFilter => _filters[_selectedFilter];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode(debugLabel: 'transactions-search');
  }

  @override
  void dispose() {
    _searchFocusNode.unfocus();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final AsyncValue<List<TransactionData>> asyncValue = ref.watch(
      transactionsProvider(_currentFilter),
    );
    final List<TransactionData> loadedTransactions =
        asyncValue.asData?.value ?? const <TransactionData>[];
    final List<SourcePlatformType> availablePlatforms = _availablePlatforms(
      loadedTransactions,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenSide,
        AppSpacing.xs,
        AppSpacing.screenSide,
        120,
      ),
      children: <Widget>[
        _TransactionsHeader(
          searchEnabled: widget.enableSearch,
          filterEnabled: widget.enableFilter,
          searchOpen: _searchOpen,
          searchController: _searchController,
          searchFocusNode: _searchFocusNode,
          hasActiveFilters: _advancedFilter.hasAny,
          onSearchTap: widget.enableSearch ? _openSearch : null,
          onSearchClose: widget.enableSearch ? _closeSearch : null,
          onSearchChanged: widget.enableSearch ? _handleSearchChanged : null,
          onFilterTap: widget.enableFilter
              ? () => _openFilterSheet(availablePlatforms)
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              final List<String> filterLabels = <String>[
                strings.thisWeek,
                strings.all,
                strings.expense,
                strings.income,
                strings.card,
                strings.cash,
              ];
              return HiFiFilterChip(
                label: filterLabels[index],
                selected: index == _selectedFilter,
                onTap: () => setState(() => _selectedFilter = index),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemCount: _filters.length,
          ),
        ),
        if (_searchQuery.isNotEmpty || _advancedFilter.hasAny) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _ActiveCriteriaBar(
            searchQuery: _searchQuery,
            filter: _advancedFilter,
            onClearSearch: _searchQuery.isNotEmpty
                ? () {
                    _searchController.clear();
                    _handleSearchChanged('');
                  }
                : null,
            onClearPeriod: _advancedFilter.period != _TransactionPeriod.any
                ? () => setState(() {
                    _advancedFilter = _advancedFilter.copyWith(
                      period: _TransactionPeriod.any,
                    );
                  })
                : null,
            onClearType: _advancedFilter.type != null
                ? () => setState(() {
                    _advancedFilter = _advancedFilter.copyWith(type: null);
                  })
                : null,
            onClearPaymentMethod: _advancedFilter.paymentMethod != null
                ? () => setState(() {
                    _advancedFilter = _advancedFilter.copyWith(
                      paymentMethod: null,
                    );
                  })
                : null,
            onClearPlatform: _advancedFilter.sourcePlatform != null
                ? () => setState(() {
                    _advancedFilter = _advancedFilter.copyWith(
                      sourcePlatform: null,
                    );
                  })
                : null,
            onClearAll: _clearAllFilters,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        asyncValue.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const _ErrorState(),
          data: (List<TransactionData> transactions) {
            final List<TransactionData> visibleTransactions = _applyViewFilters(
              transactions,
            );
            final List<_TransactionDaySection> daySections =
                _buildTransactionDaySections(context, visibleTransactions);
            if (transactions.isEmpty) {
              return const _EmptyState();
            }
            if (visibleTransactions.isEmpty) {
              return _NoResultsState(onClear: _clearAllFilters);
            }
            return _GroupedList(sections: daySections);
          },
        ),
      ],
    );
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_searchOpen) {
        return;
      }
      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    setState(() {
      _searchOpen = false;
      _searchQuery = '';
    });
    _searchController.clear();
  }

  void _handleSearchChanged(String value) {
    setState(() => _searchQuery = value.trim());
  }

  Future<void> _openFilterSheet(
    List<SourcePlatformType> availablePlatforms,
  ) async {
    final _TransactionAdvancedFilter? selected =
        await showAppModalBottomSheet<_TransactionAdvancedFilter>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (BuildContext sheetContext) {
            return _TransactionFilterSheet(
              initialFilter: _advancedFilter,
              availablePlatforms: availablePlatforms,
            );
          },
        );

    if (!mounted || selected == null) {
      return;
    }

    setState(() => _advancedFilter = selected);
  }

  void _clearAllFilters() {
    setState(() {
      _advancedFilter = const _TransactionAdvancedFilter();
      _searchQuery = '';
      _searchOpen = false;
    });
    _searchController.clear();
  }

  List<SourcePlatformType> _availablePlatforms(List<TransactionData> list) {
    final Set<SourcePlatformType> values = <SourcePlatformType>{};
    for (final TransactionData transaction in list) {
      final SourcePlatformType? platform = transaction.sourcePlatform;
      if (platform != null) {
        values.add(platform);
      }
    }
    final List<SourcePlatformType> platforms = values.toList(growable: false)
      ..sort(
        (SourcePlatformType a, SourcePlatformType b) =>
            _sourcePlatformLabel(a).compareTo(_sourcePlatformLabel(b)),
      );
    return platforms;
  }

  List<TransactionData> _applyViewFilters(List<TransactionData> raw) {
    final List<TransactionData> transactions = List<TransactionData>.from(raw)
      ..sort(_compareTransactions);
    return transactions
        .where((TransactionData transaction) {
          if (!_matchesSearch(transaction)) {
            return false;
          }
          if (!_advancedFilter.matches(transaction)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  int _compareTransactions(TransactionData a, TransactionData b) {
    final int occurredOnComparison = b.occurredOn.compareTo(a.occurredOn);
    if (occurredOnComparison != 0) {
      return occurredOnComparison;
    }
    return b.createdAt.compareTo(a.createdAt);
  }

  bool _matchesSearch(TransactionData transaction) {
    final String query = _searchQuery.toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final List<String> haystack = <String>[
      transaction.categoryName,
      transaction.note ?? '',
      transaction.vendor ?? '',
      _paymentMethodLabel(transaction.paymentMethod),
      _transactionTypeLabel(transaction.type),
      transaction.sourcePlatform == null
          ? ''
          : _sourcePlatformLabel(transaction.sourcePlatform!),
    ];

    for (final String value in haystack) {
      if (value.toLowerCase().contains(query)) {
        return true;
      }
    }
    return false;
  }

  String _paymentMethodLabel(PaymentMethodType value) =>
      context.strings.paymentMethodLabel(value);

  String _sourcePlatformLabel(SourcePlatformType value) =>
      context.strings.sourcePlatformLabel(value);

  String _transactionTypeLabel(TransactionType value) =>
      context.strings.transactionTypeLabel(value);
}

class _TransactionDaySection {
  const _TransactionDaySection({
    required this.id,
    required this.label,
    required this.netMinor,
    required this.groups,
  });

  final String id;
  final String label;
  final int netMinor;
  final List<_TransactionTypeSection> groups;
}

class _TransactionTypeSection {
  const _TransactionTypeSection({
    required this.id,
    required this.type,
    required this.totalMinor,
    required this.transactions,
  });

  final String id;
  final TransactionType type;
  final int totalMinor;
  final List<TransactionData> transactions;

  bool get income => type == TransactionType.income;
}

class _TransactionDayAccumulator {
  _TransactionDayAccumulator(this.date);

  final DateTime date;
  final List<TransactionData> expenses = <TransactionData>[];
  final List<TransactionData> income = <TransactionData>[];
  int expenseTotalMinor = 0;
  int incomeTotalMinor = 0;

  void add(TransactionData transaction) {
    if (transaction.type == TransactionType.income) {
      income.add(transaction);
      incomeTotalMinor += transaction.amountMinor;
      return;
    }
    expenses.add(transaction);
    expenseTotalMinor += transaction.amountMinor;
  }

  _TransactionDaySection build(BuildContext context) {
    final String dayId = _dateId(date);
    return _TransactionDaySection(
      id: dayId,
      label: _dateLabel(context, date),
      netMinor: incomeTotalMinor - expenseTotalMinor,
      groups: <_TransactionTypeSection>[
        if (expenses.isNotEmpty)
          _TransactionTypeSection(
            id: '$dayId-${TransactionType.expense.name}',
            type: TransactionType.expense,
            totalMinor: expenseTotalMinor,
            transactions: List<TransactionData>.unmodifiable(expenses),
          ),
        if (income.isNotEmpty)
          _TransactionTypeSection(
            id: '$dayId-${TransactionType.income.name}',
            type: TransactionType.income,
            totalMinor: incomeTotalMinor,
            transactions: List<TransactionData>.unmodifiable(income),
          ),
      ],
    );
  }
}

List<_TransactionDaySection> _buildTransactionDaySections(
  BuildContext context,
  List<TransactionData> transactions,
) {
  final Map<String, _TransactionDayAccumulator> days =
      <String, _TransactionDayAccumulator>{};

  for (final TransactionData transaction in transactions) {
    final DateTime date = DateTime(
      transaction.occurredOn.year,
      transaction.occurredOn.month,
      transaction.occurredOn.day,
    );
    final String dateId = _dateId(date);
    final _TransactionDayAccumulator day = days.putIfAbsent(
      dateId,
      () => _TransactionDayAccumulator(date),
    );
    day.add(transaction);
  }

  return days.values
      .map((_TransactionDayAccumulator day) => day.build(context))
      .where((_TransactionDaySection section) => section.groups.isNotEmpty)
      .toList(growable: false);
}

class _GroupedList extends StatefulWidget {
  const _GroupedList({required this.sections});

  final List<_TransactionDaySection> sections;

  @override
  State<_GroupedList> createState() => _GroupedListState();
}

class _GroupedListState extends State<_GroupedList> {
  late Map<String, bool> _expandedGroups;

  @override
  void initState() {
    super.initState();
    _expandedGroups = _syncExpandedGroups();
  }

  @override
  void didUpdateWidget(covariant _GroupedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sections != widget.sections) {
      _expandedGroups = _syncExpandedGroups(previous: _expandedGroups);
    }
  }

  Map<String, bool> _syncExpandedGroups({Map<String, bool>? previous}) {
    final Map<String, bool> next = <String, bool>{};
    for (final _TransactionDaySection section in widget.sections) {
      for (final _TransactionTypeSection group in section.groups) {
        next[group.id] = previous?[group.id] ?? true;
      }
    }
    return next;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final _TransactionDaySection section
            in widget.sections) ...<Widget>[
          HiFiDayGroupHeader(
            label: section.label,
            net: _netLabel(context, section.netMinor),
            positive: section.netMinor >= 0,
          ),
          const SizedBox(height: AppSpacing.xs),
          for (int i = 0; i < section.groups.length; i++) ...<Widget>[
            _TransactionTypeGroup(
              group: section.groups[i],
              expanded: _expandedGroups[section.groups[i].id] ?? true,
              onToggle: () {
                setState(() {
                  _expandedGroups[section.groups[i].id] =
                      !(_expandedGroups[section.groups[i].id] ?? true);
                });
              },
            ),
            if (i != section.groups.length - 1)
              const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _TransactionTypeGroup extends StatelessWidget {
  const _TransactionTypeGroup({
    required this.group,
    required this.expanded,
    required this.onToggle,
  });

  final _TransactionTypeSection group;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final Color amountColor = group.income
        ? AppColors.income
        : AppColors.expense;
    final Color tint = group.income
        ? const Color(0x142F8A4D)
        : const Color(0x14C2492A);
    final Color borderColor = group.income
        ? const Color(0x1F2F8A4D)
        : const Color(0x1FC2492A);

    return Column(
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey<String>('transaction-group-toggle-${group.id}'),
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppRadius.base),
            child: Ink(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(AppRadius.base),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: <Widget>[
                  AnimatedRotation(
                    turns: expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      group.type == TransactionType.expense
                          ? context.strings.expenses
                          : context.strings.income,
                      style: AppTypography.body.copyWith(
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                  Text(
                    _formatAmount(group.totalMinor),
                    style: AppTypography.numXs.copyWith(color: amountColor),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  key: ValueKey<String>(
                    'transaction-group-content-${group.id}',
                  ),
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < group.transactions.length; i++)
                        _TransactionRow(
                          transaction: group.transactions[i],
                          showDivider: i != group.transactions.length - 1,
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.showDivider});

  final TransactionData transaction;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return HiFiListRow(
      leading: HiFiIconTile(
        icon: _iconForCategory(transaction.categoryName),
        tone: transaction.type == TransactionType.income
            ? HiFiIconTileTone.income
            : HiFiIconTileTone.expense,
      ),
      title: _title(transaction),
      meta: _meta(context, transaction),
      trailing: _TransactionAmount(
        amount: _formatAmount(transaction.amountMinor),
        income: transaction.type == TransactionType.income,
      ),
      showDivider: showDivider,
      onTap: () {
        final String kind = transaction.type == TransactionType.income
            ? 'income'
            : 'expense';
        context.push('/entry/$kind?transactionId=${transaction.id}');
      },
    );
  }
}

String _dateId(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _dateLabel(BuildContext context, DateTime date) =>
    context.strings.dayMonthShortWeekday(date);

String _netLabel(BuildContext context, int netMinor) {
  final bool positive = netMinor >= 0;
  return '${context.strings.net.toLowerCase()} ${positive ? '+' : '-'}${_formatAmount(netMinor.abs())}';
}

String _title(TransactionData transaction) {
  final String? vendor = transaction.vendor?.trim();
  return (vendor != null && vendor.isNotEmpty)
      ? vendor
      : transaction.categoryName;
}

String _meta(BuildContext context, TransactionData transaction) {
  final List<String> parts = <String>[
    transaction.categoryName,
    context.strings.paymentMethodLabel(transaction.paymentMethod),
    if (transaction.sourcePlatform != null)
      context.strings.sourcePlatformLabel(transaction.sourcePlatform!),
  ];
  return parts.join(' · ');
}

String _formatAmount(int minor) {
  final int pounds = minor ~/ 100;
  final int pence = minor % 100;
  return '£$pounds.${pence.toString().padLeft(2, '0')}';
}

IconData _iconForCategory(String category) {
  final String lower = category.toLowerCase();
  if (lower.contains('food') || lower.contains('eat')) {
    return Icons.restaurant_rounded;
  }
  if (lower.contains('fuel') ||
      lower.contains('petrol') ||
      lower.contains('gas')) {
    return Icons.local_gas_station_rounded;
  }
  if (lower.contains('transport') ||
      lower.contains('uber') ||
      lower.contains('taxi')) {
    return Icons.directions_car_rounded;
  }
  if (lower.contains('shop') ||
      lower.contains('supermarket') ||
      lower.contains('groceries')) {
    return Icons.shopping_cart_rounded;
  }
  if (lower.contains('sale') ||
      lower.contains('revenue') ||
      lower.contains('income')) {
    return Icons.storefront_rounded;
  }
  if (lower.contains('supply') || lower.contains('supplies')) {
    return Icons.inventory_2_rounded;
  }
  if (lower.contains('rent') || lower.contains('utilities')) {
    return Icons.home_rounded;
  }
  if (lower.contains('salary') ||
      lower.contains('wage') ||
      lower.contains('payroll')) {
    return Icons.payments_rounded;
  }
  return Icons.receipt_long_rounded;
}

class _TransactionsHeader extends StatelessWidget {
  const _TransactionsHeader({
    required this.searchEnabled,
    required this.filterEnabled,
    required this.searchOpen,
    required this.searchController,
    required this.searchFocusNode,
    required this.hasActiveFilters,
    required this.onSearchTap,
    required this.onSearchClose,
    required this.onSearchChanged,
    required this.onFilterTap,
  });

  final bool searchEnabled;
  final bool filterEnabled;
  final bool searchOpen;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool hasActiveFilters;
  final VoidCallback? onSearchTap;
  final VoidCallback? onSearchClose;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTypography.h1,
                  children: <InlineSpan>[
                    TextSpan(
                      text: strings.allItems,
                      style: AppTypography.h1.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (searchEnabled)
              _HeaderActionButton(
                key: const ValueKey<String>('transactions-search-button'),
                icon: searchOpen ? Icons.close_rounded : Icons.search_rounded,
                active: searchOpen,
                onTap: searchOpen ? onSearchClose : onSearchTap,
              ),
            if (filterEnabled) ...<Widget>[
              if (searchEnabled) const SizedBox(width: 6),
              _HeaderActionButton(
                key: const ValueKey<String>('transactions-filter-button'),
                icon: Icons.filter_alt_outlined,
                active: hasActiveFilters,
                onTap: onFilterTap,
              ),
            ],
          ],
        ),
        if (searchEnabled && searchOpen) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _InlineSearchField(
            controller: searchController,
            focusNode: searchFocusNode,
            onChanged: onSearchChanged,
          ),
        ],
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.active,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active ? AppColors.brandSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: active ? AppColors.brand : AppColors.border,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: active ? AppColors.brandStrong : AppColors.brand,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineSearchField extends StatelessWidget {
  const _InlineSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        key: const ValueKey<String>('transactions-search-field'),
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        cursorColor: AppColors.brand,
        style: AppTypography.body,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.inkFade,
          ),
          hintText: strings.searchTransactionsHint,
          hintStyle: AppTypography.bodySoft.copyWith(color: AppColors.inkFade),
        ),
      ),
    );
  }
}

class _ActiveCriteriaBar extends StatelessWidget {
  const _ActiveCriteriaBar({
    required this.searchQuery,
    required this.filter,
    required this.onClearAll,
    this.onClearSearch,
    this.onClearPeriod,
    this.onClearType,
    this.onClearPaymentMethod,
    this.onClearPlatform,
  });

  final String searchQuery;
  final _TransactionAdvancedFilter filter;
  final VoidCallback onClearAll;
  final VoidCallback? onClearSearch;
  final VoidCallback? onClearPeriod;
  final VoidCallback? onClearType;
  final VoidCallback? onClearPaymentMethod;
  final VoidCallback? onClearPlatform;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(strings.active.toUpperCase(), style: AppTypography.eye),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            if (searchQuery.isNotEmpty)
              HiFiFilterChip(
                label: strings.searchFilterLabel(searchQuery),
                selected: true,
                onTap: onClearSearch ?? () {},
              ),
            if (filter.period != _TransactionPeriod.any)
              HiFiFilterChip(
                label: _transactionPeriodLabel(context, filter.period),
                selected: true,
                onTap: onClearPeriod ?? () {},
              ),
            if (filter.type != null)
              HiFiFilterChip(
                label: filter.type == TransactionType.income
                    ? context.strings.income
                    : context.strings.expense,
                selected: true,
                onTap: onClearType ?? () {},
              ),
            if (filter.paymentMethod != null)
              HiFiFilterChip(
                label: context.strings.paymentMethodLabel(
                  filter.paymentMethod!,
                ),
                selected: true,
                onTap: onClearPaymentMethod ?? () {},
              ),
            if (filter.sourcePlatform != null)
              HiFiFilterChip(
                label: context.strings.sourcePlatformLabel(
                  filter.sourcePlatform!,
                ),
                selected: true,
                onTap: onClearPlatform ?? () {},
              ),
            AppButton(
              label: context.strings.clearAll,
              onPressed: onClearAll,
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.compact,
              expanded: false,
            ),
          ],
        ),
      ],
    );
  }
}

enum _TransactionPeriod { any, thisWeek, thisMonth, last30Days }

String _transactionPeriodLabel(
  BuildContext context,
  _TransactionPeriod value,
) => switch (value) {
  _TransactionPeriod.any => context.strings.anyTime,
  _TransactionPeriod.thisWeek => context.strings.thisWeek,
  _TransactionPeriod.thisMonth => context.strings.thisMonth,
  _TransactionPeriod.last30Days => context.strings.last30Days,
};

class _TransactionAdvancedFilter {
  const _TransactionAdvancedFilter({
    this.period = _TransactionPeriod.any,
    this.type,
    this.paymentMethod,
    this.sourcePlatform,
  });

  final _TransactionPeriod period;
  final TransactionType? type;
  final PaymentMethodType? paymentMethod;
  final SourcePlatformType? sourcePlatform;

  bool get hasAny =>
      period != _TransactionPeriod.any ||
      type != null ||
      paymentMethod != null ||
      sourcePlatform != null;

  _TransactionAdvancedFilter copyWith({
    _TransactionPeriod? period,
    Object? type = _unset,
    Object? paymentMethod = _unset,
    Object? sourcePlatform = _unset,
  }) {
    return _TransactionAdvancedFilter(
      period: period ?? this.period,
      type: identical(type, _unset) ? this.type : type as TransactionType?,
      paymentMethod: identical(paymentMethod, _unset)
          ? this.paymentMethod
          : paymentMethod as PaymentMethodType?,
      sourcePlatform: identical(sourcePlatform, _unset)
          ? this.sourcePlatform
          : sourcePlatform as SourcePlatformType?,
    );
  }

  bool matches(TransactionData transaction) {
    if (!_matchesPeriod(transaction)) {
      return false;
    }
    if (type != null && transaction.type != type) {
      return false;
    }
    if (paymentMethod != null && transaction.paymentMethod != paymentMethod) {
      return false;
    }
    if (sourcePlatform != null &&
        transaction.sourcePlatform != sourcePlatform) {
      return false;
    }
    return true;
  }

  bool _matchesPeriod(TransactionData transaction) {
    if (period == _TransactionPeriod.any) {
      return true;
    }

    final DateTime today = DateTime.now();
    final DateTime normalizedToday = DateTime(
      today.year,
      today.month,
      today.day,
    );
    final DateTime occurredOn = DateTime(
      transaction.occurredOn.year,
      transaction.occurredOn.month,
      transaction.occurredOn.day,
    );

    switch (period) {
      case _TransactionPeriod.any:
        return true;
      case _TransactionPeriod.thisWeek:
        final DateTime start = normalizedToday.subtract(
          Duration(days: normalizedToday.weekday - 1),
        );
        final DateTime end = start.add(const Duration(days: 6));
        return !occurredOn.isBefore(start) && !occurredOn.isAfter(end);
      case _TransactionPeriod.thisMonth:
        return occurredOn.year == normalizedToday.year &&
            occurredOn.month == normalizedToday.month;
      case _TransactionPeriod.last30Days:
        final DateTime start = normalizedToday.subtract(
          const Duration(days: 29),
        );
        return !occurredOn.isBefore(start) &&
            !occurredOn.isAfter(normalizedToday);
    }
  }
}

class _TransactionFilterSheet extends StatefulWidget {
  const _TransactionFilterSheet({
    required this.initialFilter,
    required this.availablePlatforms,
  });

  final _TransactionAdvancedFilter initialFilter;
  final List<SourcePlatformType> availablePlatforms;

  @override
  State<_TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<_TransactionFilterSheet> {
  late _TransactionAdvancedFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.filters.toUpperCase(), style: AppTypography.eye),
          const SizedBox(height: 4),
          Text(strings.refineTransactions, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.md),
          _FilterSection<_TransactionPeriod>(
            title: strings.period,
            values: _TransactionPeriod.values,
            selectedValue: _draft.period,
            labelBuilder: (_TransactionPeriod value) =>
                _transactionPeriodLabel(context, value),
            keyBuilder: (_TransactionPeriod value) =>
                ValueKey<String>('filter-period-${value.name}'),
            onSelected: (_TransactionPeriod value) {
              setState(() => _draft = _draft.copyWith(period: value));
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilterSection<TransactionType?>(
            title: strings.type,
            values: const <TransactionType?>[
              null,
              TransactionType.income,
              TransactionType.expense,
            ],
            selectedValue: _draft.type,
            labelBuilder: (TransactionType? value) => value == null
                ? context.strings.any
                : value == TransactionType.income
                ? context.strings.income
                : context.strings.expense,
            keyBuilder: (TransactionType? value) =>
                ValueKey<String>('filter-type-${value?.name ?? 'any'}'),
            onSelected: (TransactionType? value) {
              setState(() => _draft = _draft.copyWith(type: value));
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilterSection<PaymentMethodType?>(
            title: strings.payment,
            values: const <PaymentMethodType?>[
              null,
              PaymentMethodType.cash,
              PaymentMethodType.card,
              PaymentMethodType.bankTransfer,
              PaymentMethodType.other,
            ],
            selectedValue: _draft.paymentMethod,
            labelBuilder: (PaymentMethodType? value) => value == null
                ? context.strings.any
                : context.strings.paymentMethodLabel(value),
            keyBuilder: (PaymentMethodType? value) =>
                ValueKey<String>('filter-payment-${value?.name ?? 'any'}'),
            onSelected: (PaymentMethodType? value) {
              setState(() => _draft = _draft.copyWith(paymentMethod: value));
            },
          ),
          if (widget.availablePlatforms.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            _FilterSection<SourcePlatformType?>(
              title: strings.platform,
              values: <SourcePlatformType?>[null, ...widget.availablePlatforms],
              selectedValue: _draft.sourcePlatform,
              labelBuilder: (SourcePlatformType? value) => value == null
                  ? context.strings.any
                  : context.strings.sourcePlatformLabel(value),
              keyBuilder: (SourcePlatformType? value) =>
                  ValueKey<String>('filter-platform-${value?.name ?? 'any'}'),
              onSelected: (SourcePlatformType? value) {
                setState(() => _draft = _draft.copyWith(sourcePlatform: value));
              },
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  key: const ValueKey<String>('transactions-filter-reset'),
                  label: strings.reset,
                  onPressed: () {
                    setState(() => _draft = const _TransactionAdvancedFilter());
                  },
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.compact,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppButton(
                  key: const ValueKey<String>('transactions-filter-apply'),
                  label: strings.apply,
                  onPressed: () => Navigator.of(context).pop(_draft),
                  size: AppButtonSize.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterSection<T> extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.values,
    required this.selectedValue,
    required this.labelBuilder,
    required this.keyBuilder,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final T selectedValue;
  final String Function(T value) labelBuilder;
  final Key Function(T value) keyBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title.toUpperCase(), style: AppTypography.eye),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: values
              .map((T value) {
                return HiFiFilterChip(
                  key: keyBuilder(value),
                  label: labelBuilder(value),
                  selected: value == selectedValue,
                  onTap: () => onSelected(value),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _TransactionAmount extends StatelessWidget {
  const _TransactionAmount({required this.amount, required this.income});

  final String amount;
  final bool income;

  @override
  Widget build(BuildContext context) {
    return Text(
      amount,
      textAlign: TextAlign.right,
      style: AppTypography.numMd.copyWith(
        color: income ? AppColors.income : AppColors.expense,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: <Widget>[
          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.inkFade),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.noTransactionsYet,
            style: AppTypography.body.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            strings.transactionsAppearHere,
            style: AppTypography.meta.copyWith(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: <Widget>[
          Icon(Icons.search_off_rounded, size: 48, color: AppColors.inkFade),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.noMatchingTransactions,
            style: AppTypography.body.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            strings.tryDifferentSearch,
            style: AppTypography.meta.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: strings.clearFilters,
            onPressed: onClear,
            variant: AppButtonVariant.ghost,
            expanded: false,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: <Widget>[
          Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.inkFade),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.transactionsLoadError,
            style: AppTypography.body.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            strings.checkConnectionAndTryAgain,
            style: AppTypography.meta.copyWith(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
