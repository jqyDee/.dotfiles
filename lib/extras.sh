# shellcheck shell=bash
# Steps: extras (things the Brewfile and stow don't cover), services.

# ensure_clone <url> <dest>
ensure_clone() {
    [ -e "$2" ] && return 0
    if [ "$MODE" = check ]; then
        note_drift "missing: $2"
        return 0
    fi
    git clone --quiet "$1" "$2" || return 1
    note_change "cloned $2"
}

# ensure_download <url> <dest>
ensure_download() {
    [ -e "$2" ] && return 0
    if [ "$MODE" = check ]; then
        note_drift "missing: $2"
        return 0
    fi
    mkdir -p "$(dirname "$2")" && curl -fsSL -o "$2" "$1" || return 1
    note_change "downloaded $2"
}

_extras_sbarlua() {
    [ -e "$HOME/.local/share/sketchybar_lua/sketchybar.so" ] && return 0
    if [ "$MODE" = check ]; then
        note_drift "missing: $HOME/.local/share/sketchybar_lua/sketchybar.so"
        return 0
    fi
    local tmp rc=0
    tmp=$(mktemp -d)
    git clone --quiet https://github.com/FelixKratz/SbarLua.git "$tmp/SbarLua" &&
        (cd "$tmp/SbarLua" && make install) || rc=1
    rm -rf "$tmp"
    [ "$rc" -eq 0 ] && note_change "built SbarLua"
    return "$rc"
}

_extras_udo_keyboard() {
    launchctl print "gui/$(id -u)/local.corne.udo-status" >/dev/null 2>&1 && return 0
    if [ "$MODE" = check ]; then
        note_drift "udo-keyboard LaunchAgent not loaded"
        return 0
    fi
    if [ ! -x "$HOME/.config/udo-keyboard/install.sh" ]; then
        log_warn "udo-keyboard install.sh missing (the stow step links it)"
        return 1
    fi
    "$HOME/.config/udo-keyboard/install.sh" || return 1
    note_change "installed udo-keyboard LaunchAgent"
}

# Sets the picture on every desktop. The first run asks to let the terminal
# control System Events.
_extras_wallpaper() {
    local want="$DOTFILES/wallpaper/tree.png" current
    current=$(osascript -e 'tell application "System Events" to get picture of every desktop' 2>/dev/null) || current=""
    # one path per desktop, comma separated
    [ -n "$current" ] && ! tr ',' '\n' <<<"$current" | sed 's/^ *//' | grep -qvxF "$want" && return 0
    if [ "$MODE" = check ]; then
        note_drift "wallpaper is not $want"
        return 0
    fi
    osascript -e "tell application \"System Events\" to set picture of every desktop to \"$want\"" >/dev/null || return 1
    note_change "set wallpaper to $want"
}

step_extras() {
    local failed=0
    ensure_clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh/zsh-autosuggestions" || failed=1
    ensure_clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.zsh/zsh-syntax-highlighting" || failed=1
    ensure_clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" || failed=1
    _extras_sbarlua || failed=1
    ensure_download https://github.com/kvndrsslr/sketchybar-app-font/releases/latest/download/sketchybar-app-font.ttf \
        "$HOME/Library/Fonts/sketchybar-app-font.ttf" || failed=1
    _extras_udo_keyboard || failed=1
    _extras_wallpaper || failed=1
    return "$failed"
}

step_services() {
    [ -z "${NO_BREW:-}" ] || return 0
    local list name status failed=0
    list=$("$BREW" services list 2>/dev/null) || list=""
    for name in sketchybar borders; do
        status=$(awk -v n="$name" '$1 == n { print $2 }' <<<"$list")
        [ "$status" = started ] && continue
        if [ "$MODE" = check ]; then
            note_drift "$name not running"
            continue
        fi
        "$BREW" services start "$name" >/dev/null && note_change "started $name" || failed=1
    done

    # Not a brew service: start-at-login only takes effect once it has run
    if ! pgrep -x AeroSpace >/dev/null; then
        if [ "$MODE" = check ]; then
            note_drift "AeroSpace not running"
        elif open -a AeroSpace; then
            note_change "started AeroSpace"
            note_followup "allow AeroSpace in System Settings → Privacy & Security → Accessibility"
        else
            failed=1
        fi
    fi

    return "$failed"
}
