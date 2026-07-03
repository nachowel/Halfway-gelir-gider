import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_filter_chip.dart';
import '../../../shared/hi_fi/hi_fi_section_header.dart';
import '../domain/payee_analytics_models.dart';
import '../domain/payee_analytics_service.dart';

class PayeeAnalyticsSection extends ConsumerStatefulWidget {
  const PayeeAnalyticsSection({super.key});

  @override
  ConsumerState<PayeeAnalyticsSection> createState() =>
      _PayeeAnalyticsSectionState();
}

class _PayeeAnalyticsSectionState
    extends ConsumerState<PayeeAnalyticsSection> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(payeeAnalyticsQueryProvider).searchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final AsyncValue<PayeeAnalyticsViewModel> asyncVm = ref.watch(
      payeeAnalyticsViewModelProvider,
    );
    final PayeeAnalyticsQuery query = ref.watch(payeeAnalyticsQueryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        HiFiSectionHeader.eye(left: strings.payeeAnalytics),
        const SizedBox(height: AppSpacing.sm),
        _PayeeRangeFilterBar(
          selected: query.preset,
          onSelected: (PayeeRangePreset preset) {
            ref.read(payeeAnalyticsQueryProvider.notifier).state =
                query.copyWith(preset: preset, searchQuery: '');
            _searchController.clear();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _PayeeSearchField(
          controller: _searchController,
          onChanged: (String value) {
            ref.read(payeeAnalyticsQueryProvider.notifier).state =
                query.copyWith(searchQuery: value);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _SortControl(
          selected: query.sortOption,
          onSelected: (SupplierSortOption option) {
            ref.read(payeeAnalyticsQueryProvider.notifier).state =
                query.copyWith(sortOption: option);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        asyncVm.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => _PayeeErrorState(
            message: strings.reportsLoadError,
          ),
          data: (PayeeAnalyticsViewModel vm) {
            if (!vm.hasData && vm.comparisons.isEmpty) {
              return _PayeeEmptyState(message: strings.noPayeesInRange);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (vm.comparisons.isNotEmpty) ...<Widget>[
                  HiFiSectionHeader.eye(left: strings.comparisonMetrics),
                  const SizedBox(height: AppSpacing.sm),
                  _ComparisonCard(comparisons: vm.comparisons),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _PayeeRangeLabelRow(
                  dateLabel: vm.dateLabel,
                  totalMinor: vm.totalMinor,
                ),
                const SizedBox(height: AppSpacing.sm),
                _PayeeList(
                  rows: vm.rows,
                  onTap: (PayeeRow row) {
                    context.push(
                      '/reports/payee/${Uri.encodeComponent(row.payeeKey)}',
                    );
                  },
                ),
                if (vm.topPayees.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  HiFiSectionHeader.eye(left: strings.topPayees),
                  const SizedBox(height: AppSpacing.sm),
                  _TopPayeesList(
                    rows: vm.topPayees,
                    onTap: (PayeeRow row) {
                      context.push(
                        '/reports/payee/${Uri.encodeComponent(row.payeeKey)}',
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SortControl extends StatelessWidget {
  const _SortControl({
    required this.selected,
    required this.onSelected,
  });

  final SupplierSortOption selected;
  final ValueChanged<SupplierSortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final PayeeAnalyticsService service = const PayeeAnalyticsService();
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: SupplierSortOption.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (BuildContext context, int index) {
          final SupplierSortOption option = SupplierSortOption.values[index];
          return HiFiFilterChip(
            label: service.sortOptionLabel(option, strings),
            selected: option == selected,
            onTap: () => onSelected(option),
          );
        },
      ),
    );
  }
}

class _PayeeRangeFilterBar extends StatelessWidget {
  const _PayeeRangeFilterBar({
    required this.selected,
    required this.onSelected,
  });

  final PayeeRangePreset selected;
  final ValueChanged<PayeeRangePreset> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: PayeeRangePreset.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (BuildContext context, int index) {
          final PayeeRangePreset preset = PayeeRangePreset.values[index];
          final AppLocalizations strings = context.strings;
          final PayeeAnalyticsService service = const PayeeAnalyticsService();
          return HiFiFilterChip(
            label: service.presetLabel(preset, strings),
            selected: preset == selected,
            onTap: () => onSelected(preset),
          );
        },
      ),
    );
  }
}

class _PayeeSearchField extends StatelessWidget {
  const _PayeeSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

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
        key: const ValueKey<String>('payee-analytics-search-field'),
        controller: controller,
        onChanged: onChanged,
        cursorColor: AppColors.brand,
        style: AppTypography.body,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.inkFade,
          ),
          hintText: strings.payeeSearchHint,
          hintStyle: AppTypography.bodySoft.copyWith(color: AppColors.inkFade),
        ),
      ),
    );
  }
}

class _PayeeRangeLabelRow extends StatelessWidget {
  const _PayeeRangeLabelRow({
    required this.dateLabel,
    required this.totalMinor,
  });

  final String dateLabel;
  final int totalMinor;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            dateLabel,
            style: AppTypography.bodySoft,
          ),
        ),
        Text(
          strings.currencyMinor(totalMinor),
          style: AppTypography.numSm.copyWith(color: AppColors.expense),
        ),
      ],
    );
  }
}

