import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/shared/overlay/app_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(AppTheme.configure);

  testWidgets('tracked bottom sheet toggles overlay state for its lifecycle', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    showAppModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (BuildContext sheetContext) {
                        return Material(
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Text('Overlay sheet'),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(sheetContext).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(isOverlayOpenProvider), isFalse);

    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(container.read(isOverlayOpenProvider), isTrue);
    expect(find.text('Overlay sheet'), findsOneWidget);

    Navigator.of(tester.element(find.text('Overlay sheet'))).pop();
    await tester.pumpAndSettle();

    expect(container.read(isOverlayOpenProvider), isFalse);
  });
}
