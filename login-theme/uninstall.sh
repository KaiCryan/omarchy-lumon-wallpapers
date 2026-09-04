#!/usr/bin/env bash
# Remove the Lumon login theme. Keeps your config and your audio file.
set -euo pipefail

MARK="lumon-login-theme"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"

say() { printf '  %s\n' "$*"; }

strip_block() {
  local file="$1" cp="$2"; [[ -f "$file" ]] || return 0
  local begin="$cp >>> $MARK >>>" end="$cp <<< $MARK <<<"
  local tmp; tmp="$(mktemp)"
  awk -v b="$begin" -v e="$end" '
    $0==b {skip=1; next}
    skip && $0==e {skip=0; blank=1; next}
    skip {next}
    blank && $0=="" {blank=0; next}
    {blank=0; print}
  ' "$file" > "$tmp"
  mv "$tmp" "$file"; say "cleaned block from $file"
}

"$BIN/lumon-login-theme" stop 2>/dev/null || true
# kill the unlock watcher (holds a flock on this file)
fuser -k "${XDG_RUNTIME_DIR:-/tmp}/lumon-login-theme-watch.lock" 2>/dev/null || true
[[ -L "$BIN/lumon-login-theme" || -f "$BIN/lumon-login-theme" ]] && { rm -f "$BIN/lumon-login-theme"; say "removed $BIN/lumon-login-theme"; }

strip_block "$CONFIG/hypr/autostart.lua" "--"
strip_block "$CONFIG/hypr/bindings.lua"  "--"

command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1 || true

echo
echo "Removed. Kept: ~/.config/omarchy/lumon-login-theme.conf and ~/.config/omarchy/lumon/ (your audio)."
