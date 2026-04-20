enum AppAuthRoutingStatus { loading, authenticated, unauthenticated }

enum BusinessSettingsBootstrapStatus { loading, required, complete, error }

const String kDefaultProtectedRoute = '/summary';
const String kLoginRoute = '/auth/login';
const String kSignupRoute = '/auth/signup';
const String kOnboardingRoute = '/onboarding';

bool isAuthRoutePath(String path) {
  return path == kLoginRoute || path == kSignupRoute;
}

bool isOnboardingRoutePath(String path) {
  return path == kOnboardingRoute;
}

bool isKnownProtectedRoutePath(String path) {
  switch (path) {
    case kDefaultProtectedRoute:
    case '/transactions':
    case '/reports':
    case '/settings':
    case '/settings/categories':
    case '/settings/recurring':
    case '/entry/income':
    case '/entry/expense':
      return true;
  }
  return false;
}

String normalizeProtectedFrom(String? rawFrom) {
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
      !isKnownProtectedRoutePath(path)) {
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
    queryParameters: <String, String>{'from': normalizeProtectedFrom(from)},
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
      return normalizeProtectedFrom(currentUri.queryParameters['from']);
  }
}
