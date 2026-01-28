/// Core constants for the LAMP app
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'LAMP';
  static const String appFullName = 'Limitless Advancement Mentoring Program';
  static const String appVersion = '1.0.0';

  // Supported locales (as per PROJECT_CONSTITUTION)
  static const List<String> supportedLanguages = [
    'en', // English (default)
    'te', // Telugu
    'ta', // Tamil
    'hi', // Hindi
    'gu', // Gujarati
    'fr', // French
  ];

  static const String defaultLanguage = 'en';

  // User roles (as per ROLE_BEHAVIOR_MATRIX)
  static const String roleAdmin = 'admin';
  static const String roleChaperone = 'chaperone';
  static const String roleProtege = 'protege';
}
