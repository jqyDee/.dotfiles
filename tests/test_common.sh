# shellcheck shell=bash
# shellcheck disable=SC1091
. "$DOTFILES/lib/common.sh"

test_summary_ok() {
    out=$(print_summary)
    assert_eq 0 $?
    case "$out" in *Drift*) fail "unexpected Drift heading: $out" ;; esac
}

test_summary_drift() {
    note_drift "x" >/dev/null
    rc=0
    out=$(print_summary) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains Drift "$out"
    assert_contains x "$out"
}

test_summary_failure() {
    note_failure "y" >/dev/null
    rc=0
    print_summary >/dev/null || rc=$?
    assert_eq 1 "$rc" "return code"
}

test_stub_logs() {
    defaults write a b -bool true
    assert_eq 1 "$(defaults read a b)"
    assert_log_has '^defaults write a b -bool true$'
}
