tap "asmvik/formulae"
tap "felixkratz/formulae", "https://github.com/FelixKratz/homebrew-formulae"
tap "hashicorp/tap"
tap "jqydee/tap", trusted: true
tap "nikitabobko/tap"

# OS-independent implementation of the ACPI specification
brew "acpica"
# Official Amazon AWS command-line interface
brew "awscli"
# GNU compiler collection
brew "gcc"
# Package compiler and linker metadata toolkit
brew "pkgconf"
# Statistics utility to count lines of code
brew "cloc"
# Cross-platform make
brew "cmake"
# Utility to configure multi-display resolutions and arrangements
brew "displayplacer"
# GitHub command-line tool
brew "gh"
# GNU Privacy Guard (OpenPGP)
brew "gnupg"
# Graphical front-end for GCC's coverage testing tool (gcov)
brew "lcov"
# Next-gen compiler infrastructure
brew "llvm"
# Powerful, lightweight programming language
brew "lua"
# Package manager for the Lua programming language
brew "luarocks"
# Mac App Store command-line interface
brew "mas"
# Ambitious Vim-fork focused on extensibility and agility
brew "neovim"
# Open-source, cross-platform JavaScript runtime environment
brew "node"
# Open client for Cisco AnyConnect VPN
brew "openconnect"
# Open source computer vision library
brew "opencv"
# Python version management
brew "pyenv"
# Search tool like grep and The Silver Searcher
brew "ripgrep"
# Rust toolchain installer
brew "rustup"
# Static analysis and lint tool, for (ba)sh scripts
brew "shellcheck"
# Cross-shell prompt for astronauts
brew "starship"
# Organize software neatly under a single directory tree (e.g. /usr/local)
brew "stow"
# Change macOS audio source from the command-line
brew "switchaudio-osx"
# Terminal multiplexer
brew "tmux"
# Display directories as trees (with optional color/HTML output)
brew "tree"
# Markup-based typesetting system
brew "typst"
# File synchronization tool
brew "unison"
# Internet file retriever
brew "wget"
# Simple hotkey-daemon for macOS.
brew "asmvik/formulae/skhd", trusted: true
# A window border system for macOS
brew "felixkratz/formulae/borders", trusted: true
# Custom macOS statusbar with shell plugin, interaction and graph support
brew "felixkratz/formulae/sketchybar", trusted: true
# Terraform
brew "hashicorp/tap/terraform", trusted: true
# Task, time and workflow manager for the terminal
brew "jqydee/tap/udo"
# Stand alone ad blocker
cask "adguard"
# AeroSpace is an i3-like tiling window manager for macOS
cask "nikitabobko/tap/aerospace", trusted: true
# GPU-accelerated terminal emulator
cask "alacritty"
# Terminal interface for Antigravity agents
cask "antigravity-cli"
# Anthropic's official Claude AI desktop app
cask "claude"
# Terminal-based AI coding assistant
cask "claude-code"
# App to build and share containerised applications and microservices
cask "docker-desktop"
# Web browser
cask "firefox"
cask "font-sf-mono"
cask "font-sf-pro"
cask "font-source-sans-3"
# Web browser
cask "google-chrome"
# Java IDE by JetBrains
cask "intellij-idea"
# Menu bar manager
cask "jordanbaird-ice"
# Full TeX Live distribution with GUI applications
cask "mactex"
# Sandbox construction video game
cask "minecraft"
# VPN client for secure internet access and private browsing
cask "nordvpn"
# Control your tools with a few keystrokes
cask "raycast"
# Free Dj app to prepare and manage your music files
cask "rekordbox"
# PDF reader and note-taking application
cask "skim"
# PDF presentation tool
cask "slidepilot"
# File sharing network
cask "soulseek"
# Music streaming service
cask "spotify"
# Mesh VPN based on WireGuard
cask "tailscale-app"
# Remote access and connectivity software focused on security
cask "teamviewer"
# Tool to invert scroll direction for physical scroll wheels
cask "unnaturalscrollwheels"
# Native desktop client for WhatsApp
cask "whatsapp"
# this is a small window switcher for macOS, relying heavily on yabai
cask "jqydee/tap/window-switcher-9000", trusted: true
# Multiplayer code editor
cask "zed"
# Collect, organise, cite, and share research sources
cask "zotero"

cargo "cargo-binstall"
cargo "cargo-dist"
cargo "cargo-llvm-cov"
cargo "cargo-release"
cargo "git-cliff"
mas "Noir", id: 1592917505
mas "Xcode", id: 497799835

# Machine-local extras from Brewfile.local (gitignored, never committed).
# Add to it with: ./bootstrap.sh --save-local [name...]
local_brewfile = File.join(__dir__, "Brewfile.local")
instance_eval(File.read(local_brewfile), local_brewfile) if File.exist?(local_brewfile)
