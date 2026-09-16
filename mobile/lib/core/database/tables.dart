import 'package:drift/drift.dart';

@DataClassName('AccountEntity')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
  IntColumn get balance => integer().withDefault(const Constant(0))();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get includeInTotal => boolean().withDefault(const Constant(true))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CategoryEntity')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get defaultKey => text().nullable()();
  TextColumn get type => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TransactionEntity')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  TextColumn get currency => text()();
  TextColumn get accountId => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get transferAccountId => text().nullable()();
  IntColumn get transferAmount => integer().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get merchant => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get note => text().nullable()();

  /// JSON array of tag names.
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Outbox of local writes waiting to be pushed to the API, in order.
@DataClassName('PendingOperation')
class PendingOperations extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get method => text()();
  TextColumn get payload => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('KeyValueEntry')
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
