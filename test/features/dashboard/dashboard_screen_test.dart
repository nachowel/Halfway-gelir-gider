import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/features/dashboard/presentation/dashboard_screen.dart';
import 'package:gider/features/dashboard/widgets/summary_cards.dart';
import 'package:gider/features/dashboard/widgets/transaction_list_item.dart';
import 'package:gider/features/dashboard/widgets/upcoming_payment_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp(Widget child) {
    AppTheme.configure();
    return MaterialApp(theme: AppTheme.light(), home: child);
  }

  testWidgets('dashboard builds T6.3 summary upcoming and recent hierarchy', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(const DashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(HeroSummaryCard), findsOneWidget);
    expect(find.byType(SummaryMetricCard), findsNWidgets(2));
    expect(find.byType(CashSplitSummaryCard), findsOneWidget);
    expect(find.byType(UpcomingPaymentItem), findsNWidgets(2));
    expect(find.byType(TransactionListItem), findsNWidgets(3));

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('£1,284'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Uber Eats payout'), findsOneWidget);
  });
}
