#!/usr/bin/env bash
# macOS settings. Sourced by bootstrap.sh (step "macos"), or run alone:
#
#   ~/.dotfiles/macos.sh           apply the settings below
#   ~/.dotfiles/macos.sh --check   only show what differs
#   ~/.dotfiles/macos.sh --record  change something in System Settings, get
#                                  the matching `setting` lines (reads only)
#
# A setting is only written when its current value differs. Dock and Finder
# are restarted once at the end, and only if one of their settings changed.

_MACOS_RESTART="" # apps to restart, space separated
_MACOS_LOGOUT=0   # a setting that only applies after logging out changed
_MACOS_SAFARI=0   # a Safari setting changed (applies when Safari restarts)
_MACOS_HOTKEYS=0  # a keyboard shortcut changed (applied by activateSettings)

# _macos_normalize <-type> <value>: compare bools as 1/0, floats as numbers
_macos_normalize() {
    case $1 in
    -bool) case $2 in true | yes | 1) echo 1 ;; *) echo 0 ;; esac ;;
    -float) printf '%g' "$2" 2>/dev/null || printf '%s' "$2" ;;
    *) printf '%s' "$2" ;;
    esac
}

_macos_mark() {
    case " $_MACOS_RESTART " in
    *" $1 "*) ;;
    *) _MACOS_RESTART="$_MACOS_RESTART $1" ;;
    esac
}

# _macos_set <defaults option...> -- <domain> <key> <-type> <value>: write a
# value with `defaults [option...]` if it differs. Shared by setting and
# setting_host.
_macos_set() {
    local opts=()
    while [ "$1" != -- ]; do
        opts+=("$1")
        shift
    done
    shift
    local domain=$1 key=$2 type=$3 value=$4 current want label
    label="$domain $key"
    [ ${#opts[@]} -eq 0 ] || label="$domain (${opts[*]}) $key"
    want=$(_macos_normalize "$type" "$value")
    if current=$(defaults ${opts[@]+"${opts[@]}"} read "$domain" "$key" 2>/dev/null); then
        current=$(_macos_normalize "$type" "$current")
    else
        current="(unset)"
    fi
    [ "$current" = "$want" ] && return 0

    if [ "$MODE" = check ]; then
        note_drift "$label: $current → $value"
        return 0
    fi
    defaults ${opts[@]+"${opts[@]}"} write "$domain" "$key" "$type" "$value"
    note_change "$label = $value"
    case $domain in
    com.apple.dock | com.apple.spaces | com.apple.WindowManager) _macos_mark Dock ;;
    com.apple.finder) _macos_mark Finder ;;
    com.apple.menuextra.clock | com.apple.controlcenter) _macos_mark ControlCenter ;;
    NSGlobalDomain | com.apple.AppleMultitouchTrackpad | com.apple.HIToolbox) _MACOS_LOGOUT=1 ;;
    com.apple.Safari) _MACOS_SAFARI=1 ;;
    esac
}

# setting <domain> <key> <-bool|-int|-float|-string> <value>
setting() {
    _macos_set -- "$@"
}

# setting_host <domain> <key> <-type> <value>: like `setting`, for settings
# macOS keeps per Mac (~/Library/Preferences/ByHost, `defaults -currentHost`),
# such as which Control Center modules show in the menu bar
setting_host() {
    _macos_set -currentHost -- "$@"
}

# _macos_plist_xml: stdin (XML or the format `defaults read` prints) as XML
# with sorted keys. Only for strings: `defaults read` prints numbers and bools
# the same way, so they would come back as strings.
_macos_plist_xml() {
    plutil -convert xml1 -o - - 2>/dev/null
}

# setting_plist <domain> <key> <xml>: like `setting`, for a dictionary or an
# array of strings, written as one line of plist XML (`<dict>…</dict>`)
setting_plist() {
    local domain=$1 key=$2 value=$3 current want
    want=$(printf '%s' "$value" | _macos_plist_xml)
    current=$(defaults read "$domain" "$key" 2>/dev/null | _macos_plist_xml) || current=""
    [ "$current" = "$want" ] && return 0

    if [ "$MODE" = check ]; then
        note_drift "$domain $key: $([ -n "$current" ] && echo differs || echo "(unset)")"
        return 0
    fi
    defaults write "$domain" "$key" "$value"
    note_change "$domain $key"
    case $domain in
    com.apple.Safari) _MACOS_SAFARI=1 ;;
    esac
}

