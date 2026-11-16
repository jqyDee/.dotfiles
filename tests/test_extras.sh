# shellcheck shell=bash

bootstrap() { bash "$DOTFILES/bootstrap.sh" "$@"; }


test_extras_clone_when_missing() {
    fake ssh ssh 1 "Hi jqyDee! You've successfully authenticated, but GitHub does not provide shell access."
    bootstrap --only extras >/dev/null
    assert_log_has '^git clone .*https://github.com/zsh-users/zsh-autosuggestions '
    assert_log_has '^git clone .*https://github.com/zsh-users/zsh-syntax-highlighting '
    assert_log_has '^git clone .*https://github.com/tmux-plugins/tpm '
    assert_log_has '^git clone .*https://github.com/FelixKratz/SbarLua.git '
    assert_log_has '^make install$'
    assert_log_has '^curl .*sketchybar-app-font.ttf'
    assert_log_has '^git clone .*git@github.com:jqyDee/typst-templates.git '
    assert_file "$HOME/.tmux/plugins/tpm"
    assert_file "$HOME/$TYPST_DIR"
}

test_extras_skip_existing() {
    all_extras_present
    bootstrap --only extras >/dev/null
    assert_log_lacks '^git clone'
    assert_log_lacks '^curl'
    assert_log_lacks '^make'
    assert_log_lacks '^ssh'
}

test_typst_without_ssh_key_warns() {
    fake ssh ssh 255 "git@github.com: Permission denied (publickey)."
    rc=0
    out=$(bootstrap --only extras 2>&1) || rc=$?
    assert_eq 0 "$rc" "return code"
    assert_log_lacks 'typst-templates'
    assert_contains "SSH key" "$out"
    assert_no_file "$HOME/$TYPST_DIR"
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
    assert_log_lacks '^ssh'
    assert_contains "missing: $HOME/.tmux/plugins/tpm" "$out"
    assert_contains "sketchybar_lua" "$out"
}

test_services_start_missing() {
    fake brew services-list 0 "Name       Status  User       File
borders    started mfischbach ~/Library/LaunchAgents/homebrew.mxcl.borders.plist
sketchybar none"
    out=$(bootstrap --only services)
    assert_log_has '^brew services start sketchybar$'
    assert_log_lacks '^brew services start borders'
    assert_log_has '^skhd --start-service$'
    case "$out" in *yabai*) fail "yabai follow-up still printed: $out" ;; esac
}

test_services_all_running() {
    fake brew services-list 0 "borders    started mfischbach x
sketchybar started mfischbach y"
    mkdir -p "$HOME/Library/LaunchAgents"
    touch "$HOME/Library/LaunchAgents/com.koekeishiya.skhd.plist"
    bootstrap --only services >/dev/null
    assert_log_lacks 'services start'
    assert_log_lacks '^skhd'
}

test_services_check_no_writes() {
    fake brew services-list 0 "sketchybar none"
    rc=0
    out=$(bootstrap --check --only services) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_log_lacks 'services start'
    assert_log_lacks '^skhd'
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
