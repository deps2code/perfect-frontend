class AppConfig {
  const AppConfig({
    required this.httpBaseUrl,
    required this.websocketBaseUrl,
  });

  final String httpBaseUrl;
  final String websocketBaseUrl;

  static AppConfig get local {
    final host = Uri.base.host.isEmpty ? '127.0.0.1' : Uri.base.host;
    return AppConfig(
      httpBaseUrl: 'http://$host:8080',
      websocketBaseUrl: 'ws://$host:8080/ws',
    );
  }
}
