#!/usr/bin/env bash
# Rebuild the Severance character wallpapers (and the greeting-badge ASCII
# portraits, if the greeting is installed).
#
#   src/*.jpg        source headshots (Wikimedia, see SOURCES.md)
#   characters.tsv   id / src / crop / name / role / dept / quote / sketch
#
# Each headshot is run through a colour-dodge pencil sketch, then to glyphs.
#
# Env overrides:
#   OUT_WALLPAPERS   where the 3840x2160 wallpapers go   (default: ./wallpapers)
#   OUT_PORTRAITS    where the badge <id>.txt + roster.tsv go
#                    (default: the greeting's portraits dir if it exists, else skipped)
set -euo pipefail
cd "$(dirname "$0")"

RENDER="./_portrait.py"
OUT_WALLPAPERS="${OUT_WALLPAPERS:-./wallpapers}"
GREETING_PORTRAITS="$HOME/.config/omarchy/branding/lumon-anims/portraits"
OUT_PORTRAITS="${OUT_PORTRAITS:-}"
if [[ -z $OUT_PORTRAITS && -d $(dirname "$GREETING_PORTRAITS") ]]; then
  OUT_PORTRAITS="$GREETING_PORTRAITS"
fi

mkdir -p portraits "$OUT_WALLPAPERS"
[[ -n $OUT_PORTRAITS ]] && mkdir -p "$OUT_PORTRAITS"

# clean slate for anything this script owns
rm -f "$OUT_WALLPAPERS"/4[0-9]-*.jpg
[[ -n $OUT_PORTRAITS ]] && { rm -f "$OUT_PORTRAITS"/*.txt "$OUT_PORTRAITS"/*.ans; : > "$OUT_PORTRAITS/roster.tsv"; }

n=40
while IFS=$'\t' read -r id src crop name role dept quote sk; do
  [ "$id" = "id" ] && continue
  echo ":: $id"
  sk=${sk:-6,0%,58%}

  # 1. normalised crop + pencil-sketch line drawing
  magick "src/$src" -auto-orient -gravity north -crop "$crop" +repage \
    -resize 1000x1250^ -gravity north -extent 1000x1250 "portraits/$id.png"
  IFS=, read -r b bk wk <<< "$sk"
  magick "portraits/$id.png" -colorspace Gray -auto-level \
    \( +clone -negate -blur 0x"$b" \) -compose colordodge -composite \
    -negate -level "${bk},${wk}" "portraits/$id-sketch.png"

  # 2. greeting-badge ASCII portrait (skipped if the greeting isn't installed)
  if [[ -n $OUT_PORTRAITS ]]; then
    python3 "$RENDER" "portraits/$id-sketch.png" --cols 46 --mode mono > "$OUT_PORTRAITS/$id.txt"
    printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$name" "$role" "$dept" "$quote" >> "$OUT_PORTRAITS/roster.tsv"
  fi

  # 3. wallpaper
  bash make-character-wallpaper.sh "portraits/$id.png" "$OUT_WALLPAPERS/$n-$id.jpg" \
    "$name" "$role" "$dept" "$quote" "$sk"
  n=$((n + 1))
done < characters.tsv

echo
echo "wallpapers -> $OUT_WALLPAPERS"
[[ -n $OUT_PORTRAITS ]] && echo "badge portraits -> $OUT_PORTRAITS"
