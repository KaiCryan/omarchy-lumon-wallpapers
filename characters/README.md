# Severance character assets

**ASCII line portraits** of the Severance cast (not photos), in two places in the
Lumon theme: the terminal greeting and the wallpaper rotation. Each headshot is
run through an ImageMagick colour-dodge pencil sketch (drops the studio
background, keeps the facial lines) and then turned into glyphs.

Currently 6: Milchick, Mark, Helly, Dylan, Irving, Kier (Kier = an Ambrose
Burnside PD engraving as a stand-in). Burt / Ms. Casey / Ms. Cobel were dropped —
their `src/*.jpg` are kept, re-add with a `characters.tsv` row.

## Regenerate everything

    ./build.sh

Reads `characters.tsv` (id / src / crop / name / role / dept / quote / sketch)
and the headshots in `src/` (provenance in `SOURCES.md`), then writes — and
prunes anything stale (old `4[0-9]-*.jpg`, `*.txt`):

| Output | Consumed by |
|---|---|
| `portraits/<id>.png` | working full-res crop (1000×1250) |
| `portraits/<id>-sketch.png` | working line drawing |
| `~/.config/omarchy/branding/lumon-anims/portraits/<id>.txt` | greeting `badge` (46-col ASCII) |
| `…/portraits/roster.tsv` | `badge` text |
| `~/.config/omarchy/backgrounds/lumon/4N-<id>.jpg` | wallpaper rotation (3840×2160) |

The `sketch` column is `blur,blackpt,whitept` — tune per photo if a face reads
muddy (lower the whitepoint for more glyph density, raise the blur for softer
lines).

## Where it shows up

- **Terminal greeting** — `lumon-anims/badge` (in the rotation). Force it with
  `LUMON_ANIM="badge"` in `~/.config/omarchy/branding/lumon-greeting.conf`, or
  weight it: `LUMON_ANIM="badge badge globe mdr elevator"`.
  Preview: `lumon-greeting badge`
- **Wallpapers** — `40-milchick` … `45-kier` in `backgrounds/lumon/`: minimal —
  "LUMON" top, a big centred ASCII face, the quote on the left. Nothing else.
  `omarchy theme bg next` cycles them (also on an hourly timer). Delete the
  `4*.jpg` files to drop them.

## Renderers

- `../lumon-anims/_portrait.py` — image → mono ASCII (used here) / duotone / truecolor half-block,
  ImageMagick only, no Python deps.
- `_previewtty.py` — run any greeting animation in a fake terminal and print the
  final screen as plain text. Non-invasive layout check:
  `python3 _previewtty.py --cols 110 --rows 44 -- python3 ../lumon-anims/badge`

## Adding a character

1. drop a headshot in `src/`
2. add a row to `characters.tsv` (tune the `crop` as `WxH+X+Y`, gravity north)
3. `./build.sh`
