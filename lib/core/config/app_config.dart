abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );

  static const maxStudyBytes = 20 * 1024 * 1024;
  static const maxAvatarBytes = 5 * 1024 * 1024;
}
