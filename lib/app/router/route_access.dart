enum AppAuthRoutingStatus { unknown, loading, authenticated, unauthenticated }

enum BusinessSettingsBootstrapStatus { loading, required, complete, error }

const String kDefaultProtectedRoute = '/summary';
const String kLoginRoute = '/auth/login';
const String kSignupRoute = '/auth/signup';
const String kOnboardingRoute = '/onboarding';

const Set<String> kProtectedRoutePaths = <String>{
  kDefaultProtectedRoute,
  '/summary/income',
  '/summary/expenses',
  '/summary/net-profit',
  '/transactions',
  '/reports',
  '/settings',
  '/settings/categories',
  '/settings/recurring',
  '/settings/suppliers',
  '/entry/income',
  '/entry/expense',
};

const Set<String> kPostAuthRestorableRoutePaths = <String>{
  kDefaultProtectedRoute,
  '/summary/income',
  '/summary/expenses',
  '/summary/net-profit',
  '/transactions',
  '/reports',
  '/entry/income',
  '/entry/expense',
};

bool isAuthRoutePath(String path) {
  return path == kLoginRoute || path == kSignupRoute;
}

bool isOnboardingRoutePath(String path) {
  return path == kOnboardingRoute;
}

bool isKnownProtectedRoutePath(String path) {
  return kProtectedRoutePaths.contains(path);
}

bool isPostAuthRestorableRoutePath(String path) {
  return kPostAuthRestorableRoutePaths.contains(path);
}

bool isAuthRoutingReady(AppAuthRoutingStatus status) {
  return status == AppAuthRoutingStatus.authenticated ||
      status == AppAuthRoutingStatus.unauthenticated;
}

String normalizePostAuthTarget(String? rawFrom) {
  if (rawFrom == null) {
    return kDefaultProtectedRoute;
  }

  final String candidate = rawFrom.trim();
  if (candidate.isEmpty) {
    return kDefaultProtectedRoute;
  }

  final Uri? uri = Uri.tryParse(candidate);
  if (uri == null || uri.hasScheme || uri.hasAuthority) {
    return kDefaultProtectedRoute;
  }

  final String path = uri.path;
  if (!path.startsWith('/') ||
      isAuthRoutePath(path) ||
      !isPostAuthRestorableRoutePath(path)) {
    return kDefaultProtectedRoute;
  }

  return Uri(
    path: path,
    queryParameters: uri.queryParameters.isEmpty ? null : uri.queryParameters,
  ).toString();
}

String buildAuthLocation(String path, {String? from}) {
  return Uri(
    path: path,
    queryParameters: <String, String>{'from': normalizePostAuthTarget(from)},
  ).toString();
}

String? resolveAppRedirect({
  required AppAuthRoutingStatus authStatus,
  required BusinessSettingsBootstrapStatus bootstrapStatus,
  required Uri currentUri,
}) {
  final bool onAuthRoute = isAuthRoutePath(currentUri.path);
  final bool onOnboardingRoute = isOnboardingRoutePath(currentUri.path);

  switch (authStatus) {
    case AppAuthRoutingStatus.unknown:
    case AppAuthRoutingStatus.loading:
      return null;
    case AppAuthRoutingStatus.unauthenticated:
      if (onAuthRoute) {
        return null;
      }
      return buildAuthLocation(kLoginRoute, from: currentUri.toString());
    case AppAuthRoutingStatus.authenticated:
      switch (bootstrapStatus) {
        case BusinessSettingsBootstrapStatus.loading:
          return null;
        case BusinessSettingsBootstrapStatus.required:
          return onOnboardingRoute ? null : kOnboardingRoute;
        case BusinessSettingsBootstrapStatus.complete:
          break;
        case BusinessSettingsBootstrapStatus.error:
          return null;
      }

      if (onOnboardingRoute) {
        return kDefaultProtectedRoute;
      }

      if (!onAuthRoute) {
        return null;
      }
      return normalizePostAuthTarget(currentUri.queryParameters['from']);
  }
}
