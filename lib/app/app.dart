import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'providers/app_providers.dart';
import 'router/app_router.dart';
import 'router/route_access.dart';
import 'theme/app_theme.dart';

class GiderApp extends ConsumerWidget {
  const GiderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppTheme.configure();
    final AppLocalizations strings = ref.watch(appLocalizationsProvider);
    final locale = ref.watch(appLocaleProvider);
    final AppAuthRoutingStatus authRoutingStatus = ref.watch(
      authRoutingStatusProvider,
    );

    if (authRoutingStatus == AppAuthRoutingStatus.loading) {
      return _buildBootstrapApp(
        locale: locale.locale,
        strings: strings,
        child: const _AuthBootstrapScreen(),
      );
    }

    if (authRoutingStatus == AppAuthRoutingStatus.authenticated) {
      final BusinessSettingsBootstrapStatus bootstrapStatus = ref.watch(
        businessSettingsBootstrapStatusProvider,
      );

      if (bootstrapStatus == BusinessSettingsBootstrapStatus.loading) {
        return _buildBootstrapApp(
          locale: locale.locale,
          strings: strings,
          child: _BootstrapProgressScreen(
            message: strings.preparingBusinessSetup,
          ),
        );
      }

      if (bootstrapStatus == BusinessSettingsBootstrapStatus.error) {
        return _buildBootstrapApp(
          locale: locale.locale,
          strings: strings,
          child: const _BootstrapFailureScreen(),
        );
      }
    }

    return MaterialApp.router(
      title: strings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: locale.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.globalDelegates,
      routerConfig: ref.watch(appRouterProvider),
    );
  }

  MaterialApp _buildBootstrapApp({
    required Locale locale,
    required AppLocalizations strings,
    required Widget child,
  }) {
    return MaterialApp(
      title: strings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.globalDelegates,
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => child,
        );
      },
    );
  }
}

class _AuthBootstrapScreen extends StatelessWidget {
  const _AuthBootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return _BootstrapProgressScreen(message: context.strings.checkingSession);
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
    final AppLocalizations strings = ref.watch(appLocalizationsProvider);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(strings.bootstrapSettingsLoadError),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(businessSettingsProvider),
                child: Text(strings.tryAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
