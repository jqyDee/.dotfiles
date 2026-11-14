# shellcheck shell=bash

bootstrap() { bash "$DOTFILES/bootstrap.sh" "$@"; }

# line number of the first log line matching <regex>
first_line() { grep -nE -- "$1" "$STUB_LOG" | head -1 | cut -d: -f1; }

test_unknown_flag() {
    rc=0
    bootstrap --nope >/dev/null 2>&1 || rc=$?
    assert_eq 64 "$rc" "return code"
}

test_unknown_step() {
    rc=0
    bootstrap --only nope >/dev/null 2>&1 || rc=$?
    assert_eq 64 "$rc" "return code"
}

test_only_runs_one_step() {
    bootstrap --only macos >/dev/null
    assert_log_has '^defaults '
    assert_log_lacks '^xcode-select'
    assert_log_lacks '^brew bundle'
}

test_step_order() {
    bootstrap >/dev/null || true
    prev=0
    for re in '^xcode-select' '^brew shellenv' '^brew bundle' '^defaults '; do
        n=$(first_line "$re")
        [ -n "$n" ] || fail "no log line for $re"
        [ "$n" -gt "$prev" ] || fail "$re (line $n) ran before line $prev"
        prev=$n
    done
}

test_signin_once() {
    marker="$HOME/.local/state/dotfiles/signin-done"
    rm "$marker"
    printf '\n' | bootstrap --only signin >/dev/null
    assert_file "$marker"
    bootstrap --only signin </dev/null >/dev/null
}

test_check_without_brew() {
    rc=0
    out=$(BREW=/nonexistent bootstrap --check) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "Homebrew not installed" "$out"
    assert_log_lacks '^brew'
}

test_check_skips_signin_prompt() {
    rm "$HOME/.local/state/dotfiles/signin-done"
    bootstrap --check --only signin </dev/null >/dev/null
    assert_no_file "$HOME/.local/state/dotfiles/signin-done"
}

test_xcode_install_when_missing() {
    fake xcode-select xcode-select 1
    rc=0
    out=$(bootstrap --only xcode 2>&1) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_log_has '^xcode-select --install$'
    assert_contains "Failed" "$out"
}

test_brew_install_attempt() {
    rc=0
    out=$(BREW=/nonexistent bootstrap --only brew 2>&1) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_log_has '^curl .*Homebrew/install/HEAD/install.sh'
}
