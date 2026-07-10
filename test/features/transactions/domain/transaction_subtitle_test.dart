import 'package:flutter_test/flutter_test.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/features/transactions/domain/transaction_subtitle.dart';

void main() {
  String paymentLabel(PaymentMethodType value) {
    switch (value) {
      case PaymentMethodType.cash:
        return 'Cash';
      case PaymentMethodType.card:
        return 'Card';
      case PaymentMethodType.bankTransfer:
        return 'Bank';
      case PaymentMethodType.other:
        return 'Other';
    }
  }

  String platformLabel(SourcePlatformType value) {
    switch (value) {
      case SourcePlatformType.uber:
        return 'Uber Eats';
      case SourcePlatformType.justEat:
        return 'Just Eat';
      case SourcePlatformType.direct:
        return 'Direct';
      case SourcePlatformType.other:
        return 'Other';
    }
  }

  TransactionData build({
    TransactionType type = TransactionType.expense,
    String? vendor,
    String? supplierName,
    String? supplierId,
    String? staffName,
    String? note,
    String categoryName = 'Stock Purchase',
    PaymentMethodType paymentMethod = PaymentMethodType.card,
    SourcePlatformType? sourcePlatform,
  }) {
    return TransactionData(
      id: 'tx',
      type: type,
      occurredOn: DateTime(2026, 4, 15),
      amountMinor: 10000,
      categoryId: 'cat',
      categoryName: categoryName,
      paymentMethod: paymentMethod,
      createdAt: DateTime(2026, 4, 15),
      sourcePlatform: sourcePlatform,
      vendor: vendor,
      supplierId: supplierId,
      supplierName: supplierName,
      staffName: staffName,
      note: note,
    );
  }

  group('buildTransactionTitle', () {
    test('uses expense supplier, vendor, or staff name as primary title', () {
      expect(
        buildTransactionTitle(
          build(
            categoryName: 'Stock Purchase',
            supplierName: 'Bread Bacon',
            vendor: 'Backup Vendor',
          ),
        ),
        'Bread Bacon',
      );
      expect(
        buildTransactionTitle(
          build(categoryName: 'Stock Purchase', vendor: '6868 Catering'),
        ),
        '6868 Catering',
      );
      expect(
        buildTransactionTitle(
          build(categoryName: 'Staff Wages', staffName: 'Yusuf abi'),
        ),
        'Yusuf abi',
      );
    });

    test(
      'prioritizes staff name for Staff Wages when payee fields conflict',
      () {
        expect(
          buildTransactionTitle(
            build(
              categoryName: 'Staff Wages',
              supplierName: 'Old Payroll Supplier',
              vendor: 'Legacy payroll note',
              staffName: 'Yusuf abi',
            ),
          ),
          'Yusuf abi',
        );
      },
    );

    test('prioritizes supplier then vendor for stock purchases', () {
      expect(
        buildTransactionTitle(
          build(
            categoryName: 'Stock Purchase',
            supplierName: 'Bread Bacon',
            vendor: '6868 Catering',
            staffName: 'Yusuf abi',
          ),
        ),
        'Bread Bacon',
      );
      expect(
        buildTransactionTitle(
          build(
            categoryName: 'Stock Purchase',
            supplierName: null,
            vendor: '6868 Catering',
            staffName: 'Yusuf abi',
          ),
        ),
        '6868 Catering',
      );
    });

    test('uses the strongest non-staff payee for other expenses', () {
      expect(
        buildTransactionTitle(
          build(
            categoryName: 'Maintenance',
            supplierName: 'Acme Repairs',
            vendor: 'Receipt counter text',
            staffName: 'Yusuf abi',
          ),
        ),
        'Acme Repairs',
      );
      expect(
        buildTransactionTitle(
          build(
            categoryName: 'Maintenance',
            supplierName: null,
            vendor: 'Receipt counter text',
            staffName: 'Yusuf abi',
          ),
        ),
        'Receipt counter text',
      );
    });

    test('falls back to category name when expense payee is empty', () {
      expect(
        buildTransactionTitle(
          build(
            categoryName: 'Stock Purchase',
            vendor: '   ',
            supplierName: null,
            staffName: null,
          ),
        ),
        'Stock Purchase',
      );
    });

    test('keeps income title as category name', () {
      expect(
        buildTransactionTitle(
          build(
            type: TransactionType.income,
            categoryName: 'Card Sales',
            vendor: 'Uber Eats payout',
          ),
        ),
        'Card Sales',
      );
    });
  });

  group('buildTransactionSubtitle', () {
    test('uses category and payment when expense has resolved supplier', () {
      final result = buildTransactionSubtitle(
        transaction: build(
          supplierId: 'sup-1',
          supplierName: 'Best Vendor',
          vendor: 'Costco',
          note: 'monthly order',
        ),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Stock Purchase · Card');
    });

    test('uses category and payment method for expense rows', () {
      final result = buildTransactionSubtitle(
        transaction: build(
          categoryName: 'Staff Wages',
          staffName: 'Yusuf abi',
          paymentMethod: PaymentMethodType.cash,
        ),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Staff Wages · Cash');
    });

    test(
      'keeps expense subtitle to category and payment when payee is blank',
      () {
        final result = buildTransactionSubtitle(
          transaction: build(
            categoryName: 'Fuel',
            vendor: '  ',
            paymentMethod: PaymentMethodType.cash,
          ),
          paymentLabel: paymentLabel,
          sourcePlatformLabel: platformLabel,
        );
        expect(result, 'Fuel · Cash');
      },
    );

    test('does not append expense note or source platform to subtitle', () {
      final result = buildTransactionSubtitle(
        transaction: build(
          categoryName: 'Stock Purchase',
          vendor: 'Bread Bacon',
          note: 'Milk, bread',
          sourcePlatform: SourcePlatformType.direct,
        ),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Stock Purchase · Card');
    });

    test('truncates long notes with ellipsis at 28 characters', () {
      final result = buildTransactionSubtitle(
        transaction: build(
          type: TransactionType.income,
          categoryName: 'Card Sales',
          vendor: 'Lidl',
          note: 'Weekly groceries for the cafe, milk bread eggs butter',
        ),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result.contains('…'), isTrue);
      final String notePart = result.split(' · ')[1];
      expect(notePart.length, lessThanOrEqualTo(29));
    });

    test('ignores empty or whitespace-only notes', () {
      final result = buildTransactionSubtitle(
        transaction: build(
          type: TransactionType.income,
          categoryName: 'Card Sales',
          vendor: 'Costco',
          note: '   ',
        ),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Costco · Card');
    });

    test('ignores null notes', () {
      final result = buildTransactionSubtitle(
        transaction: build(
          type: TransactionType.income,
          categoryName: 'Card Sales',
          vendor: 'Costco',
          note: null,
        ),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Costco · Card');
    });

    test(
      'falls back to category and payment when vendor and supplier are empty',
      () {
        final result = buildTransactionSubtitle(
          transaction: build(
            categoryName: 'Rent',
            vendor: null,
            supplierName: null,
            note: 'april rent',
          ),
          paymentLabel: paymentLabel,
          sourcePlatformLabel: platformLabel,
        );
        expect(result, 'Rent · Card');
      },
    );

    test('appends source platform for income transactions', () {
      final result = buildTransactionSubtitle(
        transaction: TransactionData(
          id: 'tx',
          type: TransactionType.income,
          occurredOn: DateTime(2026, 4, 15),
          amountMinor: 10000,
          categoryId: 'cat',
          categoryName: 'Card Sales',
          paymentMethod: PaymentMethodType.card,
          createdAt: DateTime(2026, 4, 15),
          sourcePlatform: SourcePlatformType.uber,
          vendor: 'Uber Eats payout',
        ),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Uber Eats payout · Card · Uber Eats');
    });

    test('uses category and payment for expense without platform', () {
      final result = buildTransactionSubtitle(
        transaction: build(
          vendor: 'Tesco',
          paymentMethod: PaymentMethodType.cash,
        ),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Stock Purchase · Cash');
    });

    test('uses category and payment when archived supplier resolves', () {
      final result = buildTransactionSubtitle(
        transaction: build(
          supplierId: 'sup-archived',
          supplierName: 'Old Supplier Inc',
        ),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Stock Purchase · Card');
    });

    test('uses category and payment when supplier name is missing', () {
      final result = buildTransactionSubtitle(
        transaction: build(
          supplierId: 'sup-deleted',
          supplierName: null,
          vendor: 'Fallback Vendor',
        ),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Stock Purchase · Card');
    });
  });
}
