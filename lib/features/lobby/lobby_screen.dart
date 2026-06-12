// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/websocket/game_socket.dart';
import '../game/models/game_snapshot.dart';

final appControllerProvider =
    StateNotifierProvider<AppController, AppState>((ref) {
  final config = AppConfig.local;
  final controller = AppController(config, GameApiClient(config));
  ref.onDispose(controller.dispose);
  return controller;
});

enum AppView { landing, lobby, game }

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _playerIdController = TextEditingController(text: 'p1');
  final _displayNameController = TextEditingController(text: 'Player One');
  final _roomCodeController = TextEditingController(text: 'room_1');
  final _totalRoundsController = TextEditingController(text: '3');
  final _bidController = TextEditingController(text: '0');
  String _trumpSuit = 'clubs';

  @override
  void dispose() {
    _playerIdController.dispose();
    _displayNameController.dispose();
    _roomCodeController.dispose();
    _totalRoundsController.dispose();
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      body: _CasinoShell(
        selected: state.view,
        profile: state.profile,
        onOpenLanding: () => controller.setView(AppView.landing),
        onOpenLobby: () => controller.setView(AppView.lobby),
        onOpenGame: state.snapshot == null
            ? null
            : () => controller.setView(AppView.game),
        child: switch (state.view) {
          AppView.landing => _LandingDashboard(
              state: state,
              playerIdController: _playerIdController,
              displayNameController: _displayNameController,
              roomCodeController: _roomCodeController,
              totalRoundsController: _totalRoundsController,
              onRegister: () => controller.register(
                _playerIdController.text.trim(),
                _displayNameController.text.trim(),
              ),
              onOpenLobby: () {
                controller.setView(AppView.lobby);
                controller.refreshRooms();
              },
              onCreateRoom: () => controller.createAndJoinRoom(
                _roomCodeController.text.trim(),
                int.tryParse(_totalRoundsController.text.trim()) ?? 3,
              ),
            ),
          AppView.lobby => _GameLobbyView(
              state: state,
              roomCodeController: _roomCodeController,
              totalRoundsController: _totalRoundsController,
              onRefresh: controller.refreshRooms,
              onCreateRoom: () => controller.createAndJoinRoom(
                _roomCodeController.text.trim(),
                int.tryParse(_totalRoundsController.text.trim()) ?? 3,
              ),
              onJoinRoom: controller.joinRoom,
              onStartGame: controller.startGame,
            ),
          AppView.game => _GameTableView(
              state: state,
              bidController: _bidController,
              trumpSuit: _trumpSuit,
              onTrumpChanged: (value) {
                if (value != null) {
                  setState(() => _trumpSuit = value);
                }
              },
              onBid: () => controller.placeBid(
                int.tryParse(_bidController.text.trim()) ?? 0,
              ),
              onSelectTrump: () => controller.selectTrump(_trumpSuit),
              onAcknowledgeRoundScore: controller.acknowledgeRoundScore,
              onPlayCard: controller.playCard,
              onBackToLobby: () => controller.setView(AppView.lobby),
            ),
        },
      ),
    );
  }
}

class _CasinoShell extends StatelessWidget {
  const _CasinoShell({
    required this.selected,
    required this.profile,
    required this.onOpenLanding,
    required this.onOpenLobby,
    required this.onOpenGame,
    required this.child,
  });

