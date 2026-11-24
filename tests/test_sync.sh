# shellcheck shell=bash

bootstrap() { bash "$DOTFILES/bootstrap.sh" "$@"; }

ICLOUD='Library/Mobile Documents/com~apple~CloudDocs'
PIN='com.apple.fileprovider.pinned#PX'

test_sync_fresh_mac() {
    mkdir -p "$HOME/$ICLOUD/CS-Studies"
    fake launchctl launchctl-print 1
    bootstrap --only sync >/dev/null
    assert_eq 1 "$(xattr -p "$PIN" "$HOME/$ICLOUD/CS-Studies")" "pinned"
    assert_file "$HOME/.unison/cs-sync.prf"
    assert_file "$HOME/Library/LaunchAgents/com.user.unison.sync.plist"
    assert_log_has "^unison cs-sync -batch -auto -prefer $HOME/CS-Studies-iCloud$"
    assert_log_has '^launchctl bootstrap gui/[0-9]+ .*com.user.unison.sync.plist$'
    assert_log_lacks '^launchctl load'
    # the first sync runs before the agent can start one
    u=$(grep -n '^unison' "$STUB_LOG" | cut -d: -f1)
    l=$(grep -n '^launchctl bootstrap' "$STUB_LOG" | cut -d: -f1)
    [ "$u" -lt "$l" ] || fail "agent loaded (line $l) before the first sync (line $u)"
}

test_sync_set_up_mac_does_nothing() {
    mkdir -p "$HOME/$ICLOUD/CS-Studies" "$HOME/.unison"
    xattr -w "$PIN" 1 "$HOME/$ICLOUD/CS-Studies"
    touch "$HOME/.unison/cs-sync.prf"
    out=$(bootstrap --only sync)
    assert_log_lacks '^unison'
    assert_log_lacks '^launchctl (bootstrap|load)'
    case "$out" in *"changed:"*) fail "changed something: $out" ;; esac
}

test_sync_profile_kept_no_first_sync() {
    # existing setup with the agent unloaded: load it, never re-run the first sync
    mkdir -p "$HOME/$ICLOUD/CS-Studies" "$HOME/.unison"
    xattr -w "$PIN" 1 "$HOME/$ICLOUD/CS-Studies"
    touch "$HOME/.unison/cs-sync.prf"
    fake launchctl launchctl-print 1
    bootstrap --only sync >/dev/null
    assert_log_lacks '^unison'
    assert_log_has '^launchctl bootstrap'
}

test_sync_check_reports_and_writes_nothing() {
    mkdir -p "$HOME/$ICLOUD/CS-Studies"
    fake launchctl launchctl-print 1
    rc=0
    out=$(bootstrap --check --only sync) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "CS-Studies in iCloud is not kept downloaded" "$out"
    assert_contains "unison sync not installed" "$out"
    assert_contains "unison sync agent not loaded" "$out"
    assert_no_file "$HOME/.unison/cs-sync.prf"
    xattr -p "$PIN" "$HOME/$ICLOUD/CS-Studies" >/dev/null 2>&1 && fail "pinned in check mode"
    assert_log_lacks '^unison'
    assert_log_lacks '^launchctl (bootstrap|load)'
}

test_sync_without_icloud_drive() {
    rc=0
    out=$(bootstrap --only sync 2>&1) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "iCloud Drive not found" "$out"
    assert_log_lacks '^unison'
}

test_sync_failed_first_sync_is_a_followup() {
    mkdir -p "$HOME/$ICLOUD/CS-Studies"
    fake launchctl launchctl-print 1
    fake unison unison 1
    out=$(bootstrap --only sync 2>&1)
    assert_contains "first sync did not finish cleanly" "$out"
    assert_contains "unison cs-sync -batch -auto" "$out"
    assert_log_has '^launchctl bootstrap'
}

test_sync_only_finds_brew_tools_without_path() {
    # --only sync in a shell started before Homebrew: its bin dir isn't on PATH
    mkdir -p "$HOME/$ICLOUD/CS-Studies" "$FAKE/hb/bin" "$HOME/.unison"
    xattr -w "$PIN" 1 "$HOME/$ICLOUD/CS-Studies"
    touch "$HOME/.unison/cs-sync.prf"
    ln -s "$TESTS/stubs/_stub" "$FAKE/hb/bin/brew"
    ln -s "$TESTS/stubs/_stub" "$FAKE/hb/bin/unison"
    mkdir -p "$FAKE/nounison" && for t in "$TESTS"/stubs/*; do
        case $(basename "$t") in unison | brew) ;; *) ln -s "$t" "$FAKE/nounison/" ;; esac
    done
    rc=0
    out=$(PATH="$FAKE/nounison:/usr/bin:/bin" BREW="$FAKE/hb/bin/brew" bootstrap --only sync 2>&1) || rc=$?
    assert_eq 0 "$rc" "return code ($out)"
    case "$out" in *"unison is not installed"*) fail "unison not found: $out" ;; esac
}
