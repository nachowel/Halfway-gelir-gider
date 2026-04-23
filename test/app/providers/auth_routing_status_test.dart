import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/router/route_access.dart';
import 'package:gider/data/app_models.dart';

void main() {
  group('authRoutingStatusProvider', () {
    test(
      'cached valid session during offline launch becomes authenticated',
      () async {
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            authStateProvider.overrideWith(
              (ref) => Stream<AppAuthUser?>.value(
                const AppAuthUser(id: 'user-1', email: 'owner@example.com'),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        expect(
          container.read(authRoutingStatusProvider),
          AppAuthRoutingStatus.unknown,
        );
        await container.read(authStateProvider.future);

        expect(
          container.read(authRoutingStatusProvider),
          AppAuthRoutingStatus.authenticated,
        );
      },
    );

    test(
      'synthetic signedOut after stale recovery routes through unauthenticated '
      'and re-enters authenticated on next signedIn emission',
      () async {
        final StreamController<AppAuthUser?> authStream =
            StreamController<AppAuthUser?>();
        addTearDown(authStream.close);

        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            authStateProvider.overrideWith((ref) => authStream.stream),
          ],
        );
        addTearDown(container.dispose);

        // Prime the provider and observe transitions.
        final List<AppAuthRoutingStatus> transitions =
            <AppAuthRoutingStatus>[];
        final ProviderSubscription<AppAuthRoutingStatus> sub = container
            .listen<AppAuthRoutingStatus>(
              authRoutingStatusProvider,
              (AppAuthRoutingStatus? prev, AppAuthRoutingStatus next) {
                transitions.add(next);
              },
              fireImmediately: true,
            );
        addTearDown(sub.close);

        // Synthetic signedOut from SessionController after stale recovery.
        authStream.add(null);
        await Future<void>.delayed(const Duration(milliseconds: 5));

        // User logs in cleanly on the same stream (not closed).
        authStream.add(
          const AppAuthUser(id: 'user-2', email: 'owner@example.com'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 5));

        expect(transitions.first, AppAuthRoutingStatus.unknown);
        expect(
          transitions,
          containsAllInOrder(<AppAuthRoutingStatus>[
            AppAuthRoutingStatus.unknown,
            AppAuthRoutingStatus.unauthenticated,
            AppAuthRoutingStatus.authenticated,
          ]),
        );
      },
    );

    test(
      'expired cached session with offline recovery failure becomes auth',
      () async {
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            authStateProvider.overrideWith(
              (ref) => Stream<AppAuthUser?>.error(
                TimeoutException('offline token refresh failed'),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        expect(
          container.read(authRoutingStatusProvider),
          AppAuthRoutingStatus.unknown,
        );
        await expectLater(
          container.read(authStateProvider.future),
          throwsA(isA<TimeoutException>()),
        );

        expect(
          container.read(authRoutingStatusProvider),
          AppAuthRoutingStatus.unauthenticated,
        );
      },
    );
  });
}
