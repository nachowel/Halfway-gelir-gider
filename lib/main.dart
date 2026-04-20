import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppSupabaseClient.initialize();
  } on SupabaseConfigException catch (error) {
    runApp(ProviderScope(child: _BootstrapFailureApp(message: error.message)));
    return;
  }

  runApp(const ProviderScope(child: GiderApp()));
}

class _BootstrapFailureApp extends StatelessWidget {
  const _BootstrapFailureApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFF15282B),
      builder: (_, __) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textDirection: TextDirection.ltr,
            ),
          ),
        );
      },
    );
  }
}
