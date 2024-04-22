#!/bin/bash

rm .zshenv
cp ~/.zshenv .

rm .zprofile
cp ~/.zprofile .

rm .tmux.conf
cp ~/.tmux.conf .

rm -r .config

mkdir -p .config/alacritty/toml
cp -a ~/.config/alacritty/toml/* .config/alacritty/toml/
cp ~/.config/alacritty/alacritty.toml .config/alacritty/

mkdir -p .config/zsh
cp ~/.config/zsh/.start .config/zsh
cp ~/.config/zsh/.zshrc .config/zsh

mkdir -p .config/nvim/lua/{plugins,user}
mkdir -p .config/nvim/after/plugin
cp -a ~/.config/nvim/lua/plugins/* .config/nvim/lua/plugins/
cp -a ~/.config/nvim/lua/user/* .config/nvim/lua/user/
cp -a ~/.config/nvim/after/plugin/* .config/nvim/after/plugin/
cp ~/.config/nvim/init.lua .config/nvim/
