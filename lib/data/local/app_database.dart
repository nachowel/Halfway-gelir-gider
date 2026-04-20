import 'package:drift/drift.dart';

import 'database_connection_stub.dart'
    if (dart.library.io) 'database_connection_io.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: <Type>[
    LocalCategories,
    LocalTransactions,
    LocalRecurringExpenses,
    OutboxEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor})
    : super(executor ?? openAppDatabaseConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await customStatement(
        'create unique index if not exists '
        'uq_outbox_entries_dedupe_key on outbox_entries (dedupe_key)',
      );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(localTransactions, localTransactions.syncedAt);
        await m.addColumn(outboxEntries, outboxEntries.dedupeKey);
        await m.addColumn(outboxEntries, outboxEntries.processingStartedAt);
        await customStatement(
          'create unique index if not exists '
          'uq_outbox_entries_dedupe_key on outbox_entries (dedupe_key)',
        );
      }
    },
  );
}
