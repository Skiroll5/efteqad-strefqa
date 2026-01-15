import 'package:drift/drift.dart';

// --- Base Table Mixin (if Drift supported mixins easily for columns, but we repeat for clarity or use abstract class) ---

class Users extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get email => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  TextColumn get classId => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();

  // Sync Fields
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Classes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get grade => text().nullable()(); // e.g., "5th Grade"

  // Sync Fields
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Students extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get birthdate => dateTime().nullable()();
  TextColumn get classId => text().nullable()();

  // Sync Fields
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class AttendanceSessions extends Table {
  TextColumn get id => text()();
  TextColumn get classId => text().references(Classes, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();

  // Sync Fields
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class AttendanceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(AttendanceSessions, #id)();
  TextColumn get studentId => text().references(Students, #id)();
  TextColumn get status => text()(); // PRESENT, ABSENT, EXCUSED

  // Sync Fields
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get studentId => text().references(Students, #id)();
  TextColumn get content => text()();

  // Sync Fields
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()(); // Unique ID for the operation
  TextColumn get entityType => text()(); // 'STUDENT', 'ATTENDANCE', etc.
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // 'CREATE', 'UPDATE', 'DELETE'
  TextColumn get payload => text()(); // JSON String
  DateTimeColumn get createdAt => dateTime()();
}
