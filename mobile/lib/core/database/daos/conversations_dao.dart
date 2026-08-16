import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/conversations.dart';

part 'conversations_dao.g.dart';

@DriftAccessor(tables: [Conversations])
class ConversationDao extends DatabaseAccessor<AppDatabase>
    with _$ConversationDaoMixin {
  ConversationDao(AppDatabase db) : super(db);

  // ---------------------------------------------------------------------------
  // GET ALL CONVERSATIONS
  // ---------------------------------------------------------------------------

  Future<List<Conversation>> getAllConversations() {
    return (select(conversations)
          ..orderBy([
            (conversation) => OrderingTerm(
                  expression: conversation.updatedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  // ---------------------------------------------------------------------------
  // GET ONE CONVERSATION
  // ---------------------------------------------------------------------------

  Future<Conversation?> getConversationById(
    String conversationId,
  ) {
    return (select(conversations)
          ..where(
            (conversation) =>
                conversation.conversationId.equals(conversationId),
          ))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // INSERT / UPDATE
  // ---------------------------------------------------------------------------

  Future<void> upsertConversation(
    ConversationsCompanion conversation,
  ) async {
    await into(conversations).insertOnConflictUpdate(
      conversation,
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE ALL
  // ---------------------------------------------------------------------------

  Future<void> clearConversations() async {
    await delete(conversations).go();
  }

  // ---------------------------------------------------------------------------
  // DELETE ONE
  // ---------------------------------------------------------------------------

  Future<void> deleteConversation(
    String conversationId,
  ) async {
    await (delete(conversations)
          ..where(
            (conversation) =>
                conversation.conversationId.equals(conversationId),
          ))
        .go();
  }

  // ---------------------------------------------------------------------------
  // UPDATE MESSAGE PREVIEW
  // ---------------------------------------------------------------------------

  Future<void> updateLastMessage({
    required String conversationId,
    required String message,
    required DateTime messageTime,
  }) async {
    await (update(conversations)
          ..where(
            (conversation) =>
                conversation.conversationId.equals(conversationId),
          ))
        .write(
      ConversationsCompanion(
        lastMessage: Value(message),
        lastMessageAt: Value(messageTime),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UPDATE UNREAD COUNT
  // ---------------------------------------------------------------------------

  Future<void> updateUnreadCount({
    required String conversationId,
    required int unreadCount,
  }) async {
    await (update(conversations)
          ..where(
            (conversation) =>
                conversation.conversationId.equals(conversationId),
          ))
        .write(
      ConversationsCompanion(
        unreadCount: Value(unreadCount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CLEAR UNREAD
  // ---------------------------------------------------------------------------

  Future<void> clearUnread(
    String conversationId,
  ) async {
    await updateUnreadCount(
      conversationId: conversationId,
      unreadCount: 0,
    );
  }
}