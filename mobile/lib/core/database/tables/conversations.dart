import 'package:drift/drift.dart';

class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Backend conversation UUID/ID.
  TextColumn get conversationId => text().unique()();

  /// The other user's ID in a direct conversation.
  TextColumn get otherUserId => text()();

  /// Name displayed in the conversation list.
  TextColumn get otherUserName => text()();

  /// Optional profile image URL.
  TextColumn get otherUserAvatar => text().nullable()();

  /// Last cached message preview.
  TextColumn get lastMessage => text().nullable()();

  /// Time of the last cached message.
  DateTimeColumn get lastMessageAt => dateTime().nullable()();

  /// Number of unread messages.
  IntColumn get unreadCount =>
      integer().withDefault(
        const Constant(0),
      )();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(
        currentDateAndTime,
      )();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(
        currentDateAndTime,
      )();
}