import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/crypto/encrypted_envelope.dart';
import '../../../../core/crypto/session_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/messages_dao.dart';
import '../../../../core/network/api_client.dart';

class MessageRepository {
  MessageRepository({
    required this.apiClient,
    required this.database,
    required this.currentUserId,
    required this.sessionService,
  });

  final ApiClient apiClient;
  final AppDatabase database;
  final String currentUserId;
  final SessionService sessionService;

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

    // ----------------------------------------------------------
    // Who is the other participant? Needed to know which Signal
    // session to decrypt incoming messages with (Week 6, Day 4).
    // ----------------------------------------------------------

    final conversation =
        await database.conversationDao.getConversationById(
      conversationId,
    );

    final otherUserId = conversation?.otherUserId;

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
          'senderId=$senderId | '
          'currentUserId=$currentUserId | '
          'isMe=$isMe',
        );

        // --------------------------------------------------------
        // DECRYPT (Week 6, Day 4)
        // --------------------------------------------------------
        //
        // `body` is either:
        //  - legacy Week 5 plaintext (old test data, or a message
        //    sent via today's plaintext fallback in sendMessage) ->
        //    use as-is
        //  - our own outgoing envelope, echoed back -> we already
        //    cached the real plaintext when we sent it (sender's own
        //    Double Ratchet ciphertext isn't decryptable with the
        //    same session), so keep what's already stored
        //  - the other participant's envelope -> decrypt it
        // --------------------------------------------------------

        final resolvedContent = await _resolvePlaintext(
          messageId: messageId,
          body: body,
          isMe: isMe,
          senderId: senderId,
          otherUserId: otherUserId,
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
                Value(resolvedContent),

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

  /// Resolves what to actually display/store for one server message body.
  /// See the call site above for the three cases this covers.
  Future<String> _resolvePlaintext({
    required String messageId,
    required String body,
    required bool isMe,
    required String senderId,
    required String? otherUserId,
  }) async {
    if (!EncryptedEnvelope.looksLikeEnvelope(body)) {
      // Legacy Week 5 plaintext, or today's plaintext-fallback send —
      // nothing to decrypt.
      return body;
    }

    if (isMe) {
      // Signal's send/receive chains aren't symmetric — we can't
      // decrypt our own outgoing ciphertext with the same session.
      // We already know what we sent; keep whatever's cached from
      // `sendMessage` below.
      final cached = await _messagesDao.getMessageById(messageId);

      return cached?.content ??
          '[Sent message — not available on this device]';
    }

    if (otherUserId == null || otherUserId != senderId) {
      // Shouldn't normally happen for a direct conversation, but if the
      // locally cached conversation doesn't match who actually sent
      // this, we don't know which session to decrypt with.
      debugPrint(
        'DECRYPT SKIPPED: sender $senderId does not match cached '
        'conversation participant $otherUserId',
      );

      return '🔒 Encrypted message (unknown sender session)';
    }

    try {
      final envelope = EncryptedEnvelope.fromJsonString(body);

      return await sessionService.decryptMessage(
        remoteUserId: otherUserId,
        envelope: envelope,
      );
    } catch (e) {
      debugPrint('DECRYPT ERROR for message $messageId: $e');

      return '🔒 Encrypted message (unable to decrypt)';
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
    // WHO ARE WE SENDING TO? (needed to pick/build the session)
    // ----------------------------------------------------------

    final conversation =
        await database.conversationDao.getConversationById(
      conversationId,
    );

    final otherUserId = conversation?.otherUserId;

    if (otherUserId == null || otherUserId.isEmpty) {
      throw Exception(
        'Cannot send: conversation $conversationId is not cached '
        'locally, so the recipient is unknown. Load the conversation '
        'list first.',
      );
    }

    // ----------------------------------------------------------
    // ENCRYPT, WITH A PLAINTEXT FALLBACK
    // ----------------------------------------------------------
    //
    // Try for a real encrypted session first. If it can't be built
    // yet — the backend not serving a Kyber pre-key
    // (SignalSessionException), the recipient having no keys
    // uploaded yet (NO_KEYS_AVAILABLE, a plain Exception thrown by
    // KeyApiService), or anything else encryption can fail with —
    // fall back to sending plaintext, same as before Week 6, instead
    // of blocking the send entirely. This is a broad catch on
    // purpose: whatever the specific failure, the fallback is the
    // same. Once the backend adds Kyber support and every account's
    // keys are reliably uploaded, this starts encrypting
    // automatically with no further changes here.
    // ----------------------------------------------------------

    String bodyToSend;

    try {
      if (!await sessionService.hasSession(otherUserId)) {
        await sessionService.establishSession(otherUserId);
      }

      final envelope = await sessionService.encryptMessage(
        remoteUserId: otherUserId,
        plaintext: trimmedText,
      );

      bodyToSend = envelope.toJsonString();
    } catch (e) {
      debugPrint(
        'ENCRYPTION UNAVAILABLE, sending as plaintext: $e',
      );

      bodyToSend = trimmedText;
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
      'clientMessageId: $clientMessageId',
    );

    debugPrint(
      'bodyToSend length: ${bodyToSend.length}',
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
        'body': bodyToSend,
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
      'senderId=$senderId | '
      'currentUserId=$currentUserId | '
      'isMe=$isMe',
    );

    // ----------------------------------------------------------
    // CREATE MESSAGE
    // ----------------------------------------------------------
    //
    // Use the real plaintext we already have, NOT the server's
    // echoed-back body (which may be an encrypted envelope).
    // ----------------------------------------------------------

    final message = Message(
      id: 0,
      messageId: messageId,
      conversationId: returnedConversationId,
      senderId: senderId,
      receiverId: receiverId ?? '',
      content: trimmedText,
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