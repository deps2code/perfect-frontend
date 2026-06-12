import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class GameSocket {
  GameSocket({
    required this.baseUrl,
    required this.playerId,
  });

  final String baseUrl;
  final String playerId;
  WebSocketChannel? _channel;

  Stream<Map<String, dynamic>> connect() {
    final baseUri = Uri.parse(baseUrl);
    final uri = baseUri.replace(queryParameters: {
      ...baseUri.queryParameters,
      'playerId': playerId,
    });
    _channel = WebSocketChannel.connect(uri);
    return _channel!.stream.map((event) {
      return jsonDecode(event as String) as Map<String, dynamic>;
    });
  }

  Future<void> get ready => _channel?.ready ?? Future<void>.value();

  void send(String type, String requestId, Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode({
      'type': type,
      'requestId': requestId,
      'payload': payload,
    }));
  }

  Future<void> close() async {
    await _channel?.sink.close();
  }
}
