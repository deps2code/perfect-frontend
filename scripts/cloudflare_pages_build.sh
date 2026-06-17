#!/usr/bin/env sh
set -eu

FLUTTER_DIR="${FLUTTER_DIR:-/tmp/flutter}"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter config --enable-web
flutter pub get
flutter build web --release --no-wasm-dry-run \
  --dart-define=HTTP_BASE_URL=https://perfect-backend.fly.dev \
  --dart-define=WEBSOCKET_BASE_URL=wss://perfect-backend.fly.dev/ws
