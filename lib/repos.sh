# shellcheck shell=bash
# Step: repos (clone the repos in repos.txt that are missing; in --check also
# report uncommitted or unpushed work in every repo under ~/Developer).

REPOS_FILE=${REPOS_FILE:-$DOTFILES/repos.txt}

# _repos_list: "<path> <url>" for every repo in repos.txt
_repos_list() {
    sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$REPOS_FILE"
}

# _clone_repo <dest> <url>
_clone_repo() {
    # BatchMode: fail at once instead of asking for a passphrase.
    # accept-new: trust github.com's host key on the first connect of a fresh Mac.
    GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new" \
        git clone --quiet --recurse-submodules "$2" "$1" || return 1
    # Submodules come out on a detached HEAD: put each on its branch from
    # .gitmodules (or the remote's default branch), at the latest pushed commit
    # shellcheck disable=SC2016 # expands inside git submodule foreach
    git -C "$1" submodule foreach --quiet --recursive \
        'b=$(git config -f "$toplevel/.gitmodules" "submodule.$name.branch" ||
            git symbolic-ref --short refs/remotes/origin/HEAD | sed "s|^origin/||")
        git switch --quiet "$b"'
}

# _adopt_repo <dest> <url>: <dest> has files but no .git, e.g. the Unison sync
# filled it from iCloud before the clone. Clone next to it, copy the files on
# top (they are the newer work: they show up as changes; --ignore-times, as
# a synced file can match the clone's size and mtime), then swap the two.
# The old folder is kept as <dest>.before-clone-<time>, path in ADOPT_BACKUP.
_adopt_repo() {
    local dest=$1 url=$2 tmp paused=0
    tmp="$(dirname "$dest")/.$(basename "$dest").clone"
    rm -rf "$tmp"
    _clone_repo "$tmp" "$url" || {
        rm -rf "$tmp"
        return 1
    }
    rsync -a --ignore-times --exclude .git "$dest/" "$tmp/" || {
        rm -rf "$tmp"
        return 1
    }
    ADOPT_BACKUP="$dest.before-clone-$(date +%Y%m%d-%H%M%S)"
    # The sync agent watches the folder: keep it from running mid-swap
    if [ -n "${SYNC_AGENT:-}" ] && launchctl print "gui/$(id -u)/$SYNC_AGENT" >/dev/null 2>&1; then
        launchctl bootout "gui/$(id -u)/$SYNC_AGENT" 2>/dev/null && paused=1
    fi
    mv "$dest" "$ADOPT_BACKUP" && mv "$tmp" "$dest"
    local rc=$?
    [ "$paused" -eq 0 ] || launchctl bootstrap "gui/$(id -u)" "$SYNC_PLIST" || true
    return "$rc"
}

step_repos() {
    local path url dest failed=0
    while read -r path url; do
        dest="$HOME/$path"
        [ -e "$dest/.git" ] && continue
        if [ -n "$(ls -A "$dest" 2>/dev/null)" ]; then
            if [ "$MODE" = check ]; then
                # shellcheck disable=SC2088 # ~ is shown, not expanded
                note_drift "~/$path exists but is not a git repo (bootstrap clones it and keeps the files)"
            elif _adopt_repo "$dest" "$url"; then
                note_change "cloned ~/$path over the files already there (old folder: ~/${ADOPT_BACKUP#"$HOME/"})"
            else
                note_failure "clone ~/$path over the files already there (is Bitwarden unlocked?)"
                failed=1
            fi
            continue
        fi
        if [ "$MODE" = check ]; then
            note_drift "missing repo: ~/$path"
            continue
        fi
        if _clone_repo "$dest" "$url"; then
            note_change "cloned ~/$path"
        else
            note_failure "clone ~/$path (is Bitwarden unlocked?)"
            failed=1
        fi
    done < <(_repos_list)
    [ "$failed" -eq 0 ] || note_followup "repos missing: unlock Bitwarden (Settings: Enable SSH agent), then ./bootstrap.sh --only repos"

    if [ "$MODE" = check ]; then
        while IFS= read -r dest; do
            _check_repo "$dest"
        done < <(_repo_paths)
    fi
    return "$failed"
}

# _repo_paths: every repo under ~/Developer (submodules included) and the dotfiles
_repo_paths() {
    echo "$DOTFILES"
    [ -d "$HOME/Developer" ] || return 0
    # .git is a folder in a repo and a file in a submodule
    find "$HOME/Developer" \
        \( -name target -o -name build -o -name node_modules -o -name .venv -o -name venv \
        -o -name .terraform -o -name __pycache__ -o -name .pio \) -prune \
        -o -name .git -prune -print 2>/dev/null | sed 's|/\.git$||' | sort
}

# _check_repo <dir>: drift for work that only exists on this Mac. Compares
# against the last fetch, so it needs no network.
_check_repo() {
    local dir=$1 name n line branch
    name="~${dir#"$HOME"}"
    git -C "$dir" rev-parse -q --verify HEAD >/dev/null 2>&1 || {
        note_drift "$name: no commits yet"
        return 0
    }
    # Submodules are checked as repos of their own
    n=$(git -C "$dir" status --porcelain --ignore-submodules=all | wc -l | tr -d ' ')
    [ "$n" -eq 0 ] || note_drift "$name: $n uncommitted changes"
    n=$(git -C "$dir" stash list | wc -l | tr -d ' ')
    [ "$n" -eq 0 ] || note_drift "$name: $n stashes"

    # A branch is only at risk if it has commits that no remote branch has:
    # merged branches whose upstream is gone, or ones without an upstream
    # that were pushed under another name, are fine
    while IFS= read -r branch; do
        n=$(git -C "$dir" rev-list --count "refs/heads/$branch" --not --remotes)
        [ "$n" -eq 0 ] || note_drift "$name: branch $branch has $n commits on no remote"
    done < <(git -C "$dir" for-each-ref --format='%(refname:short)' refs/heads)

    # Detached HEAD (normal in submodules): fine as long as a remote has the commit
    if ! git -C "$dir" symbolic-ref -q HEAD >/dev/null &&
        [ -z "$(git -C "$dir" branch -r --contains HEAD 2>/dev/null)" ]; then
        line=$(git -C "$dir" log -1 --format='%h %s')
        note_drift "$name: detached HEAD not on any remote branch ($line)"
    fi
}
