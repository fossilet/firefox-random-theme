#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

FIREFOX_APP="${FIREFOX_APP:-/Applications/Firefox.app}"
PROFILE="${PROFILE:-$(resolve_profile)}"
RESOURCES="$FIREFOX_APP/Contents/Resources"
CHROME_DIR="$PROFILE/chrome"

[ -d "$PROFILE" ] || fail "Firefox profile not found at $PROFILE (set PROFILE=... to override)"

remove_file "$CHROME_DIR/JS/random-newtab-wallpaper.sys.mjs"

if [ -f "$CHROME_DIR/utils/boot.sys.mjs" ] &&
  grep -q "MrOtherGuy/fx-autoconfig" "$CHROME_DIR/utils/boot.sys.mjs"; then
  for file in boot.sys.mjs fs.sys.mjs fs.jsm utils.sys.mjs uc_api.sys.mjs \
    module_loader.mjs chrome.manifest; do
    remove_file "$CHROME_DIR/utils/$file"
  done
fi
rmdir "$CHROME_DIR/JS" "$CHROME_DIR/utils" 2>/dev/null || true

if [ -f "$RESOURCES/config.js" ] &&
  grep -q "userchromejs/content/boot.sys.mjs" "$RESOURCES/config.js"; then
  for file in config.js defaults/pref/config-prefs.js defaults/pref/autoconfig.js; do
    remove_file "$RESOURCES/$file"
  done
  rmdir "$RESOURCES/defaults/pref" "$RESOURCES/defaults" 2>/dev/null || true
fi

info ""
info "Uninstalled random-newtab-wallpaper."
info "Profile: $PROFILE"
info ""
info "Fully quit Firefox, then relaunch it."
info "Open about:support and click Clear startup-cache, then restart Firefox."
info ""
info "To reset the New Tab background to Firefox's default, open about:config"
info "and reset these prefs, or use New Tab > Customize > Reset to default:"
info "  browser.newtabpage.activity-stream.newtabWallpapers.enabled"
info "  browser.newtabpage.activity-stream.newtabWallpapers.user.enabled"
info "  browser.newtabpage.activity-stream.newtabWallpapers.wallpaper"
