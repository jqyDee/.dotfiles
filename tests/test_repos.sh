# shellcheck shell=bash
# shellcheck disable=SC2088 # the messages show ~ literally

bootstrap() { bash "$DOTFILES/bootstrap.sh" "$@"; }

two_repos() {
    printf '%s\n' "# comment" "" \
        "Developer/a   git@github.com:me/a.git" \
        "Developer/projects/b git@github.com:me/b.git  # trailing comment" >"$REPOS_FILE"
}

test_repos_clone_missing() {
    two_repos
    bootstrap --only repos >/dev/null
    assert_log_has "^git clone --quiet --recurse-submodules git@github.com:me/a.git $HOME/Developer/a$"
    assert_log_has "^git clone --quiet --recurse-submodules git@github.com:me/b.git $HOME/Developer/projects/b$"
    assert_log_has "^git -C $HOME/Developer/a submodule foreach --quiet --recursive "
    assert_eq 2 "$(grep -c '^git clone' "$STUB_LOG")" "clones"
}

test_repos_skip_existing() {
    two_repos
    mkdir -p "$HOME/Developer/a/.git" "$HOME/Developer/projects/b/.git"
    bootstrap --only repos >/dev/null
    assert_log_lacks '^git'
}

test_repos_check_no_writes() {
    two_repos
    mkdir -p "$HOME/Developer/a/.git"
    rc=0
    out=$(bootstrap --check --only repos) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_log_lacks '^git clone'
    assert_contains "missing repo: ~/Developer/projects/b" "$out"
    case "$out" in *"Developer/a"*) fail "reported a present repo: $out" ;; esac
}

test_repos_clone_failure_points_to_ssh() {
    two_repos
    fake git git 128 "git@github.com: Permission denied (publickey)."
    rc=0
    out=$(bootstrap --only repos 2>&1) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "clone ~/Developer/a (is Bitwarden unlocked?)" "$out"
    assert_contains "clone ~/Developer/projects/b" "$out"
    assert_contains "./bootstrap.sh --only repos" "$out"
}

test_repos_check_folder_in_the_way() {
    two_repos
    mkdir -p "$HOME/Developer/a" "$HOME/Developer/projects/b/.git"
    touch "$HOME/Developer/a/notes.txt"
    rc=0
    out=$(bootstrap --check --only repos 2>&1) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "~/Developer/a exists but is not a git repo" "$out"
    assert_log_lacks '^git clone'
    assert_file "$HOME/Developer/a/notes.txt"
}

test_repos_empty_folder_is_cloned_into() {
    two_repos
    mkdir -p "$HOME/Developer/a" "$HOME/Developer/projects/b/.git"
    bootstrap --only repos >/dev/null
    assert_log_has "^git clone .* $HOME/Developer/a$"
}

