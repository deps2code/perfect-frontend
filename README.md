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
