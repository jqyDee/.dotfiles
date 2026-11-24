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
