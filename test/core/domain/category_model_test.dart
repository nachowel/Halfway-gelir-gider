import 'package:flutter_test/flutter_test.dart';
import 'package:gider/core/domain/category_model.dart';
import 'package:gider/core/domain/types.dart';

void main() {
  group('CategoryModel.fromPayload', () {
    test('accepts a valid payload', () {
      final CategoryModel model = CategoryModel.fromPayload(
        id: 'cat-income-cash',
        type: 'income',
        name: ' Cash Sales ',
        icon: 'storefront_rounded',
        colorToken: 'income',
        sortOrder: 0,
      );

      expect(model.id, 'cat-income-cash');
      expect(model.type, CategoryType.income);
      expect(model.name, 'Cash Sales');
      expect(model.icon, 'storefront_rounded');
      expect(model.colorToken, 'income');
      expect(model.sortOrder, 0);
      expect(model.isArchived, isFalse);
    });

    test('rejects blank names', () {
      expect(
        () => CategoryModel.fromPayload(type: 'expense', name: '   '),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'category_name.required',
          ),
        ),
      );
    });

    test('rejects negative sort_order', () {
      expect(
        () => CategoryModel.fromPayload(
          type: 'expense',
          name: 'Rent',
          sortOrder: -1,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'category.sort_order.invalid',
          ),
        ),
      );
    });
  });
}
