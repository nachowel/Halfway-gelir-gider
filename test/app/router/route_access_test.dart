import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/router/route_access.dart';

void main() {
  group('normalizePostAuthTarget', () {
    test('accepts explicitly restorable protected internal routes', () {
      expect(
        normalizePostAuthTarget('/transactions?filter=all'),
        '/transactions?filter=all',
      );
      expect(normalizePostAuthTarget('/reports'), '/reports');
      expect(normalizePostAuthTarget('/entry/income'), '/entry/income');
      expect(
        normalizePostAuthTarget('/summary/net-profit'),
        '/summary/net-profit',
      );
    });

    test(
      'falls back for empty external auth unknown and non-restorable paths',
      () {
        expect(normalizePostAuthTarget(null), kDefaultProtectedRoute);
        expect(normalizePostAuthTarget(''), kDefaultProtectedRoute);
        expect(
          normalizePostAuthTarget('https://example.com/summary'),
          kDefaultProtectedRoute,
        );
        expect(normalizePostAuthTarget('/auth/login'), kDefaultProtectedRoute);
        expect(normalizePostAuthTarget('/settings'), kDefaultProtectedRoute);
        expect(
          normalizePostAuthTarget('/settings/recurring'),
          kDefaultProtectedRoute,
        );
        expect(normalizePostAuthTarget('/unknown'), kDefaultProtectedRoute);
      },
    );
  });

  group('resolveAppRedirect', () {
    test('does not redirect while auth status is not ready', () {
      for (final AppAuthRoutingStatus status in <AppAuthRoutingStatus>[
        AppAuthRoutingStatus.unknown,
        AppAuthRoutingStatus.loading,
      ]) {
        expect(
          resolveAppRedirect(
            authStatus: status,
            bootstrapStatus: BusinessSettingsBootstrapStatus.loading,
            currentUri: Uri.parse('/summary'),
          ),
          isNull,
        );
      }
    });

    test('signedOut redirects protected requests to login', () {
      expect(
        resolveAppRedirect(
          authStatus: AppAuthRoutingStatus.unauthenticated,
          bootstrapStatus: BusinessSettingsBootstrapStatus.complete,
          currentUri: Uri.parse('/reports'),
        ),
        '/auth/login?from=%2Freports',
      );
    });

    test('keeps unauthenticated users on auth routes', () {
      expect(
        resolveAppRedirect(
          authStatus: AppAuthRoutingStatus.unauthenticated,
          bootstrapStatus: BusinessSettingsBootstrapStatus.complete,
          currentUri: Uri.parse('/auth/signup?from=%2Freports'),
        ),
        isNull,
      );
    });

    test('onboarding required redirects to onboarding', () {
      expect(
        resolveAppRedirect(
          authStatus: AppAuthRoutingStatus.authenticated,
          bootstrapStatus: BusinessSettingsBootstrapStatus.required,
          currentUri: Uri.parse('/summary'),
        ),
        kOnboardingRoute,
      );
    });

    test(
      'redirects authenticated users away from onboarding after bootstrap completion',
      () {
        expect(
          resolveAppRedirect(
            authStatus: AppAuthRoutingStatus.authenticated,
            bootstrapStatus: BusinessSettingsBootstrapStatus.complete,
            currentUri: Uri.parse(kOnboardingRoute),
          ),
          kDefaultProtectedRoute,
        );
      },
    );

    test('login without safe from redirects to summary', () {
      expect(
        resolveAppRedirect(
          authStatus: AppAuthRoutingStatus.authenticated,
          bootstrapStatus: BusinessSettingsBootstrapStatus.complete,
          currentUri: Uri.parse('/auth/login'),
        ),
        kDefaultProtectedRoute,
      );
    });

    test('auth route with from settings redirects to summary', () {
      expect(
        resolveAppRedirect(
          authStatus: AppAuthRoutingStatus.authenticated,
          bootstrapStatus: BusinessSettingsBootstrapStatus.complete,
          currentUri: Uri.parse('/auth/login?from=%2Fsettings%2Frecurring'),
        ),
        kDefaultProtectedRoute,
      );
    });

    test('auth route with allowed target redirects to that target', () {
      expect(
        resolveAppRedirect(
          authStatus: AppAuthRoutingStatus.authenticated,
          bootstrapStatus: BusinessSettingsBootstrapStatus.complete,
          currentUri: Uri.parse('/auth/login?from=%2Freports'),
        ),
        '/reports',
      );
    });

    test('browser back to login after authentication returns to summary', () {
      expect(
        resolveAppRedirect(
          authStatus: AppAuthRoutingStatus.authenticated,
          bootstrapStatus: BusinessSettingsBootstrapStatus.complete,
          currentUri: Uri.parse('/auth/login'),
        ),
        kDefaultProtectedRoute,
      );
    });

    test('browser back to protected route after logout returns to login', () {
      expect(
        resolveAppRedirect(
          authStatus: AppAuthRoutingStatus.unauthenticated,
          bootstrapStatus: BusinessSettingsBootstrapStatus.complete,
          currentUri: Uri.parse('/reports'),
        ),
        '/auth/login?from=%2Freports',
      );
    });
  });
}
