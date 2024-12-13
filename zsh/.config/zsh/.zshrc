# debug zsh startup time
# SHELL: time ZSH_DEBUGRC=1 zsh -i -c exit
if [ -n "${ZSH_DEBUGRC+1}" ]; then
    zmodload zsh/zprof
fi

# match terminal
export BAT_THEME=gruvbox-dark

# aliases
alias gcc=gcc-14

# homebrew in path
eval $(/opt/homebrew/bin/brew shellenv)

# haskell in Path
export PATH=$PATH:/Users/mfischbach/Developer/utils/haskell/
[ -f "/Users/mfischbach/.ghcup/env" ] && . "/Users/mfischbach/.ghcup/env" # ghcup-env

# move annoying .zcompdump files into a better hidden directory
autoload -Uz compinit
compinit -d ~/.config/zsh/.zcompdump

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

# java
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# zsh auto suggestions (https://github.com/zsh-users/zsh-autosuggestions)
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh syntax highlighting (https://github.com/zsh-users/zsh-syntax-highlighting.git)
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# starship
eval "$(starship init zsh)"

# debug zsh startup time
if [ -n "${ZSH_DEBUGRC+1}" ]; then
    zprof
fi
