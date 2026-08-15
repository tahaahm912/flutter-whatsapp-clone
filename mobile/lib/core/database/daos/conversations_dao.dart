import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/conversations.dart';

part 'conversations_dao.g.dart';

@DriftAccessor(tables: [Conversations])
class ConversationDao extends DatabaseAccessor<AppDatabase>
    with _$ConversationDaoMixin {
  ConversationDao(super.db);

  Future<List<Conversation>> getAllConversations() {
    return (select(conversations)
          ..orderBy([
            (c) => OrderingTerm(
                  expression: c.updatedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  Future<Conversation?> getConversationById(
    String conversationId,
  ) {
    return (select(conversations)
          ..where(
            (c) => c.conversationId.equals(conversationId),
          ))
        .getSingleOrNull();
  }

  Future<int> insertConversation(
    ConversationsCompanion conversation,
  ) {
    return into(conversations).insert(conversation);
  }

  Future<void> upsertConversation(
    ConversationsCompanion conversation,
  ) async {
    await into(conversations).insertOnConflictUpdate(conversation);
  }

  Future<bool> updateConversation(
    ConversationsCompanion conversation,
  ) async {
    final count = await update(conversations).write(conversation);
    return count > 0;
  }

  Future<int> deleteConversation(
    String conversationId,
  ) {
    return (delete(conversations)
          ..where(
            (c) => c.conversationId.equals(conversationId),
          ))
        .go();
  }

  Future<void> clearConversations() async {
    await delete(conversations).go();
  }
}