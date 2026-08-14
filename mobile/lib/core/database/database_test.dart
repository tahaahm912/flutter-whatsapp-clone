import 'package:drift/drift.dart';

import 'app_database.dart';

Future<void> testDatabase() async {
  final database = AppDatabase();

  try {
    // ------------------------------------------------------------
    // INSERT USER
    // ------------------------------------------------------------

    await database.into(database.users).insert(
      UsersCompanion.insert(
        userId: 'user_test_001',
        name: 'Test User',
        phone: const Value('+923001234567'),
        email: const Value('test@blulink.com'),
        about: const Value('Testing BluLink database'),
      ),
    );

    print('User inserted successfully.');

    // ------------------------------------------------------------
    // INSERT CONVERSATION
    // ------------------------------------------------------------

    await database.into(database.conversations).insert(
      ConversationsCompanion.insert(
        conversationId: 'conversation_test_001',
        otherUserId: 'user_test_002',
        otherUserName: 'Test Friend',
        otherUserAvatar: const Value(null),
        lastMessage: const Value('Hello BluLink!'),
        lastMessageAt: Value(DateTime.now()),
      ),
    );

    print('Conversation inserted successfully.');

    // ------------------------------------------------------------
    // INSERT MESSAGE
    // ------------------------------------------------------------

    await database.into(database.messages).insert(
      MessagesCompanion.insert(
        messageId: 'message_test_001',
        conversationId: 'conversation_test_001',
        senderId: 'user_test_001',
        receiverId: 'user_test_002',
        content: 'Hello BluLink!',
        isMe: const Value(true),
        sentAt: DateTime.now(),
      ),
    );

    print('Message inserted successfully.');

    // ------------------------------------------------------------
    // READ USERS
    // ------------------------------------------------------------

    final users = await database.select(database.users).get();

    print('Users in database:');

    for (final user in users) {
      print(
        '${user.userId} - ${user.name}',
      );
    }

    // ------------------------------------------------------------
    // READ CONVERSATIONS
    // ------------------------------------------------------------

    final conversations =
        await database.select(database.conversations).get();

    print('Conversations in database:');

    for (final conversation in conversations) {
      print(
        '${conversation.conversationId} - '
        '${conversation.otherUserName}',
      );
    }

    // ------------------------------------------------------------
    // READ MESSAGES
    // ------------------------------------------------------------

    final messages =
        await database.select(database.messages).get();

    print('Messages in database:');

    for (final message in messages) {
      print(
        '${message.messageId} - ${message.content}',
      );
    }
  } finally {
    await database.close();
  }
}