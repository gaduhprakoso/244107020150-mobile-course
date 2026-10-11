import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/models/post.dart';
import 'pages/paged_posts_page.dart';
import 'pages/post_detail_page.dart';

/// Defines the app's list and post-detail routes.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const PagedPostPage()),
    GoRoute(
      path: '/post/:id',
      builder: (context, state) {
        final postId = int.tryParse(state.pathParameters['id'] ?? '');
        if (postId == null) {
          return const _InvalidPostRoutePage();
        }
        final extra = state.extra;
        return PostDetailPage(
          postId: postId,
          initialPost: extra is Post ? extra : null,
        );
      },
    ),
  ],
);

/// Gives malformed post IDs a clear route-level response.
class _InvalidPostRoutePage extends StatelessWidget {
  const _InvalidPostRoutePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Post')),
      body: const Center(child: Text('ID post tidak valid.')),
    );
  }
}