test_repos_file_parses() {
    REPOS_FILE="$DOTFILES/repos.txt"
    # shellcheck source=lib/repos.sh
    . "$DOTFILES/lib/repos.sh"
    list=$(_repos_list)
    assert_eq 3 "$(wc -l <<<"$list" | tr -d ' ')" "repos"
    while read -r path url; do
        case $path in /* | "~"*) fail "path must be relative to ~: $path" ;; esac
        case $url in git@github.com:*.git | https://*) ;; *) fail "odd url for $path: $url" ;; esac
    done <<<"$list"
}

# The checks need a real git: put it in front of the stub
real_git() {
    mkdir -p "$FAKE/bin"
    ln -sf /usr/bin/git "$FAKE/bin/git"
    export PATH="$FAKE/bin:$PATH" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
        GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
}

# pushed_repo <dir>: a clone of a bare remote, one commit, pushed
pushed_repo() {
    git init -q --bare "$FAKE/remote-$(basename "$1").git"
    git clone -q "$FAKE/remote-$(basename "$1").git" "$1" 2>/dev/null
    git -C "$1" commit -q --allow-empty -m init
    git -C "$1" push -q origin HEAD 2>/dev/null
    git -C "$1" branch -q --set-upstream-to="origin/$(git -C "$1" branch --show-current)"
}

check_repos() {
    rc=0
    out=$(bootstrap --check --only repos 2>&1) || rc=$?
}

test_repo_check_clean_repo_is_quiet() {
    real_git
    pushed_repo "$HOME/Developer/clean"
    check_repos
    case "$out" in *"Developer/clean"*) fail "clean repo reported: $out" ;; esac
}

test_repo_check_reports_local_work() {
    real_git
    r="$HOME/Developer/projects/work"
    pushed_repo "$r"
    touch "$r/new.txt"                              # uncommitted
    git -C "$r" commit -q --allow-empty -m local    # unpushed
    git -C "$r" switch -q -c feature                # no upstream
    echo x >"$r/s.txt" && git -C "$r" stash -q -u   # stash
    check_repos
    assert_eq 1 "$rc" "return code"
    assert_contains "~/Developer/projects/work: branch feature has 1 commits on no remote" "$out"
    git -C "$r" switch -q - && git -C "$r" branch -q -D feature
    check_repos
    assert_contains "has 1 commits on no remote" "$out"
    assert_contains "~/Developer/projects/work: 1 stashes" "$out"
    git -C "$r" stash pop -q && rm "$r/s.txt"
    check_repos
    assert_contains "~/Developer/projects/work: 1 uncommitted changes" "$out"
}

test_repo_check_detached_head() {
    real_git
    r="$HOME/Developer/sub"
    pushed_repo "$r"
    git -C "$r" switch -q --detach
    check_repos
    case "$out" in *"detached"*) fail "pushed detached HEAD reported: $out" ;; esac
    git -C "$r" commit -q --allow-empty -m lost
    check_repos
    assert_contains "~/Developer/sub: detached HEAD not on any remote branch" "$out"
}

test_repo_check_skips_build_folders() {
    real_git
    pushed_repo "$HOME/Developer/app"
    git init -q "$HOME/Developer/app/target/vendored"
    check_repos
    case "$out" in *"target/vendored"*) fail "looked inside target/: $out" ;; esac
}

test_repo_check_not_in_apply_mode() {
    real_git
    pushed_repo "$HOME/Developer/w"
    touch "$HOME/Developer/w/new.txt"
    out=$(bootstrap --only repos 2>&1)
    case "$out" in *"uncommitted"*) fail "apply mode reported repo drift: $out" ;; esac
}

test_repo_check_pushed_branch_without_upstream_is_fine() {
    real_git
    r="$HOME/Developer/merged"
    pushed_repo "$r"
    git -C "$r" switch -q -c topic
    git -C "$r" commit -q --allow-empty -m topic
    git -C "$r" push -q origin topic 2>/dev/null   # pushed, but no upstream set
    check_repos
    case "$out" in *"Developer/merged"*) fail "pushed branch reported: $out" ;; esac
}

# A folder the Unison sync filled before the clone: the clone goes in, the
# synced files stay on top of it as changes, the old folder is kept
test_repos_adopts_folder_in_the_way() {
    real_git
    pushed_repo "$FAKE/seed"
    printf 'old\n' >"$FAKE/seed/notes.txt" && printf 'x\n' >"$FAKE/seed/only-in-git.txt"
    git -C "$FAKE/seed" add . && git -C "$FAKE/seed" commit -q -m files && git -C "$FAKE/seed" push -q 2>/dev/null
    echo "Developer/a $FAKE/remote-seed.git" >"$REPOS_FILE"
    mkdir -p "$HOME/Developer/a"
    printf 'new\n' >"$HOME/Developer/a/notes.txt"
    printf 'y\n' >"$HOME/Developer/a/untracked.txt"
    out=$(bootstrap --only repos 2>&1)
    a="$HOME/Developer/a"
    assert_file "$a/.git"
    assert_eq new "$(cat "$a/notes.txt")" "synced file kept"
    assert_file "$a/only-in-git.txt"
    assert_eq " M notes.txt|?? untracked.txt|" "$(git -C "$a" status --porcelain | tr '\n' '|')" "status"
    backup=$(ls -d "$HOME"/Developer/a.before-clone-*)
    assert_eq new "$(cat "$backup/notes.txt")" "backup"
    assert_no_file "$HOME/Developer/.a.clone"
    assert_contains "cloned ~/Developer/a over the files already there" "$out"
    assert_log_has "^launchctl bootout gui/[0-9]+/com.user.unison.sync$"
    assert_log_has "^launchctl bootstrap gui/[0-9]+ .*com.user.unison.sync.plist$"
}

test_repos_adopt_clone_failure_leaves_folder() {
    two_repos
    mkdir -p "$HOME/Developer/a" "$HOME/Developer/projects/b/.git"
    touch "$HOME/Developer/a/notes.txt"
    fake git git 128 "git@github.com: Permission denied (publickey)."
    rc=0
    out=$(bootstrap --only repos 2>&1) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "clone ~/Developer/a over the files already there (is Bitwarden unlocked?)" "$out"
    assert_file "$HOME/Developer/a/notes.txt"
    assert_no_file "$HOME/Developer/.a.clone"
    [ -z "$(ls -d "$HOME"/Developer/a.before-clone-* 2>/dev/null)" ] || fail "backup made on failure"
}
