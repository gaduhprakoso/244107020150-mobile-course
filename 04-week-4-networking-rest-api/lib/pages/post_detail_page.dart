import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/post.dart';
import '../data/network_errors.dart';
import '../data/providers.dart';

/// Displays a loaded post or fetches it when the route is opened directly.
class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({
    required this.postId,
    this.initialPost,
    super.key,
  });

  final int postId;
  final Post? initialPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = initialPost;
    if (post != null) return _PostDetailContent(post: post);

    final postAsync = ref.watch(postByIdProvider(postId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Post')),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(friendlyErrorMessage(error), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(postByIdProvider(postId)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (fetchedPost) => _PostDetailContent(post: fetchedPost),
      ),
    );
  }
}

/// Shows the complete post title and body without list truncation.
class _PostDetailContent extends StatelessWidget {
  const _PostDetailContent({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Post')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(post.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text(post.body, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}