import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/app_models.dart';
import '../../../features/recurring/presentation/mark_paid_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_icon_tile.dart';
import '../../../shared/hi_fi/hi_fi_section_header.dart';
import '../widgets/reserve_planner_card.dart';
import '../widgets/summary_cards.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/upcoming_payment_item.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(dashboardSnapshotProvider);

    return snapshotAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _ErrorState(),
      data: (snapshot) => _DashboardBody(snapshot: snapshot, ref: ref),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.snapshot, required this.ref});

  static const int _upcomingPreviewLimit = 3;
  static const int _recentPreviewLimit = 4;

  final DashboardSnapshot snapshot;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final net = snapshot.netMinor;
    final income = snapshot.incomeMinor;
    final expense = snapshot.expenseMinor;
    final cash = snapshot.cashIncomeMinor;
    final card = snapshot.cardIncomeMinor;
    final delta = snapshot.netDeltaMinor;
    final cashCardIncome = cash + card;
    final bankTransferIncome = income - cashCardIncome;
    final cashFraction = cashCardIncome == 0
        ? 0.0
        : (cash / cashCardIncome).clamp(0.0, 1.0);

    final heroData = HeroSummaryCardData(
      eyebrow: strings.netProfit,
      value: strings.currencyMinor(net),
      deltaValue: strings.currencyMinor(delta.abs()),
      deltaLabel: delta >= 0 ? strings.vsLastWeek : strings.vsLastWeekDown,
      sparkValues: const <double>[0.36, 0.54, 0.42, 0.68, 0.58, 0.82, 0.92],
    );

    final incomeData = SummaryMetricCardData(
      label: strings.income,
      value: strings.currencyMinor(income),
      tone: SummaryMetricTone.income,
    );

    final expenseData = SummaryMetricCardData(
      label: strings.expenses,
      value: strings.currencyMinor(expense),
      tone: SummaryMetricTone.expense,
    );

    final cashSplitData = CashSplitSummaryCardData(
      cashValue: strings.currencyMinor(cash),
      cardValue: strings.currencyMinor(card),
      progress: cashFraction,
      helperText: bankTransferIncome > 0 ? strings.bankTransferIncluded : null,
    );
    final List<RecurringUiItem> upcomingPreview =
        List<RecurringUiItem>.from(snapshot.upcomingRecurring)..sort(
          (RecurringUiItem a, RecurringUiItem b) =>
              a.record.nextDueOn.compareTo(b.record.nextDueOn),
        );
    final List<TransactionData> recentPreview = List<TransactionData>.from(
      snapshot.recentTransactions,
    )..sort(_compareRecentTransactions);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenSide,
        AppSpacing.xs,
        AppSpacing.screenSide,
        120,
      ),
      children: <Widget>[
        _DashboardHeader(weekLabel: snapshot.weekLabel),
        const SizedBox(height: AppSpacing.md),
        HeroSummaryCard(
          key: const ValueKey<String>('dashboard-net-profit-card'),
          data: heroData,
          onTap: () => context.push('/summary/net-profit'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: SummaryMetricCard(
                key: const ValueKey<String>('dashboard-income-card'),
                data: incomeData,
                onTap: () => context.push('/summary/income'),
              ),
            ),
            const SizedBox(width: AppSpacing.smTight),
            Expanded(
              child: SummaryMetricCard(
                key: const ValueKey<String>('dashboard-expense-card'),
                data: expenseData,
                onTap: () => context.push('/summary/expenses'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        CashSplitSummaryCard(data: cashSplitData),
        const SizedBox(height: AppSpacing.md),
        ReservePlannerCard(snapshot: snapshot.reservePlanner),
        const SizedBox(height: AppSpacing.md),
        _UpcomingSection(
          items: upcomingPreview.take(_upcomingPreviewLimit).toList(),
          hasNavigationTarget: snapshot.upcomingRecurring.isNotEmpty,
          ref: ref,
        ),
        const SizedBox(height: AppSpacing.md),
        _RecentSection(
          transactions: recentPreview.take(_recentPreviewLimit).toList(),
          hasNavigationTarget: snapshot.recentTransactions.isNotEmpty,
        ),
      ],
    );
  }

  static int _compareRecentTransactions(TransactionData a, TransactionData b) {
    final int occurredOnComparison = b.occurredOn.compareTo(a.occurredOn);
    if (occurredOnComparison != 0) {
      return occurredOnComparison;
    }
    return b.createdAt.compareTo(a.createdAt);
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.weekLabel});

  final String weekLabel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(weekLabel.toUpperCase(), style: AppTypography.eye),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: AppTypography.h1,
                  children: <InlineSpan>[
                    TextSpan(
                      text: '${strings.thisWeekHeadline.split(' ').first} ',
                    ),
                    TextSpan(
                      text: strings.thisWeekHeadline.split(' ').length > 1
                          ? strings.thisWeekHeadline.split(' ').last
                          : strings.thisWeekHeadline,
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
          icon: Icons.notifications_none_rounded,
          tone: HiFiIconTileTone.brand,
          shape: HiFiIconTileShape.circle,
        ),
      ],
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({
    required this.items,
    required this.hasNavigationTarget,
    required this.ref,
  });

  final List<RecurringUiItem> items;
  final bool hasNavigationTarget;
  final WidgetRef ref;

  HiFiIconTileTone _tone(RecurringUiStatus status) => switch (status) {
    RecurringUiStatus.late => HiFiIconTileTone.expense,
    RecurringUiStatus.soon => HiFiIconTileTone.amber,
    RecurringUiStatus.later => HiFiIconTileTone.amber,
  };

  DateTime _nextDueAfter(DateTime current, RecurringFrequencyType frequency) {
    return switch (frequency) {
      RecurringFrequencyType.weekly => DateTime(
        current.year,
        current.month,
        current.day + 7,
      ),
      RecurringFrequencyType.monthly => DateTime(
        current.year,
        current.month + 1,
        current.day,
      ),
      RecurringFrequencyType.quarterly => DateTime(
        current.year,
        current.month + 3,
        current.day,
      ),
      RecurringFrequencyType.yearly => DateTime(
        current.year + 1,
        current.month,
        current.day,
      ),
    };
  }

  PaymentMethodType _toPaymentMethodType(RecurringPaymentMethod m) =>
      switch (m) {
        RecurringPaymentMethod.cash => PaymentMethodType.cash,
        RecurringPaymentMethod.card => PaymentMethodType.card,
        RecurringPaymentMethod.bankTransfer => PaymentMethodType.bankTransfer,
        RecurringPaymentMethod.other => PaymentMethodType.other,
      };

  RecurringPaymentMethod? _toMarkPaidMethod(PaymentMethodType? m) =>
      switch (m) {
        PaymentMethodType.cash => RecurringPaymentMethod.cash,
        PaymentMethodType.card => RecurringPaymentMethod.card,
        PaymentMethodType.bankTransfer => RecurringPaymentMethod.bankTransfer,
        PaymentMethodType.other => RecurringPaymentMethod.other,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        HiFiSectionHeader.title(
          left: strings.upcoming,
          right: hasNavigationTarget ? strings.seeAll : null,
          actionKey: const ValueKey<String>('dashboard-upcoming-see-all'),
          onRightTap: hasNavigationTarget
              ? () => context.go('/settings/recurring')
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (items.isEmpty)
          _DashboardPreviewEmptyState(
            icon: Icons.event_repeat_rounded,
            title: strings.noUpcomingPayments,
            message: strings.recurringPreviewMessage,
          )
        else
          for (int i = 0; i < items.length; i++) ...<Widget>[
            UpcomingPaymentItem(
              data: UpcomingPaymentItemData(
                title: items[i].record.name,
                meta: items[i].frequencyMeta,
                amount: strings.currencyMinor(items[i].record.amountMinor),
                icon: items[i].icon,
                tone: _tone(items[i].status),
              ),
              onTap: () => _openMarkPaid(context, items[i]),
            ),
            if (i != items.length - 1) const SizedBox(height: AppSpacing.xs),
          ],
      ],
    );
  }

  Future<void> _openMarkPaid(BuildContext context, RecurringUiItem item) async {
    final nextDue = _nextDueAfter(item.record.nextDueOn, item.record.frequency);
    await showMarkPaidSheet(
      context,
      draft: RecurringPaymentDraft(
        id: item.record.id,
        title: item.record.name,
        frequencyLabel: context.strings.recurringFrequencyLabel(
          item.record.frequency,
        ),
        plannedAmountMinor: item.record.amountMinor,
        currentDueDate: item.record.nextDueOn,
        nextDueDate: nextDue,
        defaultMethod: _toMarkPaidMethod(item.record.defaultPaymentMethod),
      ),
      onConfirm: (RecurringPaymentResult result) async {
        await ref
            .read(giderRepositoryProvider)
            .markRecurringPaid(
              recurringExpenseId: item.record.id,
              paidOn: result.paidOn,
              amountMinor: result.amountMinor,
              method: _toPaymentMethodType(result.method),
            );
        ref.invalidate(recurringItemsProvider);
        ref.invalidate(recurringSummaryProvider);
        ref.invalidate(dashboardSnapshotProvider);
      },
    );
  }
}

