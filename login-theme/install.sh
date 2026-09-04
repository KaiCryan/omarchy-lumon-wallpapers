#!/usr/bin/env bash
# Install the Lumon login theme: symlink the script, add the keybind + the
# lock-and-play autostart. Idempotent. Undo with ./uninstall.sh
#
# You still need to supply the audio yourself (it is copyrighted — see README):
#   lumon-login-theme set-audio ~/Music/severance-main-titles.mp3

set -euo pipefail
cd "$(dirname "$0")"

MARK="lumon-login-theme"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"

say() { printf '  %s\n' "$*"; }

inject_block() {   # FILE  COMMENT_PREFIX  CONTENT
  local file="$1" cp="$2" content="$3"
  local begin="$cp >>> $MARK >>>" end="$cp <<< $MARK <<<"
  mkdir -p "$(dirname "$file")"; touch "$file"
  local tmp; tmp="$(mktemp)"
  awk -v b="$begin" -v e="$end" '
    $0==b {skip=1; next}
    skip && $0==e {skip=0; blank=1; next}
    skip {next}
    blank && $0=="" {blank=0; next}
    {blank=0; print}
  ' "$file" > "$tmp"
  { cat "$tmp"; printf '\n%s\n%s\n%s\n' "$begin" "$content" "$end"; } > "$file"
  rm -f "$tmp"
}

echo ":: installing $MARK"

mkdir -p "$BIN"
ln -sfn "$PWD/bin/lumon-login-theme" "$BIN/lumon-login-theme"
say "bin/lumon-login-theme -> $BIN"

case ":$PATH:" in *":$BIN:"*) ;; *) say "NOTE: $BIN is not on PATH — add it." ;; esac

if [[ ! -f "$CONFIG/omarchy/lumon-login-theme.conf" ]]; then
  mkdir -p "$CONFIG/omarchy"
  cp config/lumon-login-theme.conf "$CONFIG/omarchy/lumon-login-theme.conf"
  say "config -> $CONFIG/omarchy/lumon-login-theme.conf (new)"
else
  say "config already present — left as-is"
fi

mkdir -p "$CONFIG/omarchy/lumon"

inject_block "$CONFIG/hypr/autostart.lua" "--" "$(cat hypr/autostart.snippet.lua)"
say "injected the lock-and-play autostart block"
# No keybind is injected: mpv exposes MPRIS on this system, so the bar media
# widget and the XF86AudioPlay key already pause/resume it. To add a hotkey,
# put this in ~/.config/hypr/bindings.lua (pick a free chord):
#   o.bind("SUPER + ALT + P", "Pause/resume login theme", "lumon-login-theme toggle")

if command -v hyprctl >/dev/null && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
  errs="$(hyprctl configerrors 2>/dev/null || true)"
  [[ -z "$errs" ]] && say "hyprctl reload: ok" || { echo "  configerrors:"; echo "$errs"; }
fi

echo
if [[ -z "$(cd "$CONFIG/omarchy/lumon" && ls 2>/dev/null)" ]]; then
  echo "Next: add your audio file —"
  echo "  lumon-login-theme set-audio /path/to/severance-main-titles.mp3"
fi
echo "Test now:  lumon-login-theme play    (pause from the bar media widget)"
echo "It will score the lock screen at your next login."
