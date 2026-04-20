import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/router/route_access.dart';

void main() {
  group('normalizeProtectedFrom', () {
    test('accepts known protected internal routes', () {
      expect(
        normalizeProtectedFrom('/transactions?filter=all'),
        '/transactions?filter=all',
      );
      expect(normalizeProtectedFrom('/entry/income'), '/entry/income');
    });

    test('falls back for empty external auth and unknown paths', () {
      expect(normalizeProtectedFrom(null), kDefaultProtectedRoute);
      expect(normalizeProtectedFrom(''), kDefaultProtectedRoute);
      expect(
        normalizeProtectedFrom('https://example.com/summary'),
        kDefaultProtectedRoute,
      );
      expect(normalizeProtectedFrom('/auth/login'), kDefaultProtectedRoute);
      expect(normalizeProtectedFrom('/unknown'), kDefaultProtectedRoute);
    });
  });

  group('resolveAppRedirect', () {
    test('does not redirect while auth status is loading', () {
      expect(
        resolveAppRedirect(
          authStatus: AppAuthRoutingStatus.loading,
          bootstrapStatus: BusinessSettingsBootstrapStatus.loading,
          currentUri: Uri.parse('/summary'),
        ),
        isNull,
      );
    });

    test('redirects unauthenticated protected requests to login', () {
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

    test(
      'redirects authenticated users to onboarding when bootstrap is required',
      () {
        expect(
          resolveAppRedirect(
            authStatus: AppAuthRoutingStatus.authenticated,
            bootstrapStatus: BusinessSettingsBootstrapStatus.required,
            currentUri: Uri.parse('/summary'),
          ),
          kOnboardingRoute,
        );
      },
    );

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

    test('redirects authenticated users away from auth routes safely', () {
      expect(
        resolveAppRedirect(
          authStatus: AppAuthRoutingStatus.authenticated,
          bootstrapStatus: BusinessSettingsBootstrapStatus.complete,
          currentUri: Uri.parse('/auth/login?from=%2Fsettings%2Frecurring'),
        ),
        '/settings/recurring',
      );
      expect(
        resolveAppRedirect(
          authStatus: AppAuthRoutingStatus.authenticated,
          bootstrapStatus: BusinessSettingsBootstrapStatus.complete,
          currentUri: Uri.parse('/auth/login?from=%2Fauth%2Fsignup'),
        ),
        kDefaultProtectedRoute,
      );
    });
  });
}
