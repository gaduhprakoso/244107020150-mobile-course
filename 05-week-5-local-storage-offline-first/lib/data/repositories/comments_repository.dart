import 'package:dio/dio.dart';

import '../models/comment.dart';

/// Fetches and converts comments from the JSONPlaceholder API.
class CommentRepository {
  /// Uses the shared Dio client configured by the application.
  CommentRepository(this._dio);

  final Dio _dio;

  /// Fetches comments for [postId], with a ten-second send/receive timeout.
  ///
  /// The shared Dio client also sets a ten-second connection timeout in
  /// `createDio`, so all phases of this request are bounded to ten seconds.
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    final data = response.data ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
