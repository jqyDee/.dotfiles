# shellcheck shell=bash
# Steps: xcode, brew, signin.
# Steps run inside `if`, where set -e is off: every failure returns explicitly.

step_xcode() {
    xcode-select -p >/dev/null 2>&1 && return 0
    if [ "$MODE" = check ]; then
        note_drift "Xcode command line tools not installed"
        return 0
    fi
    xcode-select --install || true
    log_info "waiting for the command line tools installer to finish..."
    local waited=0
    until xcode-select -p >/dev/null 2>&1; do
        [ "$waited" -lt "${XCODE_WAIT:-1800}" ] || return 1
        sleep "${XCODE_POLL:-5}"
        waited=$((waited + ${XCODE_POLL:-5} + 1))
    done
    note_change "installed Xcode command line tools"
}

step_brew() {
    if [ ! -x "$BREW" ]; then
        if [ "$MODE" = check ]; then
            note_drift "Homebrew not installed"
            export NO_BREW=1
            return 0
        fi
        # the installer runs non-interactively and can't ask for a password
        if ! sudo -v; then
            log_warn "installing Homebrew needs an admin password (sudo)"
            export NO_BREW=1
            return 1
        fi
        NONINTERACTIVE=1 /bin/bash -c \
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true
        if [ ! -x "$BREW" ]; then
            export NO_BREW=1
            return 1
        fi
        note_change "installed Homebrew"
    fi
    eval "$("$BREW" shellenv)"
}

step_signin() {
    local marker="$STATE_DIR/signin-done"
    [ "$MODE" = apply ] || return 0
    [ -e "$marker" ] && return 0
    printf '    Sign in to the App Store and iCloud, then press Enter. '
    read -r _ || true
    mkdir -p "$STATE_DIR" && touch "$marker"
}
