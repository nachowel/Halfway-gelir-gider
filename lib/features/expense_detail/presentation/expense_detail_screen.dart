import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/app_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_filter_chip.dart';
import '../../../shared/hi_fi/hi_fi_icon_tile.dart';
import '../../../shared/hi_fi/hi_fi_screen_background.dart';
import '../../../shared/hi_fi/hi_fi_section_header.dart';
import '../../../shared/layout/mobile_scaffold.dart';
import '../domain/expense_detail_models.dart';
import '../domain/expense_detail_service.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  const ExpenseDetailScreen({super.key});

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_GB',
    symbol: '£',
    decimalDigits: 2,
  );

  final ExpenseDetailService _service = ExpenseDetailService();
  ExpenseDetailQuery _query = const ExpenseDetailQuery.thisWeek();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final DateTime today = DateTime.now();
    final ExpenseDetailRange previewRange = _service.resolveRange(
      today: today,
      query: _query,
      strings: strings,
    );
    final AsyncValue<ExpenseDetailViewModel> viewModelAsync = ref.watch(
      expenseDetailProvider(_query),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: MobileScaffold(
        child: HiFiScreenBackground(
          tone: HiFiScreenTone.warm,
          child: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenSide,
                AppSpacing.sm,
                AppSpacing.screenSide,
                AppSpacing.xxl,
              ),
              children: <Widget>[
                _ExpenseHeader(
                  onBack: () async {
                    final bool didPop = await Navigator.of(context).maybePop();
                    if (!didPop && context.mounted) {
                      context.go('/summary');
                    }
                  },
                  onInfoTap: () => _showInfoSheet(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                _PeriodFilterBar(
                  selectedPreset: _query.preset,
                  rangeLabel: previewRange.label,
                  onPresetSelected: _handlePresetSelected,
                ),
                const SizedBox(height: AppSpacing.lg),
                viewModelAsync.when(
                  loading: () => const _LoadingState(),
                  error: (_, __) => const _ErrorState(),
                  data: (ExpenseDetailViewModel viewModel) {
                    return _ExpenseDetailContent(viewModel: viewModel);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePresetSelected(ExpenseDetailRangePreset preset) async {
    if (preset == ExpenseDetailRangePreset.custom) {
      final DateTime now = DateTime.now();
      final ExpenseDetailRange currentRange = _service.resolveRange(
        today: now,
        query: _query,
        strings: context.strings,
      );
      final DateTimeRange? selection = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 3, 1, 1),
        lastDate: DateTime(now.year + 3, 12, 31),
        initialDateRange: currentRange.asDateTimeRange,
        helpText: context.strings.selectExpenseRange,
        saveText: context.strings.apply,
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.brand,
                onPrimary: AppColors.onInk,
                surface: AppColors.surface,
                onSurface: AppColors.ink,
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: AppColors.surface,
              ),
              datePickerTheme: const DatePickerThemeData(
                backgroundColor: AppColors.surface,
                rangePickerBackgroundColor: AppColors.surface,
                dividerColor: AppColors.borderSoft,
                dayBackgroundColor: WidgetStatePropertyAll<Color?>(
                  AppColors.brandTint,
                ),
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      );
      if (!mounted || selection == null) {
        return;
      }
      setState(() {
        _query = ExpenseDetailQuery.custom(
          start: selection.start,
          end: selection.end,
        );
      });
      return;
    }

    setState(() {
      _query = switch (preset) {
        ExpenseDetailRangePreset.thisWeek =>
          const ExpenseDetailQuery.thisWeek(),
        ExpenseDetailRangePreset.lastWeek =>
          const ExpenseDetailQuery.lastWeek(),
        ExpenseDetailRangePreset.thisMonth =>
          const ExpenseDetailQuery.thisMonth(),
        ExpenseDetailRangePreset.lastMonth =>
          const ExpenseDetailQuery.lastMonth(),
        ExpenseDetailRangePreset.custom => _query,
      };
    });
  }

  Future<void> _showInfoSheet(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.borderSoft),
          ),
          title: Text(context.strings.expenseDetail, style: AppTypography.h2),
          content: Text(
            context.strings.expenseDetailInfo,
            style: AppTypography.bodySoft,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.strings.close, style: AppTypography.button),
            ),
          ],
        );
      },
    );
  }

  static String formatCurrency(int amountMinor) {
    return _currencyFormatter.format(amountMinor / 100);
  }
}

