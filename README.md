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
- `Brewfile`: everything installed through Homebrew, cargo and npm
- `scripts/`: installer for the Unison iCloud sync (`install_copyonchange.sh` / `uninstall_copyonchange.sh`)

## Installation
1. Install the Xcode command line tools and [Homebrew](https://brew.sh):
```
xcode-select --install
```
2. Clone the repo into `$HOME`:
```
git clone https://github.com/jqyDee/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```
3. Install the software:
```
brew bundle --file=~/.dotfiles/Brewfile
```
4. Link the packages. Name them explicitly; `stow */` would also link `scripts/` into `$HOME`.
```
stow alacritty borders gh git ideavim nvim sketchybar skhd starship tmux udo yabai zed zsh
```
If stow reports a conflict, a real file is already in the way. Move it away (or use `stow --adopt <pkg>` and check `git diff` afterwards).

## Manual steps
Things the Brewfile and stow do not cover.

### yabai
Not in the Brewfile: installed as a pre-built binary into `/usr/local/bin`, following the [yabai wiki](https://github.com/koekeishiya/yabai/wiki).
`yabairc` loads the scripting addition (`sudo yabai --load-sa`), which needs SIP partially disabled and a sudoers entry in `/private/etc/sudoers.d/yabai` (see the wiki). Then:
```
yabai --start-service
skhd --start-service
```

### sketchybar
The Lua config needs SbarLua and the app icon font:
```
git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && (cd /tmp/SbarLua && make install) && rm -rf /tmp/SbarLua
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/latest/download/sketchybar-app-font.ttf -o ~/Library/Fonts/sketchybar-app-font.ttf
brew services start sketchybar
brew services start borders
```
The CPU and network event providers in `helpers/` are compiled on every start (`helpers/init.lua` runs `make`, which needs the Xcode command line tools).

### zsh plugins
`.zshrc` sources these from `~/.zsh`:
```
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
```

### tmux plugins
```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
Then start tmux and press `prefix + I`.

### Typst templates
The udo typst template imports `@local/templates`, which lives in its own repo:
```
git clone git@github.com:jqyDee/typst-templates.git ~/Library/Application\ Support/typst/packages/local
```

### udo keyboard
```
~/.config/udo-keyboard/install.sh
```
Creates a venv in `~/.local/share/udo-keyboard` and installs the `local.corne.udo-status` LaunchAgent.

## Not tracked
- udo data (`~/.config/udo`: `.udo.toml`, `view.toml`, `udo.db*`). The run scripts and templates follow once udo's data dir is split from its config.
- Raycast (`~/.config/raycast`): use Raycast's own settings export.
- Zed `prompts/` and `conversations/`, shell history, completion caches (see `.gitignore`).
