# match terminal
export BAT_THEME=gruvbox-dark

# SDL showing in nvim
export CPATH=$(brew --prefix sdl2)/include/SDL2:$CPATH
export LIBRARY_PATH=$(brew --prefix sdl2)/lib:$LIBRARY_PATH

# aliases
alias gcc=gcc-14
alias valgrind='docker run -it -v $PWD:/tmp -w /tmp ubuntu'
alias sshuni='ssh -X -l csbb8241 zid-gpl.uibk.ac.at'

# homebrew in path
eval $(/opt/homebrew/bin/brew shellenv)

# haskell in Path
export PATH=$PATH:/Users/mfischbach/Developer/utils/haskell/
[ -f "/Users/mfischbach/.ghcup/env" ] && . "/Users/mfischbach/.ghcup/env"

# rust first in Path
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

# brew llvm in path
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

# java in path
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# gcc as c compiler
export CC=gcc

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

# zsh auto suggestions (https://github.com/zsh-users/zsh-autosuggestions)
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh syntax highlighting (https://github.com/zsh-users/zsh-syntax-highlighting.git)
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# "include" zsh functions
source ~/.config/zsh/.zsh_functions

# starship
eval "$(starship init zsh)"
