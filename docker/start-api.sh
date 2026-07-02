#!/usr/bin/env bash
set -Eeuo pipefail

export NODE_ENV="${NODE_ENV:-production}"
export PORT="${PORT:-4100}"
export UPLOAD_DIR="${UPLOAD_DIR:-/app/uploads}"
export UPLOAD_MAX_FILE_BYTES="${UPLOAD_MAX_FILE_BYTES:-1073741824}"
export CHROME_PATH="${CHROME_PATH:-/usr/bin/google-chrome}"
export CHROME_NO_SANDBOX="${CHROME_NO_SANDBOX:-true}"
export DISPLAY="${DISPLAY:-:99}"
export DISPLAY_RESOLUTION="${DISPLAY_RESOLUTION:-1920x1080x24}"

mkdir -p "$UPLOAD_DIR" /app/browser-data /app/data

if [ ! -x "$CHROME_PATH" ] && ! command -v "$CHROME_PATH" >/dev/null 2>&1; then
  echo "Chrome was not found at CHROME_PATH=$CHROME_PATH" >&2
  exit 1
fi

display_number="${DISPLAY#:}"
display_number="${display_number%%.*}"
rm -f "/tmp/.X${display_number}-lock"

xvfb_pid=""
fluxbox_pid=""
x11vnc_pid=""
websockify_pid=""
api_pid=""

shutdown() {
  for pid in "$api_pid" "$websockify_pid" "$x11vnc_pid" "$fluxbox_pid" "$xvfb_pid"; do
    if [ -n "$pid" ]; then
      kill "$pid" >/dev/null 2>&1 || true
    fi
  done
}

trap shutdown EXIT INT TERM

Xvfb "$DISPLAY" -screen 0 "$DISPLAY_RESOLUTION" -ac +extension RANDR -noreset >/tmp/xvfb.log 2>&1 &
xvfb_pid="$!"
sleep 2

fluxbox -display "$DISPLAY" >/tmp/fluxbox.log 2>&1 &
fluxbox_pid="$!"

x11vnc -display "$DISPLAY" -forever -shared -rfbport 5900 -nopw -quiet >/tmp/x11vnc.log 2>&1 &
x11vnc_pid="$!"

websockify --web=/usr/share/novnc 0.0.0.0:6080 127.0.0.1:5900 >/tmp/websockify.log 2>&1 &
websockify_pid="$!"

echo "API: http://localhost:${PORT}"
echo "Visible browser desktop: http://localhost:6080/vnc.html?autoconnect=true&resize=scale"

npm run start &
api_pid="$!"

wait -n "$api_pid" "$websockify_pid" "$x11vnc_pid" "$fluxbox_pid" "$xvfb_pid"
