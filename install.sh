#!/usr/bin/env bash
# Install the Lumon wallpapers into Omarchy and (optionally) the hourly cycler.
set -euo pipefail
cd "$(dirname "$0")"

THEME="${LUMON_THEME_SLUG:-lumon}"
BGDIR="$HOME/.config/omarchy/backgrounds/$THEME"
UNITS="$HOME/.config/systemd/user"

echo ":: copying wallpapers -> $BGDIR"
mkdir -p "$BGDIR"
cp wallpapers/*.jpg "$BGDIR/"
[[ -d quote ]] && cp quote/*.jpg "$BGDIR/" 2>/dev/null || true

# Pull backgrounds we don't want out of the cycle: the plain gradient that ships
# with the base lumon theme reads as an empty screen, and 05 is Omarchy-branded
# rather than Lumon. omarchy-theme-bg-next scans -maxdepth 1, so a subfolder hides them.
EXCLUDE=(02-gradient.jpg 05-opinions-equally.jpg)
for d in "$HOME/.local/state/omarchy/current/theme/backgrounds" \
         "$HOME/.config/omarchy/themes/$THEME/backgrounds"; do
  [[ -d $d ]] || continue
  for f in "${EXCLUDE[@]}"; do
    if [[ -f $d/$f ]]; then
      mkdir -p "$d/.excluded-from-cycle"
      mv "$d/$f" "$d/.excluded-from-cycle/"
      echo "   excluded $f from the cycle ($d)"
    fi
  done
done

echo ":: installing the hourly cycle timer -> $UNITS"
mkdir -p "$UNITS"
cp systemd/wallpaper-cycle.service systemd/wallpaper-cycle.timer "$UNITS/"
systemctl --user daemon-reload
if [[ ${1:-} == --no-cycle ]]; then
  echo "   (timer installed but not enabled; enable with: systemctl --user enable --now wallpaper-cycle.timer)"
else
  systemctl --user enable --now wallpaper-cycle.timer
  echo "   wallpaper now advances every hour"
fi

echo
echo "Done. Cycle now:  omarchy theme bg next"
echo "Regenerate the character set:  cd characters && ./build.sh"
