import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  // Confirms missing API fields are safely mapped to model defaults.
  test('Comment.fromJson defaults missing fields', () {
    final comment = Comment.fromJson({});

    expect(comment.postId, 0);
    expect(comment.id, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });

  // Confirms null and unexpected JSON types do not cause parsing failures.
  test('Comment.fromJson defaults null and incorrectly typed fields', () {
    final comment = Comment.fromJson({
      'postId': null,
      'id': 'not an integer',
      'name': 42,
      'email': null,
      'body': false,
    });

    expect(comment.postId, 0);
    expect(comment.id, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });
}
