# shellcheck shell=bash
# Steps: bundle (Brewfile), stow (config links).

step_bundle() {
    [ -z "${NO_BREW:-}" ] || return 0
    local brewfile="$DOTFILES/Brewfile" out line

    if [ "$MODE" = apply ]; then
        "$BREW" bundle --file="$brewfile" --no-upgrade && return 0
        note_failure "brew bundle (App Store signed in?)"
        return 1
    fi

    if ! out=$("$BREW" bundle check --file="$brewfile" --no-upgrade --verbose 2>&1); then
        while IFS= read -r line; do
            case $line in "→ "*) note_drift "missing: ${line#→ }" ;; esac
        done <<<"$out"
    fi
    # without --force this only lists, it never uninstalls
    out=$("$BREW" bundle cleanup --file="$brewfile" 2>&1) || true
    while IFS= read -r line; do
        case $line in "" | Would* | Run*) ;; *) note_drift "not in Brewfile: $line" ;; esac
    done <<<"$out"
}

PACKAGES=(aerospace alacritty borders gh git ideavim nvim sketchybar skhd starship tmux udo yabai zed zsh)

# A stow conflict (a real file where a link should go) ends the whole run
# with exit 2, before anything is linked. No --adopt, nothing is moved.
# The dry run uses plain stow, not -R: restow lists every existing link.
step_stow() {
    local out rc=0 links conflicts line
    out=$(stow -n -v -d "$DOTFILES" -t "$HOME" "${PACKAGES[@]}" 2>&1) || rc=$?

    conflicts=$(grep -E 'existing target|cannot stow|conflict' <<<"$out" || true)
    if [ -n "$conflicts" ]; then
        printf '%s\n' "$conflicts" >&2
        note_failure "stow conflict: move the files above out of the way, then re-run"
        print_summary || true
        exit 2
    fi
    if [ "$rc" -ne 0 ]; then
        log_warn "$out"
        return 1
    fi

    links=$(grep '^LINK: ' <<<"$out" || true)
    [ -n "$links" ] || return 0
    if [ "$MODE" = check ]; then
        while IFS= read -r line; do
            note_drift "not linked: ${line#LINK: }"
        done <<<"$links"
        return 0
    fi
    stow -d "$DOTFILES" -t "$HOME" "${PACKAGES[@]}" || return 1
    note_change "stow linked $(wc -l <<<"$links" | tr -d ' ') paths"
}

# _brewfile_keys [file...]: "<type> <name>" for every entry (stdin without files)
_brewfile_keys() {
    sed -nE 's/^(tap|brew|cask|cargo|mas|npm|vscode|go|uv) "([^"]+)".*/\1 \2/p' "$@" 2>/dev/null || true
}

# save_local [name...]: append packages installed on this Mac but missing
# from the Brewfile to Brewfile.local (all of them, or only the named ones).
# brew bundle dump lists only what was installed on request, so their
# dependencies stay out of the file and stop drifting with them.
save_local() {
    local local_file="$DOTFILES/Brewfile.local" dump known line key name arg matched
    local comment="" found=" "
    dump=$("$BREW" bundle dump --file=- 2>/dev/null) || {
        note_failure "brew bundle dump"
        return 1
    }
    known=$(_brewfile_keys "$DOTFILES/Brewfile" "$local_file")

    while IFS= read -r line; do
        case $line in "#"*) comment=$line && continue ;; esac
        key=$(_brewfile_keys <<<"$line")
        name=${key#* }
        if [ -n "$key" ] && [ $# -gt 0 ]; then
            matched=0
            for arg in "$@"; do
                if [ "$arg" = "$name" ] || [ "$arg" = "${name##*/}" ]; then
                    found="$found$arg "
                    matched=1
                fi
            done
            [ "$matched" -eq 1 ] || key=""
        fi
        if [ -n "$key" ] && ! grep -qxF "$key" <<<"$known"; then
            [ -e "$local_file" ] || printf '%s\n' \
                "# Machine-local packages: installed on this Mac only, never committed." \
                "# Loaded by Brewfile. Add with: ./bootstrap.sh --save-local [name...]" >"$local_file"
            [ -z "$comment" ] || echo "$comment" >>"$local_file"
            echo "$line" >>"$local_file"
            known="$known"$'\n'"$key"
            note_change "Brewfile.local: $line"
        fi
        comment=""
    done <<<"$dump"

    for arg in "$@"; do
        case $found in *" $arg "*) ;; *) note_failure "$arg: not installed on request (see brew bundle dump)" ;; esac
    done
}
