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

  /// Loads conversations from the backend and synchronizes the local Drift DB.
  ///
  /// The API is the source of truth for this sync. Once the response has been
  /// saved locally, the UI reads the list from Drift so the same cached data
  /// can be reused when we add offline support later.
  Future<List<Conversation>> syncConversations() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/conversations',
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty response from /conversations');
    }

    final rawConversations = data['conversations'];
    if (rawConversations is! List) {
      throw const FormatException(
        'Invalid /conversations response: conversations must be a list',
      );
    }

    final companions = <ConversationsCompanion>[];

    for (final raw in rawConversations) {
      if (raw is! Map) {
        continue;
      }

      final map = Map<String, dynamic>.from(raw);
      final conversationId = map['id']?.toString();
      if (conversationId == null || conversationId.isEmpty) {
        continue;
      }

      final otherParticipant = map['other_participant'];
      String otherUserId = '';
      String otherUserName = 'Unknown user';
      String? otherUserAvatar;

      if (otherParticipant is Map) {
        final participant = Map<String, dynamic>.from(otherParticipant);
        otherUserId = participant['id']?.toString() ?? '';
        otherUserName = participant['name']?.toString() ?? 'Unknown user';
        otherUserAvatar = participant['profile_photo_url']?.toString();
      }

      if (otherUserId.isEmpty) {
        // Current V1 backend creates direct conversations only, so a missing
        // other participant means this row cannot be rendered correctly.
        // Do not put an unusable row into the local cache.
        continue;
      }

      final createdAt = _parseDateTime(map['created_at']);

      companions.add(
        ConversationsCompanion(
          conversationId: Value(conversationId),
          otherUserId: Value(otherUserId),
          otherUserName: Value(otherUserName),
          otherUserAvatar: Value(otherUserAvatar),
          updatedAt: Value(createdAt ?? DateTime.now()),
        ),
      );
    }

    // The current GET endpoint returns the complete conversation list, so the
    // safest cache synchronization is to replace the old snapshot atomically.
    await _database.transaction(() async {
      await _dao.clearConversations();
      for (final conversation in companions) {
        await _dao.upsertConversation(conversation);
      }
    });

    return _dao.getAllConversations();
  }

  /// Returns the most recent local snapshot without making a network request.
  Future<List<Conversation>> getCachedConversations() {
    return _dao.getAllConversations();
  }

  /// Fetches from the API and falls back to Drift if the network request fails.
  ///
  /// This gives the Day 4 screen a useful cached state while still ensuring
  /// that a successful request always refreshes the local database.
  Future<List<Conversation>> getConversations() async {
    try {
      return await syncConversations();
    } on DioException {
      return getCachedConversations();
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString())?.toLocal();
  }

  Future<void> dispose() async {
    await _database.close();
  }
}