  final AppView selected;
  final Profile? profile;
  final VoidCallback onOpenLanding;
  final VoidCallback onOpenLobby;
  final VoidCallback? onOpenGame;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101B55), Color(0xFF031026), Color(0xFF071B3F)],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final nav = _SideNav(
              selected: selected,
              profile: profile,
              onOpenLanding: onOpenLanding,
              onOpenLobby: onOpenLobby,
              onOpenGame: onOpenGame,
              compact: !wide,
            );
            if (!wide) {
              return Column(
                children: [
                  nav,
                  Expanded(child: child),
                ],
              );
            }
            return Row(
              children: [
                SizedBox(width: 250, child: nav),
                Expanded(child: child),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.selected,
    required this.profile,
    required this.onOpenLanding,
    required this.onOpenLobby,
    required this.onOpenGame,
    required this.compact,
  });

  final AppView selected;
  final Profile? profile;
  final VoidCallback onOpenLanding;
  final VoidCallback onOpenLobby;
  final VoidCallback? onOpenGame;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = [
      if (!compact) const _BrandLockup(),
      _NavButton(
        label: 'Dashboard',
        icon: Icons.space_dashboard_rounded,
        selected: selected == AppView.landing,
        onPressed: onOpenLanding,
      ),
      _NavButton(
        label: 'Game Lobby',
        icon: Icons.grid_view_rounded,
        selected: selected == AppView.lobby,
        onPressed: onOpenLobby,
      ),
      _NavButton(
        label: 'Game Table',
        icon: Icons.table_bar_rounded,
        selected: selected == AppView.game,
        onPressed: onOpenGame,
      ),
      if (!compact) const Spacer(),
      if (profile != null)
        _MiniProfile(profile: profile!)
      else if (!compact)
        const _MutedText('Register to play online'),
    ];

    return Container(
      margin: EdgeInsets.all(compact ? 10 : 20),
      padding: EdgeInsets.all(compact ? 8 : 16),
      decoration: BoxDecoration(
        color: const Color(0xDD070D25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x2230E6FF)),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 24),
        ],
      ),
      child: compact
          ? Row(children: content.map((item) => Expanded(child: item)).toList())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: content),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [Color(0xFFFFD86A), Color(0xFF30E6FF)],
            ).createShader(rect),
            child: const Text(
              'PERFECT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const Text(
            'Trick Cards',
            style: TextStyle(
              color: Color(0xFF9DB0E7),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: TextButton.styleFrom(
          foregroundColor: selected ? Colors.white : const Color(0xFF7888BE),
          backgroundColor:
              selected ? const Color(0x332D93FF) : Colors.transparent,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _MiniProfile extends StatelessWidget {
  const _MiniProfile({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(profile: profile, size: 42),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800),
              ),
              Text(
                profile.playerId,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF7888BE), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LandingDashboard extends StatelessWidget {
  const _LandingDashboard({
    required this.state,
    required this.playerIdController,
    required this.displayNameController,
    required this.roomCodeController,
    required this.totalRoundsController,
    required this.onRegister,
    required this.onOpenLobby,
    required this.onCreateRoom,
  });

  final AppState state;
  final TextEditingController playerIdController;
  final TextEditingController displayNameController;
  final TextEditingController roomCodeController;
  final TextEditingController totalRoundsController;
  final VoidCallback onRegister;
  final VoidCallback onOpenLobby;
  final VoidCallback onCreateRoom;

  @override
  Widget build(BuildContext context) {
    return _ScreenScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(
              profile: state.profile,
              error: state.error,
              status: state.statusText),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 980;
              final hero = _HeroFeature(onOpenLobby: onOpenLobby);
              final register = _RegisterPanel(
                registered: state.profile != null,
                playerIdController: playerIdController,
                displayNameController: displayNameController,
                onRegister: onRegister,
              );
              if (!twoColumns) {
                return Column(
                    children: [hero, const SizedBox(height: 16), register]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: hero),
                  const SizedBox(width: 18),
                  Expanded(flex: 2, child: register),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          _QuickCreatePanel(
            roomCodeController: roomCodeController,
            totalRoundsController: totalRoundsController,
            enabled: state.profile != null,
            onCreateRoom: onCreateRoom,
          ),
          const SizedBox(height: 18),
          _LobbyPreview(rooms: state.rooms, onOpenLobby: onOpenLobby),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar(
      {required this.profile, required this.error, required this.status});

  final Profile? profile;
  final String? error;
  final String status;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Multiplayer card arena',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Color(0xFF9DB0E7), fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(error!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFFF6B8A))),
              ),
          ],
        );
        final profileView = profile == null
            ? null
            : ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 260 : 220),
                child: _MiniProfile(profile: profile!),
              );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              if (profileView != null) ...[
                const SizedBox(height: 8),
                profileView,
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            if (profileView != null) profileView,
          ],
        );
      },
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({required this.onOpenLobby});

  final VoidCallback onOpenLobby;

  @override
  Widget build(BuildContext context) {
    return _GlowPanel(
      height: 330,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _HeroPainter())),
          Positioned(
            left: 28,
            top: 34,
            right: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLAY PERFECT WITH FRIENDS',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bid, choose trump, take tricks, and climb the table across live rooms.',
                  style: TextStyle(
                      color: Color(0xFFC7D2FF), fontSize: 18, height: 1.25),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onOpenLobby,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Open Lobby'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB72B),
                    foregroundColor: const Color(0xFF151022),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
              right: 34,
              top: 38,
              child: _FloatingCard(rank: 'A', suit: 'spades', angle: -0.18)),
          const Positioned(
              right: 102,
              top: 74,
              child: _FloatingCard(rank: 'K', suit: 'hearts', angle: 0.14)),
          const Positioned(
              right: 64, bottom: 28, child: _NeonChip(label: 'LIVE')),
        ],
      ),
    );
  }
}

class _RegisterPanel extends StatelessWidget {
  const _RegisterPanel({
    required this.registered,
    required this.playerIdController,
    required this.displayNameController,
    required this.onRegister,
  });

  final bool registered;
  final TextEditingController playerIdController;
  final TextEditingController displayNameController;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return _GlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelTitle(
              icon: Icons.person_add_alt_1_rounded, title: 'Register'),
          const SizedBox(height: 16),
          _DarkField(controller: playerIdController, label: 'Player ID'),
          const SizedBox(height: 12),
          _DarkField(controller: displayNameController, label: 'Display name'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: registered ? null : onRegister,
            icon: Icon(
                registered ? Icons.check_circle_rounded : Icons.login_rounded),
            label: Text(registered ? 'Registered' : 'Register profile'),
          ),
          const SizedBox(height: 10),
          const _MutedText(
              'MVP accounts are temporary and reset when the backend restarts.'),
        ],
      ),
    );
  }
}

class _QuickCreatePanel extends StatelessWidget {
  const _QuickCreatePanel({
    required this.roomCodeController,
    required this.totalRoundsController,
    required this.enabled,
    required this.onCreateRoom,
  });

  final TextEditingController roomCodeController;
  final TextEditingController totalRoundsController;
  final bool enabled;
  final VoidCallback onCreateRoom;

  @override
  Widget build(BuildContext context) {
    return _GlowPanel(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const SizedBox(
              width: 180,
              child: _PanelTitle(
                  icon: Icons.add_box_rounded, title: 'Host a table')),
          SizedBox(
              width: 190,
              child: _DarkField(
                  controller: roomCodeController, label: 'Room code')),
          SizedBox(
            width: 130,
            child: _DarkField(
              controller: totalRoundsController,
              label: 'Rounds',
              keyboardType: TextInputType.number,
            ),
          ),
          FilledButton.icon(
            onPressed: enabled ? onCreateRoom : null,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Create room'),
          ),
        ],
      ),
    );
  }
}

class _LobbyPreview extends StatelessWidget {
  const _LobbyPreview({required this.rooms, required this.onOpenLobby});

  final List<RoomSummary> rooms;
  final VoidCallback onOpenLobby;

  @override
  Widget build(BuildContext context) {
    final visible = rooms.take(3).toList();
    return _GlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                  child: _PanelTitle(
                      icon: Icons.casino_rounded, title: 'Running games')),
              TextButton(onPressed: onOpenLobby, child: const Text('See all')),
            ],
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const _MutedText('No active rooms yet.')
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: visible.map((room) => _RoomTile(room: room)).toList(),
            ),
        ],
      ),
    );
  }
}

class _GameLobbyView extends StatelessWidget {
  const _GameLobbyView({
    required this.state,
    required this.roomCodeController,
    required this.totalRoundsController,
    required this.onRefresh,
    required this.onCreateRoom,
    required this.onJoinRoom,
    required this.onStartGame,
  });

  final AppState state;
  final TextEditingController roomCodeController;
  final TextEditingController totalRoundsController;
  final VoidCallback onRefresh;
  final VoidCallback onCreateRoom;
  final ValueChanged<String> onJoinRoom;
  final ValueChanged<String> onStartGame;

