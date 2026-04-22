import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/core/domain/types.dart' show DomainValidationException;
import 'package:gider/data/app_models.dart';
import 'package:gider/data/app_repository.dart';
import 'package:gider/features/entry/presentation/entry_screen.dart';
import 'package:gider/l10n/app_localizations.dart';
import 'package:gider/shared/hi_fi/hi_fi_filter_chip.dart';
import 'package:gider/shared/hi_fi/hi_fi_icon_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockGiderRepository extends Mock implements GiderRepository {}

class _FakeEntryDraft extends Fake implements EntryDraft {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppTheme.configure();
    registerFallbackValue(_FakeEntryDraft());
  });

  final List<CategoryData> incomeCategories = <CategoryData>[
    const CategoryData(
      id: 'income-cash',
      type: CategoryType.income,
      name: 'Cash Sales',
      icon: Icons.storefront_rounded,
      tone: HiFiIconTileTone.income,
      sortOrder: 0,
      isArchived: false,
      entryCount: 0,
      monthlyTotalMinor: 0,
    ),
    const CategoryData(
      id: 'income-card',
      type: CategoryType.income,
      name: 'Card Sales',
      icon: Icons.credit_card_rounded,
      tone: HiFiIconTileTone.income,
      sortOrder: 0,
      isArchived: false,
      entryCount: 0,
      monthlyTotalMinor: 0,
    ),
    const CategoryData(
      id: 'income-uber',
      type: CategoryType.income,
      name: 'Uber Settlement',
      icon: Icons.directions_car_filled_rounded,
      tone: HiFiIconTileTone.income,
      sortOrder: 1,
      isArchived: false,
      entryCount: 0,
      monthlyTotalMinor: 0,
    ),
    const CategoryData(
      id: 'income-just-eat',
      type: CategoryType.income,
      name: 'Just Eat Settlement',
      icon: Icons.delivery_dining_rounded,
      tone: HiFiIconTileTone.income,
      sortOrder: 2,
      isArchived: false,
      entryCount: 0,
      monthlyTotalMinor: 0,
    ),
    const CategoryData(
      id: 'income-other',
      type: CategoryType.income,
      name: 'Other Income',
      icon: Icons.work_outline_rounded,
      tone: HiFiIconTileTone.income,
      sortOrder: 3,
      isArchived: false,
      entryCount: 0,
      monthlyTotalMinor: 0,
    ),
  ];

  final List<CategoryData> expenseCategories = <CategoryData>[
    const CategoryData(
      id: 'expense-rent',
      type: CategoryType.expense,
      name: 'Rent',
      icon: Icons.home_rounded,
      tone: HiFiIconTileTone.expense,
      sortOrder: 0,
      isArchived: false,
      entryCount: 0,
      monthlyTotalMinor: 0,
    ),
    const CategoryData(
      id: 'expense-supplies',
      type: CategoryType.expense,
      name: 'Supplies',
      icon: Icons.shopping_bag_outlined,
      tone: HiFiIconTileTone.expense,
      sortOrder: 1,
      isArchived: false,
      entryCount: 0,
      monthlyTotalMinor: 0,
    ),
  ];

  final List<SupplierData> supplierCatalog = <SupplierData>[
    const SupplierData(
      id: 'supp-1',
      expenseCategoryId: 'expense-rent',
      expenseCategoryName: 'Rent',
      name: 'Acme Ltd',
      sortOrder: 0,
      isArchived: false,
    ),
    const SupplierData(
      id: 'supp-2',
      expenseCategoryId: 'expense-supplies',
      expenseCategoryName: 'Supplies',
      name: 'Paper Depot',
      sortOrder: 1,
      isArchived: false,
    ),
    const SupplierData(
      id: 'supp-archived',
      expenseCategoryId: 'expense-rent',
      expenseCategoryName: 'Rent',
      name: 'Legacy Fuel',
      sortOrder: 2,
      isArchived: true,
    ),
  ];

  List<Override> supplierOverrides(List<SupplierData>? availableSuppliers) {
    final List<SupplierData> suppliers = availableSuppliers ?? supplierCatalog;
    return <Override>[
      suppliersProvider.overrideWith((ref, query) async {
        return suppliers.where((SupplierData supplier) {
          final bool matchesArchived =
              query.includeArchived || !supplier.isArchived;
          final bool matchesCategory =
              query.expenseCategoryId == null ||
              supplier.expenseCategoryId == query.expenseCategoryId;
          return matchesArchived && matchesCategory;
        }).toList();
      }),
      activeSuppliersProvider.overrideWith((ref) async {
        return suppliers.where((SupplierData supplier) {
          return !supplier.isArchived;
        }).toList();
      }),
    ];
  }

  Widget buildApp({
    required EntryKind kind,
    required GiderRepository repository,
    List<SupplierData>? availableSuppliers,
  }) {
    return ProviderScope(
      overrides: <Override>[
        giderRepositoryProvider.overrideWithValue(repository),
        incomeCategoriesProvider.overrideWith((ref) async => incomeCategories),
        expenseCategoriesProvider.overrideWith(
          (ref) async => expenseCategories,
        ),
        ...supplierOverrides(availableSuppliers),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.globalDelegates,
        home: Scaffold(body: EntryScreen(kind: kind)),
      ),
    );
  }

  Widget buildRouterApp({
    required GiderRepository repository,
    required String initialLocation,
    List<SupplierData>? availableSuppliers,
  }) {
    final GoRouter router = GoRouter(
      initialLocation: initialLocation,
      routes: <RouteBase>[
        GoRoute(
          path: '/summary',
          builder: (BuildContext context, GoRouterState state) {
            return Scaffold(
              body: Column(
                children: <Widget>[
                  const Text('Summary screen'),
                  TextButton(
                    onPressed: () => context.push('/entry/income'),
                    child: const Text('Open income'),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.push('/entry/expense?transactionId=tx-del'),
                    child: const Text('Open expense edit'),
                  ),
                ],
              ),
            );
          },
        ),
        GoRoute(
          path: '/entry/:kind',
          builder: (BuildContext context, GoRouterState state) {
            final EntryKind kind = state.pathParameters['kind'] == 'income'
                ? EntryKind.income
                : EntryKind.expense;
            return Scaffold(
              body: EntryScreen(
                kind: kind,
                transactionId: state.uri.queryParameters['transactionId'],
              ),
            );
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: <Override>[
        giderRepositoryProvider.overrideWithValue(repository),
        incomeCategoriesProvider.overrideWith((ref) async => incomeCategories),
        expenseCategoriesProvider.overrideWith(
          (ref) async => expenseCategories,
        ),
        ...supplierOverrides(availableSuppliers),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.globalDelegates,
        routerConfig: router,
      ),
    );
  }

  testWidgets(
    'income entry submits createTransaction with mapped income type',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final _MockGiderRepository repository = _MockGiderRepository();
      when(() => repository.createTransaction(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildApp(kind: EntryKind.income, repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gelir tipi sec'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('entry-supplier-selector')),
        findsNothing,
      );

      await tester.enterText(find.byType(TextField).first, '124.00');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gelir tipi sec'));
      await tester.pumpAndSettle();
      expect(find.text('Nakit satis'), findsOneWidget);
      expect(find.text('Kart satis'), findsOneWidget);
      expect(find.text('Uber mutabakati'), findsOneWidget);
      await tester.tap(find.text('Uber mutabakati'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Geliri kaydet'));
      await tester.pumpAndSettle();

      final VerificationResult verifyResult = verify(
        () => repository.createTransaction(captureAny()),
      );
      verifyResult.called(1);
      final EntryDraft draft = verifyResult.captured.single as EntryDraft;
      expect(draft.type, TransactionType.income);
      expect(draft.categoryId, 'income-uber');
      expect(draft.amountMinor, 12400);
      expect(draft.paymentMethod, PaymentMethodType.bankTransfer);
      expect(draft.sourcePlatform, SourcePlatformType.uber);
      expect(draft.vendor, isNull);
      expect(draft.supplierId, isNull);
    },
  );

  testWidgets('selecting Uber income type snaps occurredOn to Sunday', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();
    when(() => repository.createTransaction(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      buildApp(kind: EntryKind.income, repository: repository),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Haftalik mutabakat · bu hafta icin Pazartesi-Pazar toplamini girin',
      ),
      findsNothing,
    );

    await tester.tap(find.text('Gelir tipi sec'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uber mutabakati'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Haftalik mutabakat · bu hafta icin Pazartesi-Pazar toplamini girin',
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).first, '240.00');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Geliri kaydet'));
    await tester.pumpAndSettle();

    final VerificationResult verifyResult = verify(
      () => repository.createTransaction(captureAny()),
    );
    verifyResult.called(1);
    final EntryDraft draft = verifyResult.captured.single as EntryDraft;
    expect(draft.sourcePlatform, SourcePlatformType.uber);
    expect(draft.paymentMethod, PaymentMethodType.bankTransfer);
    expect(draft.occurredOn.weekday, DateTime.sunday);
    expect(draft.supplierId, isNull);
  });

  testWidgets('other income type opens manual payment selection', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();
    when(() => repository.createTransaction(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      buildApp(kind: EntryKind.income, repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '55.00');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gelir tipi sec'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diger'));
    await tester.pumpAndSettle();

    expect(find.text('Odeme yontemi'), findsOneWidget);

    await tester.tap(find.text('Nakit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Geliri kaydet'));
    await tester.pumpAndSettle();

    final VerificationResult verifyResult = verify(
      () => repository.createTransaction(captureAny()),
    );
    final EntryDraft draft = verifyResult.captured.single as EntryDraft;
    expect(draft.categoryId, 'income-other');
    expect(draft.paymentMethod, PaymentMethodType.cash);
    expect(draft.sourcePlatform, SourcePlatformType.other);
    expect(draft.vendor, isNull);
    expect(draft.supplierId, isNull);
  });

  testWidgets(
    'expense create submits without supplier selection and preserves vendor text',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final _MockGiderRepository repository = _MockGiderRepository();
      when(() => repository.createTransaction(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildApp(kind: EntryKind.expense, repository: repository),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '42.00');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rent'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kart'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'Wholesale Ltd');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gideri kaydet'));
      await tester.pumpAndSettle();

      final VerificationResult verifyResult = verify(
        () => repository.createTransaction(captureAny()),
      );
      verifyResult.called(1);
      final EntryDraft draft = verifyResult.captured.single as EntryDraft;
      expect(draft.type, TransactionType.expense);
      expect(draft.categoryId, 'expense-rent');
      expect(draft.vendor, 'Wholesale Ltd');
      expect(draft.supplierId, isNull);
    },
  );

  testWidgets('expense create submits with supplier from selected category', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();
    when(() => repository.createTransaction(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      buildApp(kind: EntryKind.expense, repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '42.00');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rent'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('entry-supplier-selector')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acme Ltd'), findsOneWidget);
    expect(find.text('Paper Depot'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('entry-supplier-option-supp-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acme Ltd'), findsWidgets);

    await tester.tap(find.text('Kart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gideri kaydet'));
    await tester.pumpAndSettle();

    final VerificationResult verifyResult = verify(
      () => repository.createTransaction(captureAny()),
    );
    verifyResult.called(1);
    final EntryDraft draft = verifyResult.captured.single as EntryDraft;
    expect(draft.categoryId, 'expense-rent');
    expect(draft.supplierId, 'supp-1');
  });

  testWidgets('successful income save pops back when entry was pushed', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();
    when(() => repository.createTransaction(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      buildRouterApp(repository: repository, initialLocation: '/summary'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open income'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '124.00');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gelir tipi sec'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uber mutabakati'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Geliri kaydet'));
    await tester.pump();

    expect(find.text('Kaydedildi ✓'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Summary screen'), findsOneWidget);
    expect(find.text('Geliri kaydet'), findsNothing);
    verify(() => repository.createTransaction(any())).called(1);
  });

  testWidgets(
    'successful income save falls back to summary when no back stack exists',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final _MockGiderRepository repository = _MockGiderRepository();
      when(() => repository.createTransaction(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildRouterApp(
          repository: repository,
          initialLocation: '/entry/income',
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '124.00');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gelir tipi sec'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kart satis'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Geliri kaydet'));
      await tester.pump();

      expect(find.text('Kaydedildi ✓'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Summary screen'), findsOneWidget);
      expect(find.text('Geliri kaydet'), findsNothing);
    },
  );

  testWidgets('income save does not double submit while request is in flight', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final Completer<void> completer = Completer<void>();
    final _MockGiderRepository repository = _MockGiderRepository();
    when(
      () => repository.createTransaction(any()),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      buildApp(kind: EntryKind.income, repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '124.00');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gelir tipi sec'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kart satis'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Geliri kaydet'));
    await tester.tap(find.text('Geliri kaydet'), warnIfMissed: false);
    await tester.pump();

    verify(() => repository.createTransaction(any())).called(1);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('income save failure keeps the user on the form', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();
    when(() => repository.createTransaction(any())).thenThrow(
      const DomainValidationException(
        code: 'save.failed',
        message: 'Kayit kaydedilemedi',
      ),
    );

    await tester.pumpWidget(
      buildRouterApp(repository: repository, initialLocation: '/entry/income'),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '124.00');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gelir tipi sec'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kart satis'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Geliri kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Geliri kaydet'), findsOneWidget);
    expect(find.text('Summary screen'), findsNothing);
    expect(find.text('Kayit kaydedilemedi'), findsOneWidget);
  });

  _MockGiderRepository _editRepository({
    required TransactionData? preload,
    bool preloadThrows = false,
    Future<void> Function()? onUpdate,
    Future<void> Function()? onDelete,
  }) {
    final repository = _MockGiderRepository();
    if (preloadThrows) {
      when(
        () => repository.fetchTransaction(id: any(named: 'id')),
      ).thenThrow(Exception('network error'));
    } else {
      when(
        () => repository.fetchTransaction(id: any(named: 'id')),
      ).thenAnswer((_) async => preload);
    }
    when(
      () => repository.updateTransaction(
        id: any(named: 'id'),
        draft: any(named: 'draft'),
      ),
    ).thenAnswer((_) => onUpdate?.call() ?? Future<void>.value());
    when(
      () => repository.deleteTransaction(id: any(named: 'id')),
    ).thenAnswer((_) => onDelete?.call() ?? Future<void>.value());
    return repository;
  }

  ProviderScope _editScope({
    required GiderRepository repository,
    required EntryKind kind,
    required String transactionId,
    List<SupplierData>? availableSuppliers,
  }) {
    return ProviderScope(
      overrides: <Override>[
        giderRepositoryProvider.overrideWithValue(repository),
        expenseCategoriesProvider.overrideWith(
          (ref) async => expenseCategories,
        ),
        incomeCategoriesProvider.overrideWith((ref) async => incomeCategories),
        ...supplierOverrides(availableSuppliers),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.globalDelegates,
        home: Scaffold(
          body: EntryScreen(kind: kind, transactionId: transactionId),
        ),
      ),
    );
  }

  Widget _editScopeWithRefreshProbe({
    required GiderRepository repository,
    required EntryKind kind,
    required String transactionId,
    List<SupplierData>? availableSuppliers,
  }) {
    return ProviderScope(
      overrides: <Override>[
        giderRepositoryProvider.overrideWithValue(repository),
        expenseCategoriesProvider.overrideWith(
          (ref) async => expenseCategories,
        ),
        incomeCategoriesProvider.overrideWith((ref) async => incomeCategories),
        ...supplierOverrides(availableSuppliers),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.globalDelegates,
        home: Scaffold(
          body: Column(
            children: <Widget>[
              Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? child) {
                  return Text('refresh:${ref.watch(refreshKeyProvider)}');
                },
              ),
              Expanded(
                child: EntryScreen(kind: kind, transactionId: transactionId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createScopeWithRefreshProbe({
    required GiderRepository repository,
    required EntryKind kind,
    List<SupplierData>? availableSuppliers,
  }) {
    return ProviderScope(
      overrides: <Override>[
        giderRepositoryProvider.overrideWithValue(repository),
        expenseCategoriesProvider.overrideWith(
          (ref) async => expenseCategories,
        ),
        incomeCategoriesProvider.overrideWith((ref) async => incomeCategories),
        ...supplierOverrides(availableSuppliers),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.globalDelegates,
        home: Scaffold(
          body: Column(
            children: <Widget>[
              Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? child) {
                  return Text('refresh:${ref.watch(refreshKeyProvider)}');
                },
              ),
              Expanded(child: EntryScreen(kind: kind)),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets(
    'expense entry with transactionId calls updateTransaction, not create',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _editRepository(preload: null);

      await tester.pumpWidget(
        _editScope(
          repository: repository,
          kind: EntryKind.expense,
          transactionId: 'tx-existing',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Degisiklikleri kaydet'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '42.00');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rent'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Degisiklikleri kaydet'));
      await tester.pumpAndSettle();

      verifyNever(() => repository.createTransaction(any()));
      final VerificationResult verifyResult = verify(
        () => repository.updateTransaction(
          id: captureAny(named: 'id'),
          draft: captureAny(named: 'draft'),
        ),
      );
      verifyResult.called(1);
      expect(verifyResult.captured[0], 'tx-existing');
      final EntryDraft draft = verifyResult.captured[1] as EntryDraft;
      expect(draft.type, TransactionType.expense);
      expect(draft.categoryId, 'expense-rent');
    },
  );

  testWidgets('edit mode preloads transaction data into form fields', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final preloadData = TransactionData(
      id: 'tx-preload',
      type: TransactionType.expense,
      occurredOn: DateTime(2026, 4, 10),
      amountMinor: 4250,
      categoryId: 'expense-rent',
      categoryName: 'Rent',
      paymentMethod: PaymentMethodType.cash,
      createdAt: DateTime(2026, 4, 10),
      vendor: 'Shell Mile End',
      note: 'top-up',
    );

    final repository = _editRepository(preload: preloadData);

    await tester.pumpWidget(
      _editScope(
        repository: repository,
        kind: EntryKind.expense,
        transactionId: 'tx-preload',
      ),
    );
    await tester.pumpAndSettle();

    // Amount preloaded
    expect(find.text('42.50'), findsOneWidget);
    // Category chip selected
    expect(
      tester
          .widget<HiFiFilterChip>(find.widgetWithText(HiFiFilterChip, 'Rent'))
          .selected,
      isTrue,
    );
    // Payment method preloaded
    expect(
      tester
          .widget<HiFiFilterChip>(find.widgetWithText(HiFiFilterChip, 'Nakit'))
          .selected,
      isTrue,
    );
  });

  testWidgets('expense create refreshes summary state after save', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();
    when(() => repository.createTransaction(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      _createScopeWithRefreshProbe(
        repository: repository,
        kind: EntryKind.expense,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('refresh:0'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '42.00');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gideri kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('refresh:1'), findsOneWidget);
  });

  testWidgets('expense edit preserves supplier and vendor when category is unchanged', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final preloadData = TransactionData(
      id: 'tx-preload',
      type: TransactionType.expense,
      occurredOn: DateTime(2026, 4, 10),
      amountMinor: 4250,
      categoryId: 'expense-rent',
      categoryName: 'Rent',
      paymentMethod: PaymentMethodType.cash,
      createdAt: DateTime(2026, 4, 10),
      vendor: 'Shell Mile End',
      supplierId: 'supp-1',
      supplierName: 'Acme Ltd',
      note: 'top-up',
    );
    final repository = _editRepository(preload: preloadData);

    await tester.pumpWidget(
      _editScope(
        repository: repository,
        kind: EntryKind.expense,
        transactionId: 'tx-preload',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acme Ltd'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, '45.00');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Degisiklikleri kaydet'));
    await tester.pumpAndSettle();

    final VerificationResult verifyResult = verify(
      () => repository.updateTransaction(
        id: captureAny(named: 'id'),
        draft: captureAny(named: 'draft'),
      ),
    );
    final EntryDraft draft = verifyResult.captured[1] as EntryDraft;
    expect(draft.vendor, 'Shell Mile End');
    expect(draft.supplierId, 'supp-1');
  });

  testWidgets('expense edit keeps archived linked supplier readable', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final preloadData = TransactionData(
      id: 'tx-preload',
      type: TransactionType.expense,
      occurredOn: DateTime(2026, 4, 10),
      amountMinor: 4250,
      categoryId: 'expense-rent',
      categoryName: 'Rent',
      paymentMethod: PaymentMethodType.cash,
      createdAt: DateTime(2026, 4, 10),
      vendor: 'Shell Mile End',
      supplierId: 'supp-archived',
      supplierName: 'Legacy Fuel',
      note: 'top-up',
    );
    final repository = _editRepository(preload: preloadData);

    await tester.pumpWidget(
      _editScope(
        repository: repository,
        kind: EntryKind.expense,
        transactionId: 'tx-preload',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Legacy Fuel'), findsWidgets);
    expect(find.text('Arşivli'), findsOneWidget);

    await tester.tap(find.text('Degisiklikleri kaydet'));
    await tester.pumpAndSettle();

    final VerificationResult verifyResult = verify(
      () => repository.updateTransaction(
        id: captureAny(named: 'id'),
        draft: captureAny(named: 'draft'),
      ),
    );
    final EntryDraft draft = verifyResult.captured[1] as EntryDraft;
    expect(draft.supplierId, 'supp-archived');
  });

  testWidgets('expense edit clears preloaded supplier when category changes', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final preloadData = TransactionData(
      id: 'tx-preload',
      type: TransactionType.expense,
      occurredOn: DateTime(2026, 4, 10),
      amountMinor: 4250,
      categoryId: 'expense-rent',
      categoryName: 'Rent',
      paymentMethod: PaymentMethodType.cash,
      createdAt: DateTime(2026, 4, 10),
      vendor: 'Shell Mile End',
      supplierId: 'supp-1',
      supplierName: 'Acme Ltd',
      note: 'top-up',
    );
    final repository = _editRepository(preload: preloadData);

    await tester.pumpWidget(
      _editScope(
        repository: repository,
        kind: EntryKind.expense,
        transactionId: 'tx-preload',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Supplies'));
    await tester.pumpAndSettle();

    expect(find.text('Acme Ltd'), findsNothing);
    await tester.tap(find.text('Degisiklikleri kaydet'));
    await tester.pumpAndSettle();

    final VerificationResult verifyResult = verify(
      () => repository.updateTransaction(
        id: captureAny(named: 'id'),
        draft: captureAny(named: 'draft'),
      ),
    );
    final EntryDraft draft = verifyResult.captured[1] as EntryDraft;
    expect(draft.categoryId, 'expense-supplies');
    expect(draft.supplierId, isNull);
    expect(draft.vendor, 'Shell Mile End');
  });

  testWidgets('archived supplier is hidden from active picker list', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();
    when(() => repository.createTransaction(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      buildApp(kind: EntryKind.expense, repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rent'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('entry-supplier-selector')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acme Ltd'), findsOneWidget);
    expect(find.text('Legacy Fuel'), findsNothing);
  });

  testWidgets('edit mode confirms delete before removing transaction', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _editRepository(preload: null);

    await tester.pumpWidget(
      _editScope(
        repository: repository,
        kind: EntryKind.expense,
        transactionId: 'tx-del',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sil'), findsOneWidget);

    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();

    expect(find.text('Emin misiniz?'), findsOneWidget);
    expect(find.text('Bu kayit kalici olarak silinecek.'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('entry-delete-cancel-button')),
    );
    await tester.pumpAndSettle();

    verifyNever(() => repository.deleteTransaction(id: 'tx-del'));
  });

  testWidgets('confirmed delete pops back when edit entry was pushed', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _editRepository(preload: null);

    await tester.pumpWidget(
      buildRouterApp(repository: repository, initialLocation: '/summary'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open expense edit'));
    await tester.pumpAndSettle();

    expect(find.text('Sil'), findsOneWidget);

    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('entry-delete-confirm-button')),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Summary screen'), findsOneWidget);
    expect(find.text('Sil'), findsNothing);
    verify(() => repository.deleteTransaction(id: 'tx-del')).called(1);
  });

  testWidgets('confirmed delete falls back to summary without back stack', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _editRepository(preload: null);

    await tester.pumpWidget(
      buildRouterApp(
        repository: repository,
        initialLocation: '/entry/expense?transactionId=tx-del',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('entry-delete-confirm-button')),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Summary screen'), findsOneWidget);
    expect(find.text('Sil'), findsNothing);
    verify(() => repository.deleteTransaction(id: 'tx-del')).called(1);
  });

  testWidgets('confirmed delete refreshes transaction state immediately', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _editRepository(preload: null);

    await tester.pumpWidget(
      _editScopeWithRefreshProbe(
        repository: repository,
        kind: EntryKind.expense,
        transactionId: 'tx-del',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('refresh:0'), findsOneWidget);

    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('entry-delete-confirm-button')),
    );
    await tester.pumpAndSettle();

    verify(() => repository.deleteTransaction(id: 'tx-del')).called(1);
    expect(find.text('refresh:1'), findsOneWidget);
    verifyNever(() => repository.createTransaction(any()));
    verifyNever(
      () => repository.updateTransaction(
        id: any(named: 'id'),
        draft: any(named: 'draft'),
      ),
    );
  });

  testWidgets('preload fetch failure shows error UI, not raw error text', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _editRepository(preload: null, preloadThrows: true);

    await tester.pumpWidget(
      _editScope(
        repository: repository,
        kind: EntryKind.expense,
        transactionId: 'tx-fail',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kayit yuklenemedi'), findsOneWidget);
    expect(
      find.text('Baglantinizi kontrol edip tekrar deneyin.'),
      findsOneWidget,
    );
    // No raw exception text
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('network error'), findsNothing);
  });

  testWidgets('preload loading shows spinner before data arrives', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final completer = Completer<TransactionData?>();
    final repository = _MockGiderRepository();
    when(
      () => repository.fetchTransaction(id: any(named: 'id')),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      _editScope(
        repository: repository,
        kind: EntryKind.expense,
        transactionId: 'tx-loading',
      ),
    );
    // One frame after postFrameCallback fires but before async completes
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(null);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
