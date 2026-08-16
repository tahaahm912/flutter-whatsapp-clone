import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/daos/messages_dao.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/network/api_client.dart';

class MessageRepository {
  final ApiClient apiClient;
  final AppDatabase database;

  MessageRepository({
    required this.apiClient,
    required this.database,
  });

  MessagesDao get _messagesDao => database.messagesDao;

  // ============================================================
  // LOAD MESSAGES
  // ============================================================

  Future<List<Message>> getMessages(
    String conversationId,
  ) async {
    // First load local messages immediately.
    final localMessages =
        await _messagesDao.getMessagesForConversation(
      conversationId,
    );

    try {
      // Then ask the backend for the latest messages.
      final response = await apiClient.dio.get(
        '/messages/$conversationId',
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        final messages = data['messages'];

        if (messages is List) {
          for (final item in messages) {
            if (item is! Map) {
              continue;
            }

            final messageId = item['id']?.toString();
            final senderId = item['sender_id']?.toString();
            final body = item['body']?.toString();
            final createdAt = item['created_at']?.toString();

            if (messageId == null ||
                senderId == null ||
                body == null ||
                createdAt == null) {
              continue;
            }

            final parsedCreatedAt =
                DateTime.tryParse(createdAt);

            if (parsedCreatedAt == null) {
              continue;
            }

            await _messagesDao.upsertMessage(
              MessagesCompanion(
                messageId: Value(messageId),
                conversationId:
                    Value(conversationId),
                senderId: Value(senderId),
                receiverId: const Value(''),
                content: Value(body),
                isMe: const Value(false),
                sentAt: Value(parsedCreatedAt),
                createdAt: Value(parsedCreatedAt),
              ),
            );
          }
        }
      }

      // Return the database after synchronisation.
      return await _messagesDao
          .getMessagesForConversation(conversationId);
    } catch (_) {
      // If backend is unavailable, local messages
      // are still usable.
      return localMessages;
    }
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<Message> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final clientMessageId = const Uuid().v4();

    final response = await apiClient.dio.post(
      '/messages',
      data: {
        'conversation_id': conversationId,
        'client_message_id': clientMessageId,
        'body': text,
      },
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid message response');
    }

    final messageId = data['id']?.toString();
    final returnedConversationId =
        data['conversation_id']?.toString();
    final senderId = data['sender_id']?.toString();
    final returnedClientMessageId =
        data['client_message_id']?.toString();
    final body = data['body']?.toString();
    final createdAt = data['created_at']?.toString();

    if (messageId == null ||
        returnedConversationId == null ||
        senderId == null ||
        returnedClientMessageId == null ||
        body == null ||
        createdAt == null) {
      throw Exception('Incomplete message response');
    }

    final parsedCreatedAt =
        DateTime.tryParse(createdAt);

    if (parsedCreatedAt == null) {
      throw Exception('Invalid message created_at');
    }

    final message = Message(
      id: 0,
      messageId: messageId,
      conversationId: returnedConversationId,
      senderId: senderId,
      receiverId: '',
      content: body,
      isMe: true,
      sentAt: parsedCreatedAt,
      createdAt: parsedCreatedAt,
    );

    // Save the successful server message locally.
    await _messagesDao.upsertMessage(
      MessagesCompanion(
        messageId: Value(message.messageId),
        conversationId:
            Value(message.conversationId),
        senderId: Value(message.senderId),
        receiverId:
            Value(message.receiverId),
        content: Value(message.content),
        isMe: const Value(true),
        sentAt: Value(message.sentAt),
        createdAt: Value(message.createdAt),
      ),
    );

    return message;
  }
}
