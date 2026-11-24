#!/usr/bin/env bash
# Set up this Mac from the dotfiles repo. Safe to re-run: every step skips
# work that is already done.
#
#   ./bootstrap.sh                 run every step
#   ./bootstrap.sh --check         change nothing, report drift
#   ./bootstrap.sh --only <step>   run one step
#   ./bootstrap.sh --save-local [name...]
#                                  keep packages installed by hand out of
#                                  the drift report (writes Brewfile.local)
#
# Exit codes: 0 ok, 1 drift or a failed step, 2 stow conflict, 64 usage.
set -euo pipefail

STEPS="xcode brew signin bundle stow repos sync macos extras services"

usage() {
    echo "usage: $0 [--check] [--only <step>] | --save-local [name...]" >&2
    echo "steps: $STEPS" >&2
    exit 64
}

MODE=apply
only=""
save=0
names=()
while [ $# -gt 0 ]; do
    case $1 in
    --check) MODE=check ;;
    --save-local)
        save=1
        shift
        while [ $# -gt 0 ]; do
            case $1 in -*) usage ;; esac
            names+=("$1")
            shift
        done
        break
        ;;
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
# brew's tools for every step, also with --only in a shell that predates
# the Homebrew install (the brew step adds the rest of shellenv)
case ":$PATH:" in *":$(dirname "$BREW"):"*) ;; *) PATH="$PATH:$(dirname "$BREW")" ;; esac

# shellcheck source=lib/common.sh
. "$DOTFILES/lib/common.sh"
for lib in "$DOTFILES"/lib/*.sh; do
    # shellcheck disable=SC1090
    [ "$lib" = "$DOTFILES/lib/common.sh" ] || . "$lib"
done
# shellcheck source=macos.sh
. "$DOTFILES/macos.sh"

if [ "$save" -eq 1 ]; then
    [ "$MODE" = apply ] && [ -z "$only" ] || usage
    log_step save-local
    save_local ${names[@]+"${names[@]}"}
    rc=0
    print_summary || rc=1
    exit "$rc"
fi

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
