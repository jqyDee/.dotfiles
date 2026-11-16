# shellcheck shell=bash
# Shared helpers for bootstrap.sh and macos.sh: mode, logging and the lists
# that make up the summary at the end of a run.

MODE=${MODE:-apply} # apply | check
# shellcheck disable=SC2034 # used by lib/system.sh
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"

CHANGES=()
DRIFT=()
FAILURES=()
FOLLOWUPS=()

log_step() { printf '\n==> %s\n' "$1"; }
log_info() { printf '    %s\n' "$1"; }
log_warn() { printf '    warning: %s\n' "$1" >&2; }

note_change() { CHANGES+=("$1") && log_info "changed: $1"; }
note_drift() { DRIFT+=("$1") && log_info "drift: $1"; }
note_failure() { FAILURES+=("$1") && log_warn "failed: $1"; }
note_followup() { FOLLOWUPS+=("$1"); }

_print_list() {
    local heading=$1
    shift
    [ $# -gt 0 ] || return 0
    printf '\n%s:\n' "$heading"
    printf '  - %s\n' "$@"
}

# Print what happened; returns 1 if anything drifted or failed.
print_summary() {
    # ${a[@]+"${a[@]}"}: empty arrays are "unbound" under set -u in bash 3.2
    _print_list Changed ${CHANGES[@]+"${CHANGES[@]}"}
    _print_list Drift ${DRIFT[@]+"${DRIFT[@]}"}
    _print_list Failed ${FAILURES[@]+"${FAILURES[@]}"}
    _print_list Follow-ups ${FOLLOWUPS[@]+"${FOLLOWUPS[@]}"}
    [ ${#DRIFT[@]} -eq 0 ] && [ ${#FAILURES[@]} -eq 0 ]
}
