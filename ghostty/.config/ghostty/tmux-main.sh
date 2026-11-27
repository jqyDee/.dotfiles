#!/bin/sh
# Ghostty's command: attach to the tmux session "main". The LaunchAgent
# local.tmux.main runs the server (see tmux/.config/tmux/local.tmux.main.plist),
# so it doesn't count as part of Ghostty and quitting Ghostty quits it fully.
# If the server is gone (killed by hand), start the agent again and wait for
# it; if that fails too, create the session here as before.
tmux=/opt/homebrew/bin/tmux

if ! "$tmux" has-session -t main 2>/dev/null; then
    launchctl kickstart "gui/$(id -u)/local.tmux.main" 2>/dev/null
    i=0
    while [ "$i" -lt 40 ] && ! "$tmux" has-session -t main 2>/dev/null; do
        sleep 0.05
        i=$((i + 1))
    done
fi
exec "$tmux" new-session -A -s main
