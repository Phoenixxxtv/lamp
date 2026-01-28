import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/community_post.dart';
import '../models/community_reply.dart';

// =============================================================================
// COMMUNITY POSTS PROVIDERS
// =============================================================================

/// Fetch all community posts
final communityPostsProvider = FutureProvider<List<CommunityPost>>((ref) async {
  try {
    final response = await SupabaseService.client
        .from('community_posts')
        .select('''
          *,
          author:profiles!author_id(id, name, email, role, avatar_url, created_at, updated_at),
          reply_count:community_replies(count)
        ''')
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      // Extract reply count from aggregation
      final replyCount = json['reply_count']?[0]?['count'] as int? ?? 0;
      return CommunityPost.fromJson({
        ...json,
        'reply_count': replyCount,
      });
    }).toList();
  } catch (e) {
    throw Exception('Failed to load posts: $e');
  }
});

/// Fetch single post with replies
final postDetailProvider = FutureProvider.family<PostDetail, String>((ref, postId) async {
  try {
    // Fetch post
    final postResponse = await SupabaseService.client
        .from('community_posts')
        .select('''
          *,
          author:profiles!author_id(id, name, email, role, avatar_url, created_at, updated_at)
        ''')
        .eq('id', postId)
        .single();

    final post = CommunityPost.fromJson(postResponse);

    // Fetch replies
    final repliesResponse = await SupabaseService.client
        .from('community_replies')
        .select('''
          *,
          author:profiles!author_id(id, name, email, role, avatar_url, created_at, updated_at)
        ''')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    final allReplies = (repliesResponse as List)
        .map((json) => CommunityReply.fromJson(json))
        .toList();

    // Organize into nested structure
    final topLevelReplies = allReplies.where((r) => r.parentReplyId == null).toList();
    final nestedReplies = <String, List<CommunityReply>>{};
    
    for (final reply in allReplies.where((r) => r.parentReplyId != null)) {
      nestedReplies.putIfAbsent(reply.parentReplyId!, () => []).add(reply);
    }

    final organizedReplies = topLevelReplies.map((r) {
      return r.copyWithNestedReplies(nestedReplies[r.id] ?? []);
    }).toList();

    return PostDetail(post: post, replies: organizedReplies);
  } catch (e) {
    throw Exception('Failed to load post: $e');
  }
});

/// Post detail with replies
class PostDetail {
  final CommunityPost post;
  final List<CommunityReply> replies;

  const PostDetail({required this.post, required this.replies});
}

// =============================================================================
// COMMUNITY CONTROLLER
// =============================================================================

class CommunityController {
  /// Create a new post
  static Future<CommunityPost?> createPost({
    required String title,
    required String content,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final response = await SupabaseService.client
          .from('community_posts')
          .insert({
            'author_id': userId,
            'title': title,
            'content': content,
          })
          .select()
          .single();

      return CommunityPost.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// Create a reply to a post
  static Future<CommunityReply?> createReply({
    required String postId,
    required String content,
    String? parentReplyId,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final response = await SupabaseService.client
          .from('community_replies')
          .insert({
            'post_id': postId,
            'author_id': userId,
            'content': content,
            'parent_reply_id': parentReplyId,
          })
          .select()
          .single();

      return CommunityReply.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create reply: $e');
    }
  }

  /// Delete a post (admin only)
  static Future<bool> deletePost(String postId) async {
    try {
      await SupabaseService.client
          .from('community_posts')
          .delete()
          .eq('id', postId);
      return true;
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  /// Delete a reply (admin only or own reply)
  static Future<bool> deleteReply(String replyId) async {
    try {
      await SupabaseService.client
          .from('community_replies')
          .delete()
          .eq('id', replyId);
      return true;
    } catch (e) {
      throw Exception('Failed to delete reply: $e');
    }
  }
}

// =============================================================================
// NOTIFIER FOR REFRESHING
// =============================================================================

/// State notifier for community actions
class CommunityNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  CommunityNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<bool> createPost({required String title, required String content}) async {
    state = const AsyncValue.loading();
    try {
      await CommunityController.createPost(title: title, content: content);
      ref.invalidate(communityPostsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> createReply({
    required String postId,
    required String content,
    String? parentReplyId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await CommunityController.createReply(
        postId: postId,
        content: content,
        parentReplyId: parentReplyId,
      );
      ref.invalidate(postDetailProvider(postId));
      ref.invalidate(communityPostsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    state = const AsyncValue.loading();
    try {
      await CommunityController.deletePost(postId);
      ref.invalidate(communityPostsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteReply(String replyId, String postId) async {
    state = const AsyncValue.loading();
    try {
      await CommunityController.deleteReply(replyId);
      ref.invalidate(postDetailProvider(postId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final communityNotifierProvider = 
    StateNotifierProvider<CommunityNotifier, AsyncValue<void>>((ref) {
  return CommunityNotifier(ref);
});

/// Check if current user can delete a post/reply
final canDeleteProvider = Provider.family<bool, String>((ref, authorId) {
  final authState = ref.watch(authControllerProvider);
  final currentUser = authState.profile;
  
  if (currentUser == null) return false;
  
  // Admin can delete anything
  if (currentUser.role.canModerate) return true;
  
  // User can delete their own
  return currentUser.id == authorId;
});
