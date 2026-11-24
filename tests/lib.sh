# shellcheck shell=bash
# Test helpers: every test runs in a sandbox with a temporary $HOME and the
# stubs in tests/stubs first on $PATH, so nothing touches the real machine.

TESTS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=$(cd "$TESTS/.." && pwd)

sandbox() {
    local root
    root=$(mktemp -d)
    export HOME="$root/home" FAKE="$root/fake"
    export PATH="$TESTS/stubs:/usr/bin:/bin"
    export BREW="$TESTS/stubs/brew" STUB_LOG="$root/fake/calls.log"
    export DOTFILES="$REPO" XCODE_WAIT=1 XCODE_POLL=0
    unset XDG_STATE_HOME NO_BREW MODE
    mkdir -p "$HOME/.local/state/dotfiles" "$FAKE"
    touch "$HOME/.local/state/dotfiles/signin-done"
    : >"$STUB_LOG"
}

fail() {
    echo "assertion failed: $*" >&2
    exit 1
}

assert_eq() {
    [ "$1" = "$2" ] || fail "${3:-expected} '$1', got '$2'"
}

assert_log_has() {
    grep -Eq -- "$1" "$STUB_LOG" || fail "log has no match for /$1/ (log: $(tr '\n' '|' <"$STUB_LOG"))"
}

assert_log_lacks() {
    ! grep -Eq -- "$1" "$STUB_LOG" || fail "log unexpectedly matches /$1/: $(grep -E -- "$1" "$STUB_LOG" | head -3 | tr '\n' '|')"
}

assert_contains() {
    case "$2" in *"$1"*) ;; *) fail "'$1' not found in: $2" ;; esac
}

assert_file() {
    [ -e "$1" ] || fail "missing file $1"
}

assert_no_file() {
    [ ! -e "$1" ] || fail "unexpected file $1"
}

# fake_default <domain> <key> <boolean|integer|float|string> <value>
fake_default() {
    mkdir -p "$FAKE/defaults/$1"
    printf '%s %s\n' "$3" "$4" >"$FAKE/defaults/$1/$2"
}

# fake <tool> <key> <rc> [output]: make a stub return rc and print output
fake() {
    mkdir -p "$FAKE/$1"
    echo "$3" >"$FAKE/$1/$2.rc"
    if [ $# -ge 4 ]; then printf '%s\n' "$4" >"$FAKE/$1/$2.out"; fi
}

# every extras target present, udo-keyboard agent loaded (launchctl rc 0)
all_extras_present() {
    mkdir -p "$HOME/.zsh/zsh-autosuggestions" "$HOME/.zsh/zsh-syntax-highlighting" \
        "$HOME/.tmux/plugins/tpm" "$HOME/.local/share/sketchybar_lua" \
        "$HOME/Library/Fonts"
    touch "$HOME/.local/share/sketchybar_lua/sketchybar.so" \
        "$HOME/Library/Fonts/sketchybar-app-font.ttf"
}
