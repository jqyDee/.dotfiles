export SHELL_SESSIONS_DISABLE=1

# history settings
export HISTFILE="~/.config/zsh/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

if [[ $(uname) == "Darwin" ]]; then
    export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
fi

export PATH="/opt/bin:$PATH"

# .zshrc, etc. are located here
if [ -z "$INTELLIJ_ENVIRONMENT_READER" ]; then
    export ZDOTDIR=~/.config/zsh
fi
