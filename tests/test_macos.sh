# shellcheck shell=bash
# shellcheck disable=SC1091
. "$DOTFILES/lib/common.sh"
# shellcheck disable=SC1091
. "$DOTFILES/macos.sh"

# all settings at their repo values, log cleared
all_set() {
    step_macos >/dev/null
    # shellcheck disable=SC2034 # reset common.sh lists
    CHANGES=() FOLLOWUPS=()
    : >"$STUB_LOG"
}

test_writes_differing_value() {
    fake_default com.apple.dock autohide boolean 0
    step_macos >/dev/null
    assert_log_has '^defaults write com.apple.dock autohide -bool true$'
    assert_log_has '^killall Dock$'
}

test_bool_and_float_match() {
    all_set
    # how `defaults read` really prints them: bools as 1/0, floats as numbers
    fake_default com.apple.dock autohide boolean 1
    fake_default com.apple.dock autohide-time-modifier float 0.20
    fake_default NSGlobalDomain ApplePressAndHoldEnabled boolean 0
    step_macos >/dev/null
    assert_log_lacks '^defaults write'
    assert_log_lacks '^killall'
}

test_check_mode_no_writes() {
    MODE=check
    fake_default com.apple.dock autohide boolean 0
    step_macos >/dev/null
    rc=0
    out=$(print_summary) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "com.apple.dock autohide" "$out"
    assert_log_lacks '^defaults write'
    assert_log_lacks '^killall'
}

test_restart_once() {
    step_macos >/dev/null
    assert_eq 1 "$(grep -c '^killall Dock$' "$STUB_LOG")" "killall Dock count"
    assert_eq 1 "$(grep -c '^killall Finder$' "$STUB_LOG")" "killall Finder count"
}

test_global_domain_followup() {
    all_set
    fake_default NSGlobalDomain KeyRepeat integer 2
    step_macos >/dev/null
    assert_log_has '^defaults write NSGlobalDomain KeyRepeat -int 1$'
    assert_contains "log out" "$(print_summary)"
    assert_log_lacks '^killall'
}

test_standalone_check() {
    rc=0
    bash "$DOTFILES/macos.sh" --check >/dev/null || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_log_lacks '^defaults write'
}

test_standalone_bad_flag() {
    rc=0
    bash "$DOTFILES/macos.sh" --nope >/dev/null 2>&1 || rc=$?
    assert_eq 64 "$rc" "return code"
}
