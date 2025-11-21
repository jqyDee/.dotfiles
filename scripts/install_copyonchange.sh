#!/bin/bash
# install.sh — sets up Unison bidirectional sync on macOS (iCloud-safe)
set -e

# --- Configuration ---
SOURCE_DIR="$HOME/Developer/cs-degree"
ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
DEST_DIR="$ICLOUD_DIR/CS-Studies"
SYMLINK_DIR="$HOME/CS-Studies-iCloud"  # symlink to avoid spaces

SCRIPT_DIR="$HOME/.config/scripts"
WRAPPER="$SCRIPT_DIR/unison_sync.sh"
UNISON_DIR="$HOME/.unison"
PROFILE_NAME="cs-sync"
PROFILE_PATH="$UNISON_DIR/$PROFILE_NAME.prf"
PLIST_PATH="$HOME/Library/LaunchAgents/com.user.unison.sync.plist"
LOG_FILE="$SCRIPT_DIR/unison_sync.log"

# --- Check Unison installation ---
UNISON_BIN=$(which unison || true)
if [ -z "$UNISON_BIN" ]; then
    echo "ERROR: Unison not found. Install with Homebrew first:"
    echo "  brew install unison"
    exit 1
fi
echo "Found Unison at: $UNISON_BIN"

# --- Ensure folders exist ---
mkdir -p "$SOURCE_DIR"
mkdir -p "$DEST_DIR"

# --- Create symlink to avoid spaces ---
if [ ! -L "$SYMLINK_DIR" ]; then
    ln -s "$DEST_DIR" "$SYMLINK_DIR"
    echo "Created symlink: $SYMLINK_DIR -> $DEST_DIR"
fi
SYNC_DEST="$SYMLINK_DIR"

# --- Ensure log folder/file exist ---
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# --- Create directories ---
mkdir -p "$SCRIPT_DIR"
mkdir -p "$UNISON_DIR"

# --- Create Unison profile (no quotes!) ---
cat > "$PROFILE_PATH" <<EOF
root = $SOURCE_DIR
root = $SYNC_DEST

# Exclude archive-cs folder and .DS_Store files
ignore = Path archive-cs
ignore = Name .DS_Store
ignore = Path 25w_sofar_ps/swa-skeleton

auto = true
log = true
logfile = $LOG_FILE
EOF

# --- Create wrapper script ---
cat > "$WRAPPER" <<EOF
#!/bin/bash
# Wrapper to run Unison in batch mode

PROFILE_NAME="$PROFILE_NAME"
LOG_FILE="$LOG_FILE"
UNISON_BIN="$UNISON_BIN"

echo "===== \$(date) =====" >> "\$LOG_FILE"
"\$UNISON_BIN" "\$PROFILE_NAME" -batch -auto -log >> "\$LOG_FILE" 2>&1 || \
    echo "\$(date): Unison returned non-zero" >> "\$LOG_FILE"
echo "===== done \$(date) =====" >> "\$LOG_FILE"
EOF

chmod +x "$WRAPPER"

# --- Create launchd plist ---
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.unison.sync</string>

    <key>ProgramArguments</key>
    <array>
        <string>$WRAPPER</string>
    </array>

    <key>WatchPaths</key>
    <array>
        <string>$SOURCE_DIR</string>
        <string>$SYNC_DEST</string>
    </array>

    <key>StandardOutPath</key>
    <string>/tmp/unison_sync.out</string>
    <key>StandardErrorPath</key>
    <string>/tmp/unison_sync.err</string>

    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

# --- Load LaunchAgent ---
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH" 2>/dev/null || {
    launchctl bootstrap gui/$(id -u) "$PLIST_PATH" 2>/dev/null || true
}

echo "✅ Installed Unison bidirectional sync (iCloud-safe)"
echo "   - Source: $SOURCE_DIR"
echo "   - Destination (symlink): $SYNC_DEST"
echo "   - Profile: $PROFILE_PATH"
echo "   - Wrapper: $WRAPPER"
echo "   - Log: $LOG_FILE"
echo ""
echo "Run the wrapper manually first to check behavior:"
echo "  $WRAPPER"
echo "Check log:"
echo "  tail -n 50 $LOG_FILE"

