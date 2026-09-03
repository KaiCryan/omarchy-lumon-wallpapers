#!/usr/bin/env bash
# Lumon "personnel file" wallpaper for one Severance character.
#   make-character-wallpaper.sh <portrait.png> <out.jpg> "<name>" "<role>" "<dept>" "<quote>" [sketch]
# 3840x2160.  A centred ASCII line portrait (photo -> colour-dodge sketch ->
# glyphs) over the navy ground, sized to fill the frame, with the LUMON wordmark
# up top.  (name / role / dept / quote are accepted but not drawn -- the desktop
# has its own rotating quote overlay, so a second one baked in here read as two.)
#
# [sketch] = "<blur>,<blackpt>,<whitept>"  (default "6,0%,58%")
set -euo pipefail

PORTRAIT=$1 OUT=$2 NAME=$3 ROLE=$4 DEPT=$5 QUOTE=$6
SKETCH=${7:-6,0%,58%}
IFS=, read -r SK_BLUR SK_BLACK SK_WHITE <<< "$SKETCH"
W=3840 H=2160
# resolve fonts through fontconfig so this works on any machine
_ff() { fc-match -f '%{file}' "$1" 2>/dev/null; }
MICHROMA=$(_ff 'Michroma'); [[ -f $MICHROMA ]] || MICHROMA=$(_ff 'sans-serif')
PLEX=$(_ff 'IBM Plex Sans');   [[ -f $PLEX ]]     || PLEX=$(_ff 'sans-serif')
MONO=$(_ff 'BlexMono Nerd Font Mono'); [[ -f $MONO ]] || MONO=$(_ff 'monospace')
RENDER="$(dirname "$0")/_portrait.py"
COLS=150
PORTH=1830     # rendered height of the glyph portrait (fills most of the frame)
PORTY=220      # its top edge (gravity north)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# 1. photo -> pencil-sketch line drawing -> ASCII text
magick "$PORTRAIT" -colorspace Gray -auto-level \
       \( +clone -negate -blur 0x"$SK_BLUR" \) -compose colordodge -composite \
       -negate -level "${SK_BLACK},${SK_WHITE}" "$TMP/sketch.png"
python3 "$RENDER" "$TMP/sketch.png" --cols "$COLS" --mode mono > "$TMP/art.txt"

# 2. ASCII -> bright glyph image (transparent) with a faint glow, sized + softly
#    faded at top/bottom so it melts into the ground
magick -background none -fill '#dcedf7' -font "$MONO" -pointsize 24 -interline-spacing -4 \
       label:@"$TMP/art.txt" \
       \( +clone -background '#4f96c6' -shadow 80x5+0+0 \) +swap \
       -background none -layers merge +repage \
       -resize x${PORTH} "$TMP/glyph.png"
GW=$(magick identify -format '%w' "$TMP/glyph.png")
magick "$TMP/glyph.png" \
   \( -size ${GW}x${PORTH} gradient:black-white \( +clone -flip \) \
      -compose multiply -composite -auto-level -level 0%,42% -alpha copy \) \
   -compose Dst_In -composite "$TMP/glyph_faded.png"

# 3. ground: plain vertical gradient, portrait composited dead centre (x)
magick -size ${W}x${H} gradient:'#0c1622'-'#16283a' \
  "$TMP/glyph_faded.png" -gravity north -geometry +0+${PORTY} -compose over -composite \
  "$TMP/base.png"

# 4. LUMON wordmark (top, centred)
magick "$TMP/base.png" \
  \( -background none -fill '#8fc9e6' -font "$MICHROMA" -pointsize 30 label:'L   U   M   O   N' \) \
     -gravity north -geometry +0+120 -compose over -composite \
  -quality 92 "$OUT"

echo "wrote $OUT"