class _RecentSection extends StatelessWidget {
  const _RecentSection({
    required this.transactions,
    required this.hasNavigationTarget,
  });

  final List<TransactionData> transactions;
  final bool hasNavigationTarget;

  IconData _icon(TransactionData t) {
    final name = t.categoryName.toLowerCase();
    if (name.contains('rent')) {
      return Icons.home_rounded;
    }
    if (name.contains('util') ||
        name.contains('electr') ||
        name.contains('gas')) {
      return Icons.bolt_rounded;
    }
    if (name.contains('internet') || name.contains('wifi')) {
      return Icons.wifi_rounded;
    }
    if (name.contains('uber')) {
      return Icons.directions_car_filled_rounded;
    }
    if (name.contains('eat') ||
        name.contains('food') ||
        name.contains('delivery')) {
      return Icons.delivery_dining_rounded;
    }
    if (name.contains('cash') ||
        name.contains('sale') ||
        name.contains('storefront')) {
      return Icons.storefront_rounded;
    }
    if (name.contains('card') || name.contains('payment')) {
      return Icons.payments_rounded;
    }
    if (name.contains('stock') || name.contains('inventory')) {
      return Icons.inventory_2_outlined;
    }
    if (name.contains('supply') || name.contains('supplies')) {
      return Icons.shopping_bag_outlined;
    }
    if (name.contains('maintenance')) {
      return Icons.build_circle_outlined;
    }
    if (name.contains('transport') || name.contains('delivery')) {
      return Icons.local_shipping_outlined;
    }
    return t.type == TransactionType.income
        ? Icons.arrow_upward_rounded
        : Icons.receipt_long_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        HiFiSectionHeader.title(
          left: strings.recent,
          right: hasNavigationTarget ? strings.seeAll : null,
          actionKey: const ValueKey<String>('dashboard-recent-see-all'),
          onRightTap: hasNavigationTarget
              ? () => context.go('/transactions')
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (transactions.isEmpty)
          _DashboardPreviewEmptyState(
            icon: Icons.receipt_long_rounded,
            title: strings.noRecentTransactions,
            message: strings.recentTransactionsPreview,
          )
        else
          HiFiCard.flush(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < transactions.length; i++)
                  TransactionListItem(
                    data: TransactionListItemData(
                      title: transactions[i].vendor?.trim().isNotEmpty == true
                          ? transactions[i].vendor!
                          : strings.systemCategoryName(
                              transactions[i].categoryName,
                            ),
                      meta:
                          '${strings.systemCategoryName(transactions[i].categoryName)} · ${strings.paymentMethodLabel(transactions[i].paymentMethod)}',
                      amount: strings.currencyMinor(
                        transactions[i].amountMinor,
                      ),
                      icon: _icon(transactions[i]),
                      tone: transactions[i].type == TransactionType.income
                          ? HiFiIconTileTone.income
                          : HiFiIconTileTone.expense,
                      isIncome: transactions[i].type == TransactionType.income,
                    ),
                    showDivider: i != transactions.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DashboardPreviewEmptyState extends StatelessWidget {
  const _DashboardPreviewEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return HiFiCard.compact(
      child: Row(
        children: <Widget>[
          HiFiIconTile(
            icon: icon,
            tone: HiFiIconTileTone.brand,
            size: HiFiIconTileSize.small,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTypography.ttl),
                const SizedBox(height: 2),
                Text(message, style: AppTypography.meta),
              ],
            ),
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
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: <Widget>[
          Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.inkFade),
          const SizedBox(height: 16),
          Text(
            strings.dashboardLoadError,
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
