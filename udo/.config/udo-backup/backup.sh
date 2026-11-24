#!/usr/bin/env bash
# Rolling backup of udo's database: one copy per day, the newest
# $UDO_BACKUP_KEEP (50) kept, mirrored to iCloud Drive. Run at 00:00 by the
# local.udo.backup LaunchAgent (bootstrap step "backup" installs it), or by
# hand:
#
#   ~/.config/udo-backup/backup.sh
#
# Copies are named udo-YYYY-MM-DD.db; a second run on the same day replaces
# that day's copy. Pruning counts copies, not days, so a Mac that was off for
# a while still keeps 50.
#
# Copies are made and pruned in a local folder, then unison mirrors it to
# iCloud: macOS doesn't let launchd jobs touch iCloud Drive with its own
# tools (bash, mv, find get "Operation not permitted"), but unison has the
# iCloud Drive permission already (the CS-Studies sync asked for it).
set -euo pipefail

DB=${UDO_DB:-"$HOME/Library/Application Support/udo/udo.db"}
LOCAL=${UDO_BACKUP_LOCAL:-"$HOME/.local/share/udo-backups"}
ICLOUD=${UDO_BACKUP_DIR:-"$HOME/Library/Mobile Documents/com~apple~CloudDocs/Backups/udo"}
KEEP=${UDO_BACKUP_KEEP:-50}

log() { echo "$(date '+%F %T') $*"; }

if [ ! -f "$DB" ]; then
    log "no database at $DB"
    exit 1
fi
mkdir -p "$LOCAL" "$LOCAL.unison"

day=$(date +%F)
out="$LOCAL/udo-$day.db"
tmp="$LOCAL/.udo-$day.db.partial"
trap 'rm -f "$tmp" "$tmp-wal" "$tmp-shm"' EXIT

# .backup takes a consistent snapshot even while udo is writing; a plain cp
# could catch a half-written page
sqlite3 "$DB" ".backup '$tmp'"
# the copy inherits udo's WAL mode: make it one self-contained file, without
# -wal/-shm files next to it
sqlite3 "$tmp" 'PRAGMA journal_mode=DELETE;' >/dev/null
check=$(sqlite3 "$tmp" 'PRAGMA integrity_check;')
if [ "$check" != ok ]; then
    log "backup failed the integrity check, older copies kept: $check"
    exit 1
fi
# opening the copy leaves an empty -shm behind even in DELETE mode
rm -f "$tmp-wal" "$tmp-shm"
mv -f "$tmp" "$out"
log "backed up to $out"

# dates in the names sort chronologically: drop all but the newest $KEEP
find "$LOCAL" -maxdepth 1 -name 'udo-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].db' |
    sort -r | tail -n +$((KEEP + 1)) |
    while IFS= read -r old; do
        rm -f "$old"
        log "removed $(basename "$old")"
    done

# Two-way, local wins conflicts: new and removed copies go to iCloud, and on a
# fresh Mac iCloud's older copies come back into the local folder. unison's
# state lives next to the local folder, not in ~/.unison: losing the folder
# but keeping the state would read as "all deleted" and empty iCloud too.
# Hidden files (.DS_Store, a run's .partial) stay out.
if ! UNISON="$LOCAL.unison" unison "$LOCAL" "$ICLOUD" -batch -auto -prefer "$LOCAL" \
    -ignore 'Name .*' -log=false -terse; then
    log "mirror to iCloud failed (is $ICLOUD there? unison allowed in Privacy & Security → Files and Folders?)"
    exit 1
fi
log "mirrored to $ICLOUD"