class _PayeeList extends StatelessWidget {
  const _PayeeList({required this.rows, required this.onTap});

  final List<PayeeRow> rows;
  final ValueChanged<PayeeRow> onTap;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.flush(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            _PayeeRowTile(
              row: rows[i],
              onTap: () => onTap(rows[i]),
            ),
            if (i != rows.length - 1)
              const Divider(color: AppColors.borderSoft, height: 1),
          ],
        ],
      ),
    );
  }
}

class _PayeeRowTile extends StatelessWidget {
  const _PayeeRowTile({required this.row, required this.onTap});

  final PayeeRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      row.payeeName,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.primaryCategory,
                      style: AppTypography.bodySoft,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.payeeLastPayment(row.lastPaymentDate),
                      style: AppTypography.meta,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    strings.currencyMinor(row.totalMinor),
                    style: AppTypography.numSm.copyWith(
                      color: AppColors.expense,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strings.entriesCount(row.transactionCount),
                    style: AppTypography.meta,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayeeEmptyState extends StatelessWidget {
  const _PayeeEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Text(message, style: AppTypography.bodySoft),
    );
  }
}

class _PayeeErrorState extends StatelessWidget {
  const _PayeeErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Text(message, style: AppTypography.bodySoft),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.comparisons});

  final List<PayeeComparisonMetric> comparisons;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < comparisons.length; i++) ...<Widget>[
            _ComparisonRow(metric: comparisons[i]),
            if (i != comparisons.length - 1)
              const Divider(color: AppColors.borderSoft, height: 20),
          ],
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.metric});

  final PayeeComparisonMetric metric;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final bool isIncrease = metric.differenceMinor > 0;
    final bool isDecrease = metric.differenceMinor < 0;
    final Color diffColor = isIncrease
        ? AppColors.expense
        : isDecrease
            ? AppColors.income
            : AppColors.inkSoft;
    final String diffPrefix = isIncrease ? '+' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(metric.label, style: AppTypography.eye),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(metric.currentLabel, style: AppTypography.meta),
                  Text(
                    strings.currencyMinor(metric.currentMinor),
                    style: AppTypography.numSm.copyWith(color: AppColors.expense),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(metric.previousLabel, style: AppTypography.meta),
                  Text(
                    strings.currencyMinor(metric.previousMinor),
                    style: AppTypography.numSm.copyWith(color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(strings.formatPercent(metric.percentChange),
                      style: AppTypography.meta),
                  Text(
                    '$diffPrefix${strings.currencyMinor(metric.differenceMinor)}',
                    style: AppTypography.numSm.copyWith(color: diffColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopPayeesList extends StatelessWidget {
  const _TopPayeesList({required this.rows, required this.onTap});

  final List<PayeeRow> rows;
  final ValueChanged<PayeeRow> onTap;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.flush(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            _PayeeRowTile(
              row: rows[i],
              onTap: () => onTap(rows[i]),
            ),
            if (i != rows.length - 1)
              const Divider(color: AppColors.borderSoft, height: 1),
          ],
        ],
      ),
    );
  }
}
