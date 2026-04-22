import 'package:drift/drift.dart';

class LocalCategories extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get colorToken => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class LocalTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending_create'))();
  TextColumn get type => text()();
  TextColumn get occurredOn => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withDefault(const Constant('GBP'))();
  TextColumn get categoryId => text()();
  TextColumn get categoryType => text()();
  TextColumn get categoryName => text()();
  TextColumn get paymentMethod => text()();
  TextColumn get sourcePlatform => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get vendor => text().nullable()();
  TextColumn get supplierId => text().nullable()();
  TextColumn get attachmentPath => text().nullable()();
  TextColumn get recurringExpenseId => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class LocalRecurringExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get categoryId => text()();
  TextColumn get categoryType => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withDefault(const Constant('GBP'))();
  TextColumn get frequency => text()();
  TextColumn get nextDueOn => text()();
  IntColumn get reminderDaysBefore =>
      integer().withDefault(const Constant(3))();
  TextColumn get defaultPaymentMethod => text().nullable()();
  BoolColumn get reserveEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class OutboxEntries extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get dedupeKey => text().nullable()();
  TextColumn get payload => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get processingStartedAt => dateTime().nullable()();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
