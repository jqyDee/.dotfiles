# shellcheck shell=bash

bootstrap() { bash "$DOTFILES/bootstrap.sh" "$@"; }


test_extras_clone_when_missing() {
    bootstrap --only extras >/dev/null
    assert_log_has '^git clone .*https://github.com/zsh-users/zsh-autosuggestions '
    assert_log_has '^git clone .*https://github.com/zsh-users/zsh-syntax-highlighting '
    assert_log_has '^git clone .*https://github.com/tmux-plugins/tpm '
    assert_log_has '^git clone .*https://github.com/FelixKratz/SbarLua.git '
    assert_log_has '^make install$'
    assert_log_has '^curl .*sketchybar-app-font.ttf'
    assert_file "$HOME/.tmux/plugins/tpm"
}

test_extras_skip_existing() {
    all_extras_present
    bootstrap --only extras >/dev/null
    assert_log_lacks '^git clone'
    assert_log_lacks '^curl'
    assert_log_lacks '^make'
}

test_udo_keyboard_installed_when_agent_missing() {
    all_extras_present
    fake launchctl launchctl 1
    mkdir -p "$HOME/.config/udo-keyboard"
    # shellcheck disable=SC2016 # expands when the fake installer runs
    printf '#!/bin/sh\necho "udo-install" >>"$STUB_LOG"\n' >"$HOME/.config/udo-keyboard/install.sh"
    chmod +x "$HOME/.config/udo-keyboard/install.sh"
    bootstrap --only extras >/dev/null
    assert_log_has '^udo-install$'
}

test_extras_check_no_writes() {
    rc=0
    out=$(bootstrap --check --only extras) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_log_lacks '^git clone'
    assert_log_lacks '^curl'
    assert_log_lacks '^make'
    assert_contains "missing: $HOME/.tmux/plugins/tpm" "$out"
    assert_contains "sketchybar_lua" "$out"
}

test_services_start_missing() {
    fake brew services-list 0 "Name       Status  User       File
borders    started mfischbach ~/Library/LaunchAgents/homebrew.mxcl.borders.plist
sketchybar none"
    bootstrap --only services >/dev/null
    assert_log_has '^brew services start sketchybar$'
    assert_log_lacks '^brew services start borders'
}

test_services_all_running() {
    fake brew services-list 0 "borders    started mfischbach x
sketchybar started mfischbach y"
    bootstrap --only services >/dev/null
    assert_log_lacks 'services start'
}

test_services_check_no_writes() {
    fake brew services-list 0 "sketchybar none"
    rc=0
    out=$(bootstrap --check --only services) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_log_lacks 'services start'
    assert_contains "sketchybar not running" "$out"
}

test_udo_keyboard_missing_installer_fails_clearly() {
    all_extras_present
    fake launchctl launchctl 1
    rc=0
    out=$(bootstrap --only extras 2>&1) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "udo-keyboard install.sh missing" "$out"
    case "$out" in *"No such file or directory"*) fail "raw shell error: $out" ;; esac
}

test_aerospace_started_when_not_running() {
    fake brew services-list 0 "borders    started mfischbach x
sketchybar started mfischbach y"
    fake pgrep pgrep 1
    out=$(bootstrap --only services)
    assert_log_has '^open -a AeroSpace$'
    assert_contains "Accessibility" "$out"
}

test_aerospace_running_left_alone() {
    fake brew services-list 0 "borders    started mfischbach x
sketchybar started mfischbach y"
    bootstrap --only services >/dev/null
    assert_log_lacks '^open'
}

test_aerospace_check_reports_not_running() {
    fake brew services-list 0 "borders    started mfischbach x
sketchybar started mfischbach y"
    fake pgrep pgrep 1
    rc=0
    out=$(bootstrap --check --only services) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "AeroSpace not running" "$out"
    assert_log_lacks '^open'
}

test_wallpaper_set_when_different() {
    all_extras_present
    fake osascript osascript 0 "/Users/x/Pictures/old.png, $DOTFILES/wallpaper/tree.png"
    bootstrap --only extras >/dev/null
    assert_log_has "^osascript .*set picture of every desktop to \"$DOTFILES/wallpaper/tree.png\""
}

test_wallpaper_already_set() {
    all_extras_present
    bootstrap --only extras >/dev/null
    assert_log_lacks 'set picture'
}

test_wallpaper_check_no_writes() {
    all_extras_present
    fake osascript osascript 0 "/Users/x/Pictures/old.png"
    rc=0
    out=$(bootstrap --check --only extras) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "wallpaper is not" "$out"
    assert_log_lacks 'set picture'
}

test_new_app_font_restarts_running_sketchybar() {
    all_extras_present
    rm "$HOME/Library/Fonts/sketchybar-app-font.ttf"
    fake brew services-list 0 "borders    started mfischbach x
sketchybar started mfischbach y"
    bootstrap --only extras >/dev/null
    assert_log_has '^curl .*sketchybar-app-font.ttf'
    bootstrap --only services >/dev/null
    assert_log_has '^brew services restart sketchybar$'
    : >"$STUB_LOG"
    bootstrap --only services >/dev/null
    assert_log_lacks 'services restart'
}

test_existing_app_font_leaves_sketchybar_alone() {
    all_extras_present
    fake brew services-list 0 "borders    started mfischbach x
sketchybar started mfischbach y"
    bootstrap --only extras >/dev/null
    bootstrap --only services >/dev/null
    assert_log_lacks 'services restart'
}

test_unregistered_app_font_asks_for_relogin() {
    all_extras_present
    rm "$HOME/Library/Fonts/sketchybar-app-font.ttf"
    fake brew services-list 0 "borders    started mfischbach x
sketchybar started mfischbach y"
    bootstrap --only extras >/dev/null
    fake osascript osascript 1
    out=$(FONT_WAIT=0 bootstrap --only services)
    assert_log_lacks 'services restart'
    assert_contains "log out and in" "$out"
}
