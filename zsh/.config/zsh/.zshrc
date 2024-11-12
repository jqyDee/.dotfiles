if [[ ! -v TMUX && $TERM_PROGRAM != "vscode" ]]; then
	tmux_chooser && exit
fi

# match terminal
export BAT_THEME=gruvbox-dark

# aliases
alias gcc=gcc-14

# homebrew in path
eval $(/opt/homebrew/bin/brew shellenv)

# haskell in Path
export PATH=$PATH:/Users/mfischbach/Developer/utils/haskell/

# move annoying .zcompdump files into a better hidden directory
autoload -Uz compinit
compinit -d ~/.config/zsh/.zcompdump

# Path to your oh-my-zsh installation.
export ZSH="/Users/mfischbach/.oh-my-zsh"

# oh my zsh
ZSH_THEME="geoffgarside"

DISABLE_UNTRACKED_FILES_DIRTY="true"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

plugins=(
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# zsh-autosuggest config
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

source $ZSH/oh-my-zsh.sh

# history settings
export HISTFILE="/Users/mfischbach/.config/zsh/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# set monitor?!
set +m

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# ghc ?!
[ -f "/Users/mfischbach/.ghcup/env" ] && . "/Users/mfischbach/.ghcup/env" # ghcup-env
