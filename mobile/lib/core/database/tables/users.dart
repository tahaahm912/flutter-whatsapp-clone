import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get userId => text().unique()();

  TextColumn get name => text()();

  TextColumn get phone =>
      text().nullable()();

  TextColumn get email =>
      text().nullable()();

  TextColumn get avatar =>
      text().nullable()();

  TextColumn get about =>
      text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}