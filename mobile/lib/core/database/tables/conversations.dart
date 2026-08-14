import 'package:drift/drift.dart';

class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get conversationId =>
      text().unique()();

  TextColumn get otherUserId =>
      text()();

  TextColumn get otherUserName =>
      text()();

  TextColumn get otherUserAvatar =>
      text().nullable()();

  TextColumn get lastMessage =>
      text().nullable()();

  DateTimeColumn get lastMessageAt =>
      dateTime().nullable()();

  IntColumn get unreadCount =>
      integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}