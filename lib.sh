#!/usr/bin/env bash

FIREFOX_PROFILES_DIR="${FIREFOX_PROFILES_DIR:-$HOME/Library/Application Support/Firefox}"
PROFILES_INI="${PROFILES_INI:-$FIREFOX_PROFILES_DIR/profiles.ini}"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '%s\n' "$*"
}

resolve_profile() {
  [ -r "$PROFILES_INI" ] ||
    fail "cannot read $PROFILES_INI. Open about:profiles in Firefox, copy the Root Directory of the profile in use, then run: PROFILE=\"/path/to/profile\" $0"

  # State for the section currently being read.
  local section="" path="" is_default=""
  # Path of the first usable profile, and of the first one flagged Default=1.
  local first="" default_path="" line

  # Called whenever a section ends, and once at EOF. It runs before the caller
  # resets the variables, so at that moment they still describe the section
  # that just ended: that is the only point where a profile is known complete.
  # It sees the caller's locals because bash functions are dynamically scoped.
  remember() {
    # Ignore anything that is not a [ProfileN] block with a Path.
    [[ "$section" =~ ^\[Profile[0-9]+\]$ && -n "$path" ]] || return 0
    # Keep the first usable profile, and the first one that says Default=1.
    [[ -z "$first" ]] && first="$path"
    [[ "$is_default" == 1 && -z "$default_path" ]] && default_path="$path"
    # A non-zero status here would trip "set -e" in the callers.
    return 0
  }

  # One line at a time: IFS= keeps leading spaces, -r keeps backslashes, and
  # the trailing test also reads a final line that has no newline.
  while IFS= read -r line || [[ -n "$line" ]]; do
    # profiles.ini may have been written with Windows line endings.
    line="${line%$'\r'}"
    case "$line" in
      # New section: save the previous one, then start collecting this one.
      \[*)       remember; section="$line"; path=""; is_default="" ;;
      Path=*)    path="${line#Path=}" ;;
      Default=*) is_default="${line#Default=}" ;;
    esac
  done < "$PROFILES_INI"
  # The last section has no following header to trigger it.
  remember

  # Prefer the default profile, otherwise the first one found.
  local profile="${default_path:-$first}"
  [ -n "$profile" ] || fail "could not find a profile in $PROFILES_INI"

  # Relative Path= entries are relative to the Firefox data directory.
  case "$profile" in
    /*) printf '%s\n' "$profile" ;;
    *) printf '%s\n' "$FIREFOX_PROFILES_DIR/$profile" ;;
  esac
}

remove_file() {
  local path="$1"

  { [ -f "$path" ] || [ -L "$path" ]; } || return 0

  rm -f "$path" 2>/dev/null || sudo rm -f "$path"

  info "Removed $path"
}
