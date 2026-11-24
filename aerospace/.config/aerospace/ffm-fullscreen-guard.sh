#!/bin/bash
# Disable focus-follows-mouse while a macOS native fullscreen window (e.g. browser video) is focused.
# AeroSpace doesn't tile native fullscreen windows, so focus-follows-mouse steals focus to the tiles behind it.
#
# Event driven: runs only when AeroSpace reports a focus change, no polling.
# AeroSpace has no format variable for native fullscreen (%{window-layout} shows
# "floating"), so the focused window's AXFullScreen attribute is asked instead.

AEROSPACE="$(command -v aerospace || echo /opt/homebrew/bin/aerospace)"
# Resolve the stow symlink so sed edits the real file instead of replacing the link
CONFIG="$(realpath "$HOME/.config/aerospace/aerospace.toml")"

# Only one watcher at a time
PIDFILE="${TMPDIR:-/tmp}/ffm-fullscreen-guard.pid"
if [ -f "$PIDFILE" ]; then
    old=$(cat "$PIDFILE")
    pkill -P "$old" 2>/dev/null
    kill "$old" 2>/dev/null
fi
echo $$ >"$PIDFILE"

is_fullscreen() {
    [ "$(osascript -e 'tell application "System Events" to tell (first process whose frontmost is true) to get value of attribute "AXFullScreen" of (value of attribute "AXFocusedWindow")' 2>/dev/null)" = true ]
}

set_ffm() {
    grep -q "^focus-follows-mouse.enabled = $1$" "$CONFIG" && return
    sed -i '' "s/^focus-follows-mouse.enabled = .*/focus-follows-mouse.enabled = $1/" "$CONFIG"
    "$AEROSPACE" reload-config --no-gui
}

check() {
    # AXFullScreen turns true only once the fullscreen animation is done (~1s)
    local delays="0 1"
    # A browser video going fullscreen shows up as a new floating window: pause
    # right away, then keep asking (each query takes ~0.35s) until it is fullscreen
    if [ "$("$AEROSPACE" list-windows --focused --format '%{window-layout}' 2>/dev/null)" = floating ]; then
        set_ffm false
        delays="0 0 0 0 0 0"
    fi
    for delay in $delays; do
        sleep "$delay"
        if is_fullscreen; then
            set_ffm false
            return
        fi
    done
    set_ffm true
}

# The first event is the current state; resubscribe if the connection drops
while pgrep -x AeroSpace >/dev/null; do
    "$AEROSPACE" subscribe focus-changed | while IFS= read -r _; do
        # Only the latest focus matters: drop events that queued up meanwhile
        while IFS= read -r -t 0.1 _; do :; done
        check
    done
    sleep 2
done
set_ffm true
