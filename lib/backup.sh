# shellcheck shell=bash
# Step: backup (udo's database: daily rolling copies in iCloud, restored on a
# fresh Mac).

BACKUP_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Backups/udo"
BACKUP_DB="$HOME/Library/Application Support/udo/udo.db"
BACKUP_AGENT=local.udo.backup
BACKUP_PLIST="$HOME/Library/LaunchAgents/$BACKUP_AGENT.plist"
# What Finder's "Keep Downloaded" sets: iCloud never evicts the folder's files
BACKUP_PIN='com.apple.fileprovider.pinned#PX'

_backup_pinned() { [ "$(xattr -p "$BACKUP_PIN" "$BACKUP_DIR" 2>/dev/null)" = 1 ]; }
_backup_loaded() { launchctl print "gui/$(id -u)/$BACKUP_AGENT" >/dev/null 2>&1; }

# the plist as it should be installed
_backup_plist() {
    sed "s|__SCRIPT__|$HOME/.config/udo-backup/backup.sh|" \
        "$DOTFILES/udo/.config/udo-backup/$BACKUP_AGENT.plist"
}

# newest backup, or nothing
_backup_latest() {
    find "$BACKUP_DIR" -maxdepth 1 -name 'udo-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].db' 2>/dev/null |
        sort | tail -n 1
}

step_backup() {
    if [ ! -d "${BACKUP_DIR%/Backups/udo}" ]; then
        log_warn "iCloud Drive not found: sign in to iCloud and turn on iCloud Drive"
        note_followup "turn on iCloud Drive, then ./bootstrap.sh --only backup"
        return 1
    fi
    local latest
    latest=$(_backup_latest)

    if [ "$MODE" = check ]; then
        [ -f "$BACKUP_DB" ] || note_drift "udo database missing${latest:+ (backup to restore: $(basename "$latest"))}"
        [ -d "$BACKUP_DIR" ] && ! _backup_pinned && note_drift "udo backups in iCloud are not kept downloaded"
        _backup_plist | cmp -s - "$BACKUP_PLIST" || note_drift "udo backup agent not installed or outdated"
        _backup_loaded || note_drift "udo backup agent not loaded"
        return 0
    fi

    mkdir -p "$BACKUP_DIR"
    if ! _backup_pinned; then
        xattr -w "$BACKUP_PIN" 1 "$BACKUP_DIR" || return 1
        note_change "udo backups in iCloud: keep downloaded"
    fi

    # Fresh Mac: bring the database back before anything creates an empty one
    if [ ! -f "$BACKUP_DB" ] && [ -n "$latest" ]; then
        mkdir -p "$(dirname "$BACKUP_DB")"
        # reading the file makes iCloud download it if it isn't local yet
        cp "$latest" "$BACKUP_DB.restoring" && mv "$BACKUP_DB.restoring" "$BACKUP_DB" || return 1
        note_change "restored udo database from $(basename "$latest")"
    fi

    if ! _backup_plist | cmp -s - "$BACKUP_PLIST"; then
        mkdir -p "$(dirname "$BACKUP_PLIST")"
        launchctl bootout "gui/$(id -u)/$BACKUP_AGENT" 2>/dev/null || true
        _backup_plist >"$BACKUP_PLIST" || return 1
        launchctl bootstrap "gui/$(id -u)" "$BACKUP_PLIST" || return 1
        note_change "installed udo backup agent (daily at 00:00)"
    elif ! _backup_loaded; then
        launchctl bootstrap "gui/$(id -u)" "$BACKUP_PLIST" || return 1
        note_change "loaded udo backup agent"
    fi
}
