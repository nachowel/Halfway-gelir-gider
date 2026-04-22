import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_filter_chip.dart';
import '../../../shared/hi_fi/hi_fi_icon_tile.dart';
import '../../../shared/hi_fi/hi_fi_screen_background.dart';
import '../../../shared/hi_fi/hi_fi_section_header.dart';
import '../../../shared/layout/mobile_scaffold.dart';
import '../domain/net_profit_detail_models.dart';
import '../domain/net_profit_detail_service.dart';

class NetProfitDetailScreen extends ConsumerStatefulWidget {
  const NetProfitDetailScreen({super.key});

  @override
  ConsumerState<NetProfitDetailScreen> createState() =>
      _NetProfitDetailScreenState();
}

class _NetProfitDetailScreenState extends ConsumerState<NetProfitDetailScreen> {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_GB',
    symbol: '£',
    decimalDigits: 2,
  );

  final NetProfitDetailService _service = NetProfitDetailService();
  NetProfitDetailQuery _query = const NetProfitDetailQuery.thisWeek();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final DateTime today = DateTime.now();
    final NetProfitDetailRange previewRange = _service.resolveRange(
      today: today,
      query: _query,
      strings: strings,
    );
    final AsyncValue<NetProfitDetailViewModel> viewModelAsync = ref.watch(
      netProfitDetailProvider(_query),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: MobileScaffold(
        child: HiFiScreenBackground(
          tone: HiFiScreenTone.warm,
          child: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenSide,
                      AppSpacing.sm,
                      AppSpacing.screenSide,
                      AppSpacing.lg,
                    ),
                    children: <Widget>[
                      _NetProfitHeader(
                        onBack: () async {
                          final bool didPop = await Navigator.of(
                            context,
                          ).maybePop();
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
                        data: (NetProfitDetailViewModel viewModel) {
                          return _NetProfitDetailContent(viewModel: viewModel);
                        },
                      ),
                    ],
                  ),
                ),
                viewModelAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (NetProfitDetailViewModel viewModel) {
                    return SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenSide,
                          0,
                          AppSpacing.screenSide,
                          AppSpacing.sm,
                        ),
                        child: _InsightsCard(viewModel: viewModel),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePresetSelected(NetProfitDetailRangePreset preset) async {
    if (preset == NetProfitDetailRangePreset.custom) {
      final DateTime now = DateTime.now();
      final NetProfitDetailRange currentRange = _service.resolveRange(
        today: now,
        query: _query,
        strings: context.strings,
      );
      final DateTimeRange? selection = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 3, 1, 1),
        lastDate: DateTime(now.year + 3, 12, 31),
        initialDateRange: currentRange.asDateTimeRange,
        helpText: context.strings.selectNetProfitRange,
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
        _query = NetProfitDetailQuery.custom(
          start: selection.start,
          end: selection.end,
        );
      });
      return;
    }

    setState(() {
      _query = switch (preset) {
        NetProfitDetailRangePreset.thisWeek =>
          const NetProfitDetailQuery.thisWeek(),
        NetProfitDetailRangePreset.lastWeek =>
          const NetProfitDetailQuery.lastWeek(),
        NetProfitDetailRangePreset.thisMonth =>
          const NetProfitDetailQuery.thisMonth(),
        NetProfitDetailRangePreset.lastMonth =>
          const NetProfitDetailQuery.lastMonth(),
        NetProfitDetailRangePreset.custom => _query,
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
          title: Text(context.strings.netProfitDetail, style: AppTypography.h2),
          content: Text(
            context.strings.netProfitDetailInfo,
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

class _NetProfitDetailContent extends StatelessWidget {
  const _NetProfitDetailContent({required this.viewModel});

  final NetProfitDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _KpiRow(viewModel: viewModel),
        const SizedBox(height: AppSpacing.md),
        _ProfitHealthCard(viewModel: viewModel),
        const SizedBox(height: AppSpacing.md),
        _ComparisonCard(viewModel: viewModel),
        if (viewModel.showExpensePressureWarning &&
            viewModel.expensePressureMessage != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _PressureCard(message: viewModel.expensePressureMessage!),
        ],
        const SizedBox(height: AppSpacing.lg),
        _DailyProfitChartCard(viewModel: viewModel),
        const SizedBox(height: AppSpacing.lg),
        _BreakdownSection(viewModel: viewModel),
      ],
    );
  }
}

class _NetProfitHeader extends StatelessWidget {
  const _NetProfitHeader({required this.onBack, required this.onInfoTap});

  final VoidCallback onBack;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Row(
      children: <Widget>[
        InkWell(
          key: const ValueKey<String>('net-profit-detail-back-button'),
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
            strings.netProfit,
            style: AppTypography.h1.copyWith(fontSize: 24),
          ),
        ),
        InkWell(
          key: const ValueKey<String>('net-profit-detail-info-button'),
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

  final NetProfitDetailRangePreset selectedPreset;
  final String rangeLabel;
  final ValueChanged<NetProfitDetailRangePreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (final NetProfitDetailRangePreset preset
                in NetProfitDetailRangePreset.values)
              HiFiFilterChip(
                label: context.strings.netProfitRangePresetLabel(preset),
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

  final NetProfitDetailViewModel viewModel;

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

  final NetProfitKpi kpi;
  final int index;

  Color get _valueColor => switch (index) {
    0 => kpi.primary.startsWith('-') ? AppColors.expense : AppColors.income,
    1 => AppColors.income,
    _ => AppColors.expense,
  };

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(kpi.title, style: AppTypography.lbl),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              kpi.primary,
              style: AppTypography.numLg.copyWith(
                color: _valueColor,
                fontSize: 26,
              ),
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

class _ProfitHealthCard extends StatelessWidget {
  const _ProfitHealthCard({required this.viewModel});

  final NetProfitDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final Color labelColor = viewModel.health.marginPercent < 10
        ? AppColors.expense
        : viewModel.health.marginPercent <= 25
        ? AppColors.amberInk
        : AppColors.income;

    return HiFiCard.compact(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(context.strings.profitHealth, style: AppTypography.h2),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.strings.marginPercentLabel(
                    viewModel.marginPercent.round(),
                  ),
                  style: AppTypography.numMd.copyWith(color: labelColor),
                ),
                const SizedBox(height: 4),
                Text(
                  viewModel.health.description,
                  style: AppTypography.bodySoft,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Text(
              viewModel.health.label,
              style: AppTypography.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.viewModel});

  final NetProfitDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final double income = viewModel.comparison.incomeMinor.toDouble();
    final double expense = viewModel.comparison.expenseMinor.toDouble();
    final double maxValue = math.max(income, expense);
    final double incomeFactor = maxValue == 0 ? 0 : income / maxValue;
    final double expenseFactor = maxValue == 0 ? 0 : expense / maxValue;

    return HiFiCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(context.strings.incomeVsExpenses, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(viewModel.comparison.message, style: AppTypography.bodySoft),
          const SizedBox(height: AppSpacing.md),
          _ComparisonRow(
            label: context.strings.income,
            amountLabel: _NetProfitDetailScreenState.formatCurrency(
              viewModel.comparison.incomeMinor,
            ),
            factor: incomeFactor,
            color: AppColors.income,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ComparisonRow(
            label: context.strings.expenses,
            amountLabel: _NetProfitDetailScreenState.formatCurrency(
              viewModel.comparison.expenseMinor,
            ),
            factor: expenseFactor,
            color: AppColors.expense,
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.amountLabel,
    required this.factor,
    required this.color,
  });

  final String label;
  final String amountLabel;
  final double factor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 66, child: Text(label, style: AppTypography.ttl)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 12,
              color: AppColors.surface2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: factor.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: color),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 74,
          child: Text(
            amountLabel,
            style: AppTypography.bodySoft.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _PressureCard extends StatelessWidget {
  const _PressureCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
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
                Text(context.strings.expensePressure, style: AppTypography.lbl),
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

class _DailyProfitChartCard extends StatelessWidget {
  const _DailyProfitChartCard({required this.viewModel});

  final NetProfitDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        HiFiSectionHeader.title(left: context.strings.profitByDay),
        const SizedBox(height: AppSpacing.sm),
        HiFiCard.compact(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _ProfitChartLegend(),
              const SizedBox(height: AppSpacing.md),
              if (viewModel.hasDisabledChartState)
                const _ChartEmptyState()
              else
                _NetProfitBarChart(series: viewModel.dailyProfitSeries),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfitChartLegend extends StatelessWidget {
  const _ProfitChartLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        _LegendItem(label: context.strings.profit, color: AppColors.income),
        _LegendItem(label: context.strings.loss, color: AppColors.expense),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(label, style: AppTypography.bodySoft),
      ],
    );
  }
}

class _NetProfitBarChart extends StatefulWidget {
  const _NetProfitBarChart({required this.series});

  final List<NetProfitChartPoint> series;

  @override
  State<_NetProfitBarChart> createState() => _NetProfitBarChartState();
}

class _NetProfitBarChartState extends State<_NetProfitBarChart> {
  static const double _axisLabelWidth = 52;

  final NetProfitDetailService _service = NetProfitDetailService();
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final List<NetProfitChartPoint> series = widget.series;
    final double maxMagnitudePounds = series.fold<double>(0, (
      double maxValue,
      NetProfitChartPoint point,
    ) {
      return math.max(maxValue, point.profitMinor.abs() / 100);
    });
    final double maxY = _service.niceAxisMax(maxMagnitudePounds);
    final List<double> tickValues = <double>[
      maxY,
      maxY / 2,
      0,
      -maxY / 2,
      -maxY,
    ];
    final int labelStep = _labelStep(series.length);
    final int selectedIndex = _selectedIndex ?? _defaultSelectedIndex(series);
    final NetProfitChartPoint selectedPoint = series[selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ProfitChartTooltip(
          point: selectedPoint,
          maxIndex: series.length - 1,
          index: selectedIndex,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 252,
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
                              ? Alignment.centerRight
                              : tick.isNegative
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
                                alignment: i == 2
                                    ? Alignment.center
                                    : i < 2
                                    ? Alignment.topCenter
                                    : Alignment.bottomCenter,
                                child: Container(
                                  height: i == 2 ? 1.4 : 1,
                                  color: i == 2
                                      ? AppColors.border
                                      : AppColors.borderSoft,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          for (int i = 0; i < series.length; i++)
                            Expanded(
                              child: _ProfitBarColumn(
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

  int _defaultSelectedIndex(List<NetProfitChartPoint> series) {
    final int firstNonZero = series.indexWhere(
      (NetProfitChartPoint point) =>
          point.incomeMinor != 0 || point.expenseMinor != 0,
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

  String _formatTickLabel(double value) {
    final int rounded = value.round();
    final String prefix = rounded < 0 ? '-£' : '£';
    final int absValue = rounded.abs();
    if (absValue >= 1000) {
      final double thousands = absValue / 1000;
      final String compact = thousands % 1 == 0
          ? thousands.toStringAsFixed(0)
          : thousands.toStringAsFixed(1);
      return '$prefix${compact.replaceAll('.0', '')}k';
    }
    return '$prefix$absValue';
  }
}

class _ProfitChartTooltip extends StatelessWidget {
  const _ProfitChartTooltip({
    required this.point,
    required this.maxIndex,
    required this.index,
  });

  final NetProfitChartPoint point;
  final int maxIndex;
  final int index;

  @override
  Widget build(BuildContext context) {
    final double alignmentX = maxIndex <= 0
        ? 0
        : ((index / maxIndex) * 2 - 1).clamp(-0.85, 0.85);

    return Align(
      alignment: Alignment(alignmentX, 0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 188),
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
                '${context.strings.income}  ${_NetProfitDetailScreenState.formatCurrency(point.incomeMinor)}',
                style: AppTypography.bodySoft.copyWith(color: AppColors.income),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.strings.expenses} ${_NetProfitDetailScreenState.formatCurrency(point.expenseMinor)}',
                style: AppTypography.bodySoft.copyWith(
                  color: AppColors.expense,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.strings.profit}   ${_NetProfitDetailScreenState.formatCurrency(point.profitMinor)}',
                style: AppTypography.body.copyWith(
                  color: point.profitMinor < 0
                      ? AppColors.expense
                      : AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfitBarColumn extends StatelessWidget {
  const _ProfitBarColumn({
    required this.point,
    required this.maxY,
    required this.showLabel,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final NetProfitChartPoint point;
  final double maxY;
  final bool showLabel;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double magnitudeFactor = maxY == 0
        ? 0
        : ((point.profitMinor.abs() / 100) / maxY).clamp(0.0, 1.0);
    final bool positive = point.profitMinor >= 0;

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
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: positive
                            ? FractionallySizedBox(
                                heightFactor: magnitudeFactor,
                                child: _ProfitBar(
                                  positive: true,
                                  isSelected: isSelected,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: positive
                            ? const SizedBox.shrink()
                            : FractionallySizedBox(
                                heightFactor: magnitudeFactor,
                                child: _ProfitBar(
                                  positive: false,
                                  isSelected: isSelected,
                                ),
                              ),
                      ),
                    ),
                  ],
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

class _ProfitBar extends StatelessWidget {
  const _ProfitBar({required this.positive, required this.isSelected});

  final bool positive;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 22),
      decoration: BoxDecoration(
        color: positive ? AppColors.income : AppColors.expense,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? AppColors.brandStrong : Colors.transparent,
        ),
        boxShadow: isSelected
            ? <BoxShadow>[
                BoxShadow(
                  color: (positive ? AppColors.income : AppColors.expense)
                      .withValues(alpha: 0.18),
                  offset: const Offset(0, 3),
                  blurRadius: 10,
                ),
              ]
            : const <BoxShadow>[],
      ),
    );
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

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({required this.viewModel});

  final NetProfitDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        HiFiSectionHeader.title(left: context.strings.dailyBreakdown),
        const SizedBox(height: AppSpacing.sm),
        HiFiCard.compact(
          child: Column(
            children: <Widget>[
              for (
                int i = 0;
                i < viewModel.breakdownRows.length;
                i++
              ) ...<Widget>[
                _BreakdownRow(row: viewModel.breakdownRows[i]),
                if (i != viewModel.breakdownRows.length - 1)
                  const Divider(color: AppColors.borderSoft, height: 20),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.row});

  final NetProfitBreakdownRow row;

  @override
  Widget build(BuildContext context) {
    final bool negative = row.profitMinor < 0;
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
              _NetProfitDetailScreenState.formatCurrency(row.profitMinor),
              style: AppTypography.numSm.copyWith(
                color: negative ? AppColors.expense : AppColors.incomeInk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${context.strings.income} ${_NetProfitDetailScreenState.formatCurrency(row.incomeMinor)}'
          '  ·  ${context.strings.expenses} ${_NetProfitDetailScreenState.formatCurrency(row.expenseMinor)}',
          style: AppTypography.bodySoft,
        ),
      ],
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.viewModel});

  final NetProfitDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return HiFiCard(
      variant: HiFiCardVariant.mint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: _InsightCell(insight: viewModel.bestDayInsight)),
          const _InsightDivider(),
          Expanded(child: _InsightCell(insight: viewModel.worstDayInsight)),
          const _InsightDivider(),
          Expanded(
            child: _InsightCell(insight: viewModel.averageDailyProfitInsight),
          ),
        ],
      ),
    );
  }
}

class _InsightCell extends StatelessWidget {
  const _InsightCell({required this.insight});

  final NetProfitInsight insight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(insight.title, style: AppTypography.lbl),
        const SizedBox(height: 10),
        Text(
          insight.primary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.h2.copyWith(
            fontSize: 18,
            color: insight.isEmpty ? AppColors.inkSoft : AppColors.ink,
          ),
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
                icon: Icons.show_chart_rounded,
                tone: HiFiIconTileTone.mint,
                shape: HiFiIconTileShape.circle,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.strings.noProfitRecordsInRange,
                style: AppTypography.h2,
              ),
              const SizedBox(height: 6),
              Text(
                context.strings.profitChartEmpty,
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
          Text(
            context.strings.netProfitDetailLoadError,
            style: AppTypography.h2,
          ),
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
