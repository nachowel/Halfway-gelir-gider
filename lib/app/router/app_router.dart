import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_screen.dart';
import '../../features/balances/presentation/balances_screen.dart';
import '../../features/app_lock/presentation/protected_content_gate.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/entry/presentation/entry_screen.dart';
import '../../features/expense_detail/presentation/expense_detail_screen.dart';
import '../../features/income_detail/presentation/income_detail_screen.dart';
import '../../features/net_profit_detail/presentation/net_profit_detail_screen.dart';
import '../../features/recurring/presentation/recurring_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/onboarding_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/suppliers/presentation/suppliers_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../providers/app_providers.dart';
import '../shell/app_shell.dart';
import '../theme/app_tokens.dart';
import 'route_access.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  final _RouterRefreshListenable refreshListenable = ref.watch(
    _routerRefreshListenableProvider,
  );

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: kDefaultProtectedRoute,
    refreshListenable: refreshListenable,
    redirect: (BuildContext context, GoRouterState state) {
      return resolveAppRedirect(
        authStatus: ref.read(authRoutingStatusProvider),
        bootstrapStatus: ref.read(businessSettingsBootstrapStatusProvider),
        currentUri: state.uri,
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: kLoginRoute,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: AuthScreen(from: state.uri.queryParameters['from']),
          );
        },
      ),
      GoRoute(
        path: kSignupRoute,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: SignUpScreen(from: state.uri.queryParameters['from']),
            transitionDuration: const Duration(milliseconds: 260),
            reverseTransitionDuration: const Duration(milliseconds: 220),
            transitionsBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child,
                ) {
                  final Animation<Offset> slide =
                      Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: AppEasing.expressive,
                        ),
                      );
                  final Animation<double> fade = CurvedAnimation(
                    parent: animation,
                    curve: AppEasing.standard,
                  );
                  return SlideTransition(
                    position: slide,
                    child: FadeTransition(opacity: fade, child: child),
                  );
                },
          );
        },
      ),
      GoRoute(
        path: kOnboardingRoute,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage<void>(child: OnboardingScreen());
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/entry/:kind',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String kind = state.pathParameters['kind'] ?? 'expense';
          final EntryKind entryKind = kind == 'income'
              ? EntryKind.income
              : EntryKind.expense;
          final String? transactionId =
              state.uri.queryParameters['transactionId'];
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: ProtectedContentGate(
              child: EntryScreen(kind: entryKind, transactionId: transactionId),
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/summary/income',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const ProtectedContentGate(child: IncomeDetailScreen()),
            transitionDuration: const Duration(milliseconds: 240),
            reverseTransitionDuration: const Duration(milliseconds: 220),
            transitionsBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child,
                ) {
                  final Animation<Offset> slide =
                      Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: AppEasing.expressive,
                        ),
                      );
                  final Animation<double> fade = CurvedAnimation(
                    parent: animation,
                    curve: AppEasing.standard,
                  );
                  return SlideTransition(
                    position: slide,
                    child: FadeTransition(opacity: fade, child: child),
                  );
                },
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/summary/expenses',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const ProtectedContentGate(child: ExpenseDetailScreen()),
            transitionDuration: const Duration(milliseconds: 240),
            reverseTransitionDuration: const Duration(milliseconds: 220),
            transitionsBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child,
                ) {
                  final Animation<Offset> slide =
                      Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: AppEasing.expressive,
                        ),
                      );
                  final Animation<double> fade = CurvedAnimation(
                    parent: animation,
                    curve: AppEasing.standard,
                  );
                  return SlideTransition(
                    position: slide,
                    child: FadeTransition(opacity: fade, child: child),
                  );
                },
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/summary/net-profit',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const ProtectedContentGate(child: NetProfitDetailScreen()),
            transitionDuration: const Duration(milliseconds: 240),
            reverseTransitionDuration: const Duration(milliseconds: 220),
            transitionsBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child,
                ) {
                  final Animation<Offset> slide =
                      Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: AppEasing.expressive,
                        ),
                      );
                  final Animation<double> fade = CurvedAnimation(
                    parent: animation,
                    curve: AppEasing.standard,
                  );
                  return SlideTransition(
                    position: slide,
                    child: FadeTransition(opacity: fade, child: child),
                  );
                },
          );
        },
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return ProtectedContentGate(
            child: AppShell(
              currentLocation: state.uri.toString(),
              child: child,
            ),
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: kDefaultProtectedRoute,
            pageBuilder: (BuildContext context, GoRouterState state) {
              return const NoTransitionPage<void>(child: DashboardScreen());
            },
          ),
          GoRoute(
            path: '/transactions',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return const NoTransitionPage<void>(child: TransactionsScreen());
            },
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return const NoTransitionPage<void>(child: ReportsScreen());
            },
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return const NoTransitionPage<void>(child: SettingsScreen());
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'recurring',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  return const NoTransitionPage<void>(child: RecurringScreen());
                },
              ),
              GoRoute(
                path: 'categories',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  return const NoTransitionPage<void>(
                    child: CategoriesScreen(),
                  );
                },
              ),
              GoRoute(
                path: 'suppliers',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  return const NoTransitionPage<void>(child: SuppliersScreen());
                },
              ),
              GoRoute(
                path: 'balances',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  return const NoTransitionPage<void>(child: BalancesScreen());
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: ':accountId',
                    pageBuilder: (BuildContext context, GoRouterState state) {
                      return NoTransitionPage<void>(
                        child: BalanceAccountDetailScreen(
                          accountId: state.pathParameters['accountId'] ?? '',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

final Provider<_RouterRefreshListenable> _routerRefreshListenableProvider =
    Provider<_RouterRefreshListenable>((ref) {
      final _RouterRefreshListenable notifier = _RouterRefreshListenable();
      ref.onDispose(notifier.dispose);
      ref.listen<AppAuthRoutingStatus>(authRoutingStatusProvider, (_, __) {
        notifier.refresh();
      });
      ref.listen<BusinessSettingsBootstrapStatus>(
        businessSettingsBootstrapStatusProvider,
        (_, __) {
          notifier.refresh();
        },
      );
      return notifier;
    });

final class _RouterRefreshListenable extends ChangeNotifier {
  void refresh() => notifyListeners();
}
