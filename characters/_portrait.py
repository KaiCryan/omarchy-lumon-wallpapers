#!/usr/bin/env python3
"""image -> terminal portrait, no third-party deps (ImageMagick does the decode).

A helper (leading underscore = not an animation; the `badge` animation and the
character screensaver call it, and the build script pre-renders every portrait
with it so the greeting never has to shell out to magick).

Renderers, all half-height (each text row is two image rows via the upper-half
block glyph, so a cell carries an fg pixel over a bg pixel):

  --mode truecolor : 24-bit colour straight from the photo
  --mode duotone   : photo luminance mapped onto the Lumon ramp
                     (deep navy -> cyan -> near-white) -- the theme look
  --mode mono      : no colour, a ` .:-=+*#%@`-style ASCII ramp

Aspect ratio is read from the (optionally cropped) source so the face is not
stretched. Override with --rows if you need an exact height.

  _portrait.py IMG --cols 46 --mode duotone
  _portrait.py IMG --cols 46 --mode duotone --crop 860x1040+0+30
  _portrait.py IMG --cols 96 --mode truecolor --rows 60

Palette knobs come from the environment (see _lumon.py):
LUMON_COLOR, LUMON_DIM, LUMON_HOT.  Output ends with a reset; store it in a
file and `cat` it later, that is fine.
"""
import os
import subprocess
import sys

DIM = os.environ.get("LUMON_DIM", "74;107;128")
COLOR = os.environ.get("LUMON_COLOR", "158;204;228")
HOT = os.environ.get("LUMON_HOT", "242;252;255")
NAVY = (10, 20, 32)
RAMP_MONO = " .,:;irsXA253hMHGS#9B&@"


def _rgb(s):
    return tuple(int(v) for v in s.split(";"))


def _src_aspect(path, crop):
    """height / width of the region we will actually sample"""
    if crop:
        wh = crop.split("+", 1)[0]
        w, h = (int(v) for v in wh.split("x"))
        return h / w
    out = subprocess.run(["magick", "identify", "-format", "%w %h", path + "[0]"],
                         capture_output=True, text=True, check=True).stdout.split()
    return int(out[1]) / int(out[0])


def pixels(path, cols, rows, crop=None):
    pre = ["magick", path, "-auto-orient"]
    if crop:
        pre += ["-gravity", "north", "-crop", crop, "+repage"]
    pre += ["-resize", f"{cols}x{rows}!", "-colorspace", "sRGB", "-depth", "8", "RGB:-"]
    raw = subprocess.run(pre, capture_output=True, check=True).stdout
    if len(raw) < cols * rows * 3:
        raise SystemExit("magick returned too few pixels")
    grid, i = [], 0
    for _ in range(rows):
        row = []
        for _ in range(cols):
            row.append((raw[i], raw[i + 1], raw[i + 2]))
            i += 3
        grid.append(row)
    return grid


def lum(px):
    return 0.299 * px[0] + 0.587 * px[1] + 0.114 * px[2]


def lerp(a, b, t):
    return tuple(round(a[k] + (b[k] - a[k]) * t) for k in range(3))


def duotone(px):
    stops = [NAVY, _rgb(DIM), _rgb(COLOR), _rgb(HOT)]
    t = max(0.0, min(1.0, lum(px) / 255.0)) * (len(stops) - 1)
    lo = int(t)
    if lo >= len(stops) - 1:
        return stops[-1]
    return lerp(stops[lo], stops[lo + 1], t - lo)


def render(path, cols=46, mode="duotone", crop=None, rows=None):
    if rows is None:
        # each text row is 2 stacked pixels in a ~1-wide cell, so a text row is
        # 2 screen units tall vs 1 wide -> halve to keep the face un-stretched
        rows = max(1, round(cols * _src_aspect(path, crop) / 2))
    grid = pixels(path, cols, rows * 2, crop)
    out = []

    if mode == "mono":
        for y in range(0, rows * 2, 2):
            line = []
            for x in range(cols):
                v = (lum(grid[y][x]) + lum(grid[y + 1][x])) / 2 / 255.0
                line.append(RAMP_MONO[min(len(RAMP_MONO) - 1,
                                          int(v * (len(RAMP_MONO) - 1) + 0.5))])
            out.append("".join(line))  # full width, no rstrip: callers rely on it
        return "\n".join(out)

    conv = duotone if mode == "duotone" else (lambda px: px)
    for y in range(0, rows * 2, 2):
        line, prev = [], None
        for x in range(cols):
            top, bot = conv(grid[y][x]), conv(grid[y + 1][x])
            if (top, bot) != prev:
                line.append(f"\033[38;2;{top[0]};{top[1]};{top[2]}m"
                            f"\033[48;2;{bot[0]};{bot[1]};{bot[2]}m")
                prev = (top, bot)
            line.append("▀")
        line.append("\033[0m")
        out.append("".join(line))
    return "\n".join(out)


def main():
    a = sys.argv[1:]
    path = a[0]
    cols = int(a[a.index("--cols") + 1]) if "--cols" in a else 46
    mode = a[a.index("--mode") + 1] if "--mode" in a else "duotone"
    crop = a[a.index("--crop") + 1] if "--crop" in a else None
    rows = int(a[a.index("--rows") + 1]) if "--rows" in a else None
    sys.stdout.write(render(path, cols, mode, crop, rows) + "\n")


if __name__ == "__main__":
    main()
