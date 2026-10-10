import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/data/network_errors.dart';
import 'package:week4_api/data/providers.dart';
import 'package:week4_api/data/repositories/post_repository.dart';
import 'package:week4_api/pages/post_detail_page.dart';
import 'package:week4_api/pages/widgets/post_tile.dart';

class FakePostRepository extends PostRepository {
  FakePostRepository({this.items, this.throwError = false}) : super(Dio());
  final List<Post>? items;
  final bool throwError;

  @override
  Future<List<Post>> fetchPosts() async {
    if (throwError) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      );
    }
    return items ?? const [];
  }

  @override
  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async {
    return fetchPosts();
  }

  @override
  Future<Post> fetchPost(int id) async {
    if (throwError) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts/$id'),
        type: DioExceptionType.connectionError,
      );
    }
    return (items ?? const []).firstWhere((post) => post.id == id);
  }
}

void main() {
  test('fromJson aman terhadap field yang hilang', () {
    final post = Post.fromJson({'id': 7});
    expect(post.id, 7);
    expect(post.title, '');
    expect(post.userId, 0);
  });

  test('friendlyErrorMessage untuk connection error', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/posts'),
      type: DioExceptionType.connectionError,
    );
    expect(friendlyErrorMessage(err), contains('terhubung'));
  });

  test('provider sukses dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        postRepositoryProvider.overrideWithValue(
          FakePostRepository(
            items: [const Post(userId: 1, id: 1, title: 'Tes', body: 'Isi')],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Gunakan helper readPostsOnce (lihat providers.dart).
    final posts = await readPostsOnce(container);
    expect(posts.length, 1);
    expect(posts.first.title, 'Tes');
  });

  test('provider error dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        postRepositoryProvider.overrideWithValue(
          FakePostRepository(throwError: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Gunakan helper readPostsErrorOnce (lihat providers.dart).
    final err = await readPostsErrorOnce(container);
    expect(err, isA<DioException>());
    expect(friendlyErrorMessage(err!), contains('terhubung'));
  });

  testWidgets('detail mengambil post dari repository saat dibuka langsung', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        postRepositoryProvider.overrideWithValue(
          FakePostRepository(
            items: [
              const Post(
                userId: 1,
                id: 7,
                title: 'Judul lengkap',
                body: 'Isi lengkap post.',
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PostDetailPage(postId: 7)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Judul lengkap'), findsOneWidget);
    expect(find.text('Isi lengkap post.'), findsOneWidget);
  });

  testWidgets('PostTile membuka detail dengan post yang sudah dimuat', (
    tester,
  ) async {
    const post = Post(
      userId: 1,
      id: 8,
      title: 'Post dari daftar',
      body: 'Konten lengkap dari daftar.',
    );
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: PostTile(post: post)),
        ),
        GoRoute(
          path: '/post/:id',
          builder: (context, state) => PostDetailPage(
            postId: int.parse(state.pathParameters['id']!),
            initialPost: state.extra as Post?,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Post dari daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Post'), findsOneWidget);
    expect(find.text('Konten lengkap dari daftar.'), findsOneWidget);
  });
}
