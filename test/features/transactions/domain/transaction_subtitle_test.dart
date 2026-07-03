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
    String? vendor,
    String? supplierName,
    String? supplierId,
    String? note,
    String categoryName = 'Stock Purchase',
    PaymentMethodType paymentMethod = PaymentMethodType.card,
    SourcePlatformType? sourcePlatform,
  }) {
    return TransactionData(
      id: 'tx',
      type: TransactionType.expense,
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
      note: note,
    );
  }

  group('buildTransactionTitle', () {
    test('returns category name regardless of vendor or supplier', () {
      expect(
        buildTransactionTitle(build(categoryName: 'Staff Wages')),
        'Staff Wages',
      );
      expect(
        buildTransactionTitle(
          build(categoryName: 'Stock Purchase', vendor: 'Costco'),
        ),
        'Stock Purchase',
      );
    });
  });

  group('buildTransactionSubtitle', () {
    test('uses supplier name when linked supplier resolves', () {
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
      expect(result, 'Best Vendor · monthly order · Card');
    });

    test('falls back to vendor when no supplier is linked', () {
      final result = buildTransactionSubtitle(
        transaction: build(vendor: 'Costco'),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Costco · Card');
    });

    test('trims whitespace vendor and uses it when present', () {
      final result = buildTransactionSubtitle(
        transaction: build(vendor: '   Costco   '),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Costco · Card');
    });

    test('appends note after vendor when note is short', () {
      final result = buildTransactionSubtitle(
        transaction: build(vendor: 'Lidl', note: 'Milk, bread'),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Lidl · Milk, bread · Card');
    });

    test('truncates long notes with ellipsis at 28 characters', () {
      final result = buildTransactionSubtitle(
        transaction: build(
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
        transaction: build(vendor: 'Costco', note: '   '),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Costco · Card');
    });

    test('ignores null notes', () {
      final result = buildTransactionSubtitle(
        transaction: build(vendor: 'Costco', note: null),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Costco · Card');
    });

    test('falls back to category and payment when vendor and supplier are empty', () {
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
    });

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

    test('does not append source platform for expense without platform', () {
      final result = buildTransactionSubtitle(
        transaction: build(vendor: 'Tesco', paymentMethod: PaymentMethodType.cash),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Tesco · Cash');
    });

    test('archived supplier still appears with its resolved name', () {
      final result = buildTransactionSubtitle(
        transaction: build(
          supplierId: 'sup-archived',
          supplierName: 'Old Supplier Inc',
        ),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Old Supplier Inc · Card');
    });

    test('supplier id without resolved name falls back to vendor', () {
      final result = buildTransactionSubtitle(
        transaction: build(
          supplierId: 'sup-deleted',
          supplierName: null,
          vendor: 'Fallback Vendor',
        ),
        paymentLabel: paymentLabel,
        sourcePlatformLabel: platformLabel,
      );
      expect(result, 'Fallback Vendor · Card');
    });
  });
}
