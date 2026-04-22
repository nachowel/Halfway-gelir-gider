import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/core/domain/types.dart' show DomainValidationException;
import 'package:gider/data/app_models.dart';
import 'package:gider/data/app_repository.dart';
import 'package:gider/features/suppliers/presentation/suppliers_screen.dart';
import 'package:gider/shared/hi_fi/hi_fi_filter_chip.dart';
import 'package:gider/shared/hi_fi/hi_fi_icon_tile.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/localization_test_harness.dart';

class _MockGiderRepository extends Mock implements GiderRepository {}

class _FakeSupplierDraft extends Fake implements SupplierDraft {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeSupplierDraft());
  });

  const CategoryData rentCategory = CategoryData(
    id: 'cat-rent',
    type: CategoryType.expense,
    name: 'Rent',
    icon: Icons.home_rounded,
    tone: HiFiIconTileTone.expense,
    sortOrder: 0,
    isArchived: false,
    entryCount: 0,
    monthlyTotalMinor: 0,
  );

  const CategoryData suppliesCategory = CategoryData(
    id: 'cat-supplies',
    type: CategoryType.expense,
    name: 'Supplies',
    icon: Icons.shopping_bag_outlined,
    tone: HiFiIconTileTone.expense,
    sortOrder: 1,
    isArchived: false,
    entryCount: 0,
    monthlyTotalMinor: 0,
  );

  Widget buildApp({
    required GiderRepository repository,
    required Future<List<SupplierData>> Function(SuppliersQuery query)
    suppliersForQuery,
    List<CategoryData> categories = const <CategoryData>[
      rentCategory,
      suppliesCategory,
    ],
  }) {
    return ProviderScope(
      overrides: <Override>[
        giderRepositoryProvider.overrideWithValue(repository),
        expenseCategoriesProvider.overrideWith(
          (ref) async => categories,
        ),
        suppliersProvider.overrideWith((ref, query) => suppliersForQuery(query)),
        activeSuppliersProvider.overrideWith(
          (ref) => suppliersForQuery(const SuppliersQuery()),
        ),
      ],
      child: buildLocalizedScaffoldTestApp(
        child: const SuppliersScreen(),
      ),
    );
  }

  Finder _nameField() =>
      find.byKey(const ValueKey<String>('supplier-name-field'));

  Finder _saveButton() =>
      find.byKey(const ValueKey<String>('supplier-save-button'));

  Finder _categoryChip(String label) =>
      find.widgetWithText(HiFiFilterChip, label).last;

  testWidgets(
    'suppliers screen shows empty state when no suppliers exist',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final _MockGiderRepository repository = _MockGiderRepository();

      await tester.pumpWidget(
        buildApp(
          repository: repository,
          suppliersForQuery: (_) async => const <SupplierData>[],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No suppliers yet'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('supplier-add-action')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'suppliers screen renders populated rows and category filter',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final _MockGiderRepository repository = _MockGiderRepository();
      const SupplierData rentSupplier = SupplierData(
        id: 'supp-1',
        expenseCategoryId: 'cat-rent',
        expenseCategoryName: 'Rent',
        name: 'Acme Ltd',
        sortOrder: 0,
        isArchived: false,
      );
      const SupplierData suppliesSupplier = SupplierData(
        id: 'supp-2',
        expenseCategoryId: 'cat-supplies',
        expenseCategoryName: 'Supplies',
        name: 'Bravo Foods',
        sortOrder: 1,
        isArchived: false,
      );

      await tester.pumpWidget(
        buildApp(
          repository: repository,
          suppliersForQuery: (SuppliersQuery query) async {
            switch (query.expenseCategoryId) {
              case 'cat-rent':
                return const <SupplierData>[rentSupplier];
              case 'cat-supplies':
                return const <SupplierData>[suppliesSupplier];
              default:
                return const <SupplierData>[rentSupplier, suppliesSupplier];
            }
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acme Ltd'), findsOneWidget);
      expect(find.text('Bravo Foods'), findsOneWidget);

      await tester.tap(find.widgetWithText(HiFiFilterChip, 'Rent').first);
      await tester.pumpAndSettle();

      expect(find.text('Acme Ltd'), findsOneWidget);
      expect(find.text('Bravo Foods'), findsNothing);
    },
  );

  testWidgets('suppliers screen adds a supplier', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();
    when(
      () => repository.saveSupplier(
        id: any(named: 'id'),
        draft: any(named: 'draft'),
      ),
    ).thenAnswer(
      (_) async => const SupplierData(
        id: 'supp-1',
        expenseCategoryId: 'cat-rent',
        expenseCategoryName: 'Rent',
        name: 'Acme Ltd',
        sortOrder: 0,
        isArchived: false,
      ),
    );

    await tester.pumpWidget(
      buildApp(
        repository: repository,
        suppliersForQuery: (_) async => const <SupplierData>[],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('supplier-add-action')));
    await tester.pumpAndSettle();

    expect(find.text('Add supplier'), findsWidgets);

    await tester.tap(_saveButton());
    await tester.pumpAndSettle();
    expect(find.text('Supplier name is required'), findsOneWidget);
    expect(find.text('Category is required'), findsOneWidget);

    await tester.enterText(_nameField(), 'Acme Ltd');
    await tester.tap(_categoryChip('Rent'));
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    final VerificationResult verification = verify(
      () => repository.saveSupplier(
        id: captureAny(named: 'id'),
        draft: captureAny(named: 'draft'),
      ),
    );
    verification.called(1);
    expect(verification.captured, contains(null));
    final SupplierDraft draft = verification.captured
        .whereType<SupplierDraft>()
        .single;
    expect(draft.name, 'Acme Ltd');
    expect(draft.expenseCategoryId, 'cat-rent');
  });

  testWidgets(
    'suppliers screen surfaces duplicate rejection without closing editor',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final _MockGiderRepository repository = _MockGiderRepository();
      when(
        () => repository.saveSupplier(
          id: any(named: 'id'),
          draft: any(named: 'draft'),
        ),
      ).thenThrow(
        const DomainValidationException(
          code: 'supplier.duplicate_name',
          message: 'duplicate',
        ),
      );

      await tester.pumpWidget(
        buildApp(
          repository: repository,
          suppliersForQuery: (_) async => const <SupplierData>[],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('supplier-add-action')));
      await tester.pumpAndSettle();
      await tester.enterText(_nameField(), 'Acme Ltd');
      await tester.tap(_categoryChip('Rent'));
      await tester.pumpAndSettle();
      await tester.tap(_saveButton());
      await tester.pumpAndSettle();

      expect(
        find.text('A supplier with this name already exists in this category'),
        findsOneWidget,
      );
      expect(find.text('Add supplier'), findsWidgets);
    },
  );

  testWidgets('suppliers screen renames and recategorizes a supplier', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();
    when(
      () => repository.saveSupplier(
        id: any(named: 'id'),
        draft: any(named: 'draft'),
      ),
    ).thenAnswer(
      (_) async => const SupplierData(
        id: 'supp-1',
        expenseCategoryId: 'cat-supplies',
        expenseCategoryName: 'Supplies',
        name: 'Acme Wholesale',
        sortOrder: 0,
        isArchived: false,
      ),
    );

    await tester.pumpWidget(
      buildApp(
        repository: repository,
        suppliersForQuery: (_) async => const <SupplierData>[
          SupplierData(
            id: 'supp-1',
            expenseCategoryId: 'cat-rent',
            expenseCategoryName: 'Rent',
            name: 'Acme Ltd',
            sortOrder: 0,
            isArchived: false,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('supplier-row-supp-1')));
    await tester.pumpAndSettle();

    await tester.enterText(_nameField(), '');
    await tester.enterText(_nameField(), 'Acme Wholesale');
    await tester.tap(_categoryChip('Supplies'));
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    final VerificationResult verification = verify(
      () => repository.saveSupplier(
        id: captureAny(named: 'id'),
        draft: captureAny(named: 'draft'),
      ),
    );
    verification.called(1);
    expect(verification.captured, contains('supp-1'));
    final SupplierDraft draft = verification.captured
        .whereType<SupplierDraft>()
        .single;
    expect(draft.name, 'Acme Wholesale');
    expect(draft.expenseCategoryId, 'cat-supplies');
  });

  testWidgets('suppliers screen archives an existing supplier', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();
    when(
      () => repository.archiveSupplier(id: any(named: 'id')),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      buildApp(
        repository: repository,
        suppliersForQuery: (_) async => const <SupplierData>[
          SupplierData(
            id: 'supp-1',
            expenseCategoryId: 'cat-rent',
            expenseCategoryName: 'Rent',
            name: 'Acme Ltd',
            sortOrder: 0,
            isArchived: false,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('supplier-row-supp-1')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('supplier-archive-button')),
    );
    await tester.pumpAndSettle();

    verify(() => repository.archiveSupplier(id: 'supp-1')).called(1);
  });

  testWidgets('archived supplier drops from active list after refresh', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();
    when(
      () => repository.archiveSupplier(id: any(named: 'id')),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          giderRepositoryProvider.overrideWithValue(repository),
          expenseCategoriesProvider.overrideWith(
            (ref) async => const <CategoryData>[rentCategory],
          ),
          suppliersProvider.overrideWith((ref, query) async {
            final int refreshKey = ref.watch(refreshKeyProvider);
            if (refreshKey == 0) {
              return const <SupplierData>[
                SupplierData(
                  id: 'supp-1',
                  expenseCategoryId: 'cat-rent',
                  expenseCategoryName: 'Rent',
                  name: 'Acme Ltd',
                  sortOrder: 0,
                  isArchived: false,
                ),
              ];
            }
            return const <SupplierData>[];
          }),
          activeSuppliersProvider.overrideWith((ref) async {
            final int refreshKey = ref.watch(refreshKeyProvider);
            if (refreshKey == 0) {
              return const <SupplierData>[
                SupplierData(
                  id: 'supp-1',
                  expenseCategoryId: 'cat-rent',
                  expenseCategoryName: 'Rent',
                  name: 'Acme Ltd',
                  sortOrder: 0,
                  isArchived: false,
                ),
              ];
            }
            return const <SupplierData>[];
          }),
        ],
        child: buildLocalizedScaffoldTestApp(
          child: const SuppliersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acme Ltd'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('supplier-row-supp-1')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('supplier-archive-button')),
    );
    await tester.pumpAndSettle();

    verify(() => repository.archiveSupplier(id: 'supp-1')).called(1);
    expect(find.text('Acme Ltd'), findsNothing);
    expect(find.text('No suppliers yet'), findsOneWidget);
  });
}
