# shellcheck shell=bash

# plist <file-name> <xml inside <dict>>: write a fake exported domain
plist() {
    mkdir -p "$FAKE/plists"
    printf '<?xml version="1.0" encoding="UTF-8"?>\n<plist version="1.0"><dict>%s</dict></plist>\n' "$2" \
        >"$FAKE/plists/$1"
}

record() { printf '\n' | bash "$DOTFILES/macos.sh" --record 2>/dev/null; }

test_record_prints_changed_scalar() {
    plist com.apple.dock.plist '<key>autohide</key><false/><key>tilesize</key><integer>52</integer>'
    plist com.apple.dock.after.plist '<key>autohide</key><true/><key>tilesize</key><integer>52</integer>'
    out=$(record)
    assert_contains "setting com.apple.dock autohide -bool true" "$out"
    case "$out" in *tilesize*) fail "unchanged key printed: $out" ;; esac
}

test_record_value_types() {
    plist NSGlobalDomain.plist ''
    plist NSGlobalDomain.after.plist '<key>KeyRepeat</key><integer>2</integer><key>Speed</key><real>0.5</real><key>Greeting</key><string>Hello World</string>'
    out=$(record)
    assert_contains "setting NSGlobalDomain KeyRepeat -int 2" "$out"
    assert_contains "setting NSGlobalDomain Speed -float 0.5" "$out"
    assert_contains "setting NSGlobalDomain Greeting -string 'Hello World'" "$out"
}

test_record_quotes_domain_with_spaces() {
    plist 'com.example.My App.plist' '<key>a</key><false/>'
    plist 'com.example.My App.after.plist' '<key>a</key><true/>'
    out=$(record)
    assert_contains "setting 'com.example.My App' a -bool true" "$out"
}

test_record_marks_lists_and_dicts_manual() {
    plist com.apple.dock.plist ''
    plist com.apple.dock.after.plist '<key>persistent-apps</key><array><string>x</string></array><key>opts</key><dict><key>k</key><true/></dict>'
    out=$(record)
    assert_contains "# manual (array): com.apple.dock persistent-apps" "$out"
    assert_contains "# manual (dict): com.apple.dock opts" "$out"
    case "$out" in *"setting com.apple.dock persistent-apps"*) fail "array as setting line" ;; esac
}

test_record_skips_noise() {
    plist com.apple.finder.plist '<key>NSWindow Frame Main</key><string>1 2 3 4</string><key>LastUsed</key><date>2026-01-01T00:00:00Z</date>'
    plist com.apple.finder.after.plist '<key>NSWindow Frame Main</key><string>5 6 7 8</string><key>LastUsed</key><date>2026-02-01T00:00:00Z</date>'
    out=$(record)
    case "$out" in *NSWindow* | *LastUsed*) fail "noise printed: $out" ;; esac
}

test_record_marks_existing_line() {
    plist com.apple.dock.plist '<key>tilesize</key><integer>40</integer>'
    plist com.apple.dock.after.plist '<key>tilesize</key><integer>52</integer>'
    out=$(record)
    assert_contains "setting com.apple.dock tilesize -int 52  # already in macos.sh" "$out"
}

test_record_reports_removed_and_new_domain() {
    plist com.apple.dock.plist '<key>gone</key><true/>'
    plist com.apple.dock.after.plist ''
    plist com.example.new.after.plist '<key>x</key><integer>1</integer>'
    out=$(record)
    assert_contains "# removed: com.apple.dock gone" "$out"
    assert_contains "setting com.example.new x -int 1" "$out"
}

test_record_nothing_changed() {
    plist com.apple.dock.plist '<key>a</key><true/>'
    out=$(record)
    assert_contains "no changes" "$(printf '\n' | bash "$DOTFILES/macos.sh" --record 2>&1)"
    assert_eq "" "$out" "stdout"
}

test_record_never_writes() {
    plist com.apple.dock.plist '<key>autohide</key><false/>'
    plist com.apple.dock.after.plist '<key>autohide</key><true/>'
    record >/dev/null
    assert_log_lacks '^defaults (write|delete|import)'
    assert_log_lacks '^killall'
}
