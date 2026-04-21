import 'package:flutter_test/flutter_test.dart';
import 'package:gider/features/net_profit_detail/domain/net_profit_detail_models.dart';
import 'package:gider/features/net_profit_detail/domain/net_profit_detail_service.dart';
import 'package:gider/l10n/app_locale.dart';
import 'package:gider/l10n/app_localizations.dart';

void main() {
  final NetProfitDetailService service = NetProfitDetailService();
  const AppLocalizations strings = AppLocalizations(AppLocale.en);

  group('NetProfitDetailService', () {
    test('this week resolves Monday to Sunday', () {
      final NetProfitDetailRange range = service.resolveRange(
        today: DateTime(2026, 4, 23),
        query: const NetProfitDetailQuery.thisWeek(),
        strings: strings,
      );

      expect(range.start, DateTime(2026, 4, 20));
      expect(range.end, DateTime(2026, 4, 26));
      expect(range.dayCount, 7);
    });

    test('buildViewModel computes profit, margin, and daily insights', () {
      final NetProfitDetailViewModel viewModel = service.buildViewModel(
        query: const NetProfitDetailQuery.thisWeek(),
        range: NetProfitDetailRange(
          start: DateTime(2026, 4, 20),
          end: DateTime(2026, 4, 26),
          label: 'Mon 20 Apr – Sun 26 Apr',
        ),
        transactions: <NetProfitDetailTransaction>[
          NetProfitDetailTransaction(
            occurredOn: DateTime(2026, 4, 20, 10),
            amountMinor: 10000,
            type: NetProfitTransactionType.income,
          ),
          NetProfitDetailTransaction(
            occurredOn: DateTime(2026, 4, 20, 12),
            amountMinor: 3000,
            type: NetProfitTransactionType.expense,
          ),
          NetProfitDetailTransaction(
            occurredOn: DateTime(2026, 4, 21, 10),
            amountMinor: 5000,
            type: NetProfitTransactionType.income,
          ),
          NetProfitDetailTransaction(
            occurredOn: DateTime(2026, 4, 21, 12),
            amountMinor: 7000,
            type: NetProfitTransactionType.expense,
          ),
          NetProfitDetailTransaction(
            occurredOn: DateTime(2026, 4, 23, 12),
            amountMinor: 2000,
            type: NetProfitTransactionType.expense,
          ),
        ],
        strings: strings,
      );

      expect(viewModel.incomeMinor, 15000);
      expect(viewModel.expenseMinor, 12000);
      expect(viewModel.netProfitMinor, 3000);
      expect(viewModel.marginPercent, 20);
      expect(viewModel.health.label, 'Moderate');
      expect(viewModel.dailyProfitSeries, hasLength(7));
      expect(viewModel.dailyProfitSeries[0].profitMinor, 7000);
      expect(viewModel.dailyProfitSeries[1].profitMinor, -2000);
      expect(viewModel.dailyProfitSeries[2].profitMinor, 0);
      expect(viewModel.comparison.message, 'Expenses are eating 80% of income');
      expect(viewModel.showExpensePressureWarning, isTrue);
      expect(
        viewModel.expensePressureMessage,
        'Expenses are consuming most of your income',
      );
      expect(viewModel.bestDayInsight.primary, 'Mon');
      expect(viewModel.bestDayInsight.secondary, '£70.00');
      expect(viewModel.worstDayInsight.primary, 'Tue');
      expect(viewModel.worstDayInsight.secondary, '-£20.00');
      expect(viewModel.averageDailyProfitInsight.primary, '£4.29');
      expect(viewModel.isEmpty, isFalse);
    });

    test('buildViewModel returns safe empty state with no transactions', () {
      final NetProfitDetailViewModel viewModel = service.buildViewModel(
        query: const NetProfitDetailQuery.lastMonth(),
        range: NetProfitDetailRange(
          start: DateTime(2026, 3, 1),
          end: DateTime(2026, 3, 31),
          label: 'Sun 1 Mar – Tue 31 Mar',
        ),
        transactions: <NetProfitDetailTransaction>[],
        strings: strings,
      );

      expect(viewModel.incomeMinor, 0);
      expect(viewModel.expenseMinor, 0);
      expect(viewModel.netProfitMinor, 0);
      expect(viewModel.marginPercent, 0);
      expect(viewModel.health.label, 'No margin yet');
      expect(viewModel.dailyProfitSeries, hasLength(31));
      expect(viewModel.bestDayInsight.isEmpty, isTrue);
      expect(viewModel.worstDayInsight.isEmpty, isTrue);
      expect(viewModel.averageDailyProfitInsight.primary, '£0.00');
      expect(viewModel.showExpensePressureWarning, isFalse);
      expect(viewModel.isEmpty, isTrue);
      expect(viewModel.hasDisabledChartState, isTrue);
    });
  });
}
