#!/bin/bash

# zsh
rm -rf zsh
mkdir -p ./zsh/.config/zsh/
cp ~/.zshenv ./zsh/
cp ~/.zprofile ./zsh/
cp -r ~/.config/zsh/.start zsh/.config/zsh/
cp -r ~/.config/zsh/.zshrc zsh/.config/zsh/

# alacritty
rm -rf alacritty
mkdir -p ./alacritty/.config/
cp -r ~/.config/alacritty alacritty/.config

# gh
rm -rf gh
mkdir -p ./gh/.config/
cp -r ~/.config/gh gh/.config

# nvim
rm -rf nvim
mkdir -p ./nvim/.config/
cp -r ~/.config/nvim ./nvim/.config

# sketchybar
rm -rf sketchybar
mkdir -p ./sketchybar/.config/
cp -r ~/.config/sketchybar sketchybar/.config

# yabai
rm -rf yabai
mkdir -p ./yabai/.config/
cp -r ~/.config/yabai yabai/.config
