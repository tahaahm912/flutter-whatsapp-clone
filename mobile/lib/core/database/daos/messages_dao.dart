import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/messages.dart';

part 'messages_dao.g.dart';

@DriftAccessor(tables: [Messages])
class MessagesDao extends DatabaseAccessor<AppDatabase>
    with _$MessagesDaoMixin {
  MessagesDao(super.db);

  /// Get all messages for a conversation.
  ///
  /// Messages are returned from oldest to newest.
  Future<List<Message>> getMessagesForConversation(
    String conversationId,
  ) {
    return (select(messages)
          ..where(
            (m) => m.conversationId.equals(conversationId),
          )
          ..orderBy([
            (m) => OrderingTerm(
                  expression: m.createdAt,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();
  }

  /// Get a single message by its ID.
  Future<Message?> getMessageById(
    String messageId,
  ) {
    return (select(messages)
          ..where(
            (m) => m.messageId.equals(messageId),
          ))
        .getSingleOrNull();
  }

  /// Get the latest message in a conversation.
  Future<Message?> getLatestMessage(
    String conversationId,
  ) {
    return (select(messages)
          ..where(
            (m) => m.conversationId.equals(conversationId),
          )
          ..orderBy([
            (m) => OrderingTerm(
                  expression: m.createdAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Insert a new message.
  Future<int> insertMessage(
    MessagesCompanion message,
  ) {
    return into(messages).insert(message);
  }

  /// Insert a message or update it if the primary/unique key already exists.
  Future<void> upsertMessage(
    MessagesCompanion message,
  ) async {
    await into(messages).insertOnConflictUpdate(message);
  }

  /// Update an existing message.
  Future<bool> updateMessage(
    MessagesCompanion message,
  ) async {
    if (!message.messageId.present) {
      throw ArgumentError(
        'messageId is required when updating a message',
      );
    }
  
    final count = await (update(messages)
          ..where(
            (m) => m.messageId.equals(
              message.messageId.value,
            ),
          ))
        .write(
      message,
    );
  
    return count > 0;
  }

  /// Delete one message by ID.
  Future<int> deleteMessage(
    String messageId,
  ) {
    return (delete(messages)
          ..where(
            (m) => m.messageId.equals(messageId),
          ))
        .go();
  }

  /// Delete all messages belonging to a conversation.
  Future<int> deleteMessagesForConversation(
    String conversationId,
  ) {
    return (delete(messages)
          ..where(
            (m) => m.conversationId.equals(conversationId),
          ))
        .go();
  }

  /// Delete every message from the local database.
  Future<int> clearMessages() {
    return delete(messages).go();
  }
}