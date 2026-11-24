# shellcheck shell=bash
# Step: sync (Unison between ~/Developer/cs-degree and iCloud's CS-Studies).

SYNC_ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
SYNC_REMOTE="$SYNC_ICLOUD/CS-Studies"
SYNC_PROFILE="$HOME/.unison/cs-sync.prf"
SYNC_PLIST="$HOME/Library/LaunchAgents/com.user.unison.sync.plist"
SYNC_AGENT=com.user.unison.sync
# What Finder's "Keep Downloaded" sets: iCloud never evicts the folder's files
SYNC_PIN='com.apple.fileprovider.pinned#PX'

_sync_pinned() { [ "$(xattr -p "$SYNC_PIN" "$SYNC_REMOTE" 2>/dev/null)" = 1 ]; }
_sync_loaded() { launchctl print "gui/$(id -u)/$SYNC_AGENT" >/dev/null 2>&1; }

step_sync() {
    if [ ! -d "$SYNC_ICLOUD" ]; then
        log_warn "iCloud Drive not found: sign in to iCloud and turn on iCloud Drive"
        note_followup "turn on iCloud Drive, then ./bootstrap.sh --only sync"
        return 1
    fi
    if ! command -v unison >/dev/null; then
        log_warn "unison is not installed (it comes from the Brewfile)"
        return 1
    fi

    if [ "$MODE" = check ]; then
        [ -d "$SYNC_REMOTE" ] || note_drift "missing in iCloud: CS-Studies"
        [ -d "$SYNC_REMOTE" ] && ! _sync_pinned && note_drift "CS-Studies in iCloud is not kept downloaded"
        [ -f "$SYNC_PROFILE" ] || note_drift "unison sync not installed ($SYNC_PROFILE missing)"
        _sync_loaded || note_drift "unison sync agent not loaded"
        return 0
    fi

    mkdir -p "$SYNC_REMOTE"
    if ! _sync_pinned; then
        xattr -w "$SYNC_PIN" 1 "$SYNC_REMOTE" || return 1
        note_change "CS-Studies in iCloud: keep downloaded"
    fi

    if [ ! -f "$SYNC_PROFILE" ]; then
        NO_LOAD=1 "$DOTFILES/scripts/install_copyonchange.sh" >/dev/null || return 1
        note_change "installed unison sync"
        # No archive yet, so unison can't tell edits from old copies: a fresh
        # clone only has what was committed, iCloud has the latest work. Take
        # iCloud's version of every file that differs.
        log_info "first sync, iCloud wins (downloads what isn't local yet, can take a while)"
        if unison cs-sync -batch -auto -prefer "$HOME/CS-Studies-iCloud" >/dev/null 2>&1; then
            note_change "first sync (iCloud wins)"
        else
            log_warn "first sync did not finish cleanly: see unison cs-sync -batch"
            note_followup "check the first sync: unison cs-sync -batch -auto"
        fi
    fi

    if ! _sync_loaded; then
        launchctl bootstrap "gui/$(id -u)" "$SYNC_PLIST" || return 1
        note_change "loaded unison sync agent"
    fi
}
