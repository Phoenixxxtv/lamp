import '../../auth/models/user_profile.dart';

/// Community reply model with nested reply support
class CommunityReply {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final String? parentReplyId;
  final DateTime createdAt;
  
  // Joined data
  final UserProfile? author;
  final List<CommunityReply> nestedReplies;

  const CommunityReply({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    this.parentReplyId,
    required this.createdAt,
    this.author,
    this.nestedReplies = const [],
  });

  factory CommunityReply.fromJson(Map<String, dynamic> json) {
    UserProfile? author;
    if (json['author'] != null && json['author'] is Map<String, dynamic>) {
      author = UserProfile.fromJson(json['author'] as Map<String, dynamic>);
    }
    
    return CommunityReply(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String,
      content: json['content'] as String,
      parentReplyId: json['parent_reply_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      author: author,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'author_id': authorId,
      'content': content,
      'parent_reply_id': parentReplyId,
    };
  }

  /// Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inDays > 365) {
      return '${diff.inDays ~/ 365}y ago';
    } else if (diff.inDays > 30) {
      return '${diff.inDays ~/ 30}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Create a copy with nested replies
  CommunityReply copyWithNestedReplies(List<CommunityReply> nested) {
    return CommunityReply(
      id: id,
      postId: postId,
      authorId: authorId,
      content: content,
      parentReplyId: parentReplyId,
      createdAt: createdAt,
      author: author,
      nestedReplies: nested,
    );
  }
}
