import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import 'api_client.dart';
import 'models/comment.dart';
import 'models/post.dart';
import 'repositories/comments_repository.dart';
import 'repositories/post_repository.dart';

// Shares one configured Dio client between repositories.
final dioProvider = Provider<Dio>((ref) => createDio());

// Creates the existing posts repository from the shared Dio client.
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

// Fetches a single post for direct detail-route navigation.
final postByIdProvider = FutureProvider.family<Post, int>(
  (ref, id) => ref.watch(postRepositoryProvider).fetchPost(id),
  retry: (retryCount, error) => null,
);

// Creates the comments repository from the shared Dio client.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

// Loads comments for the postId supplied to this family notifier.
class CommentsNotifier extends AsyncNotifier<List<Comment>> {
  /// Stores this provider instance's post ID for loading and refreshing.
  CommentsNotifier(this.postId);

  final int postId;

  @override
  Future<List<Comment>> build() {
    return ref.watch(commentRepositoryProvider).fetchComments(postId);
  }

  // Reloads this post's comments and exposes failures as AsyncError.
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final comments = await ref
          .read(commentRepositoryProvider)
          .fetchComments(postId);
      state = AsyncData(comments);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

// Uses a family so each postId has its own independently cached async state.
// Automatic retries are disabled so request failures are surfaced immediately.
final commentsProvider =
    AsyncNotifierProvider.family<CommentsNotifier, List<Comment>, int>(
      CommentsNotifier.new,
      retry: (retryCount, error) => null,
    );

class PostListNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    // Exception dari repository otomatis menjadi AsyncError.
    // Inilah ekuivalen deklaratif dari AsyncValue.guard di versi lama.
    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPosts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(postRepositoryProvider);
      state = AsyncData(await repository.fetchPosts());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final postListProvider = AsyncNotifierProvider<PostListNotifier, List<Post>>(
  PostListNotifier.new,
  // Nonaktifkan retry otomatis Riverpod 3 agar error langsung
  // final dan mudah diuji (tanpa ini, future provider di-test
  // akan me-retry dan menggantung).
  retry: (retryCount, error) => null,
);

/// Helper khusus testing (letakkan di providers.dart): membaca state
/// pertama yang bukan loading lewat listener + completer, sehingga
/// test tidak menunggu retry dan tidak melakukan HTTP sungguhan.
Future<List<Post>> readPostsOnce(ProviderContainer container) {
  final completer = Completer<List<Post>>();
  final sub = container.listen<AsyncValue<List<Post>>>(postListProvider, (
    previous,
    next,
  ) {
    if (next.isLoading || completer.isCompleted) return;
    next.whenData(completer.complete);
    if (next.hasError) {
      completer.completeError(
        next.error ?? StateError('unknown error'),
        next.stackTrace ?? StackTrace.empty,
      );
    }
  }, fireImmediately: true);
  return completer.future.whenComplete(sub.close);
}

Future<Object?> readPostsErrorOnce(ProviderContainer container) {
  final completer = Completer<Object?>();
  final sub = container.listen<AsyncValue<List<Post>>>(postListProvider, (
    previous,
    next,
  ) {
    if (next.isLoading || completer.isCompleted) return;
    completer.complete(next.error);
  }, fireImmediately: true);
  return completer.future.whenComplete(sub.close);
}
