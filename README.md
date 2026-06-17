# Perfect Frontend

Flutter client scaffold for the multiplayer trick-taking card game MVP.

Planned structure:

```text
lib/
  main.dart
  core/
    config/
    networking/
    websocket/
    storage/
    theme/
  features/
    auth/
    lobby/
    matchmaking/
    game/
      models/
      screens/
      widgets/
      state/
      animations/
    profile/
    leaderboard/
  shared/
    widgets/
    utils/
```

Run in Firefox through Flutter's web server:

```bash
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000
```

Open:

```text
http://127.0.0.1:3000
```

The current screen supports connecting by temporary player id, creating/joining a room, starting with a total round count, bidding, selecting trump, and playing legal cards.

## Cloudflare Pages

Build the Flutter web app with the production backend URLs:

```bash
flutter pub get
flutter build web --release \
  --dart-define=HTTP_BASE_URL=https://perfect-backend.fly.dev \
  --dart-define=WEBSOCKET_BASE_URL=wss://perfect-backend.fly.dev/ws
```

Deploy the generated static files with Wrangler:

```bash
npx wrangler pages deploy build/web --project-name perfect-frontend
```

For a Git-connected Cloudflare Pages project, use:

```text
Framework preset: None
Build command: flutter pub get && flutter build web --release --dart-define=HTTP_BASE_URL=https://perfect-backend.fly.dev --dart-define=WEBSOCKET_BASE_URL=wss://perfect-backend.fly.dev/ws
Build output directory: build/web
```