# setting_hotkey <id> <on|off> <char> <keycode> <modifiers>: one system
# keyboard shortcut (System Settings → Keyboard → Keyboard Shortcuts), an
# entry of com.apple.symbolichotkeys AppleSymbolicHotKeys. Only that entry is
# compared and written, the others stay as they are. char/keycode/modifiers
# are the key, as macOS stores it (modifiers: 131072 shift, 262144 control,
# 524288 option, 1048576 command, added up).
setting_hotkey() {
    local id=$1 enabled=false current want
    [ "$2" = on ] && enabled=true
    want="<dict><key>enabled</key><$enabled/><key>value</key><dict><key>parameters</key><array><integer>$3</integer><integer>$4</integer><integer>$5</integer></array><key>type</key><string>standard</string></dict></dict>"
    current=$(defaults export com.apple.symbolichotkeys - 2>/dev/null |
        plutil -extract "AppleSymbolicHotKeys.$id" xml1 -o - - 2>/dev/null) || current=""
    [ "$current" = "$(printf '%s' "$want" | _macos_plist_xml)" ] && return 0

    if [ "$MODE" = check ]; then
        note_drift "keyboard shortcut $id: $([ -n "$current" ] && echo differs || echo "(unset)") → $2"
        return 0
    fi
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$id" "$want"
    note_change "keyboard shortcut $id = $2"
    _MACOS_HOTKEYS=1
}

