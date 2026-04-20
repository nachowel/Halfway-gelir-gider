import 'package:flutter/material.dart';

import '../../../shared/hi_fi/hi_fi_icon_tile.dart';

enum CategoryKind { expense, income }

extension CategoryKindX on CategoryKind {
  String get label => this == CategoryKind.expense ? 'Expense' : 'Income';
}

class CategoryPresentationData {
  const CategoryPresentationData({
    required this.title,
    required this.icon,
    required this.tone,
    required this.entryCount,
    required this.monthlyTotalLabel,
  });

  final String title;
  final IconData icon;
  final HiFiIconTileTone tone;
  final int entryCount;
  final String monthlyTotalLabel;

  String get metaLabel => '$entryCount entries · $monthlyTotalLabel this month';

  CategoryPresentationData copyWith({
    String? title,
    IconData? icon,
    HiFiIconTileTone? tone,
    int? entryCount,
    String? monthlyTotalLabel,
  }) {
    return CategoryPresentationData(
      title: title ?? this.title,
      icon: icon ?? this.icon,
      tone: tone ?? this.tone,
      entryCount: entryCount ?? this.entryCount,
      monthlyTotalLabel: monthlyTotalLabel ?? this.monthlyTotalLabel,
    );
  }
}

const List<CategoryPresentationData> expenseCategoryCatalog =
    <CategoryPresentationData>[
      CategoryPresentationData(
        title: 'Rent',
        icon: Icons.home_rounded,
        tone: HiFiIconTileTone.expense,
        entryCount: 4,
        monthlyTotalLabel: '£3,400',
      ),
      CategoryPresentationData(
        title: 'Utilities',
        icon: Icons.bolt_rounded,
        tone: HiFiIconTileTone.expense,
        entryCount: 5,
        monthlyTotalLabel: '£890',
      ),
      CategoryPresentationData(
        title: 'Internet',
        icon: Icons.wifi_rounded,
        tone: HiFiIconTileTone.expense,
        entryCount: 3,
        monthlyTotalLabel: '£210',
      ),
      CategoryPresentationData(
        title: 'Stock Purchase',
        icon: Icons.inventory_2_rounded,
        tone: HiFiIconTileTone.expense,
        entryCount: 11,
        monthlyTotalLabel: '£2,120',
      ),
      CategoryPresentationData(
        title: 'Supplies',
        icon: Icons.shopping_bag_outlined,
        tone: HiFiIconTileTone.expense,
        entryCount: 12,
        monthlyTotalLabel: '£640',
      ),
      CategoryPresentationData(
        title: 'Maintenance',
        icon: Icons.build_circle_outlined,
        tone: HiFiIconTileTone.expense,
        entryCount: 4,
        monthlyTotalLabel: '£480',
      ),
      CategoryPresentationData(
        title: 'Delivery/Transport',
        icon: Icons.delivery_dining_rounded,
        tone: HiFiIconTileTone.expense,
        entryCount: 6,
        monthlyTotalLabel: '£410',
      ),
      CategoryPresentationData(
        title: 'Other Expense',
        icon: Icons.receipt_long_rounded,
        tone: HiFiIconTileTone.expense,
        entryCount: 6,
        monthlyTotalLabel: '£380',
      ),
    ];

const List<CategoryPresentationData> incomeCategoryCatalog =
    <CategoryPresentationData>[
      CategoryPresentationData(
        title: 'Cash Sales',
        icon: Icons.storefront_rounded,
        tone: HiFiIconTileTone.income,
        entryCount: 14,
        monthlyTotalLabel: '£4,620',
      ),
      CategoryPresentationData(
        title: 'Card Sales',
        icon: Icons.credit_card_rounded,
        tone: HiFiIconTileTone.income,
        entryCount: 11,
        monthlyTotalLabel: '£3,980',
      ),
      CategoryPresentationData(
        title: 'Uber Settlement',
        icon: Icons.local_taxi_rounded,
        tone: HiFiIconTileTone.income,
        entryCount: 4,
        monthlyTotalLabel: '£2,860',
      ),
      CategoryPresentationData(
        title: 'Just Eat Settlement',
        icon: Icons.delivery_dining_rounded,
        tone: HiFiIconTileTone.income,
        entryCount: 3,
        monthlyTotalLabel: '£1,940',
      ),
      CategoryPresentationData(
        title: 'Other Income',
        icon: Icons.account_balance_wallet_outlined,
        tone: HiFiIconTileTone.income,
        entryCount: 2,
        monthlyTotalLabel: '£860',
      ),
    ];
