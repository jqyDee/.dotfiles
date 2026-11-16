#!/usr/bin/env bash
# macOS settings. Sourced by bootstrap.sh (step "macos"), or run alone:
#
#   ~/.dotfiles/macos.sh           apply the settings below
#   ~/.dotfiles/macos.sh --check   only show what differs
#   ~/.dotfiles/macos.sh --record  change something in System Settings, get
#                                  the matching `setting` lines (reads only)
#
# A setting is only written when its current value differs. Dock and Finder
# are restarted once at the end, and only if one of their settings changed.

_MACOS_RESTART="" # apps to restart, space separated
_MACOS_LOGOUT=0   # a setting that only applies after logging out changed

# _macos_normalize <-type> <value>: compare bools as 1/0, floats as numbers
_macos_normalize() {
    case $1 in
    -bool) case $2 in true | yes | 1) echo 1 ;; *) echo 0 ;; esac ;;
    -float) printf '%g' "$2" 2>/dev/null || printf '%s' "$2" ;;
    *) printf '%s' "$2" ;;
    esac
}

_macos_mark() {
    case " $_MACOS_RESTART " in
    *" $1 "*) ;;
    *) _MACOS_RESTART="$_MACOS_RESTART $1" ;;
    esac
}

# setting <domain> <key> <-bool|-int|-float|-string> <value>
setting() {
    local domain=$1 key=$2 type=$3 value=$4 current want
    want=$(_macos_normalize "$type" "$value")
    if current=$(defaults read "$domain" "$key" 2>/dev/null); then
        current=$(_macos_normalize "$type" "$current")
    else
        current="(unset)"
    fi
    [ "$current" = "$want" ] && return 0

    if [ "$MODE" = check ]; then
        note_drift "$domain $key: $current → $value"
        return 0
    fi
    defaults write "$domain" "$key" "$type" "$value"
    note_change "$domain $key = $value"
    case $domain in
    com.apple.dock | com.apple.spaces | com.apple.WindowManager) _macos_mark Dock ;;
    com.apple.finder) _macos_mark Finder ;;
    NSGlobalDomain | com.apple.AppleMultitouchTrackpad) _MACOS_LOGOUT=1 ;;
    esac
}

step_macos() {
    _MACOS_RESTART=""
    _MACOS_LOGOUT=0

    # Dock
    setting com.apple.dock autohide -bool true
    setting com.apple.dock autohide-time-modifier -float 0.2
    setting com.apple.dock tilesize -int 52
    setting com.apple.dock show-recents -bool false
    setting com.apple.dock mru-spaces -bool false # don't reorder Spaces

    # Finder
    setting com.apple.finder ShowPathbar -bool true
    setting com.apple.finder ShowStatusBar -bool true
    setting com.apple.finder FXPreferredViewStyle -string Nlsv  # list view
    setting com.apple.finder FXDefaultSearchScope -string SCcf # search current folder

    # keyboard, text, appearance
    setting NSGlobalDomain KeyRepeat -int 1
    setting NSGlobalDomain InitialKeyRepeat -int 12
    setting NSGlobalDomain ApplePressAndHoldEnabled -bool false
    setting NSGlobalDomain AppleInterfaceStyle -string Dark
    setting NSGlobalDomain _HIHideMenuBar -bool true # sketchybar replaces it
    setting NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    setting NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    setting NSGlobalDomain com.apple.swipescrolldirection -bool true # macOS default

    # trackpad
    setting com.apple.AppleMultitouchTrackpad Clicking -bool true # tap to click

    # desktop and Spaces
    setting com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
    setting com.apple.WindowManager GloballyEnabled -bool false # Stage Manager, macOS default
    setting com.apple.spaces spans-displays -bool false         # macOS default

    [ "$MODE" = apply ] || return 0
    local app
    for app in $_MACOS_RESTART; do
        killall "$app" 2>/dev/null || true
    done
    if [ "$_MACOS_LOGOUT" -eq 1 ]; then
        note_followup "log out and back in for keyboard/trackpad/menu bar settings"
    fi
}

# _macos_snapshot <dir>: export every defaults domain into <dir>/<domain>.plist
_macos_snapshot() {
    local d
    mkdir -p "$1"
    { echo NSGlobalDomain && defaults domains | tr ',' '\n'; } | sed 's/^ *//;/^$/d' |
        while IFS= read -r d; do
            defaults export "$d" "$1/$d.plist" 2>/dev/null || true
        done
}

# macos_record: print the settings that change while you wait at the prompt
macos_record() {
    local tmp rc=0
    tmp=$(mktemp -d)
    _macos_snapshot "$tmp/before"
    printf 'Change the settings now, then press Enter. ' >&2
    read -r _ || true
    _macos_snapshot "$tmp/after"
    python3 "$_MACOS_DIR/lib/defaults_diff.py" "$tmp/before" "$tmp/after" "$_MACOS_DIR/macos.sh" || rc=$?
    rm -rf "$tmp"
    return "$rc"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    set -euo pipefail
    _MACOS_DIR=$(cd "$(dirname "$0")" && pwd)
    # shellcheck source=lib/common.sh
    . "$_MACOS_DIR/lib/common.sh"
    case ${1:-} in
    --check) MODE=check ;;
    --record)
        macos_record
        exit
        ;;
    "") ;;
    *)
        echo "usage: $0 [--check | --record]" >&2
        exit 64
        ;;
    esac
    log_step macos
    step_macos
    print_summary
fi
