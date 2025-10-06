#!/bin/bash
# uninstall.sh — removes the Unison bidirectional sync setup
set -e

PLIST_PATH="$HOME/Library/LaunchAgents/com.user.unison.sync.plist"
WRAPPER="$HOME/.config/scripts/unison_sync.sh"
PROFILE="$HOME/.unison/cs-sync.prf"
LOG="$HOME/.config/scripts/unison_sync.log"
SYMLINK="$HOME/CS-Studies-iCloud"

echo "🧹 Uninstalling Unison bidirectional sync..."

# Unload LaunchAgent (old method)
if launchctl list | grep -q "com.user.unison.sync"; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
fi

# Unload LaunchAgent (newer macOS method)
if launchctl print gui/$(id -u) 2>/dev/null | grep -q "com.user.unison.sync"; then
    launchctl bootout gui/$(id -u) "$PLIST_PATH" 2>/dev/null || true
fi

# Remove files
rm -f "$PLIST_PATH"
rm -f "$WRAPPER"

# Remove log
if [ -f "$LOG" ]; then
    echo "Removing log: $LOG"
    rm -f "$LOG"
fi

# Remove Unison profile
if [ -f "$PROFILE" ]; then
    echo "Removing Unison profile: $PROFILE"
    rm -f "$PROFILE"
fi

# Remove symlink
if [ -L "$SYMLINK" ]; then
    echo "Removing symlink: $SYMLINK"
    rm -f "$SYMLINK"
fi

echo "✅ Uninstall complete."