# _macos_strings <string...>: a plist XML array of strings
_macos_strings() {
    printf '<array>'
    [ $# -eq 0 ] || printf '<string>%s</string>' "$@"
    printf '</array>'
}

# Safari keeps its settings in its sandbox container. Without Full Disk
# Access `defaults` can't see them: reads come back unset and writes land in
# the wrong file, so skip them instead.
_macos_safari() {
    if ! ls "$HOME/Library/Containers/com.apple.Safari/Data/Library/Preferences" >/dev/null 2>&1; then
        log_warn "Safari settings skipped: no access to Safari's container"
        note_followup "open Safari once, give your terminal Full Disk Access (System Settings → Privacy & Security), restart it, then run ./bootstrap.sh --only macos"
        return 0
    fi
    setting com.apple.Safari IncludeDevelopMenu -bool true
    setting com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    setting com.apple.Safari WebKitPreferences.developerExtrasEnabled -bool true
    setting com.apple.Safari AutoOpenSafeDownloads -bool false
    setting com.apple.Safari ShowStandaloneTabBar -bool false # compact tab layout
    setting com.apple.Safari EnableNarrowTabs -bool true
    setting com.apple.Safari ShowFullURLInSmartSearchField -bool false
    setting com.apple.Safari ShowOverlayStatusBar -bool false
    setting com.apple.Safari ShowBackgroundImageInFavorites -bool false
    setting com.apple.Safari PrivateBrowsingRequiresAuthentication -bool true
    setting com.apple.Safari HomePage -string "http://localhost:8765/"
    setting com.apple.Safari NewWindowBehavior -int 0 # new windows: homepage
    setting com.apple.Safari NewTabBehavior -int 4    # new tabs: Start Page

    # toolbar layout, normal and private windows. Extension buttons are named
    # "<bundle id> (<team id>) <item>" and only show once the extension is
    # installed and turned on (AdGuard, Noir and Zotero are in the Brewfile).
    # The -v4.6/-v1 suffix is Safari's toolbar version: a Safari update can
    # move to a new key and ignore these.
    local adguard="com.adguard.safari.AdGuard.Extension (TC3Q7MAJXF) Button"
    local adguard_assistant="com.adguard.mac.adguard.safari-assistant (TC3Q7MAJXF) Button"
    local noir="nl.jeffreykuiken.NoirApp.mac.Mac-Extension (X23AVVY2HZ) NoirPopup"
    local zotero="org.zotero.zotero.SafariExtension (8LAYR367YV) Button"
    local zotero_web="WebExtension-org.zotero.zotero.SafariWebExtension (8LAYR367YV)"
    setting_plist com.apple.Safari "ExtensionsToolbarConfiguration BrowserToolbarIdentifier-v4.6" \
        "<dict><key>OrderedToolbarItemIdentifiers</key>$(_macos_strings \
            CombinedSidebarTabGroupToolbarIdentifier SidebarSeparatorToolbarItemIdentifier \
            BackForwardToolbarIdentifier "$adguard" "$adguard_assistant" "$noir" "$zotero" \
            "$zotero_web" UnifiedTabBarToolbarIdentifier ShareToolbarIdentifier \
            NewTabToolbarIdentifier TabPickerToolbarIdentifier)<key>UserRemovedToolbarItemIdentifiers</key>$(_macos_strings \
            "$adguard")</dict>"
    setting_plist com.apple.Safari "ExtensionsToolbarConfiguration PrivateBrowsingCompactTabBarBrowserToolbarIdentifier-v1" \
        "<dict><key>OrderedToolbarItemIdentifiers</key>$(_macos_strings \
            CombinedSidebarTabGroupToolbarIdentifier SidebarSeparatorToolbarItemIdentifier \
            BackForwardToolbarIdentifier "$noir" "$adguard" UnifiedTabBarToolbarIdentifier \
            ShareToolbarIdentifier NewTabToolbarIdentifier TabPickerToolbarIdentifier)</dict>"
}

step_macos() {
    _MACOS_RESTART=""
    _MACOS_LOGOUT=0
    _MACOS_SAFARI=0
    _MACOS_HOTKEYS=0

    # Dock
    setting com.apple.dock autohide -bool true
    setting com.apple.dock autohide-time-modifier -float 0.2
    setting com.apple.dock tilesize -int 52
    setting com.apple.dock show-recents -bool false
    setting com.apple.dock mru-spaces -bool false # don't reorder Spaces
    setting com.apple.dock mineffect -string scale

    # Finder
    setting com.apple.finder ShowPathbar -bool true
    setting com.apple.finder ShowStatusBar -bool true
    setting com.apple.finder FXPreferredViewStyle -string Nlsv  # list view
    setting com.apple.finder FXDefaultSearchScope -string SCcf # search current folder
    setting com.apple.finder FXPreferredGroupBy -string "Date Added"
    setting com.apple.finder NewWindowTarget -string PfLo # new windows: the folder below
    setting com.apple.finder NewWindowTargetPath -string "file://$HOME/Downloads/"
    setting com.apple.finder FinderSpawnTab -bool false                 # open folders in windows, not tabs
    setting com.apple.finder ShowRecentTags -bool false                 # no Recent Tags in the sidebar
    setting com.apple.finder FXEnableExtensionChangeWarning -bool false # no warning on extension change
    setting NSGlobalDomain AppleShowAllExtensions -bool true

    # keyboard, text, appearance
    setting NSGlobalDomain KeyRepeat -int 1
    setting NSGlobalDomain InitialKeyRepeat -int 12
    setting NSGlobalDomain ApplePressAndHoldEnabled -bool false
    setting NSGlobalDomain AppleInterfaceStyle -string Dark
    setting NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    setting NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    setting NSGlobalDomain com.apple.swipescrolldirection -bool true # macOS default
    setting NSGlobalDomain AppleReduceDesktopTinting -bool true      # no wallpaper tint in windows
    setting NSGlobalDomain AppleWindowTabbingMode -string manual     # open documents as windows, not tabs
    setting NSGlobalDomain com.apple.keyboard.fnState -bool true     # F1-F12 as standard function keys
    setting com.apple.HIToolbox AppleFnUsageType -int 0              # fn/globe key does nothing
    setting NSGlobalDomain NSCloseAlwaysConfirmsChanges -bool true   # ask to keep changes when closing documents
    setting NSGlobalDomain NSGlassTintAmount -float 0.5333243012428284 # Liquid Glass tint (slider)

    # keyboard shortcuts
    setting_hotkey 64 off 32 49 1048576 # Spotlight (cmd-space): off

    # Spotlight, Siri, iPhone
    setting_plist com.apple.Spotlight EnabledPreferenceRules "$(_macos_strings Custom.relatedContents)" # no related content
    setting com.apple.assistant.support "Search Queries Data Sharing Status" -int 2 # don't help improve Search
    setting com.apple.chronod remoteWidgetsEnabled -bool false # no iPhone widgets

    # menu bar (hidden for sketchybar, still used by Control Center).
    # macOS 26+ reads "Automatically hide and show the menu bar" from
    # AutoHideMenuBarOption (0 always, 1 on desktop only, 2 in full screen
    # only, 3 never); older versions and AppKit apps read _HIHideMenuBar.
    # Keep both in step, or some apps hide the bar and others don't.
    setting NSGlobalDomain _HIHideMenuBar -bool true
    setting com.apple.controlcenter AutoHideMenuBarOption -int 0
    setting NSGlobalDomain SLSMenuBarUseBlurredAppearance -bool true # dark menu bar background, not transparent
    setting com.apple.menuextra.clock ShowSeconds -bool true
    setting com.apple.TextInputMenu visible -bool false # no input source menu
    # which Control Center items show, and their order (pixels from the right)
    setting com.apple.controlcenter "NSStatusItem Visible Battery" -bool true
    setting com.apple.controlcenter "NSStatusItem Visible BentoBox" -bool true
    setting com.apple.controlcenter "NSStatusItem Visible Clock" -bool true
    setting com.apple.controlcenter "NSStatusItem Visible Sound" -bool true
    setting com.apple.controlcenter "NSStatusItem Visible WiFi" -bool true
    setting com.apple.controlcenter "NSStatusItem Visible NowPlaying" -bool false
    setting com.apple.controlcenter "NSStatusItem Visible ScreenMirroring" -bool false
    setting com.apple.controlcenter "NSStatusItem Visible AudioVideoModule" -bool false
    setting com.apple.controlcenter "NSStatusItem Visible Shortcuts" -bool false
    setting com.apple.controlcenter "NSStatusItem Preferred Position BentoBox" -float 190
    setting com.apple.controlcenter "NSStatusItem Preferred Position Battery" -float 224
    setting com.apple.controlcenter "NSStatusItem Preferred Position NowPlaying" -float 270
    setting com.apple.controlcenter "NSStatusItem Preferred Position WiFi" -float 297
    setting com.apple.controlcenter "NSStatusItem Preferred Position Sound" -float 335
    setting com.apple.controlcenter "NSStatusItem Preferred Position ScreenMirroring" -float 341
    setting bobko.aerospace "NSStatusItem Preferred Position Item-0" -float 517
    # the same choices as System Settings → Menu Bar writes them, per Mac:
    # 18 always show, 8 don't show
    setting_host com.apple.controlcenter Sound -int 18     # volume and output device
    setting_host com.apple.controlcenter FocusModes -int 8 # no Focus item
    setting_host com.apple.controlcenter NowPlaying -int 8
    setting_host com.apple.controlcenter ScreenMirroring -int 8
    setting_host com.apple.controlcenter Timer -int 8
    setting_host com.apple.controlcenter Spotlight -int 8
    setting_host com.apple.controlcenter BatteryShowPercentage -bool true
    setting_host com.apple.controlcenter BatteryShowEnergyMode -int 0 # Energy Mode: not shown
    setting com.apple.controlcenter RemoteLiveActivitiesEnabled -bool false # no iPhone Live Activities

    # trackpad and mouse
    setting com.apple.AppleMultitouchTrackpad Clicking -bool true # tap to click
    setting NSGlobalDomain com.apple.mouse.scaling -float 1.5     # mouse tracking speed

    # desktop and Spaces
    setting com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
    setting com.apple.WindowManager GloballyEnabled -bool false # Stage Manager, macOS default
    setting com.apple.spaces spans-displays -bool false         # macOS default
    setting com.apple.WindowManager HideDesktop -bool true      # no desktop icons
    setting com.apple.WindowManager StandardHideWidgets -bool true
    setting com.apple.WindowManager StageManagerHideWidgets -bool true
    setting com.apple.WindowManager AppWindowGroupingBehavior -int 1
    setting com.apple.WindowManager AutoHide -bool true
    setting com.apple.WindowManager EnableTiledWindowMargins -bool false # no gaps between tiled windows

    _macos_safari

    [ "$MODE" = apply ] || return 0
    local app
    for app in $_MACOS_RESTART; do
        killall "$app" 2>/dev/null || true
    done
    if [ "$_MACOS_LOGOUT" -eq 1 ]; then
        note_followup "log out and back in for keyboard/trackpad/menu bar settings"
    fi
    if [ "$_MACOS_HOTKEYS" -eq 1 ]; then
        /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u ||
            note_followup "log out and back in for the keyboard shortcuts"
    fi
    # not killed like Dock/Finder: that would close the open tabs
    if [ "$_MACOS_SAFARI" -eq 1 ]; then
        note_followup "restart Safari for its new settings"
    fi
}

# _macos_snapshot <dir>: export every defaults domain into <dir>/<domain>.plist,
# and the per-Mac ones (`defaults -currentHost`) into <dir>/host/
_macos_snapshot() {
    local d
    mkdir -p "$1/host"
    { echo NSGlobalDomain && defaults domains | tr ',' '\n'; } | sed 's/^ *//;/^$/d' |
        while IFS= read -r d; do
            defaults export "$d" "$1/$d.plist" 2>/dev/null || true
        done
    { echo NSGlobalDomain && defaults -currentHost domains | tr ',' '\n'; } | sed 's/^ *//;/^$/d' |
        while IFS= read -r d; do
            defaults -currentHost export "$d" "$1/host/$d.plist" 2>/dev/null || true
        done
}

# macos_record: print the settings that change while you wait at the prompt
macos_record() {
    local tmp rc=0
    tmp=$(mktemp -d)
    _macos_snapshot "$tmp/before"
    printf 'Change the settings now, then press Enter. ' >&2
    read -r _ || true
    _macos_snapshot "$tmp/after"
    python3 "$_MACOS_DIR/lib/defaults_diff.py" "$tmp/before" "$tmp/after" "$_MACOS_DIR/macos.sh" || rc=$?
    rm -rf "$tmp"
    return "$rc"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    set -euo pipefail
    _MACOS_DIR=$(cd "$(dirname "$0")" && pwd)
    # shellcheck source=lib/common.sh
    . "$_MACOS_DIR/lib/common.sh"
    case ${1:-} in
    --check) MODE=check ;;
    --record)
        macos_record
        exit
        ;;
    "") ;;
    *)
        echo "usage: $0 [--check | --record]" >&2
        exit 64
        ;;
    esac
    log_step macos
    step_macos
    print_summary
fi
