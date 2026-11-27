# shellcheck shell=bash
# Steps: bundle (Brewfile), stow (config links).

# The Brewfile's `cargo` entries need cargo on PATH, or brew bundle installs
# the `rust` formula to get one (plus libgit2 and libssh2), which then shows
# as drift. rustup is keg-only and .zshrc adds it to PATH, but bootstrap runs
# in bash without it. So install rustup and a toolchain first, and put
# rustup's cargo on PATH for the bundle run (and for --check, so it lists
# the same crates). Only apply mode installs anything.
_bundle_rustup() {
    local rustup_bin
    rustup_bin="$("$BREW" --prefix)/opt/rustup/bin"
    export PATH="$rustup_bin:$HOME/.cargo/bin:$PATH"
    [ "$MODE" = apply ] || return 0
    if [ ! -x "$rustup_bin/rustup" ]; then
        "$BREW" install rustup || {
            note_failure "brew install rustup"
            return 1
        }
    fi
    if rustup toolchain list 2>/dev/null | grep -qi "^no installed toolchains"; then
        rustup default stable || {
            note_failure "rustup default stable"
            return 1
        }
        note_change "rust stable toolchain (rustup)"
    fi
}

step_bundle() {
    [ -z "${NO_BREW:-}" ] || return 0
    local brewfile="$DOTFILES/Brewfile" out line

    _bundle_rustup || return 1
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

PACKAGES=(aerospace borders ghostty gh git ideavim nvim sketchybar ssh starship tmux typst udo zed zsh)

# A stow conflict (a real file where a link should go) ends the whole run
# with exit 2, before anything is linked. No --adopt, nothing is moved.
# The dry run uses plain stow, not -R: restow lists every existing link.
step_stow() {
    local out rc=0 links conflicts line
    if ! command -v stow >/dev/null; then
        log_warn "stow is not installed (it comes from the Brewfile; did the brew or bundle step fail?)"
        return 1
    fi
    # Without a real ~/.ssh, stow would link the whole folder into the repo
    # and known_hosts would land in git
    if [ "$MODE" = apply ] && [ ! -d "$HOME/.ssh" ]; then
        mkdir -m 700 "$HOME/.ssh" || return 1
    fi
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
