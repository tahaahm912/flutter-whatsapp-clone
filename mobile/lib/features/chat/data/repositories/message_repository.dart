import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/messages_dao.dart';
import '../../../../core/network/api_client.dart';

class MessageRepository {
  MessageRepository({
    required this.apiClient,
    required this.database,
    required this.currentUserId,
  });

  final ApiClient apiClient;
  final AppDatabase database;
  final String currentUserId;

  MessagesDao get _messagesDao => database.messagesDao;

  // ============================================================
  // LOAD MESSAGES
  // ============================================================

  Future<List<Message>> getMessages(
    String conversationId,
  ) async {
    if (conversationId.trim().isEmpty) {
      throw ArgumentError(
        'conversationId cannot be empty',
      );
    }

    if (currentUserId.trim().isEmpty) {
      throw ArgumentError(
        'currentUserId cannot be empty',
      );
    }

    debugPrint('==========================================');
    debugPrint('GET MESSAGES');
    debugPrint('conversationId: $conversationId');
    debugPrint('currentUserId: $currentUserId');
    debugPrint('==========================================');

    try {
      // ----------------------------------------------------------
      // GET SERVER MESSAGES
      // ----------------------------------------------------------

      final response = await apiClient.dio.get(
        '/messages/$conversationId',
      );

      final data = response.data;

      if (data is! Map) {
        throw Exception(
          'Invalid messages response',
        );
      }

      final rawMessages = data['messages'];

      if (rawMessages is! List) {
        throw Exception(
          'Invalid messages response: messages is not a list',
        );
      }

      debugPrint(
        'SERVER MESSAGE COUNT: ${rawMessages.length}',
      );

      // ----------------------------------------------------------
      // SAVE SERVER MESSAGES
      // ----------------------------------------------------------

      for (final rawMessage in rawMessages) {
        if (rawMessage is! Map) {
          continue;
        }

        final messageData =
            Map<String, dynamic>.from(rawMessage);

        final messageId =
            messageData['id']?.toString();

        final serverConversationId =
            messageData['conversation_id']?.toString();

        final senderId =
            messageData['sender_id']?.toString();

        final receiverId =
            messageData['receiver_id']?.toString();

        final body =
            messageData['body']?.toString();

        final createdAt =
            messageData['created_at']?.toString();

        // --------------------------------------------------------
        // VALIDATION
        // --------------------------------------------------------

        if (messageId == null ||
            messageId.isEmpty ||
            senderId == null ||
            senderId.isEmpty ||
            body == null ||
            createdAt == null ||
            createdAt.isEmpty) {
          debugPrint(
            'SKIPPING INVALID SERVER MESSAGE',
          );

          continue;
        }

        // --------------------------------------------------------
        // CONVERSATION CHECK
        // --------------------------------------------------------

        final actualConversationId =
            serverConversationId ?? conversationId;

        if (actualConversationId != conversationId) {
          debugPrint(
            'SKIPPING MESSAGE FROM DIFFERENT CONVERSATION',
          );

          continue;
        }

        // --------------------------------------------------------
        // DATE
        // --------------------------------------------------------

        final parsedCreatedAt =
            DateTime.tryParse(createdAt);

        if (parsedCreatedAt == null) {
          debugPrint(
            'SKIPPING MESSAGE WITH INVALID DATE',
          );

          continue;
        }

        // --------------------------------------------------------
        // OWNERSHIP
        // --------------------------------------------------------
        //
        // THIS IS THE ONLY RULE:
        //
        // senderId == currentUserId -> MY MESSAGE -> RIGHT
        // senderId != currentUserId -> OTHER MESSAGE -> LEFT
        //
        // receiverId is NOT used.
        // --------------------------------------------------------

        final bool isMe =
            senderId == currentUserId;

        debugPrint(
          'SERVER MESSAGE => '
          'content=$body | '
          'senderId=$senderId | '
          'currentUserId=$currentUserId | '
          'isMe=$isMe',
        );

        // --------------------------------------------------------
        // SAVE
        // --------------------------------------------------------

        await _messagesDao.upsertMessage(
          MessagesCompanion(
            messageId: Value(messageId),

            conversationId:
                Value(actualConversationId),

            senderId:
                Value(senderId),

            receiverId:
                Value(receiverId ?? ''),

            content:
                Value(body),

            isMe:
                Value(isMe),

            sentAt:
                Value(parsedCreatedAt),

            createdAt:
                Value(parsedCreatedAt),
          ),
        );
      }

      // ----------------------------------------------------------
      // READ DATABASE
      // ----------------------------------------------------------

      final messages =
          await _messagesDao.getMessagesForConversation(
        conversationId,
      );

      // ----------------------------------------------------------
      // DO NOT TRUST STORED isMe
      // ----------------------------------------------------------
      //
      // Recalculate it from senderId.
      //
      // We deliberately DO NOT UPDATE THE DATABASE here.
      // This prevents the UNIQUE message_id problem.
      // ----------------------------------------------------------

      final correctedMessages =
          messages.map((message) {
        final bool isMe =
            message.senderId == currentUserId;

        debugPrint(
          'UI MESSAGE => '
          'content=${message.content} | '
          'senderId=${message.senderId} | '
          'currentUserId=$currentUserId | '
          'isMe=$isMe',
        );

        return Message(
          id: message.id,
          messageId: message.messageId,
          conversationId: message.conversationId,
          senderId: message.senderId,
          receiverId: message.receiverId,
          content: message.content,
          isMe: isMe,
          sentAt: message.sentAt,
          createdAt: message.createdAt,
        );
      }).toList();

      return correctedMessages;
    } catch (e, stackTrace) {
      debugPrint(
        '==========================================',
      );
      debugPrint(
        'GET MESSAGES ERROR',
      );
      debugPrint(
        '$e',
      );
      debugPrint(
        '$stackTrace',
      );
      debugPrint(
        '==========================================',
      );

      // ----------------------------------------------------------
      // SERVER FAILED
      // ----------------------------------------------------------
      //
      // Return local cache, but recalculate isMe.
      // ----------------------------------------------------------

      try {
        final cachedMessages =
            await _messagesDao.getMessagesForConversation(
          conversationId,
        );

        return cachedMessages.map((message) {
          final bool isMe =
              message.senderId == currentUserId;

          debugPrint(
            'CACHED UI MESSAGE => '
            'content=${message.content} | '
            'senderId=${message.senderId} | '
            'currentUserId=$currentUserId | '
            'isMe=$isMe',
          );

          return Message(
            id: message.id,
            messageId: message.messageId,
            conversationId: message.conversationId,
            senderId: message.senderId,
            receiverId: message.receiverId,
            content: message.content,
            isMe: isMe,
            sentAt: message.sentAt,
            createdAt: message.createdAt,
          );
        }).toList();
      } catch (cacheError) {
        debugPrint(
          'CACHE LOAD ERROR: $cacheError',
        );

        rethrow;
      }
    }
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<Message> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    if (conversationId.trim().isEmpty) {
      throw ArgumentError(
        'conversationId cannot be empty',
      );
    }

    if (currentUserId.trim().isEmpty) {
      throw ArgumentError(
        'currentUserId cannot be empty',
      );
    }

    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      throw ArgumentError(
        'Message cannot be empty',
      );
    }

