class AppConfig {
  const AppConfig({
    required this.httpBaseUrl,
    required this.websocketBaseUrl,
  });

  final String httpBaseUrl;
  final String websocketBaseUrl;

  static AppConfig get local {
    const httpBaseUrl = String.fromEnvironment('HTTP_BASE_URL');
    const websocketBaseUrl = String.fromEnvironment('WEBSOCKET_BASE_URL');

    if (httpBaseUrl.isNotEmpty && websocketBaseUrl.isNotEmpty) {
      return const AppConfig(
        httpBaseUrl: httpBaseUrl,
        websocketBaseUrl: websocketBaseUrl,
      );
    }

    final host = Uri.base.host.isEmpty ? '127.0.0.1' : Uri.base.host;
    return AppConfig(
      httpBaseUrl: 'http://$host:8080',
      websocketBaseUrl: 'ws://$host:8080/ws',
    );
  }
}
