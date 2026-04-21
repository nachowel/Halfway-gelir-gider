import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/app_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/hi_fi/hi_fi_bar.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_icon_tile.dart';
import '../../../shared/hi_fi/hi_fi_recurring_row.dart';
import 'mark_paid_sheet.dart';
import 'recurring_form_sheet.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool canNavigateBack = Navigator.of(context).canPop();
    final itemsAsync = ref.watch(recurringItemsProvider);
    final summaryAsync = ref.watch(recurringSummaryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenSide,
        AppSpacing.xs,
        AppSpacing.screenSide,
        120,
      ),
      children: <Widget>[
        _RecurringHeader(
          canNavigateBack: canNavigateBack,
          onBack: () => Navigator.of(context).maybePop(),
          onAdd: () => showRecurringFormSheet(context),
        ),
        const SizedBox(height: AppSpacing.md),
        _SummaryCard(summaryAsync: summaryAsync),
        const SizedBox(height: AppSpacing.sm),
        itemsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const _ErrorState(),
          data: (items) {
            if (items.isEmpty) return const _EmptyState();
            return _ItemList(items: items);
          },
        ),
      ],
    );
  }
}

class _ItemList extends ConsumerWidget {
  const _ItemList({required this.items});

  final List<RecurringUiItem> items;

  HiFiRecurringStatus _toHiFiStatus(RecurringUiStatus s) => switch (s) {
    RecurringUiStatus.late => HiFiRecurringStatus.late,
    RecurringUiStatus.soon => HiFiRecurringStatus.soon,
    RecurringUiStatus.later => HiFiRecurringStatus.later,
  };

  String _formatAmount(int minor) {
    final pounds = minor ~/ 100;
    final pence = minor % 100;
    return '£$pounds.${pence.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          GestureDetector(
            onTap: () =>
                showRecurringFormSheet(context, existing: items[i].record),
            child: HiFiRecurringRow(
              title: items[i].record.name,
              status: _toHiFiStatus(items[i].status),
              statusLabel: items[i].statusLabel,
              frequencyMeta: items[i].frequencyMeta,
              amount: _formatAmount(items[i].record.amountMinor),
              icon: items[i].icon,
              onPaidTap: () => _openMarkPaid(context, ref, items[i]),
            ),
          ),
          if (i != items.length - 1) const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

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

  Future<void> _openMarkPaid(
    BuildContext context,
    WidgetRef ref,
    RecurringUiItem item,
  ) async {
    final DateTime nextDue = _nextDueAfter(
      item.record.nextDueOn,
      item.record.frequency,
    );
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
        defaultMethod: item.record.defaultPaymentMethod == null
            ? null
            : _toMarkPaidMethod(item.record.defaultPaymentMethod!),
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

  RecurringPaymentMethod _toMarkPaidMethod(PaymentMethodType m) => switch (m) {
    PaymentMethodType.cash => RecurringPaymentMethod.cash,
    PaymentMethodType.card => RecurringPaymentMethod.card,
    PaymentMethodType.bankTransfer => RecurringPaymentMethod.bankTransfer,
    PaymentMethodType.other => RecurringPaymentMethod.other,
  };

  PaymentMethodType _toPaymentMethodType(RecurringPaymentMethod m) =>
      switch (m) {
        RecurringPaymentMethod.cash => PaymentMethodType.cash,
        RecurringPaymentMethod.card => PaymentMethodType.card,
        RecurringPaymentMethod.bankTransfer => PaymentMethodType.bankTransfer,
        RecurringPaymentMethod.other => PaymentMethodType.other,
      };
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summaryAsync});

  final AsyncValue<RecurringSummarySnapshot> summaryAsync;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return summaryAsync.when(
      loading: () => HiFiCard.compact(
        child: Text(strings.loading, style: AppTypography.meta),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (snapshot) {
        final total = snapshot.totalMinor;
        final paid = snapshot.paidMinor;
        final remaining = total - paid;
        final fraction = total == 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);
        return HiFiCard.compact(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(strings.summaryThisMonth, style: AppTypography.eye),
                  Text(
                    strings.currencyMinor(total),
                    style: AppTypography.numSm,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              HiFiBar(value: fraction, tone: HiFiBarTone.expense),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    strings.paidAmountLabel(strings.currencyMinor(paid)),
                    style: AppTypography.meta,
                  ),
                  Text(
                    strings.remainingAmountLabel(
                      strings.currencyMinor(remaining),
                    ),
                    style: AppTypography.meta,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecurringHeader extends StatelessWidget {
  const _RecurringHeader({
    required this.canNavigateBack,
    required this.onBack,
    required this.onAdd,
  });

  final bool canNavigateBack;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (canNavigateBack)
              _HeaderTextAction(
                key: const ValueKey<String>('recurring-back-button'),
                icon: Icons.chevron_left_rounded,
                label: strings.back,
                onTap: onBack,
              )
            else
              Text(strings.monthly.toUpperCase(), style: AppTypography.eye),
            const Spacer(),
            _HeaderIconAction(
              key: const ValueKey<String>('recurring-add-button'),
              icon: Icons.add_rounded,
              onTap: onAdd,
            ),
          ],
        ),
        if (canNavigateBack) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(strings.monthly.toUpperCase(), style: AppTypography.eye),
        ],
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: AppTypography.h1,
            children: <InlineSpan>[
              TextSpan(
                text: strings.recurring,
                style: AppTypography.h1.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderTextAction extends StatelessWidget {
  const _HeaderTextAction({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18, color: AppColors.inkSoft),
              const SizedBox(width: 2),
              Text(label, style: AppTypography.bodySoft.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconAction extends StatelessWidget {
  const _HeaderIconAction({required this.icon, required this.onTap, super.key});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: HiFiIconTile(
              icon: icon,
              size: HiFiIconTileSize.small,
              tone: HiFiIconTileTone.brand,
            ),
          ),
        ),
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
          Icon(Icons.event_repeat_rounded, size: 48, color: AppColors.inkFade),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.noRecurringExpenses,
            style: AppTypography.body.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            strings.tapPlusToAddFirstRecurring,
            style: AppTypography.meta.copyWith(color: AppColors.inkSoft),
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
            strings.recurringLoadError,
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
