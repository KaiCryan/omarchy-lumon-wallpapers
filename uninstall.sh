#!/usr/bin/env bash
# Remove the Lumon wallpapers and the hourly cycler.
set -euo pipefail
cd "$(dirname "$0")"

THEME="${LUMON_THEME_SLUG:-lumon}"
BGDIR="$HOME/.config/omarchy/backgrounds/$THEME"
UNITS="$HOME/.config/systemd/user"

systemctl --user disable --now wallpaper-cycle.timer 2>/dev/null || true
rm -f "$UNITS/wallpaper-cycle.service" "$UNITS/wallpaper-cycle.timer"
systemctl --user daemon-reload 2>/dev/null || true

for f in wallpapers/*.jpg quote/*.jpg; do
  [[ -e $f ]] && rm -f "$BGDIR/$(basename "$f")"
done

echo "Done. Pick a remaining wallpaper with:  omarchy theme bg next"
