class AppConfig {
  // Backend base URL
  // For Android emulator: http://10.0.2.2:3000
  // For iOS simulator: http://localhost:3000
  static const String baseUrl = 'http://10.0.2.2:3000';
  // Player Value AI service
  // For Android emulator: http://10.0.2.2:8300
  // For iOS simulator: http://localhost:8300
  static const String playerValueAiBaseUrl = 'http://10.0.2.2:8300';

  static String get apiBaseUrl => '$baseUrl/api';
}
