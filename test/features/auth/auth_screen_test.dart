import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/data/app_repository.dart';
import 'package:gider/features/auth/presentation/auth_screen.dart';
import 'package:gider/shared/widgets/app_button.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockGiderRepository extends Mock implements GiderRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const String networkErrorMessage =
      'No internet connection. Please try again.';

  setUpAll(AppTheme.configure);

  Widget buildApp(GiderRepository repository) {
    return ProviderScope(
      overrides: <Override>[
        giderRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const AuthScreen()),
    );
  }

  testWidgets('login sanitizes network auth errors and resets loading state', (
    WidgetTester tester,
  ) async {
    final _MockGiderRepository repository = _MockGiderRepository();
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      const AuthException(
        "ClientException with SocketException: Failed host lookup: 'example.supabase.co' (OS Error: No address associated with hostname, errno = 7), uri=https://example.supabase.co/auth/v1/token?grant_type=password",
      ),
    );

    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret12');
    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text(networkErrorMessage), findsOneWidget);
    expect(find.textContaining('Failed host lookup'), findsNothing);
    expect(find.textContaining('supabase.co'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    verify(
      () => repository.signIn(email: 'test@example.com', password: 'secret12'),
    ).called(1);
  });
}
