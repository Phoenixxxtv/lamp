import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../models/app_notification.dart';

// =============================================================================
// NOTIFICATIONS PROVIDERS
// =============================================================================

/// Fetch notifications for current user
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final userId = SupabaseService.currentUser?.id;
  if (userId == null) return [];

  try {
    final response = await SupabaseService.client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((json) => AppNotification.fromJson(json))
        .toList();
  } catch (e) {
    throw Exception('Failed to load notifications: $e');
  }
});

/// Unread notification count
final unreadCountProvider = FutureProvider<int>((ref) async {
  final userId = SupabaseService.currentUser?.id;
  if (userId == null) return 0;

  try {
    final response = await SupabaseService.client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (response as List).length;
  } catch (e) {
    return 0;
  }
});

// =============================================================================
// NOTIFICATIONS CONTROLLER
// =============================================================================

class NotificationsController {
  /// Mark single notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      await SupabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      return true;
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<bool> markAllAsRead() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await SupabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      return true;
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  /// Delete a notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      await SupabaseService.client
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      return true;
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Clear all notifications
  static Future<bool> clearAll() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await SupabaseService.client
          .from('notifications')
          .delete()
          .eq('user_id', userId);

      return true;
    } catch (e) {
      throw Exception('Failed to clear notifications: $e');
    }
  }
}

// =============================================================================
// STATE NOTIFIER
// =============================================================================

class NotificationsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  NotificationsNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<bool> markAsRead(String notificationId) async {
    try {
      await NotificationsController.markAsRead(notificationId);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    state = const AsyncValue.loading();
    try {
      await NotificationsController.markAllAsRead();
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await NotificationsController.deleteNotification(notificationId);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearAll() async {
    state = const AsyncValue.loading();
    try {
      await NotificationsController.clearAll();
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<void>>((ref) {
  return NotificationsNotifier(ref);
});
