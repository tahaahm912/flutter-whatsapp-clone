import 'package:drift/drift.dart';

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get messageId =>
      text().unique()();

  TextColumn get conversationId =>
      text()();

  TextColumn get senderId =>
      text()();

  TextColumn get receiverId =>
      text()();

  TextColumn get content =>
      text()();

  BoolColumn get isMe =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get sentAt =>
      dateTime()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}