/// Supabase configuration for LAMP app
/// 
/// IMPORTANT: In production, these values should be loaded from
/// environment variables or a secure config management system.
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase project URL
  static const String supabaseUrl = 'https://lvwjbiokawwqguslwdid.supabase.co';

  /// Supabase anonymous key (safe for client-side)
  static const String supabaseAnonKey = 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2d2piaW9rYXd3cWd1c2x3ZGlkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk2MjQ1MTEsImV4cCI6MjA4NTIwMDUxMX0.iLUUob_vhsO6bx-N2iVd9HgQAmoJMbKoxhm7rK5dSpI';

  /// Storage bucket names
  static const String avatarsBucket = 'avatars';
  static const String attachmentsBucket = 'attachments';
}
