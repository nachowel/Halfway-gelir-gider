import 'package:flutter_test/flutter_test.dart';
import 'package:gider/features/income_detail/domain/income_detail_models.dart';
import 'package:gider/features/income_detail/domain/income_detail_service.dart';
import 'package:gider/l10n/app_locale.dart';
import 'package:gider/l10n/app_localizations.dart';

void main() {
  final IncomeDetailService service = IncomeDetailService();
  const AppLocalizations strings = AppLocalizations(AppLocale.en);

  group('IncomeDetailService', () {
    test('this week resolves Monday to Sunday', () {
      final IncomeDetailRange range = service.resolveRange(
        today: DateTime(2026, 4, 23),
        query: const IncomeDetailQuery.thisWeek(),
        strings: strings,
      );

      expect(range.start, DateTime(2026, 4, 20));
      expect(range.end, DateTime(2026, 4, 26));
      expect(range.dayCount, 7);
    });

    test(
      'buildViewModel groups cash and card by day and fills missing days',
      () {
        final IncomeDetailViewModel viewModel = service.buildViewModel(
          query: const IncomeDetailQuery.thisWeek(),
          range: IncomeDetailRange(
            start: DateTime(2026, 4, 20),
            end: DateTime(2026, 4, 26),
            label: 'Mon 20 Apr – Sun 26 Apr',
          ),
          transactions: <IncomeDetailTransaction>[
            IncomeDetailTransaction(
              occurredOn: DateTime(2026, 4, 20, 10),
              amountMinor: 3000,
              paymentMethod: IncomeDetailPaymentMethod.cash,
            ),
            IncomeDetailTransaction(
              occurredOn: DateTime(2026, 4, 20, 11),
              amountMinor: 1000,
              paymentMethod: IncomeDetailPaymentMethod.card,
            ),
            IncomeDetailTransaction(
              occurredOn: DateTime(2026, 4, 21, 11),
              amountMinor: 4000,
              paymentMethod: IncomeDetailPaymentMethod.cash,
            ),
            IncomeDetailTransaction(
              occurredOn: DateTime(2026, 4, 21, 12),
              amountMinor: 2000,
              paymentMethod: IncomeDetailPaymentMethod.card,
            ),
            IncomeDetailTransaction(
              occurredOn: DateTime(2026, 4, 24, 12),
              amountMinor: 1000,
              paymentMethod: IncomeDetailPaymentMethod.other,
            ),
          ],
          strings: strings,
        );

        expect(viewModel.totalIncomeMinor, 10000);
        expect(viewModel.cashIncomeMinor, 7000);
        expect(viewModel.cardIncomeMinor, 3000);
        expect(viewModel.cashSharePercent, 70);
        expect(viewModel.cardSharePercent, 30);
        expect(viewModel.chartSeries, hasLength(7));
        expect(viewModel.breakdownRows, hasLength(7));
        expect(viewModel.breakdownRows[0].totalMinor, 4000);
        expect(viewModel.breakdownRows[2].totalMinor, 0);
        expect(viewModel.breakdownRows[6].totalMinor, 0);
        expect(viewModel.highestDayInsight.primary, 'Tue');
        expect(viewModel.highestDayInsight.secondary, '£60.00');
        expect(viewModel.bestPaymentMixInsight.primary, 'Mon');
        expect(viewModel.bestPaymentMixInsight.secondary, '75% cash');
        expect(viewModel.averagePerDayInsight.primary, '£14.29');
        expect(viewModel.isEmpty, isFalse);
        expect(viewModel.hasDisabledChartState, isFalse);
      },
    );

    test(
      'buildViewModel returns safe empty state when range has no income',
      () {
        final IncomeDetailViewModel viewModel = service.buildViewModel(
          query: const IncomeDetailQuery.lastMonth(),
          range: IncomeDetailRange(
            start: DateTime(2026, 3, 1),
            end: DateTime(2026, 3, 31),
            label: 'Sun 1 Mar – Tue 31 Mar',
          ),
          transactions: <IncomeDetailTransaction>[],
          strings: strings,
        );

        expect(viewModel.totalIncomeMinor, 0);
        expect(viewModel.cashIncomeMinor, 0);
        expect(viewModel.cardIncomeMinor, 0);
        expect(viewModel.cashSharePercent, 0);
        expect(viewModel.cardSharePercent, 0);
        expect(viewModel.breakdownRows, hasLength(31));
        expect(
          viewModel.breakdownRows.every((IncomeDetailBreakdownRow row) {
            return row.totalMinor == 0;
          }),
          isTrue,
        );
        expect(viewModel.highestDayInsight.isEmpty, isTrue);
        expect(viewModel.bestPaymentMixInsight.isEmpty, isTrue);
        expect(viewModel.averagePerDayInsight.primary, '£0.00');
        expect(viewModel.isEmpty, isTrue);
        expect(viewModel.hasDisabledChartState, isTrue);
      },
    );
  });
}
