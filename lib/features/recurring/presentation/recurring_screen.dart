import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/hi_fi/hi_fi_bar.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_icon_tile.dart';
import '../../../shared/hi_fi/hi_fi_recurring_row.dart';
import 'mark_paid_sheet.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  late List<_RecurringItem> _items;

  @override
  void initState() {
    super.initState();
    _items = <_RecurringItem>[
      _RecurringItem(
        id: 'gas',
        title: 'Gas bill',
        amountLabel: '£62',
        amountMinor: 6200,
        status: HiFiRecurringStatus.late,
        statusLabel: 'Late · 3d',
        frequencyMeta: 'Every month · was due 13 Apr',
        frequencyLabel: 'Monthly',
        currentDueDate: DateTime(2026, 4, 13),
        nextDueDate: DateTime(2026, 5, 13),
        defaultMethod: RecurringPaymentMethod.bankTransfer,
      ),
      _RecurringItem(
        id: 'rent',
        title: 'Rent',
        amountLabel: '£850',
        amountMinor: 85000,
        status: HiFiRecurringStatus.soon,
        statusLabel: 'In 2 days',
        frequencyMeta: 'Every month · Fri 18 Apr',
        frequencyLabel: 'Monthly',
        currentDueDate: DateTime(2026, 4, 18),
        nextDueDate: DateTime(2026, 5, 18),
        defaultMethod: RecurringPaymentMethod.bankTransfer,
      ),
      _RecurringItem(
        id: 'internet',
        title: 'Internet',
        amountLabel: '£38',
        amountMinor: 3800,
        status: HiFiRecurringStatus.later,
        statusLabel: 'Later',
        frequencyMeta: 'In 6 days · Tue 22',
        frequencyLabel: 'Monthly',
        currentDueDate: DateTime(2026, 4, 22),
        nextDueDate: DateTime(2026, 5, 22),
        defaultMethod: RecurringPaymentMethod.card,
        icon: Icons.wifi_rounded,
      ),
      _RecurringItem(
        id: 'electricity',
        title: 'Electricity',
        amountLabel: '£124',
        amountMinor: 12400,
        status: HiFiRecurringStatus.later,
        statusLabel: 'Later',
        frequencyMeta: 'In 11 days · Sun 27',
        frequencyLabel: 'Monthly',
        currentDueDate: DateTime(2026, 4, 27),
        nextDueDate: DateTime(2026, 5, 27),
        defaultMethod: RecurringPaymentMethod.bankTransfer,
        icon: Icons.bolt_rounded,
      ),
      _RecurringItem(
        id: 'insurance',
        title: 'Insurance',
        amountLabel: '£86',
        amountMinor: 8600,
        status: HiFiRecurringStatus.later,
        statusLabel: 'Later',
        frequencyMeta: 'Next month · 3 May',
        frequencyLabel: 'Monthly',
        currentDueDate: DateTime(2026, 5, 3),
        nextDueDate: DateTime(2026, 6, 3),
        defaultMethod: RecurringPaymentMethod.other,
        icon: Icons.shield_outlined,
      ),
    ];
  }

  Future<void> _openMarkPaidSheet(_RecurringItem item) async {
    await showMarkPaidSheet(
      context,
      draft: RecurringPaymentDraft(
        id: item.id,
        title: item.title,
        frequencyLabel: item.frequencyLabel,
        plannedAmountMinor: item.amountMinor,
        currentDueDate: item.currentDueDate,
        nextDueDate: item.nextDueDate,
        defaultMethod: item.defaultMethod,
      ),
      onConfirm: (RecurringPaymentResult result) async {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        if (!mounted) return;
        setState(() {
          _items = _items.map((_RecurringItem current) {
            if (current.id != item.id) return current;
            return current.copyWith(
              amountMinor: result.amountMinor,
              amountLabel: _formatCurrency(result.amountMinor),
              status: HiFiRecurringStatus.later,
              statusLabel: 'Later',
              frequencyMeta:
                  'Next month · ${_formatMonthDay(item.nextDueDate)}',
            );
          }).toList()..sort(_sortRecurring);
        });
      },
    );
  }

  int _sortRecurring(_RecurringItem a, _RecurringItem b) {
    int weight(HiFiRecurringStatus status) {
      switch (status) {
        case HiFiRecurringStatus.late:
          return 0;
        case HiFiRecurringStatus.soon:
          return 1;
        case HiFiRecurringStatus.later:
          return 2;
      }
    }

    final int cmp = weight(a.status).compareTo(weight(b.status));
    if (cmp != 0) return cmp;
    return a.currentDueDate.compareTo(b.currentDueDate);
  }

  String _formatCurrency(int amountMinor) {
    final String value = (amountMinor / 100).toStringAsFixed(2);
    final List<String> parts = value.split('.');
    final String whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match _) => ',',
    );
    return '£$whole.${parts.last}';
  }

  String _formatMonthDay(DateTime value) {
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
    return '${value.day} ${months[value.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenSide,
        AppSpacing.xs,
        AppSpacing.screenSide,
        120,
      ),
      children: <Widget>[
        const _RecurringHeader(),
        const SizedBox(height: AppSpacing.md),
        const _RecurringSummaryCard(),
        const SizedBox(height: AppSpacing.sm),
        for (int i = 0; i < _items.length; i++) ...<Widget>[
          HiFiRecurringRow(
            title: _items[i].title,
            status: _items[i].status,
            statusLabel: _items[i].statusLabel,
            frequencyMeta: _items[i].frequencyMeta,
            amount: _items[i].amountLabel,
            icon: _items[i].icon,
            onPaidTap: () => _openMarkPaidSheet(_items[i]),
          ),
          if (i != _items.length - 1) const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _RecurringHeader extends StatelessWidget {
  const _RecurringHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('MONTHLY', style: AppTypography.eye),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: AppTypography.h1,
                  children: <InlineSpan>[
                    TextSpan(
                      text: 'Recurring',
                      style: AppTypography.h1.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const HiFiIconTile(
          icon: Icons.add_rounded,
          size: HiFiIconTileSize.small,
          tone: HiFiIconTileTone.brand,
        ),
      ],
    );
  }
}

class _RecurringSummaryCard extends StatelessWidget {
  const _RecurringSummaryCard();

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('THIS MONTH', style: AppTypography.eye),
              Text('£1,620', style: AppTypography.numSm),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const HiFiBar(value: 0.42, tone: HiFiBarTone.expense),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('£680 paid', style: AppTypography.meta),
              Text('£940 remaining', style: AppTypography.meta),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecurringItem {
  const _RecurringItem({
    required this.id,
    required this.title,
    required this.amountLabel,
    required this.amountMinor,
    required this.status,
    required this.statusLabel,
    required this.frequencyMeta,
    required this.frequencyLabel,
    required this.currentDueDate,
    required this.nextDueDate,
    this.defaultMethod,
    this.icon,
  });

  final String id;
  final String title;
  final String amountLabel;
  final int amountMinor;
  final HiFiRecurringStatus status;
  final String statusLabel;
  final String frequencyMeta;
  final String frequencyLabel;
  final DateTime currentDueDate;
  final DateTime nextDueDate;
  final RecurringPaymentMethod? defaultMethod;
  final IconData? icon;

  _RecurringItem copyWith({
    String? amountLabel,
    int? amountMinor,
    HiFiRecurringStatus? status,
    String? statusLabel,
    String? frequencyMeta,
  }) {
    return _RecurringItem(
      id: id,
      title: title,
      amountLabel: amountLabel ?? this.amountLabel,
      amountMinor: amountMinor ?? this.amountMinor,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      frequencyMeta: frequencyMeta ?? this.frequencyMeta,
      frequencyLabel: frequencyLabel,
      currentDueDate: currentDueDate,
      nextDueDate: nextDueDate,
      defaultMethod: defaultMethod,
      icon: icon,
    );
  }
}
