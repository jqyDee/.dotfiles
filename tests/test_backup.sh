# shellcheck shell=bash

bootstrap() { bash "$DOTFILES/bootstrap.sh" "$@"; }

ICLOUD='Library/Mobile Documents/com~apple~CloudDocs'
PIN='com.apple.fileprovider.pinned#PX'
DB="Library/Application Support/udo/udo.db"
SCRIPT="$DOTFILES/udo/.config/udo-backup/backup.sh"

make_db() {
    mkdir -p "$(dirname "$1")"
    # WAL like udo's own database
    sqlite3 "$1" "PRAGMA journal_mode=WAL; CREATE TABLE t (x); INSERT INTO t VALUES ('$2');" >/dev/null
}

# backup.sh, with real sqlite3 (the iCloud mirror is the unison fake)

LOCAL=.local/share/udo-backups

test_backup_script_copies_db() {
    make_db "$HOME/$DB" hello
    bash "$SCRIPT" >/dev/null
    out="$HOME/$LOCAL/udo-$(date +%F).db"
    assert_eq hello "$(sqlite3 "$out" 'SELECT x FROM t;')" "backed up row"
    assert_eq "udo-$(date +%F).db" "$(ls -A "$HOME/$LOCAL")" "files in backup folder"
    assert_eq delete "$(sqlite3 "$out" 'PRAGMA journal_mode;')" "journal mode"
    assert_log_has "^unison $HOME/$LOCAL $HOME/$ICLOUD/Backups/udo -batch -auto -prefer $HOME/$LOCAL "
}

test_backup_script_keeps_newest() {
    make_db "$HOME/$DB" hello
    dir="$HOME/$LOCAL"
    mkdir -p "$dir"
    for d in 01 02 03 04 05; do touch "$dir/udo-2020-01-$d.db"; done
    touch "$dir/notes.txt"
    UDO_BACKUP_KEEP=3 bash "$SCRIPT" >/dev/null
    assert_file "$dir/udo-$(date +%F).db"
    assert_file "$dir/udo-2020-01-05.db"
    assert_file "$dir/udo-2020-01-04.db"
    assert_no_file "$dir/udo-2020-01-03.db"
    assert_no_file "$dir/udo-2020-01-01.db"
    assert_file "$dir/notes.txt"
}

test_backup_script_without_db_fails() {
    rc=0
    bash "$SCRIPT" >/dev/null 2>&1 || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_no_file "$HOME/$LOCAL"
    assert_log_lacks '^unison'
}

test_backup_script_corrupt_db_keeps_old_copies() {
    mkdir -p "$(dirname "$HOME/$DB")" "$HOME/$LOCAL"
    echo "not a database" >"$HOME/$DB"
    touch "$HOME/$LOCAL/udo-2020-01-01.db"
    rc=0
    UDO_BACKUP_KEEP=0 bash "$SCRIPT" >/dev/null 2>&1 || rc=$?
    [ "$rc" -ne 0 ] || fail "corrupt database backed up"
    assert_file "$HOME/$LOCAL/udo-2020-01-01.db"
    assert_no_file "$HOME/$LOCAL/udo-$(date +%F).db"
    assert_log_lacks '^unison'
}

test_backup_script_mirror_failure_fails() {
    make_db "$HOME/$DB" hello
    fake unison unison 1
    rc=0
    out=$(bash "$SCRIPT" 2>&1) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "mirror to iCloud failed" "$out"
    assert_file "$HOME/$LOCAL/udo-$(date +%F).db"
}

# the bootstrap step

test_backup_step_fresh_mac_restores_newest() {
    dir="$HOME/$ICLOUD/Backups/udo"
    make_db "$dir/udo-2026-01-01.db" old
    make_db "$dir/udo-2026-01-02.db" new
    fake launchctl launchctl-print 1
    bootstrap --only backup >/dev/null
    assert_eq new "$(sqlite3 "$HOME/$DB" 'SELECT x FROM t;')" "restored row"
    assert_eq 1 "$(xattr -p "$PIN" "$dir")" "pinned"
    plist="$HOME/Library/LaunchAgents/local.udo.backup.plist"
    assert_file "$plist"
    grep -q "$HOME/.config/udo-backup/backup.sh" "$plist" || fail "script path not filled in"
    assert_log_has '^launchctl bootstrap gui/[0-9]+ .*local.udo.backup.plist$'
}

test_backup_step_keeps_existing_db() {
    make_db "$HOME/$DB" mine
    make_db "$HOME/$ICLOUD/Backups/udo/udo-2026-01-01.db" old
    bootstrap --only backup >/dev/null
    assert_eq mine "$(sqlite3 "$HOME/$DB" 'SELECT x FROM t;')" "database kept"
}

test_backup_step_set_up_mac_does_nothing() {
    mkdir -p "$HOME/$ICLOUD"
    make_db "$HOME/$DB" mine
    bootstrap --only backup >/dev/null
    : >"$STUB_LOG"
    out=$(bootstrap --only backup)
    assert_log_lacks '^launchctl (bootstrap|bootout)'
    case "$out" in *"changed:"*) fail "changed something: $out" ;; esac
}

test_backup_step_outdated_plist_reinstalled() {
    mkdir -p "$HOME/$ICLOUD" "$HOME/Library/LaunchAgents"
    echo old >"$HOME/Library/LaunchAgents/local.udo.backup.plist"
    bootstrap --only backup >/dev/null
    assert_log_has '^launchctl bootout gui/[0-9]+/local.udo.backup$'
    assert_log_has '^launchctl bootstrap gui/[0-9]+ .*local.udo.backup.plist$'
}

test_backup_step_check_writes_nothing() {
    make_db "$HOME/$ICLOUD/Backups/udo/udo-2026-01-02.db" new
    fake launchctl launchctl-print 1
    rc=0
    out=$(bootstrap --check --only backup) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "udo database missing (backup to restore: udo-2026-01-02.db)" "$out"
    assert_contains "not kept downloaded" "$out"
    assert_contains "udo backup agent not installed" "$out"
    assert_no_file "$HOME/$DB"
    assert_no_file "$HOME/Library/LaunchAgents/local.udo.backup.plist"
    assert_log_lacks '^launchctl (bootstrap|bootout)'
}

test_backup_step_without_icloud_drive() {
    rc=0
    out=$(bootstrap --only backup 2>&1) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "iCloud Drive not found" "$out"
    assert_no_file "$HOME/Library/LaunchAgents/local.udo.backup.plist"
}
