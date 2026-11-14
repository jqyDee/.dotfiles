# shellcheck shell=bash

bootstrap() { bash "$DOTFILES/bootstrap.sh" "$@"; }

test_bundle_apply() {
    bootstrap --only bundle >/dev/null
    assert_log_has "^brew bundle --file=$DOTFILES/Brewfile$"
}

test_bundle_failure_continues() {
    fake brew bundle 1
    rc=0
    out=$(bootstrap 2>&1) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_log_has '^defaults ' # the macos step still ran
    assert_contains "Failed" "$out"
    assert_contains "App Store signed in?" "$out"
}

test_bundle_check_never_forces() {
    bootstrap --check --only bundle >/dev/null
    assert_log_has '^brew bundle check '
    assert_log_has '^brew bundle cleanup '
    assert_log_lacks '--force'
    assert_log_lacks '^brew bundle --file'
}

test_bundle_check_reports_drift() {
    fake brew bundle-check 1 "→ Cask claude needs to be installed or updated.
brew bundle can't satisfy your Brewfile's dependencies."
    fake brew bundle-cleanup 0 "Would uninstall formulae:
acpica
Would uninstall casks:
microsoft-office
Run \`brew bundle cleanup --force\` to make these changes."
    rc=0
    out=$(bootstrap --check --only bundle) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "missing: Cask claude" "$out"
    assert_contains "not in Brewfile: acpica" "$out"
    assert_contains "not in Brewfile: microsoft-office" "$out"
    case "$out" in *"not in Brewfile: Run"* | *"not in Brewfile: Would"*) fail "parsed a header as a package: $out" ;; esac
}

test_brewfile_parses() {
    assert_eq 2 "$(grep -c '^mas ' "$DOTFILES/Brewfile")" "mas entries"
    grep -q '^mas "Xcode", id: 497799835$' "$DOTFILES/Brewfile" || fail "Xcode entry"
    grep -q '^mas "Noir", id: 1592917505$' "$DOTFILES/Brewfile" || fail "Noir entry"
    for e in 'brew "mas"' 'cask "claude"' 'cask "minecraft"' 'cask "teamviewer"'; do
        grep -qx "$e" "$DOTFILES/Brewfile" || fail "missing $e"
    done
}

PKGS="alacritty borders gh git ideavim nvim sketchybar skhd starship tmux udo yabai zed zsh"

test_stow_conflict_aborts() {
    fake stow stow 1 "WARNING! stowing zsh would cause conflicts:
  * existing target is not owned by stow: .zshrc
All operations aborted."
    rc=0
    out=$(bootstrap 2>&1) || rc=$?
    assert_eq 2 "$rc" "return code"
    assert_eq 1 "$(grep -c '^stow ' "$STUB_LOG")" "stow calls"
    assert_log_has '^stow .*-n'
    assert_log_lacks '^defaults '
    assert_contains ".zshrc" "$out"
}

test_stow_uses_package_list() {
    fake stow stow 0 "LINK: .tmux.conf => .dotfiles/tmux/.tmux.conf"
    bootstrap --only stow >/dev/null
    assert_log_has "^stow .* $PKGS$"
    assert_log_lacks '^stow .*scripts'
    assert_log_lacks '^stow .*-R'
    assert_eq 2 "$(grep -c '^stow ' "$STUB_LOG")" "dry run + real run"
}

test_stow_nothing_to_link_skips_real_run() {
    fake stow stow 0 "WARNING: in simulation mode so not modifying filesystem."
    bootstrap --only stow >/dev/null
    assert_eq 1 "$(grep -c '^stow ' "$STUB_LOG")" "only the dry run"
}

test_stow_check_reports_missing_links() {
    fake stow stow 0 "LINK: .tmux.conf => .dotfiles/tmux/.tmux.conf
WARNING: in simulation mode so not modifying filesystem."
    rc=0
    out=$(bootstrap --check --only stow) || rc=$?
    assert_eq 1 "$rc" "return code"
    assert_contains "not linked: .tmux.conf" "$out"
    assert_eq 1 "$(grep -c '^stow ' "$STUB_LOG")" "only the dry run"
}

test_bundle_check_ignores_outdated() {
    # without --no-upgrade, brew counts every outdated package as missing
    bootstrap --check --only bundle >/dev/null
    assert_log_has '^brew bundle check .*--no-upgrade'
}