  @override
  Widget build(BuildContext context) {
    return _ScreenScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(
              profile: state.profile,
              error: state.error,
              status: 'Choose a live table'),
          const SizedBox(height: 18),
          _QuickCreatePanel(
            roomCodeController: roomCodeController,
            totalRoundsController: totalRoundsController,
            enabled: state.profile != null,
            onCreateRoom: onCreateRoom,
          ),
          const SizedBox(height: 18),
          _GlowPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PanelTitle(
                        icon: Icons.grid_view_rounded,
                        title:
                            'Game lobby (${state.rooms.length} room${state.rooms.length == 1 ? '' : 's'})',
                      ),
                    ),
                    IconButton(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh_rounded)),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.rooms.isEmpty)
                  const _MutedText('No rooms are running. Create one to start.')
                else
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: state.rooms.map((room) {
                      return _LobbyRoomCard(
                        room: room,
                        canUse: state.profile != null,
                        currentPlayerId: state.profile?.playerId,
                        onJoin: () => onJoinRoom(room.roomId),
                        onStart: () => onStartGame(room.roomId),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyRoomCard extends StatelessWidget {
  const _LobbyRoomCard({
    required this.room,
    required this.canUse,
    required this.currentPlayerId,
    required this.onJoin,
    required this.onStart,
  });

  final RoomSummary room;
  final bool canUse;
  final String? currentPlayerId;
  final VoidCallback onJoin;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final isHost =
        currentPlayerId != null && currentPlayerId == room.hostPlayerId;
    final canStart = canUse && isHost && room.canStart;
    return SizedBox(
      width: 310,
      child: _GlowPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    room.roomId,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900),
                  ),
                ),
                _StatusPill(text: room.status),
              ],
            ),
            const SizedBox(height: 14),
            _RoomMetric(
                label: 'Players', value: '${room.players}/${room.maxPlayers}'),
            _RoomMetric(
                label: 'Host',
                value: room.hostPlayerId.isEmpty ? '-' : room.hostPlayerId),
            _RoomMetric(
                label: 'Round',
                value: '${room.roundNumber}/${room.totalRounds}'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canUse && room.canJoin ? onJoin : null,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Join'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canStart ? onStart : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GameTableView extends StatefulWidget {
  const _GameTableView({
    required this.state,
    required this.bidController,
    required this.trumpSuit,
    required this.onTrumpChanged,
    required this.onBid,
    required this.onSelectTrump,
    required this.onAcknowledgeRoundScore,
    required this.onPlayCard,
    required this.onBackToLobby,
  });

  final AppState state;
  final TextEditingController bidController;
  final String trumpSuit;
  final ValueChanged<String?> onTrumpChanged;
  final VoidCallback onBid;
  final VoidCallback onSelectTrump;
  final VoidCallback onAcknowledgeRoundScore;
  final ValueChanged<String> onPlayCard;
  final VoidCallback onBackToLobby;

  @override
  State<_GameTableView> createState() => _GameTableViewState();
}

class _GameTableViewState extends State<_GameTableView> {
  int? _shownRoundScoreRound;
  bool _scoreDialogOpen = false;
  late final ValueNotifier<int> _roundScoreAckCount;

  @override
  void initState() {
    super.initState();
    _roundScoreAckCount =
        ValueNotifier(widget.state.snapshot?.roundScoreAckCount ?? 0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showScoreDialog());
  }

  @override
  void dispose() {
    _roundScoreAckCount.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _GameTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _roundScoreAckCount.value = widget.state.snapshot?.roundScoreAckCount ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showScoreDialog());
  }

  Future<void> _showScoreDialog() async {
    if (!mounted || _scoreDialogOpen) {
      return;
    }
    final snapshot = widget.state.snapshot;
    if (snapshot == null || snapshot.roundScores.isEmpty) {
      return;
    }
    final latest = snapshot.roundScores.last;
    if (_shownRoundScoreRound == latest.roundNumber) {
      return;
    }

    _scoreDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _RoundScoreModal(
              snapshot: snapshot,
              ackCount: _roundScoreAckCount,
              onClose: () {
                if (snapshot.viewerAvailableActions
                    .contains('ACK_ROUND_SCORE')) {
                  widget.onAcknowledgeRoundScore();
                  _roundScoreAckCount.value = math.min(
                      snapshot.players.length, _roundScoreAckCount.value + 1);
                }
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _shownRoundScoreRound = latest.roundNumber;
      _scoreDialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.state.snapshot;
    if (snapshot == null) {
      return _ScreenScroll(
        child: _GlowPanel(
          child: Column(
            children: [
              const _MutedText('Join a room to open the game table.'),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: widget.onBackToLobby,
                  child: const Text('Open lobby')),
            ],
          ),
        ),
      );
    }

    final me = snapshot.player(widget.state.profile?.playerId ?? '');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: _TopBar(
            profile: widget.state.profile,
            error: widget.state.error,
            status:
                'Room ${widget.state.activeRoomId ?? snapshot.id} - ${snapshot.status}',
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _TableScene(
              snapshot: snapshot,
              viewerPlayerId: widget.state.profile?.playerId ?? '',
              onPlayCard: widget.onPlayCard,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _GameActionBar(
            snapshot: snapshot,
            me: me,
            bidController: widget.bidController,
            trumpSuit: widget.trumpSuit,
            onTrumpChanged: widget.onTrumpChanged,
            onBid: widget.onBid,
            onSelectTrump: widget.onSelectTrump,
          ),
        ),
      ],
    );
  }
}

class _TableScene extends StatefulWidget {
  const _TableScene({
    required this.snapshot,
    required this.viewerPlayerId,
    required this.onPlayCard,
  });

  final GameSnapshot snapshot;
  final String viewerPlayerId;
  final ValueChanged<String> onPlayCard;

  @override
  State<_TableScene> createState() => _TableSceneState();
}

