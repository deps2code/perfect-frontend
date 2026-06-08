class AppConfig {
  const AppConfig({
    required this.httpBaseUrl,
    required this.websocketBaseUrl,
  });

  final String httpBaseUrl;
  final String websocketBaseUrl;

  static const local = AppConfig(
    httpBaseUrl: 'http://localhost:8080',
    websocketBaseUrl: 'ws://localhost:8080/ws',
  );
}
