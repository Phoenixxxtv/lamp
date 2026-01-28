import '../../auth/models/user_profile.dart';

/// Community post model
class CommunityPost {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Joined data
  final UserProfile? author;
  final int replyCount;

  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.replyCount = 0,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    UserProfile? author;
    if (json['author'] != null && json['author'] is Map<String, dynamic>) {
      author = UserProfile.fromJson(json['author'] as Map<String, dynamic>);
    }
    
    return CommunityPost(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      author: author,
      replyCount: json['reply_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author_id': authorId,
      'title': title,
      'content': content,
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
}
