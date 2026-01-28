import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../models/user_profile.dart';
import '../models/invitation.dart';
import '../models/interest.dart';

// =============================================================================
// AUTH STATE
// =============================================================================

/// Auth state enum
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  needsProfileCompletion,
}

/// Combined auth state
class AuthState {
  final AuthStatus status;
  final UserProfile? profile;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.profile,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? profile,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: error,
    );
  }
}

// =============================================================================
// AUTH CONTROLLER
// =============================================================================

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState()) {
    _init();
  }

  /// Initialize auth state
  Future<void> _init() async {
    try {
      // Listen to auth state changes
      SupabaseService.authStateChanges.listen((data) {
        _handleAuthChange(data.session);
      });

      // Check current session
      final session = SupabaseService.client.auth.currentSession;
      await _handleAuthChange(session);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  /// Handle auth state change
  Future<void> _handleAuthChange(Session? session) async {
    if (session == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      // Fetch user profile
      final profileData = await SupabaseService.getCurrentProfile();
      
      if (profileData == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      final profile = UserProfile.fromJson(profileData);
      
      // Check if profile is complete
      if (!profile.isProfileComplete || !profile.isActive) {
        state = AuthState(
          status: AuthStatus.needsProfileCompletion,
          profile: profile,
        );
      } else {
        state = AuthState(
          status: AuthStatus.authenticated,
          profile: profile,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Validate invite code
  Future<Invitation?> validateInviteCode(String email, String code) async {
    try {
      final data = await SupabaseService.validateInviteCode(
        email: email,
        code: code,
      );
      
      if (data == null) return null;
      
      final invitation = Invitation.fromJson(data);
      return invitation.isValid ? invitation : null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Sign up with email and password (after invite validation)
  Future<bool> signUpWithInvite({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await SupabaseService.signUpWithEmail(
        email: email,
        password: password,
        metadata: {'name': name},
      );
      
      if (response.user != null) {
        await _handleAuthChange(response.session);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      final response = await SupabaseService.signInWithEmail(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        await _handleAuthChange(response.session);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Complete user profile
  Future<bool> completeProfile({
    required String name,
    required String phone,
    String? address,
    required String language,
    String? courseType,
    List<String>? interestIds,
  }) async {
    try {
      // Update profile
      await SupabaseService.updateProfile({
        'name': name,
        'phone': phone,
        'address': address,
        'language': language,
        'course_type': courseType,
        'is_active': true,
      });

      // Add interests if provided
      if (interestIds != null && interestIds.isNotEmpty) {
        final userId = SupabaseService.currentUser!.id;
        for (final interestId in interestIds) {
          await SupabaseService.insert('user_interests', {
            'user_id': userId,
            'interest_id': interestId,
          });
        }
      }

      // Refresh profile
      final profileData = await SupabaseService.getCurrentProfile();
      if (profileData != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          profile: UserProfile.fromJson(profileData),
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await SupabaseService.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// =============================================================================
// PROVIDERS
// =============================================================================

/// Auth controller provider
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});

/// Current user profile provider
final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authControllerProvider).profile;
});

/// Current user role provider
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentUserProfileProvider)?.role;
});

/// Auth status provider
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authControllerProvider).status;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStatusProvider) == AuthStatus.authenticated;
});

/// Interests list provider
final interestsProvider = FutureProvider<List<Interest>>((ref) async {
  try {
    final data = await SupabaseService.getInterests();
    return data.map((e) => Interest.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});