class _ExpenseDetailContent extends StatelessWidget {
  const _ExpenseDetailContent({required this.viewModel});

  final ExpenseDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _KpiRow(viewModel: viewModel),
        const SizedBox(height: AppSpacing.md),
        _CompositionCard(viewModel: viewModel),
        const SizedBox(height: AppSpacing.lg),
        _DailyExpenseChartCard(viewModel: viewModel),
        const SizedBox(height: AppSpacing.lg),
        _CategoryBreakdownSection(viewModel: viewModel),
        const SizedBox(height: AppSpacing.lg),
        _DailyBreakdownSection(viewModel: viewModel),
        if (viewModel.warningInsightMessage != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          _WarningCard(message: viewModel.warningInsightMessage!),
        ],
        const SizedBox(height: AppSpacing.lg),
        _InsightsCard(viewModel: viewModel),
      ],
    );
  }
}

class _ExpenseHeader extends StatelessWidget {
  const _ExpenseHeader({required this.onBack, required this.onInfoTap});

  final VoidCallback onBack;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Row(
      children: <Widget>[
        InkWell(
          key: const ValueKey<String>('expense-detail-back-button'),
          onTap: onBack,
          borderRadius: BorderRadius.circular(999),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 24,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            strings.expenses,
            style: AppTypography.h1.copyWith(fontSize: 24),
          ),
        ),
        InkWell(
          key: const ValueKey<String>('expense-detail-info-button'),
          onTap: onInfoTap,
          borderRadius: BorderRadius.circular(999),
          child: const HiFiIconTile(
            icon: Icons.info_outline_rounded,
            tone: HiFiIconTileTone.mint,
            shape: HiFiIconTileShape.circle,
          ),
        ),
      ],
    );
  }
}

class _PeriodFilterBar extends StatelessWidget {
  const _PeriodFilterBar({
    required this.selectedPreset,
    required this.rangeLabel,
    required this.onPresetSelected,
  });

  final ExpenseDetailRangePreset selectedPreset;
  final String rangeLabel;
  final ValueChanged<ExpenseDetailRangePreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (final ExpenseDetailRangePreset preset
                in ExpenseDetailRangePreset.values)
              HiFiFilterChip(
                label: context.strings.expenseRangePresetLabel(preset),
                selected: preset == selectedPreset,
                onTap: () => onPresetSelected(preset),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          rangeLabel,
          style: AppTypography.body.copyWith(
            fontSize: 15,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.viewModel});

  final ExpenseDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < viewModel.kpis.length; i++) ...<Widget>[
          Expanded(
            child: _KpiCard(kpi: viewModel.kpis[i], index: i),
          ),
          if (i != viewModel.kpis.length - 1)
            const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi, required this.index});

  final ExpenseKpiDescriptor kpi;
  final int index;

  Color get _primaryColor => switch (index) {
    0 => AppColors.expense,
    1 => AppColors.ink,
    _ => AppColors.expenseInk,
  };

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(kpi.title, style: AppTypography.lbl),
          const SizedBox(height: 8),
          if (index == 0)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                kpi.primary,
                style: AppTypography.numLg.copyWith(
                  color: _primaryColor,
                  fontSize: 26,
                ),
              ),
            )
          else
            Text(
              kpi.primary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h2.copyWith(
                fontSize: 18,
                color: kpi.isEmpty ? AppColors.inkSoft : _primaryColor,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            kpi.secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySoft,
          ),
        ],
      ),
    );
  }
}

class _CompositionCard extends StatelessWidget {
  const _CompositionCard({required this.viewModel});

