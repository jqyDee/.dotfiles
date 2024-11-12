export SHELL_SESSIONS_DISABLE=1

# .zshrc, etc. are located here
if [ -z "$INTELLIJ_ENVIRONMENT_READER" ]; then
    export ZDOTDIR=~/.config/zsh
fi