class _TableSceneState extends State<_TableScene>
    with TickerProviderStateMixin {
  late final AnimationController _dealController;
  late final AnimationController _pulseController;
  int _lastVersion = -1;
  int _lastHandSize = -1;

  @override
  void initState() {
    super.initState();
    _dealController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 720));
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _TableScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    final me = widget.snapshot.player(widget.viewerPlayerId);
    final handSize = me?.handSize ?? 0;
    if (widget.snapshot.version != _lastVersion && handSize > _lastHandSize) {
      _dealController.forward(from: 0);
    }
    _lastVersion = widget.snapshot.version;
    _lastHandSize = handSize;
  }

  @override
  void dispose() {
    _dealController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final me = snapshot.player(widget.viewerPlayerId);
    final others = snapshot.players
        .where((player) => player.id != widget.viewerPlayerId)
        .toList();
    final legalCards = snapshot.viewerLegalCardIds.toSet();
    final canPlay = snapshot.viewerAvailableActions.contains('PLAY_CARD');

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _TablePainter(
                  trumpSuit: snapshot.trumpSuit,
                  leadSuit: snapshot.leadSuit,
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _OpponentRing(
                  players: others,
                  activePlayerId: snapshot.currentTurnPlayerId,
                  pulse: _pulseController,
                ),
              ),
            ),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _TrickPile(snapshot: snapshot),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: _TableSuitBadges(
                trumpSuit: snapshot.trumpSuit,
                leadSuit: snapshot.leadSuit,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: _PlayerHandFan(
                player: me,
                legalCardIds: legalCards,
                canPlay: canPlay,
                dealAnimation: _dealController,
                onPlayCard: widget.onPlayCard,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OpponentRing extends StatelessWidget {
  const _OpponentRing({
    required this.players,
    required this.activePlayerId,
    required this.pulse,
  });

  final List<PlayerSnapshot> players;
  final String? activePlayerId;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final center =
            Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        final radiusX = constraints.maxWidth * 0.39;
        final radiusY = constraints.maxHeight * 0.31;
        return Stack(
          children: List.generate(players.length, (index) {
            final player = players[index];
            final angle = -math.pi / 2 +
                (2 * math.pi * index / math.max(players.length, 1));
            final position = Offset(center.dx + math.cos(angle) * radiusX,
                center.dy + math.sin(angle) * radiusY);
            return Positioned(
              left: position.dx - 82,
              top: position.dy - 54,
              width: 164,
              child: _OpponentSeat(
                player: player,
                active: player.id == activePlayerId,
                pulse: pulse,
              ),
            );
          }),
        );
      },
    );
  }
}

class _OpponentSeat extends StatelessWidget {
  const _OpponentSeat({
    required this.player,
    required this.active,
    required this.pulse,
  });

