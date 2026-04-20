import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/hi_fi/hi_fi_day_group_header.dart';
import '../../../shared/hi_fi/hi_fi_filter_chip.dart';
import '../../../shared/hi_fi/hi_fi_icon_tile.dart';
import '../../../shared/hi_fi/hi_fi_list_row.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _selectedFilter = 0;

  static const List<String> _filters = <String>[
    'This week',
    'All',
    'Expense',
    'Income',
    'Card',
    'Cash',
  ];

  final List<_TransactionDayGroup> _groups = const <_TransactionDayGroup>[
    _TransactionDayGroup(
      label: 'Wed 16 Apr',
      net: 'net +£144',
      positive: true,
      rows: <_TransactionRowData>[
        _TransactionRowData(
          title: 'Uber Eats payout',
          meta: 'Food sales · Card',
          amount: '£186',
          income: true,
          icon: Icons.arrow_upward_rounded,
          tone: HiFiIconTileTone.income,
        ),
        _TransactionRowData(
          title: 'Shell fuel',
          meta: 'Fuel · Card',
          amount: '£42',
          income: false,
          icon: Icons.local_gas_station_rounded,
          tone: HiFiIconTileTone.expense,
        ),
      ],
    ),
    _TransactionDayGroup(
      label: 'Tue 15 Apr',
      net: 'net +£212',
      positive: true,
      rows: <_TransactionRowData>[
        _TransactionRowData(
          title: 'Walk-in sales',
          meta: 'Food sales · Cash',
          amount: '£320',
          income: true,
          icon: Icons.storefront_rounded,
          tone: HiFiIconTileTone.income,
        ),
        _TransactionRowData(
          title: 'Bakery supplies',
          meta: 'Supplies · Cash',
          amount: '£108',
          income: false,
          icon: Icons.breakfast_dining_rounded,
          tone: HiFiIconTileTone.expense,
        ),
      ],
    ),
    _TransactionDayGroup(
      label: 'Mon 14 Apr',
      net: 'net +£196',
      positive: true,
      rows: <_TransactionRowData>[
        _TransactionRowData(
          title: 'Deliveroo payout',
          meta: 'Food sales · Card',
          amount: '£240',
          income: true,
          icon: Icons.north_east_rounded,
          tone: HiFiIconTileTone.income,
        ),
      ],
    ),
  ];

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
        const _TransactionsHeader(),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              return HiFiFilterChip(
                label: _filters[index],
                selected: index == _selectedFilter,
                onTap: () => setState(() => _selectedFilter = index),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemCount: _filters.length,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final _TransactionDayGroup group in _groups) ...<Widget>[
          HiFiDayGroupHeader(
            label: group.label,
            net: group.net,
            positive: group.positive,
          ),
          const SizedBox(height: 2),
          for (int index = 0; index < group.rows.length; index++)
            HiFiListRow(
              leading: HiFiIconTile(
                icon: group.rows[index].icon,
                tone: group.rows[index].tone,
              ),
              title: group.rows[index].title,
              meta: group.rows[index].meta,
              trailing: _TransactionAmount(
                amount: group.rows[index].amount,
                income: group.rows[index].income,
              ),
              showDivider: index != group.rows.length - 1,
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _TransactionsHeader extends StatelessWidget {
  const _TransactionsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.h1,
              children: <InlineSpan>[
                const TextSpan(text: 'All '),
                TextSpan(
                  text: 'items',
                  style: AppTypography.h1.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.brand,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Row(
          children: <Widget>[
            HiFiIconTile(
              icon: Icons.search_rounded,
              tone: HiFiIconTileTone.brand,
              size: HiFiIconTileSize.small,
            ),
            SizedBox(width: 6),
            HiFiIconTile(
              icon: Icons.filter_alt_outlined,
              tone: HiFiIconTileTone.brand,
              size: HiFiIconTileSize.small,
            ),
          ],
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

class _TransactionDayGroup {
  const _TransactionDayGroup({
    required this.label,
    required this.net,
    required this.positive,
    required this.rows,
  });

  final String label;
  final String net;
  final bool positive;
  final List<_TransactionRowData> rows;
}

class _TransactionRowData {
  const _TransactionRowData({
    required this.title,
    required this.meta,
    required this.amount,
    required this.income,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String meta;
  final String amount;
  final bool income;
  final IconData icon;
  final HiFiIconTileTone tone;
}
