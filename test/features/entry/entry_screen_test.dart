import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/data/app_repository.dart';
import 'package:gider/features/entry/presentation/entry_screen.dart';
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

  testWidgets(
    'expense entry with transactionId calls updateTransaction, not create',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final _MockGiderRepository repository = _MockGiderRepository();
      when(
        () => repository.updateTransaction(
          id: any(named: 'id'),
          draft: any(named: 'draft'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
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
            home: const Scaffold(
              body: EntryScreen(
                kind: EntryKind.expense,
                transactionId: 'tx-existing',
              ),
            ),
          ),
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
}