  final PlayerSnapshot player;
  final bool active;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final glow = active ? 0.35 + pulse.value * 0.45 : 0.12;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xDD07122C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Color.lerp(
                    const Color(0xFF263B78), const Color(0xFF30E6FF), glow)!),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF30E6FF)
                      .withOpacity(active ? glow * 0.35 : 0),
                  blurRadius: 20),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        children: [
          Text(
            player.id,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(math.min(player.handSize, 8), (index) {
                return Transform.translate(
                  offset:
                      Offset((index - math.min(player.handSize, 8) / 2) * 9, 0),
                  child: const _TinyCardBack(),
                );
              }),
            ),
          ),
          Text(
            'Bid ${player.hasBid ? player.bid : '-'}  Tricks ${player.tricksWon}',
            style: const TextStyle(color: Color(0xFF9DB0E7), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TrickPile extends StatelessWidget {
  const _TrickPile({required this.snapshot});

  final GameSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x77040A18),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0x5530E6FF)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Round ${snapshot.roundNumber}/${snapshot.totalRounds}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Turn: ${snapshot.currentTurnPlayerId ?? '-'}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF9DB0E7)),
          ),
          const SizedBox(height: 8),
          if (snapshot.currentTrick.isEmpty)
            const _MutedText('Waiting for first card')
          else
            SizedBox(
              height: 76,
              child: Stack(
                alignment: Alignment.center,
                children: List.generate(snapshot.currentTrick.length, (index) {
                  final played = snapshot.currentTrick[index];
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    left: 38.0 + index * 42,
                    top: 4,
                    child: _MiniPlayingCard(
                        card: played.card, label: played.playerId),
                  );
                }),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'Trump ${_suitDisplay(snapshot.trumpSuit)}  Lead ${_suitDisplay(snapshot.leadSuit)}',
            style: const TextStyle(
                color: Color(0xFFFFD86A),
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PlayerHandFan extends StatelessWidget {
  const _PlayerHandFan({
    required this.player,
    required this.legalCardIds,
    required this.canPlay,
    required this.dealAnimation,
    required this.onPlayCard,
  });

  final PlayerSnapshot? player;
  final Set<String> legalCardIds;
  final bool canPlay;
  final Animation<double> dealAnimation;
  final ValueChanged<String> onPlayCard;

  @override
  Widget build(BuildContext context) {
    final cards = player?.hand ?? <CardSnapshot>[];
    if (cards.isEmpty) {
      return const Center(child: _MutedText('Your cards will appear here.'));
    }

    return AnimatedBuilder(
      animation: dealAnimation,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            const cardWidth = 92.0;
            final handWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : cards.length * 68.0 + cardWidth;
            final centerX = handWidth / 2;

            return SizedBox(
              width: handWidth,
              height: 166,
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(cards.length, (index) {
                  final card = cards[index];
                  final fanOffset = (index - (cards.length - 1) / 2) * 68;
                  final angle = (index - (cards.length - 1) / 2) * 0.045;
                  final isLegal =
                      legalCardIds.isEmpty || legalCardIds.contains(card.id);
                  final enabled = canPlay && isLegal;
                  final arrival =
                      Curves.easeOutBack.transform(dealAnimation.value);
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    left: centerX + fanOffset - cardWidth / 2,
                    bottom: enabled ? 16 : 0,
                    child: Transform.translate(
                      offset: Offset(0, (1 - arrival) * 80),
                      child: Transform.rotate(
                        angle: angle,
                        child: _LargePlayingCard(
                          card: card,
                          enabled: enabled,
                          legal: isLegal,
                          onTap: () => onPlayCard(card.id),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }
}

class _GameActionBar extends StatelessWidget {
  const _GameActionBar({
    required this.snapshot,
    required this.me,
    required this.bidController,
    required this.trumpSuit,
    required this.onTrumpChanged,
    required this.onBid,
    required this.onSelectTrump,
  });

  final GameSnapshot snapshot;
  final PlayerSnapshot? me;
  final TextEditingController bidController;
  final String trumpSuit;
  final ValueChanged<String?> onTrumpChanged;
  final VoidCallback onBid;
  final VoidCallback onSelectTrump;

  @override
  Widget build(BuildContext context) {
    final actions = snapshot.viewerAvailableActions;
    final isMyTurn = snapshot.currentTurnPlayerId == me?.id;
    return _GlowPanel(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _RoomMetric(label: 'Score', value: '${me?.totalScore ?? 0}'),
          _RoomMetric(
              label: 'Bid', value: me?.hasBid == true ? '${me!.bid}' : '-'),
          _RoomMetric(label: 'Tricks', value: '${me?.tricksWon ?? 0}'),
          if (actions.isEmpty)
            _NeonChip(
              label: isMyTurn
                  ? 'WAITING FOR GAME STATE'
                  : 'WAITING FOR ${snapshot.currentTurnPlayerId ?? 'START'}',
            ),
          if (actions.contains('PLACE_BID')) ...[
            SizedBox(
              width: 110,
              child: _DarkField(
                controller: bidController,
                label: 'Bid',
                keyboardType: TextInputType.number,
              ),
            ),
            FilledButton(onPressed: onBid, child: const Text('Place bid')),
          ],
          if (actions.contains('SELECT_TRUMP')) ...[
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: trumpSuit,
                dropdownColor: const Color(0xFF07122C),
                decoration: _darkInputDecoration('Trump'),
                style: const TextStyle(color: Colors.white),
                items: [
                  DropdownMenuItem(
                      value: 'clubs',
                      child: Text('${_suitSymbol('clubs')} Clubs')),
                  DropdownMenuItem(
                      value: 'diamonds',
                      child: Text('${_suitSymbol('diamonds')} Diamonds')),
                  DropdownMenuItem(
                      value: 'hearts',
                      child: Text('${_suitSymbol('hearts')} Hearts')),
                  DropdownMenuItem(
                      value: 'spades',
                      child: Text('${_suitSymbol('spades')} Spades')),
                ],
                onChanged: onTrumpChanged,
              ),
            ),
            FilledButton(
                onPressed: onSelectTrump, child: const Text('Select trump')),
          ],
          if (actions.contains('PLAY_CARD'))
            const _NeonChip(label: 'PLAY A HIGHLIGHTED CARD'),
        ],
      ),
    );
  }
}

class _TableSuitBadges extends StatelessWidget {
  const _TableSuitBadges({required this.trumpSuit, required this.leadSuit});

  final String? trumpSuit;
  final String? leadSuit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SuitBadge(label: 'Trump', suit: trumpSuit),
        const SizedBox(width: 8),
        _SuitBadge(label: 'Lead', suit: leadSuit),
      ],
    );
  }
}

class _SuitBadge extends StatelessWidget {
  const _SuitBadge({required this.label, required this.suit});

  final String label;
  final String? suit;

  @override
  Widget build(BuildContext context) {
    final symbol = _suitDisplay(suit);
    final red = suit != null && _isRedSuit(suit!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xDD07122C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x5530E6FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: Color(0xFF9DB0E7),
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Text(
            symbol,
            style: TextStyle(
                color: red ? const Color(0xFFFF6B8A) : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _RoundScoreModal extends StatelessWidget {
  const _RoundScoreModal({
    required this.snapshot,
    required this.ackCount,
    required this.onClose,
  });

  final GameSnapshot snapshot;
  final ValueListenable<int> ackCount;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final latest = snapshot.roundScores.last;
    final isFinalScore = snapshot.status == 'FINISHED';
    final winnerIds = snapshot.winnerPlayerIds.toSet();
    final ranked = [...latest.players]..sort((a, b) {
        final scoreCompare = b.totalScore.compareTo(a.totalScore);
        if (scoreCompare != 0) {
          return scoreCompare;
        }
        return a.playerId.compareTo(b.playerId);
      });

    return _GlowPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _PanelTitle(
                    icon: isFinalScore
                        ? Icons.emoji_events_rounded
                        : Icons.leaderboard_rounded,
                    title: isFinalScore
                        ? 'Final scores'
                        : 'Round ${latest.roundNumber} scores'),
              ),
              ValueListenableBuilder<int>(
                valueListenable: ackCount,
                builder: (context, value, child) {
                  return _NeonChip(
                      label: '$value/${snapshot.players.length} CLOSED');
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 34,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 42,
              columnSpacing: 22,
              headingTextStyle: const TextStyle(
                  color: Color(0xFF9DB0E7),
                  fontSize: 12,
                  fontWeight: FontWeight.w800),
              dataTextStyle: const TextStyle(color: Colors.white),
              columns: const [
                DataColumn(label: Text('Rank')),
                DataColumn(label: Text('Player')),
                DataColumn(label: Text('Bid')),
                DataColumn(label: Text('Tricks')),
                DataColumn(label: Text('Round')),
                DataColumn(label: Text('Total')),
              ],
              rows: List.generate(ranked.length, (index) {
                final score = ranked[index];
                final previous =
                    index == 0 ? null : ranked[index - 1].totalScore;
                final rank = previous == score.totalScore ? null : index + 1;
                final displayedRank = rank ??
                    1 +
                        ranked.indexWhere(
                            (item) => item.totalScore == score.totalScore);
                final isWinner = winnerIds.contains(score.playerId);
                return DataRow(
                  color: isWinner
                      ? MaterialStateProperty.all(const Color(0x332FE6A6))
                      : null,
                  cells: [
                    DataCell(Text('$displayedRank')),
                    DataCell(Text(score.playerId)),
                    DataCell(Text('${score.bid}')),
                    DataCell(Text('${score.tricksWon}')),
                    DataCell(Text('+${score.scoreEarned}')),
                    DataCell(Text('${score.totalScore}')),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onClose,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                  snapshot.viewerAvailableActions.contains('ACK_ROUND_SCORE')
                      ? 'Close and continue'
                      : 'Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LargePlayingCard extends StatefulWidget {
  const _LargePlayingCard({
    required this.card,
    required this.enabled,
    required this.legal,
    required this.onTap,
  });

  final CardSnapshot card;
  final bool enabled;
  final bool legal;
  final VoidCallback onTap;

  @override
  State<_LargePlayingCard> createState() => _LargePlayingCardState();
}

class _LargePlayingCardState extends State<_LargePlayingCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final red = _isRedSuit(widget.card.suit);
    final border = widget.enabled
        ? const Color(0xFFFFD86A)
        : widget.legal
            ? const Color(0xFFDBE6FF)
            : const Color(0xFF526080);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: widget.enabled && _hovered ? 1.08 : 1,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: widget.legal ? 1 : 0.48,
            child: Container(
              width: 92,
              height: 128,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: border, width: widget.enabled ? 3 : 1.5),
                boxShadow: [
                  BoxShadow(
                      color: border.withOpacity(widget.enabled ? 0.45 : 0.12),
                      blurRadius: 18),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(widget.card.rank,
                        style: TextStyle(
                            color: red ? Colors.red : Colors.black,
                            fontWeight: FontWeight.w900)),
                  ),
                  Text(_suitSymbol(widget.card.suit),
                      style: TextStyle(
                          color: red ? Colors.red : Colors.black,
                          fontSize: 36,
                          fontWeight: FontWeight.w900)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(widget.card.rank,
                        style: TextStyle(
                            color: red ? Colors.red : Colors.black,
                            fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPlayingCard extends StatelessWidget {
  const _MiniPlayingCard({required this.card, required this.label});

  final CardSnapshot card;
  final String label;

  @override
  Widget build(BuildContext context) {
    final red = _isRedSuit(card.suit);
    return Column(
      children: [
        Container(
          width: 46,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFD86A)),
          ),
          child: Center(
            child: Text(
              '${card.rank}\n${_suitSymbol(card.suit)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: red ? Colors.red : Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 13),
            ),
          ),
        ),
        SizedBox(
          width: 54,
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9DB0E7), fontSize: 10)),
        ),
      ],
    );
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard(
      {required this.rank, required this.suit, required this.angle});

  final String rank;
  final String suit;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: _LargePlayingCard(
        card: CardSnapshot(
            id: '${rank}_of_$suit', rank: rank, suit: suit, value: 14),
        enabled: false,
        legal: true,
        onTap: () {},
      ),
    );
  }
}

class _TinyCardBack extends StatelessWidget {
  const _TinyCardBack();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF234CFF), Color(0xFF1BE7FF)]),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white24),
      ),
    );
  }
}

class _GlowPanel extends StatelessWidget {
  const _GlowPanel({
    required this.child,
    this.height,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final double? height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xCC09122F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x2430E6FF)),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 26)],
      ),
      child: child,
    );
  }
}

