#!/bin/sh
if [ -n "$XDG_DATA_HOME" ]; then
    USER_APP_DIR="$XDG_DATA_HOME/cornelsen-offline-lernen-bin"
else
    USER_APP_DIR="$HOME/.local/share/cornelsen-offline-lernen-bin"
fi

if [ -n "$XDG_CONFIG_HOME" ]; then
    CONFIG_DIR="$XDG_CONFIG_HOME/CornelsenOfflineLernen"
else
    CONFIG_DIR="$HOME/.config/CornelsenOfflineLernen"
fi

SYSTEM_ASAR="@out@/share/cornelsen-offline-lernen/app.asar"
USER_ASAR="$USER_APP_DIR/app.asar"

mkdir -p "$USER_APP_DIR" "$CONFIG_DIR"

if [ ! -f "$USER_ASAR" ] || [ "$(cat "$USER_APP_DIR/.from" 2>/dev/null)" != "@out@" ]; then
    cp -f "$SYSTEM_ASAR" "$USER_ASAR"
    chmod u+w "$USER_ASAR"
    echo "@out@" > "$USER_APP_DIR/.from"
fi

exec @electron@/bin/electron \
  "$USER_ASAR" \
  --user-data-dir="$CONFIG_DIR" \
  --ozone-platform-hint=auto \
  "$@"
