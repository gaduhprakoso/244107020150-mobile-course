/// Represents one comment returned by the JSONPlaceholder API.
class Comment {
  /// Creates a comment, using API field names as model properties.
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  /// ID of the post this comment belongs to; defaults to zero if absent.
  final int postId;

  /// Comment ID; defaults to zero if absent.
  final int id;

  /// Comment author's name; defaults to an empty string if absent.
  final String name;

  /// Comment author's email; defaults to an empty string if absent.
  final String email;

  /// Comment text; defaults to an empty string if absent.
  final String body;

  /// Builds a comment from API JSON and safely supplies defaults for null,
  /// missing, or incorrectly typed values.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: json['postId'] is num ? (json['postId'] as num).toInt() : 0,
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      name: json['name'] is String ? json['name'] as String : '',
      email: json['email'] is String ? json['email'] as String : '',
      body: json['body'] is String ? json['body'] as String : '',
    );
  }
}
