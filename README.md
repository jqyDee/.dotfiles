# Dotfiles of jqyDee
macOS (Apple Silicon) dotfiles, managed with [GNU stow](https://www.gnu.org/software/stow/).
Every top-level folder (except `scripts/`) is a stow package that mirrors `$HOME`.

## Packages
| Package | Links to | What |
|---|---|---|
| `alacritty` | `~/.config/alacritty` | terminal (Gruvbox Material) |
| `borders` | `~/.config/borders` | JankyBorders window borders |
| `gh` | `~/.config/gh` | GitHub CLI config (token lives in the keychain) |
| `git` | `~/.gitconfig`, `~/.config/git/ignore` | identity, SSH commit signing, global ignore |
| `ideavim` | `~/.ideavimrc` | IdeaVim for JetBrains IDEs |
| `nvim` | `~/.config/nvim` | Neovim (lazy.nvim) |
| `sketchybar` | `~/.config/sketchybar` | status bar (Lua config via SbarLua) |
| `skhd` | `~/.config/skhd` | hotkeys |
| `starship` | `~/.config/starship.toml` | prompt |
| `tmux` | `~/.tmux.conf` | tmux with a hand-rolled gruvbox status line |
| `udo` | `~/.config/udo-keyboard` | feeds `udo status` to the Corne keyboard display |
| `yabai` | `~/.config/yabai` | tiling window manager |
| `zed` | `~/.config/zed` | Zed editor |
| `zsh` | `~/.zshenv`, `~/.config/zsh` | zsh (`ZDOTDIR` is set to `~/.config/zsh`) |

Not a package:
- `bootstrap.sh`, `macos.sh`, `lib/`: the setup scripts (below)
- `Brewfile`: everything installed through Homebrew, the App Store (`mas`), cargo and npm
- `scripts/`: installer for the Unison iCloud sync (`install_copyonchange.sh` / `uninstall_copyonchange.sh`)
- `tests/`: tests for the setup scripts (`bash tests/run.sh`); they run against fakes and never touch the machine

## Installation
```
git clone https://github.com/jqyDee/.dotfiles.git ~/.dotfiles
~/.dotfiles/bootstrap.sh
```
On a fresh Mac `git` itself triggers the Xcode command line tools installer; let it finish, then run the two lines again.

`bootstrap.sh` is safe to re-run: every step skips work that is already done.
- `./bootstrap.sh --check` changes nothing and lists where the Mac differs from the repo: missing or extra packages, missing links, settings with other values, missing extras. Run this first on a Mac that is already set up.
- `./bootstrap.sh --only <step>` runs one step: `xcode brew signin bundle stow macos extras services`.
- `./macos.sh [--check]` applies (or checks) only the macOS settings.

Exit codes: `0` ok, `1` drift or a failed step, `2` stow conflict, `64` wrong usage.

## What bootstrap does
1. Installs the Xcode command line tools and Homebrew if they are missing.
2. First run only: waits until you have signed in to the App Store and iCloud (needed for `mas` and the Unison sync).
3. `brew bundle` with the Brewfile: installs what is missing, never upgrades (run `brew upgrade` yourself). In `--check` mode it also lists installed packages that are not in the Brewfile; it never uninstalls anything.
4. Links every stow package. If a real file is in the way it stops before linking anything and prints the paths: move those files away and run it again. It never uses `--adopt`.
5. Applies the settings in `macos.sh`. Only values that differ are written; Dock and Finder restart only if one of their settings changed. Keyboard, trackpad and menu bar settings need a log out.
6. Extras: zsh plugins (`~/.zsh`), tpm (`~/.tmux/plugins/tpm`, then `prefix + I` in tmux), SbarLua and the sketchybar app font, the typst templates repo (`@local/templates`, needs a GitHub SSH key; skipped with a note otherwise), the udo-keyboard LaunchAgent.
7. Starts the sketchybar, borders and skhd services.

The sketchybar event providers in `helpers/` are compiled on every start (`helpers/init.lua` runs `make`).

## Manual steps
### Permissions
yabai, skhd and sketchybar ask for Accessibility / Screen Recording access when they first start. Grant it in System Settings.

### yabai
Not in the Brewfile: installed as a pre-built binary into `/usr/local/bin`, following the [yabai wiki](https://github.com/koekeishiya/yabai/wiki).
`yabairc` loads the scripting addition (`sudo yabai --load-sa`), which needs SIP partially disabled and a sudoers entry in `/private/etc/sudoers.d/yabai` (see the wiki). Then:
```
yabai --start-service
```
(To be replaced by AeroSpace.)

### Unison sync
After signing in to iCloud: `~/.dotfiles/scripts/install_copyonchange.sh`.

## Not managed
- Cemu and WiiUDownloader: no Homebrew casks, download them by hand.
- Microsoft Office: installed outside the Brewfile.

## Not tracked
- udo data (`~/.config/udo`: `.udo.toml`, `view.toml`, `udo.db*`). The run scripts and templates follow once udo's data dir is split from its config.
- Raycast (`~/.config/raycast`): use Raycast's own settings export.
- Zed `prompts/` and `conversations/`, shell history, completion caches (see `.gitignore`).
