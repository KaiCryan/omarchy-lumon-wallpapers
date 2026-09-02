#!/usr/bin/env bash
# Composite an eerie Severance quote onto a background, Lumon-placard style.
# Usage: make-quote-wallpaper.sh <in-image> <out.png> "<quote>" "<attribution>"
set -euo pipefail

IN="$1"; OUT="$2"; QUOTE="$3"; ATTR="${4:-}"

W=3840; H=2160
SANS="IBM Plex Sans"
MONO="$HOME/.local/share/fonts/BlexMonoNerdFont-Regular.ttf"
[[ -f "$MONO" ]] || MONO=$(fc-match -f '%{file}' "monospace")

INK="#e6eef3"
ACCENT="#8bc9eb"
SCRIM="#060d12"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# 1. cover-fit + a restrained cold grade so every still sits in the same world
magick "$IN" -resize "${W}x${H}^" -gravity center -extent "${W}x${H}" \
  -modulate 100,86,100 -fill "#16242d" -colorize 7% \
  "$TMP/bg.png"

# 2. soft bottom scrim for legibility
magick -size "${W}x1300" \
  gradient:'rgba(6,13,18,0)-rgba(6,13,18,0.88)' \
  "$TMP/scrim.png"
magick "$TMP/bg.png" "$TMP/scrim.png" -gravity south -composite "$TMP/base.png"

# 3. the quote, wrapped in a fixed column, bottom-left
magick -background none -fill "$INK" -family "$SANS" -weight 300 \
  -pointsize 110 -interline-spacing 16 \
  -size 2500x caption:"$QUOTE" -trim +repage \
  "$TMP/quote.png"
QH=$(magick identify -format '%h' "$TMP/quote.png")

MX=236                              # left text margin
ATTR_GAP=44
ATTR_H=0
ATTR_IMG=""
if [[ -n "$ATTR" ]]; then
  UP=$(printf '%s' "$ATTR" | tr '[:lower:]' '[:upper:]')
  magick -background none -fill "$ACCENT" -font "$MONO" -pointsize 34 \
    -kerning 6 label:"$UP" -trim +repage "$TMP/attr.png"
  ATTR_IMG="$TMP/attr.png"
  ATTR_H=$(magick identify -format '%h' "$TMP/attr.png")
fi

BLOCK_H=$(( QH + (ATTR_H>0 ? ATTR_GAP + ATTR_H : 0) ))
BLOCK_BOTTOM_MARGIN=196
QY=$(( H - BLOCK_BOTTOM_MARGIN - BLOCK_H ))
ATTR_Y=$(( QY + QH + ATTR_GAP ))
BAR_TOP=$(( QY - 4 ))
BAR_BOT=$(( QY + BLOCK_H + 4 ))

magick "$TMP/base.png" \
  -fill "$ACCENT" -draw "rectangle $((MX-42)),${BAR_TOP} $((MX-34)),${BAR_BOT}" \
  "$TMP/quote.png" -gravity northwest -geometry "+${MX}+${QY}" -composite \
  "$TMP/out1.png"

if [[ -n "$ATTR_IMG" ]]; then
  magick "$TMP/out1.png" "$ATTR_IMG" \
    -gravity northwest -geometry "+${MX}+${ATTR_Y}" -composite "$OUT"
else
  cp "$TMP/out1.png" "$OUT"
fi

magick identify -format '%f  %wx%h  %b\n' "$OUT"
