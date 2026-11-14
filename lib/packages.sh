# shellcheck shell=bash
# Steps: bundle (Brewfile), stow (config links).

step_bundle() {
    [ -z "${NO_BREW:-}" ] || return 0
    local brewfile="$DOTFILES/Brewfile" out line

    if [ "$MODE" = apply ]; then
        "$BREW" bundle --file="$brewfile" && return 0
        note_failure "brew bundle (App Store signed in?)"
        return 1
    fi

    if ! out=$("$BREW" bundle check --file="$brewfile" --verbose 2>&1); then
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