  final ExpenseDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final List<ExpenseCompositionItem> items = viewModel.compositionItems;
    return HiFiCard.compact(
      child: Row(
        children: <Widget>[
          Expanded(
            child: _CompositionMetric(
              item: items[0],
              progressColor: AppColors.expense,
              progressSoftColor: AppColors.expenseSoft,
            ),
          ),
          Container(
            width: 1,
            height: 86,
            color: AppColors.borderSoft,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          Expanded(
            child: _CompositionMetric(
              item: items[1],
              progressColor: AppColors.amber,
              progressSoftColor: AppColors.amberSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompositionMetric extends StatelessWidget {
  const _CompositionMetric({
    required this.item,
    required this.progressColor,
    required this.progressSoftColor,
  });

  final ExpenseCompositionItem item;
  final Color progressColor;
  final Color progressSoftColor;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = item.isPlaceholder || item.amountMinor == 0;
    final Color ringColor = isDisabled ? AppColors.border : progressSoftColor;
    final Color activeColor = isDisabled ? AppColors.inkFade : progressColor;
    final Color textColor = isDisabled ? AppColors.inkSoft : AppColors.ink;

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.ttl,
              ),
              const SizedBox(height: 6),
              Text(
                '${item.percent.round()}%',
                style: AppTypography.h1.copyWith(
                  fontSize: 20,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _ExpenseDetailScreenState.formatCurrency(item.amountMinor),
                style: AppTypography.bodySoft,
              ),
            ],
          ),
        ),
        SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CircularProgressIndicator(
                value: 1,
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation<Color>(ringColor),
              ),
              CircularProgressIndicator(
                value: (item.percent / 100).clamp(0.0, 1.0),
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                backgroundColor: Colors.transparent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyExpenseChartCard extends StatelessWidget {
  const _DailyExpenseChartCard({required this.viewModel});

  final ExpenseDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        HiFiSectionHeader.title(left: context.strings.expensesByDay),
        const SizedBox(height: AppSpacing.sm),
        HiFiCard.compact(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _ExpenseChartLegend(),
              const SizedBox(height: AppSpacing.md),
              if (viewModel.hasDisabledChartState)
                const _ChartEmptyState()
              else
                _ExpenseBarChart(series: viewModel.chartSeries),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpenseChartLegend extends StatelessWidget {
  const _ExpenseChartLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _LegendDot(color: AppColors.expense),
        const SizedBox(width: 7),
        Text(context.strings.totalExpensesLegend),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ExpenseBarChart extends StatefulWidget {
  const _ExpenseBarChart({required this.series});

  final List<ExpenseDetailChartPoint> series;

  @override
  State<_ExpenseBarChart> createState() => _ExpenseBarChartState();
}

class _ExpenseBarChartState extends State<_ExpenseBarChart> {
  static const double _axisLabelWidth = 48;

  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final List<ExpenseDetailChartPoint> series = widget.series;
    final double maxTotalPounds = series.fold<double>(
      0,
      (double maxValue, ExpenseDetailChartPoint point) =>
          math.max(maxValue, point.totalMinor / 100),
    );
    final double maxY = _niceAxisMax(maxTotalPounds);
    final List<double> tickValues = <double>[
      for (int i = 4; i >= 0; i--) (maxY / 4) * i,
    ];
    final int labelStep = _labelStep(series.length);
    final int selectedIndex = _selectedIndex ?? _defaultSelectedIndex(series);
    final ExpenseDetailChartPoint selectedPoint = series[selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ExpenseChartTooltip(
          point: selectedPoint,
          maxIndex: series.length - 1,
          index: selectedIndex,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 228,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: _axisLabelWidth,
                child: Column(
                  children: <Widget>[
                    for (final double tick in tickValues)
                      Expanded(
                        child: Align(
                          alignment: tick == 0
                              ? Alignment.bottomRight
                              : Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _AxisTickLabel(
                              label: _formatTickLabel(tick),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Column(
                        children: <Widget>[
                          for (int i = 0; i < tickValues.length; i++)
                            Expanded(
                              child: Align(
                                alignment: i == tickValues.length - 1
                                    ? Alignment.bottomCenter
                                    : Alignment.topCenter,
                                child: Container(
                                  height: 1,
                                  color: AppColors.borderSoft,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          for (int i = 0; i < series.length; i++)
                            Expanded(
                              child: _ExpenseBarColumn(
                                point: series[i],
                                maxY: maxY,
                                showLabel:
                                    i % labelStep == 0 ||
                                    i == series.length - 1,
                                label: series.length <= 7
                                    ? context.strings.weekdayShort(
                                        series[i].date,
                                      )
                                    : '${series[i].date.day}',
                                isSelected: i == selectedIndex,
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = i;
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _defaultSelectedIndex(List<ExpenseDetailChartPoint> series) {
    final int firstNonZero = series.indexWhere(
      (ExpenseDetailChartPoint point) => point.totalMinor > 0,
    );
    return firstNonZero == -1 ? 0 : firstNonZero;
  }

  int _labelStep(int pointCount) {
    if (pointCount <= 7) return 1;
    if (pointCount <= 14) return 2;
    if (pointCount <= 31) return 5;
    if (pointCount <= 62) return 10;
    return math.max(1, (pointCount / 6).ceil());
  }

  double _niceAxisMax(double rawMax) {
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

  String _formatTickLabel(double tick) {
    final int rounded = tick.round();
    if (rounded >= 1000) {
      final double thousands = rounded / 1000;
      final String compact = thousands % 1 == 0
          ? thousands.toStringAsFixed(0)
          : thousands.toStringAsFixed(1);
      return '£${compact.replaceAll('.0', '')}k';
    }
    return '£$rounded';
  }
}

class _AxisTickLabel extends StatelessWidget {
  const _AxisTickLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          textAlign: TextAlign.right,
          style: AppTypography.meta,
        ),
      ),
    );
  }
}

class _ExpenseChartTooltip extends StatelessWidget {
  const _ExpenseChartTooltip({
    required this.point,
    required this.maxIndex,
    required this.index,
  });

  final ExpenseDetailChartPoint point;
  final int maxIndex;
  final int index;

  @override
  Widget build(BuildContext context) {
    final double alignmentX = maxIndex <= 0
        ? 0
        : ((index / maxIndex) * 2 - 1).clamp(-0.85, 0.85);
    final List<String> splitLines = <String>[
      if (point.cashMinor > 0)
        context.strings.cashAmount(
          _ExpenseDetailScreenState.formatCurrency(point.cashMinor),
        ),
      if (point.cardMinor > 0)
        context.strings.cardAmount(
          _ExpenseDetailScreenState.formatCurrency(point.cardMinor),
        ),
      if (point.otherMinor > 0)
        '${context.strings.paymentMethodLabel(PaymentMethodType.other)}  ${_ExpenseDetailScreenState.formatCurrency(point.otherMinor)}',
    ];

    return Align(
      alignment: Alignment(alignmentX, 0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 184),
        child: HiFiCard.compact(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.strings.weekdayShortDate(point.date),
                style: AppTypography.meta.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${context.strings.totalExpenses}  ${_ExpenseDetailScreenState.formatCurrency(point.totalMinor)}',
                style: AppTypography.body.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (final String line in splitLines) ...<Widget>[
                const SizedBox(height: 4),
                Text(line, style: AppTypography.bodySoft),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseBarColumn extends StatelessWidget {
  const _ExpenseBarColumn({
    required this.point,
    required this.maxY,
    required this.showLabel,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final ExpenseDetailChartPoint point;
  final double maxY;
  final bool showLabel;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double totalPounds = point.totalMinor / 100;
    final double totalFactor = maxY == 0
        ? 0
        : (totalPounds / maxY).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: totalFactor,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 22),
                      decoration: BoxDecoration(
                        color: AppColors.expense,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandStrong
                              : Colors.transparent,
                        ),
                        boxShadow: isSelected
                            ? const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x1AC2492A),
                                  offset: Offset(0, 3),
                                  blurRadius: 10,
                                ),
                              ]
                            : const <BoxShadow>[],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 16,
                child: Center(
                  child: showLabel
                      ? Text(label, style: AppTypography.meta)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBreakdownSection extends StatelessWidget {
  const _CategoryBreakdownSection({required this.viewModel});

  final ExpenseDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.strings.categoryBreakdown,
          style: AppTypography.h2.copyWith(fontSize: 19),
        ),
        const SizedBox(height: AppSpacing.sm),
        HiFiCard.compact(
          child: viewModel.categoryBreakdownRows.isEmpty
              ? const _CategoryEmptyState()
              : Column(
                  children: <Widget>[
                    for (
                      int i = 0;
                      i < viewModel.categoryBreakdownRows.length;
                      i++
                    ) ...<Widget>[
                      _CategoryBreakdownRow(
                        row: viewModel.categoryBreakdownRows[i],
                      ),
                      if (i != viewModel.categoryBreakdownRows.length - 1)
                        const Divider(color: AppColors.borderSoft, height: 20),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _CategoryBreakdownRow extends StatelessWidget {
  const _CategoryBreakdownRow({required this.row});

  final ExpenseCategoryBreakdownRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                row.categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.ttl,
              ),
              const SizedBox(height: 5),
              Text(
                '${context.strings.ofTotal(row.sharePercent.round())} · ${context.strings.entriesCount(row.transactionCount)}',
                style: AppTypography.bodySoft,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          _ExpenseDetailScreenState.formatCurrency(row.totalMinor),
          style: AppTypography.numSm.copyWith(color: AppColors.expense),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}

class _CategoryEmptyState extends StatelessWidget {
  const _CategoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.strings.noExpenseCategoriesRange, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.strings.categoriesAppearInRange,
          style: AppTypography.bodySoft,
        ),
      ],
    );
  }
}

class _DailyBreakdownSection extends StatelessWidget {
  const _DailyBreakdownSection({required this.viewModel});

  final ExpenseDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.strings.dailyBreakdown,
          style: AppTypography.h2.copyWith(fontSize: 19),
        ),
        const SizedBox(height: AppSpacing.sm),
        HiFiCard.compact(
          child: Column(
            children: <Widget>[
              for (
                int i = 0;
                i < viewModel.dailyBreakdownRows.length;
                i++
              ) ...<Widget>[
                _DailyBreakdownRow(row: viewModel.dailyBreakdownRows[i]),
                if (i != viewModel.dailyBreakdownRows.length - 1)
                  const Divider(color: AppColors.borderSoft, height: 20),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyBreakdownRow extends StatelessWidget {
  const _DailyBreakdownRow({required this.row});

  final ExpenseDailyBreakdownRow row;

  @override
  Widget build(BuildContext context) {
    final List<String> parts = <String>[
      if (row.cashMinor > 0)
        context.strings.cashAmount(
          _ExpenseDetailScreenState.formatCurrency(row.cashMinor),
        ),
      if (row.cardMinor > 0)
        context.strings.cardAmount(
          _ExpenseDetailScreenState.formatCurrency(row.cardMinor),
        ),
      if (row.otherMinor > 0)
        '${context.strings.paymentMethodLabel(PaymentMethodType.other)} ${_ExpenseDetailScreenState.formatCurrency(row.otherMinor)}',
    ];
    final String summary = row.totalMinor == 0
        ? context.strings.noExpenses
        : parts.join('  ·  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.strings.weekdayShortDate(row.date),
                style: AppTypography.ttl,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _ExpenseDetailScreenState.formatCurrency(row.totalMinor),
              style: AppTypography.numSm.copyWith(color: AppColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(summary, style: AppTypography.bodySoft),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      variant: HiFiCardVariant.surface,
      border: Border.all(color: AppColors.amberSoft),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const HiFiIconTile(
            icon: Icons.priority_high_rounded,
            tone: HiFiIconTileTone.amber,
            shape: HiFiIconTileShape.circle,
            size: HiFiIconTileSize.small,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.strings.spendingPressure,
                  style: AppTypography.lbl,
                ),
                const SizedBox(height: 4),
                Text(message, style: AppTypography.bodySoft),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.viewModel});

  final ExpenseDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return HiFiCard(
      variant: HiFiCardVariant.mint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: _InsightCell(insight: viewModel.highestSpendDayInsight),
          ),
          const _InsightDivider(),
          Expanded(
            child: _InsightCell(insight: viewModel.averagePerDayInsight),
          ),
          const _InsightDivider(),
          Expanded(child: _InsightCell(insight: viewModel.topCategoryInsight)),
        ],
      ),
    );
  }
}

class _InsightCell extends StatelessWidget {
  const _InsightCell({required this.insight});

  final ExpenseDetailInsight insight;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = insight.isEmpty
        ? AppColors.inkSoft
        : AppColors.expenseInk;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(insight.title, style: AppTypography.lbl),
        const SizedBox(height: 10),
        Text(
          insight.primary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.h2.copyWith(fontSize: 18, color: primaryColor),
        ),
        const SizedBox(height: 4),
        Text(insight.secondary, style: AppTypography.bodySoft),
      ],
    );
  }
}

class _InsightDivider extends StatelessWidget {
  const _InsightDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: AppColors.cardMintBorder,
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 228,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.base),
        color: AppColors.surface2.withValues(alpha: 0.55),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const HiFiIconTile(
                icon: Icons.bar_chart_rounded,
                tone: HiFiIconTileTone.amber,
                shape: HiFiIconTileShape.circle,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.strings.noExpenseRecordsInRange,
                style: AppTypography.h2,
              ),
              const SizedBox(height: 6),
              Text(
                context.strings.expenseChartEmpty,
                style: AppTypography.bodySoft,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(context.strings.expenseDetailLoadError, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.strings.checkConnectionAndTryAgain,
            style: AppTypography.bodySoft,
          ),
        ],
      ),
    );
  }
}
