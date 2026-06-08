import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/websocket/game_socket.dart';

final lobbyControllerProvider =
    StateNotifierProvider<LobbyController, LobbyState>((ref) {
  return LobbyController();
});

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _playerIdController = TextEditingController(text: 'p1');
  final _roomCodeController = TextEditingController(text: 'room_1');

  @override
  void dispose() {
    _playerIdController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lobbyControllerProvider);
    final controller = ref.read(lobbyControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfect')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Lobby',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _playerIdController,
              decoration: const InputDecoration(
                labelText: 'Player ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roomCodeController,
              decoration: const InputDecoration(
                labelText: 'Room code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: state.connected
                  ? null
                  : () => controller.connect(_playerIdController.text.trim()),
              child: Text(state.connected ? 'Connected' : 'Connect'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: state.connected
                  ? () => controller.createRoom(_roomCodeController.text.trim())
                  : null,
              child: const Text('Create room'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: state.connected
                  ? () => controller.joinRoom(_roomCodeController.text.trim())
                  : null,
              child: const Text('Join room'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: state.connected
                  ? () => controller.startGame(_roomCodeController.text.trim())
                  : null,
              child: const Text('Start game'),
            ),
            const SizedBox(height: 16),
            if (state.error != null)
              Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(state.messages[index]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LobbyState {
  const LobbyState({
    this.connected = false,
    this.messages = const [],
    this.error,
  });

  final bool connected;
  final List<String> messages;
  final String? error;

  LobbyState copyWith({
    bool? connected,
    List<String>? messages,
    String? error,
  }) {
    return LobbyState(
      connected: connected ?? this.connected,
      messages: messages ?? this.messages,
      error: error,
    );
  }
}

class LobbyController extends StateNotifier<LobbyState> {
  LobbyController() : super(const LobbyState());

  GameSocket? _socket;
  int _requestNumber = 0;

  void connect(String playerId) {
    if (playerId.isEmpty) {
      state = state.copyWith(error: 'Player ID is required');
      return;
    }

    final socket = GameSocket(
      baseUrl: AppConfig.local.websocketBaseUrl,
      playerId: playerId,
    );
    _socket = socket;
    state = state.copyWith(
      connected: true,
      error: null,
      messages: [...state.messages, 'Connecting as $playerId'],
    );

    socket.connect().listen(
      (message) {
        state = state.copyWith(
          messages: [...state.messages, message.toString()],
          error: null,
        );
      },
      onError: (Object error) {
        state = state.copyWith(
          connected: false,
          error: error.toString(),
        );
      },
      onDone: () {
        state = state.copyWith(
          connected: false,
          messages: [...state.messages, 'Disconnected'],
        );
      },
    );
  }

  void createRoom(String roomId) {
    _sendRoomCommand('CREATE_ROOM', roomId);
  }

  void joinRoom(String roomId) {
    _sendRoomCommand('JOIN_ROOM', roomId);
  }

  void startGame(String roomId) {
    _sendRoomCommand('START_GAME', roomId);
  }

  void _sendRoomCommand(String type, String roomId) {
    if (roomId.isEmpty) {
      state = state.copyWith(error: 'Room code is required');
      return;
    }
    final requestId = 'req_${++_requestNumber}';
    _socket?.send(type, requestId, {'roomId': roomId});
    state = state.copyWith(
      error: null,
      messages: [...state.messages, '$type $roomId'],
    );
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }
}