class _ScreenScroll extends StatelessWidget {
  const _ScreenScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF30E6FF)),
        const SizedBox(width: 8),
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _DarkField extends StatelessWidget {
  const _DarkField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _darkInputDecoration(label),
    );
  }
}

InputDecoration _darkInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF9DB0E7)),
    filled: true,
    fillColor: const Color(0xFF07122C),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF263B78)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF30E6FF)),
    ),
  );
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: Color(0xFF9DB0E7)));
  }
}

class _NeonChip extends StatelessWidget {
  const _NeonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x2230E6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF30E6FF)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: text == 'WAITING'
            ? const Color(0x3345F36C)
            : const Color(0x33FFB72B),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }
}

class _RoomMetric extends StatelessWidget {
  const _RoomMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 6),
      child: RichText(
        text: TextSpan(
          text: '$label ',
          style: const TextStyle(color: Color(0xFF7888BE), fontSize: 13),
          children: [
            TextSpan(
                text: value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room});

  final RoomSummary room;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF07122C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF263B78)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(room.roomId,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _RoomMetric(
              label: 'Players', value: '${room.players}/${room.maxPlayers}'),
          _StatusPill(text: room.status),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile, required this.size});

  final Profile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient:
            LinearGradient(colors: [profile.color, const Color(0xFF30E6FF)]),
      ),
      child: Center(
        child: Text(
          profile.displayName.isEmpty
              ? '?'
              : profile.displayName[0].toUpperCase(),
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.42),
        ),
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF173688), Color(0xFF04A06C), Color(0xFF0E55A6)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(BorderRadius.circular(18).toRRect(Offset.zero & size), bg);

    final line = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 8; i++) {
      canvas.drawLine(Offset(size.width * 0.48 + i * 48, -20),
          Offset(size.width * 0.18 + i * 64, size.height + 20), line);
    }

    final orb = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFFB72B).withOpacity(0.35), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.78, size.height * 0.42), radius: 170));
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.42), 170, orb);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TablePainter extends CustomPainter {
  const _TablePainter({required this.trumpSuit, required this.leadSuit});

  final String? trumpSuit;
  final String? leadSuit;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()..color = const Color(0xFF06122B);
    canvas.drawRRect(BorderRadius.circular(26).toRRect(rect), bg);

    final center = Offset(size.width / 2, size.height / 2);
    final tableRect = Rect.fromCenter(
        center: center, width: size.width * 0.72, height: size.height * 0.58);
    final tablePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF0B9A6B), Color(0xFF07583F), Color(0xFF033025)],
      ).createShader(tableRect);
    canvas.drawOval(tableRect, tablePaint);

    final rail = Paint()
      ..color = const Color(0xFF10235C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22;
    canvas.drawOval(tableRect.inflate(12), rail);

    final neon = Paint()
      ..color = const Color(0xFF30E6FF).withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(tableRect.inflate(25), neon);
  }

  @override
  bool shouldRepaint(covariant _TablePainter oldDelegate) {
    return oldDelegate.trumpSuit != trumpSuit ||
        oldDelegate.leadSuit != leadSuit;
  }
}

String _suitSymbol(String suit) {
  return switch (suit) {
    'clubs' => '♣',
    'diamonds' => '♦',
    'hearts' => '♥',
    'spades' => '♠',
    _ => '?',
  };
}

String _suitDisplay(String? suit) {
  if (suit == null || suit.isEmpty) {
    return '-';
  }
  return _suitSymbol(suit);
}

