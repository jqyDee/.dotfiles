#!/usr/bin/env bash
# Set up this Mac from the dotfiles repo. Safe to re-run: every step skips
# work that is already done.
#
#   ./bootstrap.sh                 run every step
#   ./bootstrap.sh --check         change nothing, report drift
#   ./bootstrap.sh --only <step>   run one step
#
# Exit codes: 0 ok, 1 drift or a failed step, 2 stow conflict, 64 usage.
set -euo pipefail

STEPS="xcode brew signin bundle stow macos extras services"

usage() {
    echo "usage: $0 [--check] [--only <step>]" >&2
    echo "steps: $STEPS" >&2
    exit 64
}

MODE=apply
only=""
while [ $# -gt 0 ]; do
    case $1 in
    --check) MODE=check ;;
    --only)
        [ $# -ge 2 ] || usage
        only=$2
        shift
        ;;
    *) usage ;;
    esac
    shift
done
if [ -n "$only" ]; then
    case " $STEPS " in *" $only "*) ;; *) usage ;; esac
fi

DOTFILES=$(cd "$(dirname "$0")" && pwd)
BREW=${BREW:-/opt/homebrew/bin/brew}
export DOTFILES BREW MODE

# shellcheck source=lib/common.sh
. "$DOTFILES/lib/common.sh"
for lib in "$DOTFILES"/lib/*.sh; do
    # shellcheck disable=SC1090
    [ "$lib" = "$DOTFILES/lib/common.sh" ] || . "$lib"
done
# shellcheck source=macos.sh
. "$DOTFILES/macos.sh"

for step in $STEPS; do
    [ -z "$only" ] || [ "$only" = "$step" ] || continue
    declare -F "step_$step" >/dev/null || continue
    log_step "$step"
    if ! "step_$step"; then
        note_failure "$step"
    fi
done

rc=0
print_summary || rc=1
exit "$rc"
