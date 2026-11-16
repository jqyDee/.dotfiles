# shellcheck shell=bash
# --save-local writes Brewfile.local, so these tests run a copy of the repo:
# the real repo never gets a Brewfile.local from a test run.

copy_repo() {
    COPY="$FAKE/repo"
    mkdir -p "$COPY"
    cp -R "$DOTFILES/bootstrap.sh" "$DOTFILES/macos.sh" "$DOTFILES/lib" "$COPY/"
    printf '%s\n' 'tap "jqydee/tap", trusted: true' '# Tree' 'brew "tree"' 'cask "zed"' >"$COPY/Brewfile"
}

save_local() { bash "$COPY/bootstrap.sh" --save-local "$@"; }

DUMP='tap "jqydee/tap"
# Display directories as trees
brew "tree"
# Blazing fast terminal file manager
brew "yazi"
# Command-line fuzzy finder
brew "fzf"
brew "foo/tap/baz"
cask "zed"
mas "Noir", id: 1592917505'

test_save_local_adds_unlisted() {
    copy_repo
    fake brew bundle-dump 0 "$DUMP"
    save_local >/dev/null
    local_file=$(cat "$COPY/Brewfile.local")
    assert_contains '# Blazing fast terminal file manager
brew "yazi"' "$local_file"
    assert_contains 'brew "foo/tap/baz"' "$local_file"
    assert_contains 'mas "Noir", id: 1592917505' "$local_file"
    case "$local_file" in *'"tree"'* | *'"zed"'* | *'tap "jqydee/tap"'*) fail "copied an entry the Brewfile already has: $local_file" ;; esac
    assert_eq 1 "$(grep -c '^# Machine-local packages' "$COPY/Brewfile.local")" "header"
}

test_save_local_only_named() {
    copy_repo
    fake brew bundle-dump 0 "$DUMP"
    save_local fzf baz >/dev/null
    local_file=$(cat "$COPY/Brewfile.local")
    assert_contains 'brew "fzf"' "$local_file"
    assert_contains 'brew "foo/tap/baz"' "$local_file" # short name matches a tap formula
    case "$local_file" in *yazi* | *Noir*) fail "added an entry without being asked: $local_file" ;; esac
}

test_save_local_skips_entries_already_local() {
    copy_repo
    fake brew bundle-dump 0 "$DUMP"
    save_local yazi >/dev/null
    save_local >/dev/null
    assert_eq 1 "$(grep -c '^brew "yazi"$' "$COPY/Brewfile.local")" "yazi entries"
    assert_eq 1 "$(grep -c '^# Machine-local packages' "$COPY/Brewfile.local")" "header"
}

test_save_local_unknown_name_fails() {
    copy_repo
    fake brew bundle-dump 0 "$DUMP"
    rc=0
    out=$(save_local nope 2>&1) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "nope" "$out"
}

test_save_local_leaves_brewfile_alone() {
    copy_repo
    before=$(cat "$COPY/Brewfile")
    fake brew bundle-dump 0 "$DUMP"
    save_local >/dev/null
    assert_eq "$before" "$(cat "$COPY/Brewfile")" "Brewfile"
    assert_log_lacks '^brew bundle (--file|cleanup|check)'
}

test_brewfile_includes_local() {
    grep -q 'Brewfile.local' "$DOTFILES/Brewfile" || fail "Brewfile doesn't load Brewfile.local"
    grep -qx 'Brewfile.local' "$DOTFILES/.gitignore" || fail "Brewfile.local not gitignored"
}