    // ----------------------------------------------------------
    // CLIENT MESSAGE ID
    // ----------------------------------------------------------

    final clientMessageId =
        const Uuid().v4();

    debugPrint(
      '==========================================',
    );

    debugPrint(
      'SEND MESSAGE',
    );

    debugPrint(
      'conversationId: $conversationId',
    );

    debugPrint(
      'currentUserId: $currentUserId',
    );

    debugPrint(
      'body: $trimmedText',
    );

    debugPrint(
      'clientMessageId: $clientMessageId',
    );

    debugPrint(
      '==========================================',
    );

    // ----------------------------------------------------------
    // POST
    // ----------------------------------------------------------

    final response =
        await apiClient.dio.post(
      '/messages',
      data: {
        'conversation_id': conversationId,
        'client_message_id': clientMessageId,
        'body': trimmedText,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception(
        'Invalid message response',
      );
    }

    final messageData =
        Map<String, dynamic>.from(data);

    // ----------------------------------------------------------
    // RESPONSE FIELDS
    // ----------------------------------------------------------

    final messageId =
        messageData['id']?.toString();

    final returnedConversationId =
        messageData['conversation_id']?.toString();

    final senderId =
        messageData['sender_id']?.toString();

    final receiverId =
        messageData['receiver_id']?.toString();

    final returnedClientMessageId =
        messageData['client_message_id']?.toString();

    final body =
        messageData['body']?.toString();

    final createdAt =
        messageData['created_at']?.toString();

    // ----------------------------------------------------------
    // VALIDATE
    // ----------------------------------------------------------

    if (messageId == null ||
        messageId.isEmpty) {
      throw Exception(
        'Message response is missing id',
      );
    }

    if (returnedConversationId == null ||
        returnedConversationId.isEmpty) {
      throw Exception(
        'Message response is missing conversation_id',
      );
    }

    if (returnedConversationId != conversationId) {
      throw Exception(
        'Server returned a different conversation_id. '
        'Expected $conversationId but received '
        '$returnedConversationId',
      );
    }

    if (senderId == null ||
        senderId.isEmpty) {
      throw Exception(
        'Message response is missing sender_id',
      );
    }

    if (returnedClientMessageId == null ||
        returnedClientMessageId.isEmpty) {
      throw Exception(
        'Message response is missing client_message_id',
      );
    }

    if (body == null) {
      throw Exception(
        'Message response is missing body',
      );
    }

    if (createdAt == null ||
        createdAt.isEmpty) {
      throw Exception(
        'Message response is missing created_at',
      );
    }

    // ----------------------------------------------------------
    // DATE
    // ----------------------------------------------------------

    final parsedCreatedAt =
        DateTime.tryParse(createdAt);

    if (parsedCreatedAt == null) {
      throw Exception(
        'Invalid message created_at',
      );
    }

    // ----------------------------------------------------------
    // OWNERSHIP
    // ----------------------------------------------------------

    final bool isMe =
        senderId == currentUserId;

    debugPrint(
      'SENT MESSAGE => '
      'content=$body | '
      'senderId=$senderId | '
      'currentUserId=$currentUserId | '
      'isMe=$isMe',
    );

    // ----------------------------------------------------------
    // CREATE MESSAGE
    // ----------------------------------------------------------

    final message = Message(
      id: 0,
      messageId: messageId,
      conversationId: returnedConversationId,
      senderId: senderId,
      receiverId: receiverId ?? '',
      content: body,
      isMe: isMe,
      sentAt: parsedCreatedAt,
      createdAt: parsedCreatedAt,
    );

    // ----------------------------------------------------------
    // SAVE LOCALLY
    // ----------------------------------------------------------

    await _messagesDao.upsertMessage(
      MessagesCompanion(
        messageId:
            Value(message.messageId),

        conversationId:
            Value(message.conversationId),

        senderId:
            Value(message.senderId),

        receiverId:
            Value(message.receiverId),

        content:
            Value(message.content),

        isMe:
            Value(message.isMe),

        sentAt:
            Value(message.sentAt),

        createdAt:
            Value(message.createdAt),
      ),
    );

    return message;
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<List<Message>> refreshMessages(
    String conversationId,
  ) {
    return getMessages(conversationId);
  }

  // ============================================================
  // CACHED MESSAGES
  // ============================================================

  Future<List<Message>> getCachedMessages(
    String conversationId,
  ) async {
    final messages =
        await _messagesDao.getMessagesForConversation(
      conversationId,
    );

    return messages.map((message) {
      return Message(
        id: message.id,
        messageId: message.messageId,
        conversationId: message.conversationId,
        senderId: message.senderId,
        receiverId: message.receiverId,
        content: message.content,
        isMe:
            message.senderId == currentUserId,
        sentAt: message.sentAt,
        createdAt: message.createdAt,
      );
    }).toList();
  }

  // ============================================================
  // DELETE MESSAGES
  // ============================================================

  Future<int> deleteConversationMessages(
    String conversationId,
  ) {
    return _messagesDao
        .deleteMessagesForConversation(
      conversationId,
    );
  }
}