import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/app_providers.dart';
import 'router/app_router.dart';
import 'router/route_access.dart';
import 'theme/app_theme.dart';

class GiderApp extends ConsumerWidget {
  const GiderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppTheme.configure();
    final AppAuthRoutingStatus authRoutingStatus = ref.watch(
      authRoutingStatusProvider,
    );

    if (authRoutingStatus == AppAuthRoutingStatus.loading) {
      return MaterialApp(
        title: 'Gider',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _AuthBootstrapScreen(),
      );
    }

    if (authRoutingStatus == AppAuthRoutingStatus.authenticated) {
      final BusinessSettingsBootstrapStatus bootstrapStatus = ref.watch(
        businessSettingsBootstrapStatusProvider,
      );

      if (bootstrapStatus == BusinessSettingsBootstrapStatus.loading) {
        return MaterialApp(
          title: 'Gider',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: const _BootstrapProgressScreen(
            message: 'Preparing your business setup…',
          ),
        );
      }

      if (bootstrapStatus == BusinessSettingsBootstrapStatus.error) {
        return MaterialApp(
          title: 'Gider',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: const _BootstrapFailureScreen(),
        );
      }
    }

    return MaterialApp.router(
      title: 'Gider',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

class _AuthBootstrapScreen extends StatelessWidget {
  const _AuthBootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const _BootstrapProgressScreen(message: 'Checking your session…');
  }
}

class _BootstrapProgressScreen extends StatelessWidget {
  const _BootstrapProgressScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _BootstrapFailureScreen extends ConsumerWidget {
  const _BootstrapFailureScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('We could not load your business settings.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(businessSettingsProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
