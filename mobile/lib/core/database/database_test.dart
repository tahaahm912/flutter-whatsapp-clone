import 'package:drift/drift.dart';

import 'app_database.dart';
import 'tables/messages.dart';

Future<void> testMessagesDatabase(AppDatabase db) async {
  print('========== BLULINK MESSAGE DB TEST ==========');

  // Start with a clean database for this test.
  await db.messagesDao.clearMessages();

  // -----------------------------------------
  // TEST 1: Insert my message
  // -----------------------------------------

  final insertedId = await db.messagesDao.insertMessage(
    MessagesCompanion.insert(
      messageId: 'test-message-001',
      conversationId: 'conversation-001',
      senderId: 'user-001',
      receiverId: 'user-002',
      content: 'Hello from Taha!',
      isMe: const Value(true),
      sentAt: DateTime.now(),
    ),
  );

  print('Inserted SQLite row ID: $insertedId');

  // -----------------------------------------
  // TEST 2: Read message by messageId
  // -----------------------------------------

  final message =
      await db.messagesDao.getMessageById(
    'test-message-001',
  );

  if (message == null) {
    print('❌ FAILED: Message not found');
    return;
  }

  print('Message ID: ${message.messageId}');
  print('Conversation ID: ${message.conversationId}');
  print('Sender ID: ${message.senderId}');
  print('Receiver ID: ${message.receiverId}');
  print('Content: ${message.content}');
  print('isMe: ${message.isMe}');

  // -----------------------------------------
  // TEST 3: Verify values
  // -----------------------------------------

  final valuesCorrect =
      message.messageId == 'test-message-001' &&
      message.conversationId == 'conversation-001' &&
      message.senderId == 'user-001' &&
      message.receiverId == 'user-002' &&
      message.content == 'Hello from Taha!' &&
      message.isMe == true;

  if (valuesCorrect) {
    print('✅ INSERT + READ PASSED');
  } else {
    print('❌ INSERT + READ FAILED');
  }

  // -----------------------------------------
  // TEST 4: Insert received message
  // -----------------------------------------

  await db.messagesDao.insertMessage(
    MessagesCompanion.insert(
      messageId: 'test-message-002',
      conversationId: 'conversation-001',
      senderId: 'user-002',
      receiverId: 'user-001',
      content: 'Hi Taha!',
      isMe: const Value(false),
      sentAt: DateTime.now(),
    ),
  );

  // -----------------------------------------
  // TEST 5: Get conversation messages
  // -----------------------------------------

  final messages =
      await db.messagesDao.getMessagesForConversation(
    'conversation-001',
  );

  print('Messages in conversation: ${messages.length}');

  for (final msg in messages) {
    print(
      '${msg.isMe ? "ME" : "THEM"}: ${msg.content}',
    );
  }

  if (messages.length == 2) {
    print('✅ CONVERSATION QUERY PASSED');
  } else {
    print('❌ CONVERSATION QUERY FAILED');
  }

  // -----------------------------------------
  // TEST 6: Latest message
  // -----------------------------------------

  final latest =
      await db.messagesDao.getLatestMessage(
    'conversation-001',
  );

  if (latest != null) {
    print('Latest message: ${latest.content}');
    print('✅ LATEST MESSAGE QUERY PASSED');
  } else {
    print('❌ LATEST MESSAGE QUERY FAILED');
  }

  print('========== TEST COMPLETE ==========');
}