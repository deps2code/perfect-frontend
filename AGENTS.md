# Frontend Agent Notes

## Current State

- Flutter client scaffold for the multiplayer trick-taking card game MVP.
- State management uses Riverpod.
- WebSocket client uses `web_socket_channel`.
- The current screen can connect to the Go backend, create/join a room, start a game with total rounds, place bids, select trump, play legal cards, acknowledge round score cards, and render the live game table.
- Playing cards and suit UI use suit symbols (`♣`, `♦`, `♥`, `♠`) instead of suit initials.
- Trump and lead suits are visible on the table for all players once available.
- Round scores open in a modal. Players close the modal to send `ACK_ROUND_SCORE`; non-final rounds do not advance until every player has closed it.
- Final scores reuse the score modal, show rankings, and highlight winning row(s) instead of using an icon in the player name.
- The score modal close counter is driven by snapshot `roundScoreAckCount` through a local notifier so the open modal can update without rebuilding the whole table.

## Key Areas

- `lib/main.dart`: App entrypoint and theme.
- `lib/core/config/app_config.dart`: Local backend URLs.
- `lib/core/websocket/game_socket.dart`: Minimal WebSocket wrapper.
- `lib/features/lobby/lobby_screen.dart`: Current working lobby flow and Riverpod controller.
- `lib/features/game/models/game_snapshot.dart`: Client-side models for server snapshots.

## Commands

Install dependencies:

```bash
flutter pub get
```

Run in Firefox through Flutter web server:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000
```

Then open:

```text
http://127.0.0.1:3000
```

Analyze:

```bash
flutter analyze
```

## Local Usage

Run the backend separately from `backend/`:

```bash
GOCACHE=/tmp/go-build GOMODCACHE=/tmp/go/pkg/mod go run ./cmd/api
```

For a full start-game test, open two or more browser tabs and use different player IDs:

- `p1`
- `p2`
- `p3` if testing 3-player flow

Use the same room code, for example `room_1`.

## Implementation Rules

- Keep the server authoritative. The Flutter app should send intended actions, not enforce game results.
- Do not assume other players' hidden cards exist client-side.
- Keep WebSocket messages aligned with the backend message types.
- Supported game actions from the client currently include `PLACE_BID`, `SELECT_TRUMP`, `PLAY_CARD`, and `ACK_ROUND_SCORE`.
- Treat the backend snapshot as the source of truth for `trumpSuit`, `leadSuit`, `roundScores`, `roundScoreAckCount`, `viewerAvailableActions`, and `winnerPlayerIds`.
- Keep the score table in a modal, not inline in the game table layout.
- Winner display in final scores should be row highlighting, not a crown or other prefix icon.
- Keep fixed-format table elements responsive. The table scene, trick pile, hand fan, and top bar should scale or ellipsize instead of producing Flutter overflow stripes on narrow or short viewports.
- Preserve Firefox-friendly `web-server` usage unless adding explicit Chrome-only debugging instructions.
- Prefer small Riverpod controllers per feature as the app grows.

## Known Gaps

- There is no dedicated room screen, reconnect screen, or auth screen yet.
- Temporary auth uses `playerId`; JWT integration is pending backend auth.
- Multi-tab local testing can make each browser viewport narrow; verify game-table changes at constrained widths/heights as well as desktop size.
