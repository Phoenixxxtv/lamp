import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Supabase service for database and auth operations
class SupabaseService {
  SupabaseService._();

  static SupabaseClient? _client;

  /// Initialize Supabase - call this in main() before runApp
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  /// Get the Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseService.initialize() first.');
    }
    return _client!;
  }

  /// Get the current authenticated user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get auth state stream
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // ===========================================================================
  // AUTH METHODS
  // ===========================================================================

  /// Sign in with email and password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email (used after invite validation)
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // ===========================================================================
  // INVITATION METHODS
  // ===========================================================================

  /// Validate an invite code
  static Future<Map<String, dynamic>?> validateInviteCode({
    required String email,
    required String code,
  }) async {
    final response = await client
        .from('invitations')
        .select()
        .eq('email', email)
        .eq('invite_code', code)
        .eq('used', false)
        .gt('expires_at', DateTime.now().toIso8601String())
        .maybeSingle();
    
    return response;
  }

  // ===========================================================================
  // PROFILE METHODS
  // ===========================================================================

  /// Get current user's profile
  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    if (currentUser == null) return null;
    
    return await client
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .maybeSingle();
  }

  /// Update current user's profile
  static Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (currentUser == null) throw Exception('Not authenticated');
    
    await client
        .from('profiles')
        .update(updates)
        .eq('id', currentUser!.id);
  }

  /// Get user role
  static Future<String?> getUserRole() async {
    final profile = await getCurrentProfile();
    return profile?['role'] as String?;
  }

  // ===========================================================================
  // INTERESTS METHODS
  // ===========================================================================

  /// Get all interests
  static Future<List<Map<String, dynamic>>> getInterests() async {
    final response = await client
        .from('interests')
        .select()
        .order('name');
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get user's interests
  static Future<List<Map<String, dynamic>>> getUserInterests(String userId) async {
    final response = await client
        .from('user_interests')
        .select('interest_id, interests(id, name)')
        .eq('user_id', userId);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // ===========================================================================
  // QUERY HELPERS
  // ===========================================================================

  /// Generic query helper
  static PostgrestFilterBuilder<List<Map<String, dynamic>>> from(String table) {
    return client.from(table).select();
  }

  /// Insert into table
  static Future<List<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    final response = await client.from(table).insert(data).select();
    return List<Map<String, dynamic>>.from(response);
  }

  /// Update in table
  static Future<void> update(
    String table,
    Map<String, dynamic> data,
    String column,
    dynamic value,
  ) async {
    await client.from(table).update(data).eq(column, value);
  }

  /// Delete from table
  static Future<void> delete(
    String table,
    String column,
    dynamic value,
  ) async {
    await client.from(table).delete().eq(column, value);
  }
}
