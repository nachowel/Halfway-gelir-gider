import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/features/reports/domain/payee_analytics_models.dart';
import 'package:gider/features/reports/domain/payee_analytics_service.dart';
import 'package:gider/l10n/app_locale.dart';
import 'package:gider/l10n/app_localizations.dart';

void main() {
  const AppLocalizations strings = AppLocalizations(AppLocale.en);
  final PayeeAnalyticsService service = const PayeeAnalyticsService();

  TransactionData tx({
    required String id,
    required int amountMinor,
    required DateTime occurredOn,
    required TransactionType type,
    String categoryName = 'Stock Purchase',
    PaymentMethodType paymentMethod = PaymentMethodType.card,
    String? supplierId,
    String? supplierName,
    String? vendor,
    String? staffName,
    String? note,
  }) {
    return TransactionData(
      id: id,
      type: type,
      occurredOn: occurredOn,
      amountMinor: amountMinor,
      categoryId: 'cat-$id',
      categoryName: categoryName,
      paymentMethod: paymentMethod,
      createdAt: occurredOn,
      supplierId: supplierId,
      supplierName: supplierName,
      vendor: vendor,
      staffName: staffName,
      note: note,
    );
  }

  DateTime d(int y, int m, int day) => DateTime(y, m, day);

  PayeeAnalyticsDataset ds(List<TransactionData> list) {
    return PayeeAnalyticsDataset(
      transactions: list,
      expenseCategoryIcons: const <String, IconData>{},
    );
  }

  group('PayeeAnalyticsService - payee resolution', () {
    test('uses linked supplier name when present', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 5000,
          occurredOn: d(2026, 4, 10),
          type: TransactionType.expense,
          supplierId: 'sup-1',
          supplierName: 'Costco',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows, hasLength(1));
      expect(vm.rows.first.payeeName, 'Costco');
      expect(vm.rows.first.totalMinor, 5000);
    });

    test('falls back to vendor when supplier is missing', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 3000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Tesco',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows, hasLength(1));
      expect(vm.rows.first.payeeName, 'Tesco');
    });

    test(
      'falls back to Unknown when neither supplier nor vendor is present',
      () {
        final DateTime today = d(2026, 4, 15);
        final List<TransactionData> txs = <TransactionData>[
          tx(
            id: 't1',
            amountMinor: 2000,
            occurredOn: d(2026, 4, 5),
            type: TransactionType.expense,
          ),
        ];
        final PayeeAnalyticsViewModel vm = service.buildViewModel(
          now: today,
          dataset: ds(txs),
          query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
          strings: strings,
        );
        expect(vm.rows, hasLength(1));
        expect(vm.rows.first.payeeName, 'Unknown');
      },
    );

    test('treats trimmed and case-variant names as same payee', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: '  6868  ',
        ),
        tx(
          id: 't2',
          amountMinor: 2000,
          occurredOn: d(2026, 4, 6),
          type: TransactionType.expense,
          vendor: '6868',
        ),
        tx(
          id: 't3',
          amountMinor: 3000,
          occurredOn: d(2026, 4, 7),
          type: TransactionType.expense,
          vendor: '  6868',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows, hasLength(1));
      expect(vm.rows.first.totalMinor, 6000);
      expect(vm.rows.first.payeeName, '6868');
    });

    test('collapses extra whitespace in payee names', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'JJ  Food  Service',
        ),
        tx(
          id: 't2',
          amountMinor: 2000,
          occurredOn: d(2026, 4, 6),
          type: TransactionType.expense,
          vendor: 'JJ Food Service',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows, hasLength(1));
      expect(vm.rows.first.totalMinor, 3000);
    });

    test('treats same name via supplier and vendor as same payee', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          supplierId: 'sup-1',
          supplierName: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 2000,
          occurredOn: d(2026, 4, 6),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows, hasLength(1));
      expect(vm.rows.first.totalMinor, 3000);
      expect(vm.rows.first.payeeName, 'Costco');
    });

    test('archived supplier still appears with its resolved name', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 7000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          supplierId: 'sup-archived',
          supplierName: 'Old Supplier Inc',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows, hasLength(1));
      expect(vm.rows.first.payeeName, 'Old Supplier Inc');
    });
  });

  group('PayeeAnalyticsService - exclusion rules', () {
    test('income transactions are never included', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 'income-1',
          amountMinor: 10000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.income,
          vendor: 'Walk-in sales',
        ),
        tx(
          id: 'exp-1',
          amountMinor: 5000,
          occurredOn: d(2026, 4, 6),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows, hasLength(1));
      expect(vm.rows.first.payeeName, 'Costco');
    });

    test('expenses outside the range are excluded', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 1, 5),
          type: TransactionType.expense,
          vendor: 'Old Vendor',
        ),
        tx(
          id: 't2',
          amountMinor: 2000,
          occurredOn: d(2026, 4, 6),
          type: TransactionType.expense,
          vendor: 'Current Vendor',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows, hasLength(1));
      expect(vm.rows.first.payeeName, 'Current Vendor');
    });
  });

  group('PayeeAnalyticsService - time range resolution', () {
    test('thisWeek starts on Monday', () {
      // 2026-04-15 is a Wednesday; Monday of that week is 2026-04-13
      final PayeeRange range = service.resolveRange(
        today: d(2026, 4, 15),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisWeek),
      );
      expect(range.start, d(2026, 4, 13));
      expect(range.end, d(2026, 4, 19));
    });

    test('lastWeek is the previous Monday-Sunday block', () {
      final PayeeRange range = service.resolveRange(
        today: d(2026, 4, 15),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.lastWeek),
      );
      expect(range.start, d(2026, 4, 6));
      expect(range.end, d(2026, 4, 12));
    });

    test('thisMonth and lastMonth cover full calendar months', () {
      final PayeeRange thisMonth = service.resolveRange(
        today: d(2026, 4, 15),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
      );
      expect(thisMonth.start, d(2026, 4, 1));
      expect(thisMonth.end, d(2026, 4, 30));

      final PayeeRange lastMonth = service.resolveRange(
        today: d(2026, 4, 15),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.lastMonth),
      );
      expect(lastMonth.start, d(2026, 3, 1));
      expect(lastMonth.end, d(2026, 3, 31));
    });

    test('last3Weeks covers 21 days including today', () {
      final PayeeRange range = service.resolveRange(
        today: d(2026, 4, 15),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.last3Weeks),
      );
      // Service normalises today to midnight local time then subtracts 20 days.
      final DateTime expectedStart = DateTime(
        2026,
        4,
        15,
      ).subtract(const Duration(days: 20));
      expect(range.start, expectedStart);
      expect(range.end, d(2026, 4, 15));
    });

    test('last1Month covers 30 days including today', () {
      final PayeeRange range = service.resolveRange(
        today: d(2026, 4, 15),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.last1Month),
      );
      final DateTime expectedStart = DateTime(
        2026,
        4,
        15,
      ).subtract(const Duration(days: 29));
      expect(range.start, expectedStart);
      expect(range.end, d(2026, 4, 15));
    });

    test('last2Months covers 60 days including today', () {
      final PayeeRange range = service.resolveRange(
        today: d(2026, 4, 15),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.last2Months),
      );
      final DateTime expectedStart = DateTime(
        2026,
        4,
        15,
      ).subtract(const Duration(days: 59));
      expect(range.start, expectedStart);
      expect(range.end, d(2026, 4, 15));
    });

    test('thisYear covers Jan 1 to Dec 31 of current year', () {
      final PayeeRange range = service.resolveRange(
        today: d(2026, 4, 15),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisYear),
      );
      expect(range.start, d(2026, 1, 1));
      expect(range.end, d(2026, 12, 31));
    });

    test('lastYear covers previous calendar year', () {
      final PayeeRange range = service.resolveRange(
        today: d(2026, 4, 15),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.lastYear),
      );
      expect(range.start, d(2026 - 1, 1, 1));
      expect(range.end, d(2026 - 1, 12, 31));
    });

    test('custom range normalizes reversed start/end', () {
      final PayeeRange range = service.resolveRange(
        today: d(2026, 4, 15),
        query: PayeeAnalyticsQuery(
          preset: PayeeRangePreset.custom,
          customStart: d(2026, 4, 20),
          customEnd: d(2026, 4, 10),
        ),
      );
      expect(range.start, d(2026, 4, 10));
      expect(range.end, d(2026, 4, 20));
    });
  });

  group('PayeeAnalyticsService - sorting and search', () {
    test('rows are sorted by total descending', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Small',
        ),
        tx(
          id: 't2',
          amountMinor: 5000,
          occurredOn: d(2026, 4, 6),
          type: TransactionType.expense,
          vendor: 'Big',
        ),
        tx(
          id: 't3',
          amountMinor: 3000,
          occurredOn: d(2026, 4, 7),
          type: TransactionType.expense,
          vendor: 'Medium',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows.map((PayeeRow r) => r.payeeName).toList(), <String>[
        'Big',
        'Medium',
        'Small',
      ]);
    });

    test('search filters by payee name case-insensitively', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 2000,
          occurredOn: d(2026, 4, 6),
          type: TransactionType.expense,
          vendor: 'Tesco',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(
          preset: PayeeRangePreset.thisMonth,
          searchQuery: 'cos',
        ),
        strings: strings,
      );
      expect(vm.rows, hasLength(1));
      expect(vm.rows.first.payeeName, 'Costco');
    });

    test('numeric search by payee name works', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: '6868',
        ),
        tx(
          id: 't2',
          amountMinor: 2000,
          occurredOn: d(2026, 4, 6),
          type: TransactionType.expense,
          vendor: 'Tesco',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(
          preset: PayeeRangePreset.thisMonth,
          searchQuery: '6868',
        ),
        strings: strings,
      );
      expect(vm.rows, hasLength(1));
      expect(vm.rows.first.payeeName, '6868');
    });
  });

  group('PayeeAnalyticsService - row metadata', () {
    test('row carries last payment date and transaction count', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 2000,
          occurredOn: d(2026, 4, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't3',
          amountMinor: 3000,
          occurredOn: d(2026, 4, 8),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows, hasLength(1));
      expect(vm.rows.first.transactionCount, 3);
      expect(vm.rows.first.totalMinor, 6000);
      expect(vm.rows.first.lastPaymentDate, d(2026, 4, 10));
    });

    test(
      'primary category is the one with the highest spend for that payee',
      () {
        final DateTime today = d(2026, 4, 15);
        final List<TransactionData> txs = <TransactionData>[
          tx(
            id: 't1',
            amountMinor: 5000,
            occurredOn: d(2026, 4, 5),
            type: TransactionType.expense,
            categoryName: 'Rent',
            vendor: 'Landlord',
          ),
          tx(
            id: 't2',
            amountMinor: 2000,
            occurredOn: d(2026, 4, 6),
            type: TransactionType.expense,
            categoryName: 'Maintenance',
            vendor: 'Landlord',
          ),
        ];
        final PayeeAnalyticsViewModel vm = service.buildViewModel(
          now: today,
          dataset: ds(txs),
          query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
          strings: strings,
        );
        expect(vm.rows.first.primaryCategory, 'Rent');
      },
    );

    test('works for any future expense category without hardcoded mapping', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          categoryName: 'Brand New Category 2099',
          vendor: 'FutureCo',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows.first.primaryCategory, 'Brand New Category 2099');
    });
  });

  group('PayeeAnalyticsService - detail view model', () {
    test('summary tiles cover all presets and lifetime', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 2000,
          occurredOn: d(2026, 4, 1),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't3',
          amountMinor: 3000,
          occurredOn: d(2026, 3, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't4',
          amountMinor: 4000,
          occurredOn: d(2025, 4, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't5',
          amountMinor: 5000,
          occurredOn: d(2026, 1, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
        now: today,
      );
      expect(detail.payeeName, 'Costco');
      expect(detail.transactionCount, 5);
      expect(detail.lifetimeTotalMinor, 15000);
      final Map<String, int> byLabel = <String, int>{
        for (final PayeeSummaryTile tile in detail.summaryTiles)
          tile.label: tile.totalMinor,
      };
      expect(byLabel[strings.paidThisWeek], 0);
      expect(byLabel[strings.paidLastWeek], 1000);
      expect(byLabel[strings.paidThisMonth], 3000);
      expect(byLabel[strings.paidLastMonth], 3000);
      expect(byLabel[strings.paidThisYear], 11000);
      expect(byLabel[strings.paidLastYear], 4000);
    });

    test('transactions are sorted newest first', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't-older',
          amountMinor: 1000,
          occurredOn: d(2026, 3, 1),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't-newest',
          amountMinor: 2000,
          occurredOn: d(2026, 4, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't-mid',
          amountMinor: 1500,
          occurredOn: d(2026, 4, 1),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
        now: today,
      );
      expect(
        detail.transactions.map((PayeeDetailTransaction t) => t.id).toList(),
        <String>['t-newest', 't-mid', 't-older'],
      );
    });

    test('detail only includes transactions for the matching payee', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 2000,
          occurredOn: d(2026, 4, 10),
          type: TransactionType.expense,
          vendor: 'Tesco',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
        now: today,
      );
      expect(detail.transactions, hasLength(1));
      expect(detail.transactions.first.id, 't1');
      expect(detail.lifetimeTotalMinor, 1000);
    });

    test(
      'detail excludes income transactions even if they share vendor name',
      () {
        final DateTime today = d(2026, 4, 15);
        final List<TransactionData> txs = <TransactionData>[
          tx(
            id: 't1',
            amountMinor: 1000,
            occurredOn: d(2026, 4, 10),
            type: TransactionType.expense,
            vendor: 'Costco',
          ),
          tx(
            id: 'income',
            amountMinor: 5000,
            occurredOn: d(2026, 4, 11),
            type: TransactionType.income,
            vendor: 'Costco',
          ),
        ];
        final PayeeDetailViewModel detail = service.buildDetailViewModel(
          dataset: ds(txs),
          payeeKey: 'costco',
          strings: strings,
          now: today,
        );
        expect(detail.transactionCount, 1);
        expect(detail.lifetimeTotalMinor, 1000);
      },
    );

    test('transaction history includes note and payment method', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
          paymentMethod: PaymentMethodType.cash,
          note: 'weekly stock',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
        now: today,
      );
      expect(detail.transactions.first.note, 'weekly stock');
      expect(detail.transactions.first.paymentMethod, PaymentMethodType.cash);
    });
  });

  group('PayeeAnalyticsService - staff fallback', () {
    test('uses staffName when supplier and vendor are missing', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 5000,
          occurredOn: d(2026, 4, 10),
          type: TransactionType.expense,
          categoryName: 'Staff Wages',
          staffName: 'Ali',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows, hasLength(1));
      expect(vm.rows.first.payeeName, 'Ali');
      expect(vm.rows.first.totalMinor, 5000);
    });

    test('Staff Wages with staffName does not end up under Unknown', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 3000,
          occurredOn: d(2026, 4, 8),
          type: TransactionType.expense,
          categoryName: 'Staff Wages',
          staffName: 'Ali',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows, hasLength(1));
      expect(vm.rows.first.payeeName, 'Ali');
      expect(vm.rows.first.payeeName, isNot(strings.unknownPayee));
    });

    test('supplierName takes priority over staffName', () {
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          supplierId: 'sup-1',
          supplierName: 'Costco',
          staffName: 'Ali',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: d(2026, 4, 15),
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows.first.payeeName, 'Costco');
    });

    test('vendor takes priority over staffName', () {
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Tesco',
          staffName: 'Ali',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: d(2026, 4, 15),
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows.first.payeeName, 'Tesco');
    });

    test('staffName normalizes case and whitespace like other fields', () {
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          staffName: '  Ali  ',
        ),
        tx(
          id: 't2',
          amountMinor: 2000,
          occurredOn: d(2026, 4, 6),
          type: TransactionType.expense,
          staffName: 'ali',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: d(2026, 4, 15),
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.rows, hasLength(1));
      expect(vm.rows.first.totalMinor, 3000);
    });
  });

  group('PayeeAnalyticsService - comparison metrics', () {
    test('this week vs last week computes difference and percent', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 'tw',
          amountMinor: 5000,
          occurredOn: d(2026, 4, 14),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 'lw',
          amountMinor: 3000,
          occurredOn: d(2026, 4, 7),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.comparisons, hasLength(3));
      final PayeeComparisonMetric weekCmp = vm.comparisons.first;
      expect(weekCmp.label, strings.thisWeekVsLastWeek);
      expect(weekCmp.currentMinor, 5000);
      expect(weekCmp.previousMinor, 3000);
      expect(weekCmp.differenceMinor, 2000);
      expect(weekCmp.percentChange, closeTo(66.7, 0.1));
    });

    test('this month vs last month computes correctly', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 'tm',
          amountMinor: 10000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 'lm',
          amountMinor: 4000,
          occurredOn: d(2026, 3, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      final PayeeComparisonMetric monthCmp = vm.comparisons[1];
      expect(monthCmp.label, strings.thisMonthVsLastMonth);
      expect(monthCmp.currentMinor, 10000);
      expect(monthCmp.previousMinor, 4000);
      expect(monthCmp.differenceMinor, 6000);
    });

    test('this year vs last year computes correctly', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 'ty',
          amountMinor: 20000,
          occurredOn: d(2026, 2, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 'ly',
          amountMinor: 15000,
          occurredOn: d(2025, 6, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      final PayeeComparisonMetric yearCmp = vm.comparisons[2];
      expect(yearCmp.label, strings.thisYearVsLastYear);
      expect(yearCmp.currentMinor, 20000);
      expect(yearCmp.previousMinor, 15000);
      expect(yearCmp.differenceMinor, 5000);
    });

    test('percent change is null when previous is zero', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 'tw',
          amountMinor: 5000,
          occurredOn: d(2026, 4, 14),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.comparisons.first.percentChange, isNull);
    });
  });

  group('PayeeAnalyticsService - top payees', () {
    test('top payees are limited to 10 and sorted by total descending', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        for (int i = 1; i <= 12; i++)
          tx(
            id: 't$i',
            amountMinor: i * 1000,
            occurredOn: d(2026, 4, 5),
            type: TransactionType.expense,
            vendor: 'Vendor$i',
          ),
      ];
      final PayeeAnalyticsViewModel vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(preset: PayeeRangePreset.thisMonth),
        strings: strings,
      );
      expect(vm.topPayees, hasLength(10));
      expect(vm.topPayees.first.totalMinor, 12000);
      expect(vm.topPayees.first.payeeName, 'Vendor12');
      expect(vm.topPayees.last.totalMinor, 3000);
      expect(vm.topPayees.last.payeeName, 'Vendor3');
    });
  });

  group('PayeeAnalyticsService - detail metrics', () {
    test('average, largest, smallest payment are correct', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 1),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 5000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't3',
          amountMinor: 3000,
          occurredOn: d(2026, 4, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
        now: today,
      );
      expect(detail.metrics.lifetimeTotalMinor, 9000);
      expect(detail.metrics.transactionCount, 3);
      expect(detail.metrics.averagePaymentMinor, 3000);
      expect(detail.metrics.largestPaymentMinor, 5000);
      expect(detail.metrics.smallestPaymentMinor, 1000);
    });

    test('average days between payments is correct', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 1),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't3',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 9),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
        now: today,
      );
      expect(detail.metrics.averageDaysBetween, 4.0);
    });

    test('average days is null for single transaction', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 1),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
        now: today,
      );
      expect(detail.metrics.averageDaysBetween, isNull);
    });

    test('metrics are zero for empty payee', () {
      final DateTime today = d(2026, 4, 15);
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: const PayeeAnalyticsDataset(
          transactions: <TransactionData>[],
          expenseCategoryIcons: <String, IconData>{},
        ),
        payeeKey: 'nobody',
        strings: strings,
        now: today,
      );
      expect(detail.metrics.lifetimeTotalMinor, 0);
      expect(detail.metrics.transactionCount, 0);
      expect(detail.metrics.averagePaymentMinor, 0);
    });
  });

  group('PayeeAnalyticsService - category breakdown', () {
    test('category breakdown shows totals, percentages, and counts', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 6000,
          occurredOn: d(2026, 4, 1),
          type: TransactionType.expense,
          categoryName: 'Rent',
          vendor: 'Landlord',
        ),
        tx(
          id: 't2',
          amountMinor: 3000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          categoryName: 'Maintenance',
          vendor: 'Landlord',
        ),
        tx(
          id: 't3',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 10),
          type: TransactionType.expense,
          categoryName: 'Rent',
          vendor: 'Landlord',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'landlord',
        strings: strings,
        now: today,
      );
      expect(detail.categoryBreakdown, hasLength(2));
      final PayeeCategoryBreakdown rent = detail.categoryBreakdown.first;
      expect(rent.categoryName, 'Rent');
      expect(rent.amountMinor, 7000);
      expect(rent.sharePercent, closeTo(70.0, 0.1));
      expect(rent.transactionCount, 2);
      final PayeeCategoryBreakdown maint = detail.categoryBreakdown[1];
      expect(maint.amountMinor, 3000);
      expect(maint.sharePercent, closeTo(30.0, 0.1));
      expect(maint.transactionCount, 1);
    });
  });

  group('PayeeAnalyticsService - trend datasets', () {
    test('weekly trend has 12 points', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
        now: today,
      );
      expect(detail.weeklyTrend, hasLength(12));
    });

    test('weekly trend includes matching transaction in correct week', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 14),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
        now: today,
      );
      final PayeeTrendPoint currentWeek = detail.weeklyTrend.last;
      expect(currentWeek.totalMinor, 1000);
      expect(currentWeek.transactionCount, 1);
      final PayeeTrendPoint earlierWeek = detail.weeklyTrend.first;
      expect(earlierWeek.totalMinor, 0);
    });

    test('monthly trend has 12 points', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
        now: today,
      );
      expect(detail.monthlyTrend, hasLength(12));
    });

    test('monthly trend includes matching transaction in correct month', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 2000,
          occurredOn: d(2026, 4, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 3000,
          occurredOn: d(2026, 3, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
        now: today,
      );
      final PayeeTrendPoint aprPoint = detail.monthlyTrend.last;
      expect(aprPoint.totalMinor, 2000);
      expect(aprPoint.transactionCount, 1);
      final PayeeTrendPoint marPoint =
          detail.monthlyTrend[detail.monthlyTrend.length - 2];
      expect(marPoint.totalMinor, 3000);
    });
  });

  group('PayeeAnalyticsService - supplier scorecard', () {
    test(
      'scorecard computes lifetime, this year, last year, this month, last month',
      () {
        final DateTime today = d(2026, 4, 15);
        final List<TransactionData> txs = <TransactionData>[
          tx(
            id: 't1',
            amountMinor: 5000,
            occurredOn: d(2026, 4, 5),
            type: TransactionType.expense,
            vendor: 'Costco',
          ),
          tx(
            id: 't2',
            amountMinor: 3000,
            occurredOn: d(2026, 3, 10),
            type: TransactionType.expense,
            vendor: 'Costco',
          ),
          tx(
            id: 't3',
            amountMinor: 7000,
            occurredOn: d(2025, 6, 10),
            type: TransactionType.expense,
            vendor: 'Costco',
          ),
        ];
        final SupplierScorecard sc = service.buildScorecard(
          dataset: ds(txs),
          payeeKey: 'costco',
          today: today,
        );
        expect(sc.lifetimeSpendMinor, 15000);
        expect(sc.thisYearMinor, 8000);
        expect(sc.lastYearMinor, 7000);
        expect(sc.thisMonthMinor, 5000);
        expect(sc.lastMonthMinor, 3000);
        expect(sc.transactionCount, 3);
      },
    );

    test('scorecard computes first and last purchase dates', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 2000,
          occurredOn: d(2025, 1, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't3',
          amountMinor: 3000,
          occurredOn: d(2026, 1, 20),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final SupplierScorecard sc = service.buildScorecard(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
      );
      expect(sc.firstPurchaseDate, d(2025, 1, 10));
      expect(sc.lastPurchaseDate, d(2026, 4, 5));
    });

    test('scorecard computes days since last purchase', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final SupplierScorecard sc = service.buildScorecard(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
      );
      expect(sc.daysSinceLastPurchase, 5);
    });

    test('scorecard computes average monthly and weekly spend', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 12000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 12000,
          occurredOn: d(2026, 1, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final SupplierScorecard sc = service.buildScorecard(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
      );
      expect(sc.lifetimeSpendMinor, 24000);
      expect(sc.averageMonthlySpendMinor, greaterThan(0));
      expect(sc.averageWeeklySpendMinor, greaterThan(0));
    });

    test('scorecard returns zeros for unknown payee', () {
      final DateTime today = d(2026, 4, 15);
      final SupplierScorecard sc = service.buildScorecard(
        dataset: const PayeeAnalyticsDataset(
          transactions: <TransactionData>[],
          expenseCategoryIcons: <String, IconData>{},
        ),
        payeeKey: 'nobody',
        today: today,
      );
      expect(sc.lifetimeSpendMinor, 0);
      expect(sc.transactionCount, 0);
      expect(sc.firstPurchaseDate, isNull);
      expect(sc.lastPurchaseDate, isNull);
    });
  });

  group('PayeeAnalyticsService - purchase frequency', () {
    test('computes average days between purchases', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 1),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't3',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 9),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PurchaseFrequency freq = service.buildPurchaseFrequency(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
      );
      expect(freq.averageDaysBetween, 4.0);
    });

    test('computes expected next purchase date', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 2),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 8),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PurchaseFrequency freq = service.buildPurchaseFrequency(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
      );
      expect(freq.expectedNextPurchaseDate, isNotNull);
      expect(freq.expectedNextPurchaseDate!.day, 14);
    });

    test('detects overdue when today is past expected next purchase', () {
      final DateTime today = d(2026, 4, 20);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 2),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 8),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PurchaseFrequency freq = service.buildPurchaseFrequency(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
      );
      expect(freq.isOverdue, isTrue);
      expect(freq.daysOverdue, greaterThan(0));
    });

    test('not overdue when within expected interval', () {
      final DateTime today = d(2026, 4, 10);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 2),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 8),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PurchaseFrequency freq = service.buildPurchaseFrequency(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
      );
      expect(freq.isOverdue, isFalse);
    });

    test('returns null for single transaction', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PurchaseFrequency freq = service.buildPurchaseFrequency(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
      );
      expect(freq.averageDaysBetween, isNull);
      expect(freq.expectedNextPurchaseDate, isNull);
    });
  });

  group('PayeeAnalyticsService - trend analysis', () {
    test('detects increasing trend', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 1, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 2000,
          occurredOn: d(2026, 2, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't3',
          amountMinor: 4000,
          occurredOn: d(2026, 3, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't4',
          amountMinor: 8000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final SupplierTrendAnalysis ta = service.buildTrendAnalysis(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
      );
      expect(ta.monthlyDirection, TrendDirection.increasing);
    });

    test('detects decreasing trend', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 8000,
          occurredOn: d(2026, 1, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 4000,
          occurredOn: d(2026, 2, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't3',
          amountMinor: 2000,
          occurredOn: d(2026, 3, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't4',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final SupplierTrendAnalysis ta = service.buildTrendAnalysis(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
      );
      expect(ta.monthlyDirection, TrendDirection.decreasing);
    });

    test('detects stable trend', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 3000,
          occurredOn: d(2026, 1, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 3000,
          occurredOn: d(2026, 2, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't3',
          amountMinor: 3000,
          occurredOn: d(2026, 3, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't4',
          amountMinor: 3000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final SupplierTrendAnalysis ta = service.buildTrendAnalysis(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
      );
      expect(ta.monthlyDirection, TrendDirection.stable);
    });

    test('insufficient data for trend with fewer than 3 months', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final SupplierTrendAnalysis ta = service.buildTrendAnalysis(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
      );
      expect(ta.monthlyDirection, TrendDirection.insufficient);
    });

    test('3-month moving average is correct', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 3000,
          occurredOn: d(2026, 2, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 6000,
          occurredOn: d(2026, 3, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't3',
          amountMinor: 9000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final SupplierTrendAnalysis ta = service.buildTrendAnalysis(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
      );
      expect(ta.threeMonthMovingAverageMinor, 6000);
    });

    test('year-over-year percent change is computed', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 20000,
          occurredOn: d(2026, 2, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 10000,
          occurredOn: d(2025, 2, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final SupplierTrendAnalysis ta = service.buildTrendAnalysis(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
      );
      expect(ta.yearOverYearPercentChange, closeTo(100.0, 0.1));
    });
  });

  group('PayeeAnalyticsService - biggest purchases', () {
    test('returns top 10 by amount descending', () {
      final List<TransactionData> txs = <TransactionData>[
        for (int i = 1; i <= 12; i++)
          tx(
            id: 't$i',
            amountMinor: i * 1000,
            occurredOn: d(2026, 4, 5),
            type: TransactionType.expense,
            vendor: 'Costco',
          ),
      ];
      final List<BiggestPurchase> purchases = service.buildBiggestPurchases(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
      );
      expect(purchases, hasLength(10));
      expect(purchases.first.amountMinor, 12000);
      expect(purchases.last.amountMinor, 3000);
    });

    test('includes date, amount, category, note', () {
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 5000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          categoryName: 'Stock Purchase',
          vendor: 'Costco',
          note: 'bulk order',
        ),
      ];
      final List<BiggestPurchase> purchases = service.buildBiggestPurchases(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
      );
      expect(purchases.first.note, 'bulk order');
      expect(purchases.first.categoryName, 'Stock Purchase');
      expect(purchases.first.date, d(2026, 4, 5));
    });
  });

  group('PayeeAnalyticsService - spending distribution', () {
    test('computes this week, last week, 30/90 days, 12 months, lifetime', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 'tw',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 14),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 'lw',
          amountMinor: 2000,
          occurredOn: d(2026, 4, 7),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 'd30',
          amountMinor: 3000,
          occurredOn: d(2026, 3, 20),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 'd90',
          amountMinor: 4000,
          occurredOn: d(2026, 1, 20),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 'm12',
          amountMinor: 5000,
          occurredOn: d(2025, 6, 10),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final SpendingDistribution dist = service.buildSpendingDistribution(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
      );
      expect(dist.thisWeekMinor, 1000);
      expect(dist.lastWeekMinor, 2000);
      expect(dist.last30DaysMinor, greaterThanOrEqualTo(3000));
      expect(dist.last90DaysMinor, greaterThanOrEqualTo(7000));
      expect(dist.last12MonthsMinor, greaterThanOrEqualTo(10000));
      expect(dist.lifetimeMinor, 15000);
    });
  });

  group('PayeeAnalyticsService - monthly history 24', () {
    test('generates 24 months of data', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 2000,
          occurredOn: d(2025, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final List<MonthlyHistoryPoint> history = service.buildMonthlyHistory24(
        dataset: ds(txs),
        payeeKey: 'costco',
        today: today,
        strings: strings,
      );
      expect(history, hasLength(24));
      expect(history.last.totalMinor, 1000);
      expect(history.last.transactionCount, 1);
      final MonthlyHistoryPoint lastYear = history[history.length - 13];
      expect(lastYear.totalMinor, 2000);
    });

    test('empty months have zero totals', () {
      final DateTime today = d(2026, 4, 15);
      final List<MonthlyHistoryPoint> history = service.buildMonthlyHistory24(
        dataset: const PayeeAnalyticsDataset(
          transactions: <TransactionData>[],
          expenseCategoryIcons: <String, IconData>{},
        ),
        payeeKey: 'costco',
        today: today,
        strings: strings,
      );
      expect(history, hasLength(24));
      for (final p in history) {
        expect(p.totalMinor, 0);
        expect(p.transactionCount, 0);
      }
    });
  });

  group('PayeeAnalyticsService - sorting', () {
    test('sorts by highest spend descending', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'A',
        ),
        tx(
          id: 't2',
          amountMinor: 5000,
          occurredOn: d(2026, 4, 6),
          type: TransactionType.expense,
          vendor: 'B',
        ),
        tx(
          id: 't3',
          amountMinor: 3000,
          occurredOn: d(2026, 4, 7),
          type: TransactionType.expense,
          vendor: 'C',
        ),
      ];
      final vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(
          preset: PayeeRangePreset.thisMonth,
          sortOption: SupplierSortOption.highestSpend,
        ),
        strings: strings,
      );
      expect(vm.rows.map((r) => r.payeeName).toList(), <String>['B', 'C', 'A']);
    });

    test('sorts by lowest spend', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'A',
        ),
        tx(
          id: 't2',
          amountMinor: 5000,
          occurredOn: d(2026, 4, 6),
          type: TransactionType.expense,
          vendor: 'B',
        ),
      ];
      final vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(
          preset: PayeeRangePreset.thisMonth,
          sortOption: SupplierSortOption.lowestSpend,
        ),
        strings: strings,
      );
      expect(vm.rows.first.payeeName, 'A');
    });

    test('sorts by most transactions', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'A',
        ),
        tx(
          id: 't2',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 6),
          type: TransactionType.expense,
          vendor: 'A',
        ),
        tx(
          id: 't3',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 7),
          type: TransactionType.expense,
          vendor: 'B',
        ),
      ];
      final vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(
          preset: PayeeRangePreset.thisMonth,
          sortOption: SupplierSortOption.mostTransactions,
        ),
        strings: strings,
      );
      expect(vm.rows.first.payeeName, 'A');
      expect(vm.rows.first.transactionCount, 2);
    });

    test('sorts by least transactions', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'A',
        ),
        tx(
          id: 't2',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 6),
          type: TransactionType.expense,
          vendor: 'A',
        ),
        tx(
          id: 't3',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 7),
          type: TransactionType.expense,
          vendor: 'B',
        ),
      ];
      final vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(
          preset: PayeeRangePreset.thisMonth,
          sortOption: SupplierSortOption.leastTransactions,
        ),
        strings: strings,
      );
      expect(vm.rows.first.payeeName, 'B');
    });

    test('sorts by recently used', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Old',
        ),
        tx(
          id: 't2',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 14),
          type: TransactionType.expense,
          vendor: 'Recent',
        ),
      ];
      final vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(
          preset: PayeeRangePreset.thisMonth,
          sortOption: SupplierSortOption.recentlyUsed,
        ),
        strings: strings,
      );
      expect(vm.rows.first.payeeName, 'Recent');
    });

    test('sorts by longest inactive', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 14),
          type: TransactionType.expense,
          vendor: 'Recent',
        ),
        tx(
          id: 't2',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Old',
        ),
      ];
      final vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(
          preset: PayeeRangePreset.thisMonth,
          sortOption: SupplierSortOption.longestInactive,
        ),
        strings: strings,
      );
      expect(vm.rows.first.payeeName, 'Old');
    });

    test('sorts alphabetically', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 5000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Zebra',
        ),
        tx(
          id: 't2',
          amountMinor: 1000,
          occurredOn: d(2026, 4, 6),
          type: TransactionType.expense,
          vendor: 'Alpha',
        ),
      ];
      final vm = service.buildViewModel(
        now: today,
        dataset: ds(txs),
        query: const PayeeAnalyticsQuery(
          preset: PayeeRangePreset.thisMonth,
          sortOption: SupplierSortOption.alphabetical,
        ),
        strings: strings,
      );
      expect(vm.rows.first.payeeName, 'Alpha');
      expect(vm.rows.last.payeeName, 'Zebra');
    });
  });

  group('PayeeAnalyticsService - alerts', () {
    test('generates inactivity alert for 30+ days', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 3, 1),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
        now: today,
      );
      final hasInactivity = detail.alerts.any(
        (a) => a.type == SupplierAlertType.inactivity,
      );
      expect(hasInactivity, isTrue);
    });

    test('generates spending increase alert', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 3, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 5000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't3',
          amountMinor: 2000,
          occurredOn: d(2026, 2, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't4',
          amountMinor: 1000,
          occurredOn: d(2026, 1, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
        now: today,
      );
      final hasIncrease = detail.alerts.any(
        (a) => a.type == SupplierAlertType.spendingIncrease,
      );
      expect(hasIncrease, isTrue);
    });

    test('generates highest month alert', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 1000,
          occurredOn: d(2026, 1, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 2000,
          occurredOn: d(2026, 2, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't3',
          amountMinor: 9000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
        now: today,
      );
      final hasHighest = detail.alerts.any(
        (a) => a.type == SupplierAlertType.highestMonth,
      );
      expect(hasHighest, isTrue);
    });

    test('no alerts for empty payee', () {
      final DateTime today = d(2026, 4, 15);
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: const PayeeAnalyticsDataset(
          transactions: <TransactionData>[],
          expenseCategoryIcons: <String, IconData>{},
        ),
        payeeKey: 'nobody',
        strings: strings,
        now: today,
      );
      expect(detail.alerts, isEmpty);
    });
  });

  group('PayeeAnalyticsService - detail view model integration', () {
    test('detail view model includes scorecard, trend, frequency, alerts', () {
      final DateTime today = d(2026, 4, 15);
      final List<TransactionData> txs = <TransactionData>[
        tx(
          id: 't1',
          amountMinor: 5000,
          occurredOn: d(2026, 4, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't2',
          amountMinor: 3000,
          occurredOn: d(2026, 3, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
        tx(
          id: 't3',
          amountMinor: 2000,
          occurredOn: d(2026, 2, 5),
          type: TransactionType.expense,
          vendor: 'Costco',
        ),
      ];
      final PayeeDetailViewModel detail = service.buildDetailViewModel(
        dataset: ds(txs),
        payeeKey: 'costco',
        strings: strings,
        now: today,
      );
      expect(detail.scorecard.lifetimeSpendMinor, 10000);
      expect(detail.trendAnalysis, isNotNull);
      expect(detail.purchaseFrequency, isNotNull);
      expect(detail.biggestPurchases, isNotEmpty);
      expect(detail.spendingDistribution, isNotNull);
      expect(detail.monthlyHistory, hasLength(24));
    });
  });
}
