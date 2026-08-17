import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/daos/conversations_dao.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/network/api_client.dart';

class ConversationRepository {
  ConversationRepository({
    ApiClient? apiClient,
    AppDatabase? database,
  })  : _apiClient = apiClient ?? ApiClient(),
        _database = database ?? AppDatabase();

  final ApiClient _apiClient;
  final AppDatabase _database;

  ConversationDao get _dao => _database.conversationDao;

  // ============================================================
  // CREATE CONVERSATION
  // ============================================================

  /// Creates a direct conversation with another user.
  ///
  /// Backend:
  /// POST /conversations
  ///
  /// Expected request:
  /// {
  ///   "participant_id": "USER_ID"
  /// }
  ///
  /// Returns the created conversation ID.
  Future<String> createConversation({
    required String otherUserId,
  }) async {
    if (otherUserId.trim().isEmpty) {
      throw ArgumentError(
        'otherUserId cannot be empty',
      );
    }

    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/conversations',
      data: {
        'participant_id': otherUserId,
      },
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException(
        'Empty response from /conversations',
      );
    }

    final conversationId = data['id']?.toString();

    if (conversationId == null ||
        conversationId.isEmpty) {
      throw const FormatException(
        'Invalid conversation response: missing conversation ID',
      );
    }

    return conversationId;
  }

  // ============================================================
  // LOAD / SYNC CONVERSATIONS
  // ============================================================

  /// Loads conversations from the backend and synchronizes
  /// the local Drift database.
  Future<List<Conversation>> syncConversations() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/conversations',
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException(
        'Empty response from /conversations',
      );
    }

    final rawConversations = data['conversations'];

    if (rawConversations is! List) {
      throw const FormatException(
        'Invalid /conversations response: '
        'conversations must be a list',
      );
    }

    final companions = <ConversationsCompanion>[];

    for (final raw in rawConversations) {
      if (raw is! Map) {
        continue;
      }

      final map = Map<String, dynamic>.from(raw);

      final conversationId =
          map['id']?.toString();

      if (conversationId == null ||
          conversationId.isEmpty) {
        continue;
      }

      final otherParticipant =
          map['other_participant'];

      String otherUserId = '';
      String otherUserName = 'Unknown user';
      String? otherUserAvatar;

      if (otherParticipant is Map) {
        final participant =
            Map<String, dynamic>.from(
          otherParticipant,
        );

        otherUserId =
            participant['id']?.toString() ?? '';

        otherUserName =
            participant['name']?.toString() ??
                'Unknown user';

        otherUserAvatar =
            participant['profile_photo_url']
                ?.toString();
      }

      if (otherUserId.isEmpty) {
        continue;
      }

      final createdAt =
          _parseDateTime(map['created_at']);

      companions.add(
        ConversationsCompanion(
          conversationId:
              Value(conversationId),

          otherUserId:
              Value(otherUserId),

          otherUserName:
              Value(otherUserName),

          otherUserAvatar:
              Value(otherUserAvatar),

          updatedAt:
              Value(
            createdAt ?? DateTime.now(),
          ),
        ),
      );
    }

    await _database.transaction(() async {
      await _dao.clearConversations();

      for (final conversation
          in companions) {
        await _dao.upsertConversation(
          conversation,
        );
      }
    });

    return _dao.getAllConversations();
  }

  // ============================================================
  // GET CACHED CONVERSATIONS
  // ============================================================

  Future<List<Conversation>>
      getCachedConversations() {
    return _dao.getAllConversations();
  }

  // ============================================================
  // GET CONVERSATIONS
  // ============================================================

  /// Fetches conversations from the backend.
  ///
  /// If the backend is unavailable, cached Drift
  /// conversations are returned.
  Future<List<Conversation>>
      getConversations() async {
    try {
      return await syncConversations();
    } on DioException {
      return getCachedConversations();
    }
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  DateTime? _parseDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime
        .tryParse(value.toString())
        ?.toLocal();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await _database.close();
  }
}