#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

FIREFOX_APP="${FIREFOX_APP:-/Applications/Firefox.app}"
FX_AUTOCONFIG_REF="${FX_AUTOCONFIG_REF:-dfdab5684faffc112b76ccb1d8cab7f75da0102c}"
FX_AUTOCONFIG_URL="${FX_AUTOCONFIG_URL:-https://github.com/MrOtherGuy/fx-autoconfig/archive/$FX_AUTOCONFIG_REF.tar.gz}"

PROFILE="${PROFILE:-$(resolve_profile)}"
RESOURCES="$FIREFOX_APP/Contents/Resources"
MODULE_SOURCE="$SCRIPT_DIR/chrome/JS/random-newtab-wallpaper.sys.mjs"

[ -d "$RESOURCES" ] ||
  fail "Firefox resources directory not found at $RESOURCES (set FIREFOX_APP=... to override)"
[ -d "$PROFILE" ] || fail "Firefox profile not found at $PROFILE (set PROFILE=... to override)"
[ -f "$MODULE_SOURCE" ] || fail "module not found at $MODULE_SOURCE"

if [ -f "$RESOURCES/config.js" ] &&
  ! grep -q "userchromejs/content/boot.sys.mjs" "$RESOURCES/config.js"; then
  fail "refusing to overwrite existing autoconfig file $RESOURCES/config.js"
fi

if [ -f "$PROFILE/chrome/utils/boot.sys.mjs" ] &&
  ! grep -q "MrOtherGuy/fx-autoconfig" "$PROFILE/chrome/utils/boot.sys.mjs"; then
  fail "refusing to overwrite existing loader in $PROFILE/chrome/utils"
fi

TMPDIR_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/random-newtab-wallpaper.XXXXXX")"
trap 'rm -rf "$TMPDIR_ROOT"' EXIT

SOURCE="$TMPDIR_ROOT"
curl -fsSL "$FX_AUTOCONFIG_URL" | tar -xz -C "$SOURCE" --strip-components=1

[ -f "$SOURCE/program/config.js" ] ||
  fail "fx-autoconfig download is missing program/config.js"
[ -f "$SOURCE/profile/chrome/utils/boot.sys.mjs" ] ||
  fail "fx-autoconfig download is missing profile/chrome/utils/boot.sys.mjs"

info "Installing fx-autoconfig program files into $RESOURCES"

if [ -w "$RESOURCES" ]; then
  cp -R "$SOURCE/program/." "$RESOURCES/"
else
  info "Administrator access is required to write to $RESOURCES"
  sudo cp -R "$SOURCE/program/." "$RESOURCES/"
fi

info "Installing the module into $PROFILE/chrome/JS"

mkdir -p "$PROFILE/chrome/JS"
cp -R "$SOURCE/profile/chrome/utils/." "$PROFILE/chrome/utils/"
cp "$MODULE_SOURCE" "$PROFILE/chrome/JS/random-newtab-wallpaper.sys.mjs"

info ""
info "Installed random-newtab-wallpaper."
info "Firefox app: $FIREFOX_APP"
info "Profile:     $PROFILE"
info ""
info "Fully quit Firefox, then relaunch it."
info "If nothing changes, open about:support and click Clear startup-cache,"
info "then restart Firefox."
info "Re-run this script after Firefox updates, because updates replace the"
info "autoconfig files in the app bundle."
