#!/usr/bin/env bash
# Install (or with --uninstall remove) the udo-keyboard LaunchAgent, which runs
# udo_keyboard.py at login and keeps it running. It feeds `udo status` to the
# Corne's right nice!view (firmware: corne-zmk repo, modules/udo-status).
#
#   ~/.config/udo-keyboard/install.sh
#   ~/.config/udo-keyboard/install.sh --uninstall
#
# The venv lives outside the dotfiles, in ~/.local/share/udo-keyboard.
set -euo pipefail

DIR=$(cd "$(dirname "$0")" && pwd)
VENV=~/.local/share/udo-keyboard/.venv
LABEL=local.corne.udo-status
PLIST=~/Library/LaunchAgents/$LABEL.plist
DOMAIN=gui/$(id -u)

launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
if [[ ${1:-} == --uninstall ]]; then
    rm -f "$PLIST"
    echo "removed $LABEL (venv kept: $VENV)"
    exit
fi

[[ -x $VENV/bin/python ]] || python3 -m venv "$VENV"
"$VENV/bin/pip" install -q -r "$DIR/requirements.txt"

mkdir -p ~/Library/LaunchAgents
sed -e "s|__PYTHON__|$VENV/bin/python|" -e "s|__SCRIPT__|$DIR/udo_keyboard.py|" \
    "$DIR/$LABEL.plist" > "$PLIST"
launchctl bootstrap "$DOMAIN" "$PLIST"
echo "installed $LABEL (log: /tmp/udo-status.log)"
