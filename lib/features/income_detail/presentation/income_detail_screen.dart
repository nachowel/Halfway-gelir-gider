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
import '../domain/income_detail_models.dart';
import '../domain/income_detail_service.dart';

class IncomeDetailScreen extends ConsumerStatefulWidget {
  const IncomeDetailScreen({super.key});

  @override
  ConsumerState<IncomeDetailScreen> createState() => _IncomeDetailScreenState();
}

class _IncomeDetailScreenState extends ConsumerState<IncomeDetailScreen> {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_GB',
    symbol: '£',
    decimalDigits: 2,
  );
  final IncomeDetailService _service = IncomeDetailService();
  IncomeDetailQuery _query = const IncomeDetailQuery.thisWeek();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final DateTime today = DateTime.now();
    final IncomeDetailRange previewRange = _service.resolveRange(
      today: today,
      query: _query,
      strings: strings,
    );
    final AsyncValue<IncomeDetailViewModel> viewModelAsync = ref.watch(
      incomeDetailProvider(_query),
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
                _IncomeHeader(
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
                  data: (IncomeDetailViewModel viewModel) {
                    return _IncomeDetailContent(viewModel: viewModel);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePresetSelected(IncomeDetailRangePreset preset) async {
    if (preset == IncomeDetailRangePreset.custom) {
      final DateTime now = DateTime.now();
      final IncomeDetailRange currentRange = _service.resolveRange(
        today: now,
        query: _query,
        strings: context.strings,
      );
      final DateTimeRange? selection = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 3, 1, 1),
        lastDate: DateTime(now.year + 3, 12, 31),
        initialDateRange: currentRange.asDateTimeRange,
        helpText: context.strings.selectIncomeRange,
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
        _query = IncomeDetailQuery.custom(
          start: selection.start,
          end: selection.end,
        );
      });
      return;
    }

    setState(() {
      _query = switch (preset) {
        IncomeDetailRangePreset.thisWeek => const IncomeDetailQuery.thisWeek(),
        IncomeDetailRangePreset.lastWeek => const IncomeDetailQuery.lastWeek(),
        IncomeDetailRangePreset.thisMonth =>
          const IncomeDetailQuery.thisMonth(),
        IncomeDetailRangePreset.lastMonth =>
          const IncomeDetailQuery.lastMonth(),
        IncomeDetailRangePreset.custom => _query,
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
          title: Text(context.strings.incomeDetail, style: AppTypography.h2),
          content: Text(
            context.strings.incomeDetailInfo,
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

class _IncomeDetailContent extends StatelessWidget {
  const _IncomeDetailContent({required this.viewModel});

  final IncomeDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _KpiRow(viewModel: viewModel),
        const SizedBox(height: AppSpacing.md),
        _PaymentSplitCard(viewModel: viewModel),
        const SizedBox(height: AppSpacing.lg),
        _DailyIncomeChartCard(viewModel: viewModel),
        const SizedBox(height: AppSpacing.lg),
        _BreakdownSection(viewModel: viewModel),
        const SizedBox(height: AppSpacing.lg),
        _InsightsCard(viewModel: viewModel),
      ],
    );
  }
}

class _IncomeHeader extends StatelessWidget {
  const _IncomeHeader({required this.onBack, required this.onInfoTap});

  final VoidCallback onBack;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Row(
      children: <Widget>[
        InkWell(
          key: const ValueKey<String>('income-detail-back-button'),
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
            strings.income,
            style: AppTypography.h1.copyWith(fontSize: 24),
          ),
        ),
        InkWell(
          key: const ValueKey<String>('income-detail-info-button'),
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

  final IncomeDetailRangePreset selectedPreset;
  final String rangeLabel;
  final ValueChanged<IncomeDetailRangePreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (final IncomeDetailRangePreset preset
                in IncomeDetailRangePreset.values)
              HiFiFilterChip(
                label: context.strings.incomeRangePresetLabel(preset),
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

  final IncomeDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _MetricCard(
            title: context.strings.totalIncome,
            value: _IncomeDetailScreenState.formatCurrency(
              viewModel.totalIncomeMinor,
            ),
            color: AppColors.income,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _MetricCard(
            title: context.strings.cash,
            value: _IncomeDetailScreenState.formatCurrency(
              viewModel.cashIncomeMinor,
            ),
            color: AppColors.income,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _MetricCard(
            title: context.strings.card,
            value: _IncomeDetailScreenState.formatCurrency(
              viewModel.cardIncomeMinor,
            ),
            color: AppColors.cardIncome,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppTypography.lbl),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.numLg.copyWith(color: color, fontSize: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSplitCard extends StatelessWidget {
  const _PaymentSplitCard({required this.viewModel});

  final IncomeDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SplitMetric(
              title: context.strings.cashShare,
              percent: viewModel.cashSharePercent,
              progressColor: AppColors.income,
              progressSoftColor: AppColors.incomeSoft,
              isDisabled: viewModel.totalIncomeMinor == 0,
            ),
          ),
          Container(
            width: 1,
            height: 74,
            color: AppColors.borderSoft,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          Expanded(
            child: _SplitMetric(
              title: context.strings.cardShare,
              percent: viewModel.cardSharePercent,
              progressColor: AppColors.cardIncome,
              progressSoftColor: AppColors.cardIncomeSoft,
              isDisabled: viewModel.totalIncomeMinor == 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitMetric extends StatelessWidget {
  const _SplitMetric({
    required this.title,
    required this.percent,
    required this.progressColor,
    required this.progressSoftColor,
    required this.isDisabled,
  });

  final String title;
  final double percent;
  final Color progressColor;
  final Color progressSoftColor;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final Color ringColor = isDisabled ? AppColors.border : progressSoftColor;
    final Color activeColor = isDisabled ? AppColors.inkFade : progressColor;
    final Color textColor = isDisabled ? AppColors.inkSoft : AppColors.ink;
    final double clamped = (percent / 100).clamp(0.0, 1.0);

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: AppTypography.ttl),
              const SizedBox(height: 6),
              Text(
                '${percent.round()}%',
                style: AppTypography.h1.copyWith(
                  fontSize: 20,
                  color: textColor,
                ),
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
                value: clamped,
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

class _DailyIncomeChartCard extends StatelessWidget {
  const _DailyIncomeChartCard({required this.viewModel});

  final IncomeDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        HiFiSectionHeader.title(left: context.strings.incomeByDay),
        const SizedBox(height: AppSpacing.sm),
        HiFiCard.compact(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _ChartLegend(),
              const SizedBox(height: AppSpacing.md),
              if (viewModel.hasDisabledChartState)
                const _ChartEmptyState()
              else
                _IncomeStackedBarChart(series: viewModel.chartSeries),
            ],
          ),
        ),
      ],
    );
  }
}

class _IncomeStackedBarChart extends StatefulWidget {
  const _IncomeStackedBarChart({required this.series});

  final List<IncomeDetailChartPoint> series;

  @override
  State<_IncomeStackedBarChart> createState() => _IncomeStackedBarChartState();
}

class _IncomeStackedBarChartState extends State<_IncomeStackedBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final List<IncomeDetailChartPoint> series = widget.series;
    final double maxTotalPounds = series.fold<double>(
      0,
      (double maxValue, IncomeDetailChartPoint point) =>
          math.max(maxValue, point.totalMinor / 100),
    );
    final double maxY = _niceAxisMax(maxTotalPounds);
    final List<double> tickValues = <double>[
      for (int i = 4; i >= 0; i--) (maxY / 4) * i,
    ];
    final int labelStep = _labelStep(series.length);
    final int selectedIndex = _selectedIndex ?? _defaultSelectedIndex(series);
    final IncomeDetailChartPoint selectedPoint = series[selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ChartTooltip(
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
                width: 34,
                child: Column(
                  children: <Widget>[
                    for (final double tick in tickValues)
                      Expanded(
                        child: Align(
                          alignment: tick == 0
                              ? Alignment.bottomRight
                              : Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              '£${tick.toStringAsFixed(0)}',
                              style: AppTypography.meta,
                              textAlign: TextAlign.right,
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
                              child: _ChartBarColumn(
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

  int _defaultSelectedIndex(List<IncomeDetailChartPoint> series) {
    final int firstNonZero = series.indexWhere(
      (IncomeDetailChartPoint point) => point.totalMinor > 0,
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
}

class _ChartTooltip extends StatelessWidget {
  const _ChartTooltip({
    required this.point,
    required this.maxIndex,
    required this.index,
  });

  final IncomeDetailChartPoint point;
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
        constraints: const BoxConstraints(maxWidth: 176),
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
                context.strings.cashAmount(
                  _IncomeDetailScreenState.formatCurrency(point.cashMinor),
                ),
                style: AppTypography.bodySoft.copyWith(color: AppColors.income),
              ),
              const SizedBox(height: 4),
              Text(
                context.strings.cardAmount(
                  _IncomeDetailScreenState.formatCurrency(point.cardMinor),
                ),
                style: AppTypography.bodySoft.copyWith(
                  color: AppColors.cardIncome,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.strings.totalIncome}  ${_IncomeDetailScreenState.formatCurrency(point.totalMinor)}',
                style: AppTypography.body.copyWith(
                  color: AppColors.ink,
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

class _ChartBarColumn extends StatelessWidget {
  const _ChartBarColumn({
    required this.point,
    required this.maxY,
    required this.showLabel,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IncomeDetailChartPoint point;
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
    final double cashFactor = maxY == 0
        ? 0
        : ((point.cashMinor / 100) / maxY).clamp(0.0, 1.0);
    final double cardFactor = maxY == 0
        ? 0
        : ((point.cardMinor / 100) / maxY).clamp(0.0, 1.0);

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
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandStrong
                              : Colors.transparent,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: cashFactor == 0
                                    ? 0
                                    : (cashFactor / totalFactor).clamp(
                                        0.0,
                                        1.0,
                                      ),
                                child: Container(color: AppColors.income),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topCenter,
                              child: FractionallySizedBox(
                                heightFactor: cardFactor == 0
                                    ? 0
                                    : (cardFactor / totalFactor).clamp(
                                        0.0,
                                        1.0,
                                      ),
                                child: Container(color: AppColors.cardIncome),
                              ),
                            ),
                          ],
                        ),
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

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        _LegendItem(label: context.strings.cash, color: AppColors.income),
        _LegendItem(label: context.strings.card, color: AppColors.cardIncome),
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
                tone: HiFiIconTileTone.mint,
                shape: HiFiIconTileShape.circle,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.strings.noIncomeRecordsInRange,
                style: AppTypography.h2,
              ),
              const SizedBox(height: 6),
              Text(
                context.strings.incomeChartEmpty,
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

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({required this.viewModel});

  final IncomeDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        HiFiSectionHeader.title(left: context.strings.breakdown),
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

  final IncomeDetailBreakdownRow row;

  @override
  Widget build(BuildContext context) {
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
              _IncomeDetailScreenState.formatCurrency(row.totalMinor),
              style: AppTypography.numSm.copyWith(color: AppColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${context.strings.cashAmount(_IncomeDetailScreenState.formatCurrency(row.cashMinor))}'
          '  ·  ${context.strings.cardAmount(_IncomeDetailScreenState.formatCurrency(row.cardMinor))}',
          style: AppTypography.bodySoft,
        ),
      ],
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.viewModel});

  final IncomeDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return HiFiCard(
      variant: HiFiCardVariant.mint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: _InsightCell(insight: viewModel.highestDayInsight)),
          const _InsightDivider(),
          Expanded(
            child: _InsightCell(insight: viewModel.averagePerDayInsight),
          ),
          const _InsightDivider(),
          Expanded(
            child: _InsightCell(insight: viewModel.bestPaymentMixInsight),
          ),
        ],
      ),
    );
  }
}

class _InsightCell extends StatelessWidget {
  const _InsightCell({required this.insight});

  final IncomeDetailInsight insight;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = insight.isEmpty
        ? AppColors.inkSoft
        : AppColors.incomeInk;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(insight.title, style: AppTypography.lbl),
        const SizedBox(height: 10),
        Text(
          insight.primary,
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
          Text(context.strings.incomeDetailLoadError, style: AppTypography.h2),
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
