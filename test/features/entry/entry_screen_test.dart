import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/data/app_repository.dart';
import 'package:gider/features/entry/presentation/entry_screen.dart';
import 'package:gider/shared/hi_fi/hi_fi_filter_chip.dart';
import 'package:gider/shared/hi_fi/hi_fi_icon_tile.dart';
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
  ];

  Widget buildApp({
    required EntryKind kind,
    required GiderRepository repository,
  }) {
    return ProviderScope(
      overrides: <Override>[
        giderRepositoryProvider.overrideWithValue(repository),
        incomeCategoriesProvider.overrideWith((ref) async => incomeCategories),
        expenseCategoriesProvider.overrideWith(
          (ref) async => expenseCategories,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: EntryScreen(kind: kind)),
      ),
    );
  }

  testWidgets('income entry submits createTransaction with selected category', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();
    when(() => repository.createTransaction(any())).thenAnswer((_) async {});

    await tester.pumpWidget(buildApp(
      kind: EntryKind.income,
      repository: repository,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Choose category'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '124.00');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose category'));
    await tester.pumpAndSettle();
    expect(find.text('Card Sales'), findsOneWidget);
    expect(find.text('Uber Settlement'), findsOneWidget);
    await tester.tap(find.text('Uber Settlement'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Geliri kaydet'));
    await tester.pumpAndSettle();

    final VerificationResult verifyResult =
        verify(() => repository.createTransaction(captureAny()));
    verifyResult.called(1);
    final EntryDraft draft = verifyResult.captured.single as EntryDraft;
    expect(draft.type, TransactionType.income);
    expect(draft.categoryId, 'income-uber');
    expect(draft.amountMinor, 12400);
    expect(draft.paymentMethod, PaymentMethodType.card);
  });

  testWidgets('selecting Uber source platform snaps occurredOn to Sunday', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();
    when(() => repository.createTransaction(any())).thenAnswer((_) async {});

    await tester.pumpWidget(buildApp(
      kind: EntryKind.income,
      repository: repository,
    ));
    await tester.pumpAndSettle();

    expect(
      find.text('Weekly settlement · enter the Monday-Sunday total for this week'),
      findsNothing,
    );

    await tester.tap(find.text('Uber'));
    await tester.pumpAndSettle();

    expect(
      find.text('Weekly settlement · enter the Monday-Sunday total for this week'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).first, '240.00');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uber Settlement'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Geliri kaydet'));
    await tester.pumpAndSettle();

    final VerificationResult verifyResult =
        verify(() => repository.createTransaction(captureAny()));
    verifyResult.called(1);
    final EntryDraft draft = verifyResult.captured.single as EntryDraft;
    expect(draft.sourcePlatform, SourcePlatformType.uber);
    expect(draft.occurredOn.weekday, DateTime.sunday);
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
  }) {
    return ProviderScope(
      overrides: <Override>[
        giderRepositoryProvider.overrideWithValue(repository),
        expenseCategoriesProvider.overrideWith(
          (ref) async => expenseCategories,
        ),
        incomeCategoriesProvider.overrideWith(
          (ref) async => incomeCategories,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: EntryScreen(kind: kind, transactionId: transactionId),
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
      tester.widget<HiFiFilterChip>(find.widgetWithText(HiFiFilterChip, 'Rent'))
          .selected,
      isTrue,
    );
    // Payment method preloaded
    expect(
      tester.widget<HiFiFilterChip>(find.widgetWithText(HiFiFilterChip, 'Cash'))
          .selected,
      isTrue,
    );
  });

  testWidgets('edit mode shows Delete button and calls deleteTransaction', (
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

    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(
      () => repository.deleteTransaction(id: 'tx-del'),
    ).called(1);
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

    expect(find.text('Could not load entry'), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
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