bool _isRedSuit(String suit) {
  return suit == 'hearts' || suit == 'diamonds';
}

class GameApiClient {
  const GameApiClient(this.config);

  final AppConfig config;

  Future<Profile> register(String playerId, String displayName) async {
    final response = await _request(
      'POST',
      '/auth/register',
      body: {'playerId': playerId, 'displayName': displayName},
    );
    return Profile.fromJson(response);
  }

  Future<Profile> currentUser() async {
    final response = await _request('GET', '/me');
    return Profile.fromJson(response);
  }

  Future<List<RoomSummary>> rooms() async {
    final response = await _request('GET', '/rooms');
    return ((response['rooms'] as List<dynamic>?) ?? [])
        .map((item) => RoomSummary.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.roomId.compareTo(b.roomId));
  }

  Future<RoomSummary> createRoom(String roomId, int totalRounds) async {
    final response = await _request(
      'POST',
      '/rooms',
      body: {'roomId': roomId, 'totalRounds': totalRounds},
    );
    return RoomSummary.fromJson(response);
  }

  Future<Map<String, dynamic>> _request(String method, String path,
      {Map<String, dynamic>? body}) async {
    final request = await html.HttpRequest.request(
      '${config.httpBaseUrl}$path',
      method: method,
      requestHeaders: {'Content-Type': 'application/json'},
      sendData: body == null ? null : jsonEncode(body),
      withCredentials: true,
    );
    final status = request.status ?? 0;
    final text = request.responseText ?? '{}';
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    if (status < 200 || status >= 300) {
      throw ApiException(
        (decoded['error'] as String?) ?? 'request failed',
        statusCode: status,
      );
    }
    return decoded;
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class Profile {
  const Profile({
    required this.playerId,
    required this.displayName,
    required this.avatar,
    required this.color,
  });

  final String playerId;
  final String displayName;
  final String avatar;
  final Color color;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      playerId: json['playerId'] as String,
      displayName: json['displayName'] as String,
      avatar: json['avatar'] as String? ?? 'nova',
      color: _colorFromHex(json['color'] as String? ?? '#30E6FF'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'displayName': displayName,
      'avatar': avatar,
      'color': '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    };
  }
}

class RoomSummary {
  const RoomSummary({
    required this.roomId,
    required this.status,
    required this.players,
    required this.maxPlayers,
    required this.hostPlayerId,
    required this.roundNumber,
    required this.totalRounds,
    required this.canJoin,
    required this.canStart,
  });

  final String roomId;
  final String status;
  final int players;
  final int maxPlayers;
  final String hostPlayerId;
  final int roundNumber;
  final int totalRounds;
  final bool canJoin;
  final bool canStart;

  factory RoomSummary.fromJson(Map<String, dynamic> json) {
    return RoomSummary(
      roomId: json['roomId'] as String,
      status: json['status'] as String,
      players: json['players'] as int,
      maxPlayers: json['maxPlayers'] as int,
      hostPlayerId: json['hostPlayerId'] as String? ?? '',
      roundNumber: json['roundNumber'] as int? ?? 0,
      totalRounds: json['totalRounds'] as int? ?? 0,
      canJoin: json['canJoin'] as bool? ?? false,
      canStart: json['canStart'] as bool? ?? false,
    );
  }
}

class AppState {
  const AppState({
    this.view = AppView.landing,
    this.profile,
    this.rooms = const [],
    this.snapshot,
    this.activeRoomId,
    this.connected = false,
    this.error,
    this.statusText = 'Welcome to Perfect',
  });

  final AppView view;
  final Profile? profile;
  final List<RoomSummary> rooms;
  final GameSnapshot? snapshot;
  final String? activeRoomId;
  final bool connected;
  final String? error;
  final String statusText;

  AppState copyWith({
    AppView? view,
    Profile? profile,
    List<RoomSummary>? rooms,
    GameSnapshot? snapshot,
    String? activeRoomId,
    bool? connected,
    String? error,
    String? statusText,
    bool clearProfile = false,
    bool clearSnapshot = false,
    bool clearActiveRoom = false,
  }) {
    return AppState(
      view: view ?? this.view,
      profile: clearProfile ? null : profile ?? this.profile,
      rooms: rooms ?? this.rooms,
      snapshot: clearSnapshot ? null : snapshot ?? this.snapshot,
      activeRoomId: clearActiveRoom ? null : activeRoomId ?? this.activeRoomId,
      connected: connected ?? this.connected,
      error: error,
      statusText: statusText ?? this.statusText,
    );
  }
}

class AppController extends StateNotifier<AppState> {
  AppController(this._config, this._api) : super(const AppState()) {
    _loadCurrentUser();
    refreshRooms();
    _poller = Timer.periodic(const Duration(seconds: 4), (_) => refreshRooms());
  }

  final AppConfig _config;
  final GameApiClient _api;
  GameSocket? _socket;
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  Timer? _poller;
  int _requestNumber = 0;

  void setView(AppView view) {
    state = state.copyWith(view: view, error: null);
  }

  Future<void> register(String playerId, String displayName) async {
    if (playerId.isEmpty) {
      state = state.copyWith(error: 'Player ID is required');
      return;
    }
    try {
      Profile profile;
      try {
        profile = await _api.register(playerId, displayName);
      } on ApiException catch (error) {
        state = state.copyWith(error: error.toString());
        return;
      }
      state = state.copyWith(
          profile: profile,
          error: null,
          statusText: 'Welcome, ${profile.displayName}');
      await refreshRooms();
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  Future<void> refreshRooms() async {
    try {
      final rooms = await _api.rooms();
      state = state.copyWith(rooms: rooms, error: null);
    } catch (error) {
      state = state.copyWith(
        error: 'Could not refresh lobby: $error',
        statusText: state.statusText,
      );
    }
  }

  Future<void> createAndJoinRoom(String roomId, int totalRounds) async {
    if (!_requireProfile() || !_requireRoom(roomId)) {
      return;
    }
    if (totalRounds < 1) {
      state = state.copyWith(error: 'Rounds must be at least 1');
      return;
    }
    try {
      final created = await _api.createRoom(roomId, totalRounds);
      state = state.copyWith(
        rooms: _mergeRoom(state.rooms, created),
        activeRoomId: roomId,
        view: AppView.lobby,
        statusText: 'Created $roomId',
        error: null,
      );
      await refreshRooms();
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  Future<void> joinRoom(String roomId) async {
    if (!_requireProfile() || !_requireRoom(roomId)) {
      return;
    }
    await _connect();
    if (!state.connected) {
      return;
    }
    _send('JOIN_ROOM', {'roomId': roomId});
    state = state.copyWith(
      activeRoomId: roomId,
      view: AppView.game,
      statusText: 'Joining $roomId',
      error: null,
      clearSnapshot: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await refreshRooms();
  }

  Future<void> startGame(String roomId) async {
    if (!_requireProfile() || !_requireRoom(roomId)) {
      return;
    }
    final room = state.rooms.firstWhere(
      (room) => room.roomId == roomId,
      orElse: () => RoomSummary(
        roomId: roomId,
        status: 'WAITING',
        players: 0,
        maxPlayers: 8,
        hostPlayerId: '',
        roundNumber: 0,
        totalRounds: 3,
        canJoin: true,
        canStart: false,
      ),
    );
    if (room.hostPlayerId != state.profile?.playerId) {
      state = state.copyWith(error: 'Only the room host can start the game');
      return;
    }
    await _connect();
    if (!state.connected) {
      return;
    }
    final rounds = state.rooms
        .firstWhere(
          (room) => room.roomId == roomId,
          orElse: () => RoomSummary(
            roomId: roomId,
            status: 'WAITING',
            players: 0,
            maxPlayers: 8,
            hostPlayerId: '',
            roundNumber: 0,
            totalRounds: 3,
            canJoin: true,
            canStart: true,
          ),
        )
        .totalRounds;
    _send('JOIN_ROOM', {'roomId': roomId});
    _send('START_GAME',
        {'roomId': roomId, 'totalRounds': rounds <= 0 ? 3 : rounds});
    state = state.copyWith(
      activeRoomId: roomId,
      view: AppView.game,
      statusText: 'Starting $roomId',
      error: null,
      clearSnapshot: true,
    );
  }

  void placeBid(int bid) {
    final roomId = state.activeRoomId;
    if (roomId == null) {
      state = state.copyWith(error: 'Join a room first');
      return;
    }
    _send('PLACE_BID', {'roomId': roomId, 'bid': bid});
  }

  void selectTrump(String suit) {
    final roomId = state.activeRoomId;
    if (roomId == null) {
      state = state.copyWith(error: 'Join a room first');
      return;
    }
    _send('SELECT_TRUMP', {'roomId': roomId, 'suit': suit});
  }

  void acknowledgeRoundScore() {
    final roomId = state.activeRoomId;
    if (roomId == null) {
      state = state.copyWith(error: 'Join a room first');
      return;
    }
    _send('ACK_ROUND_SCORE', {'roomId': roomId});
  }

  void playCard(String cardId) {
    final roomId = state.activeRoomId;
    if (roomId == null) {
      state = state.copyWith(error: 'Join a room first');
      return;
    }
    _send('PLAY_CARD', {'roomId': roomId, 'cardId': cardId});
  }

  Future<void> _connect() async {
    final profile = state.profile;
    if (profile == null || state.connected) {
      return;
    }
    final socket = GameSocket(
      baseUrl: _config.websocketBaseUrl,
      playerId: profile.playerId,
    );
    _socket = socket;
    _socketSubscription = socket.connect().listen(
      (message) {
        final type = message['type'] as String? ?? '';
        final snapshot = _snapshotFromMessage(message) ?? state.snapshot;
        state = state.copyWith(
          connected: true,
          snapshot: snapshot,
          error: type == 'INVALID_ACTION' || type == 'INVALID_MESSAGE'
              ? message['error'] as String?
              : null,
        );
        if (snapshot != null) {
          state = state.copyWith(
            view: AppView.game,
            activeRoomId: snapshot.id,
            statusText: 'Joined ${snapshot.id}',
          );
        }
      },
      onError: (Object error) {
        state = state.copyWith(connected: false, error: error.toString());
      },
      onDone: () {
        state = state.copyWith(connected: false, statusText: 'Disconnected');
      },
    );
    try {
      await socket.ready.timeout(const Duration(seconds: 5));
      state = state.copyWith(connected: true, error: null);
    } catch (error) {
      await _socketSubscription?.cancel();
      await socket.close();
      if (_socket == socket) {
        _socket = null;
      }
      state = state.copyWith(
        connected: false,
        error: 'Could not connect to game server: $error',
      );
    }
  }

  void _send(String type, Map<String, dynamic> payload) {
    final requestId = 'req_${++_requestNumber}';
    _socket?.send(type, requestId, payload);
  }

  List<RoomSummary> _mergeRoom(List<RoomSummary> rooms, RoomSummary updated) {
    final merged = [
      for (final room in rooms)
        if (room.roomId != updated.roomId) room,
      updated,
    ];
    merged.sort((a, b) => a.roomId.compareTo(b.roomId));
    return merged;
  }

  GameSnapshot? _snapshotFromMessage(Map<String, dynamic> message) {
    if (message['type'] != 'GAME_STATE_UPDATED') {
      return null;
    }
    final payload = message['payload'];
    if (payload is! Map<String, dynamic>) {
      return null;
    }
    return GameSnapshot.fromJson(payload);
  }

  bool _requireProfile() {
    if (state.profile != null) {
      return true;
    }
    state = state.copyWith(error: 'Register a profile first');
    return false;
  }

  bool _requireRoom(String roomId) {
    if (roomId.isNotEmpty) {
      return true;
    }
    state = state.copyWith(error: 'Room code is required');
    return false;
  }

  Future<void> _loadCurrentUser() async {
    try {
      final profile = await _api.currentUser();
      state = state.copyWith(
        profile: profile,
        error: null,
        statusText: 'Welcome, ${profile.displayName}',
      );
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        state = state.copyWith(error: error.toString());
      }
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    _socketSubscription?.cancel();
    _socket?.close();
    super.dispose();
  }
}

Color _colorFromHex(String hex) {
  final normalized = hex.replaceFirst('#', '');
  return Color(int.parse('FF$normalized', radix: 16));
}
