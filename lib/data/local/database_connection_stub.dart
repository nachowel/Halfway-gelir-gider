import 'package:drift/drift.dart';

QueryExecutor openAppDatabaseConnection() {
  return LazyDatabase(() async {
    throw UnsupportedError(
      'AppDatabase file storage is unavailable on this platform. '
      'Inject a QueryExecutor explicitly.',
    );
  });
}
