# omarchy-lumon-wallpapers

> Part of **[Omarchy · Lumon Industries](https://github.com/KaiCryan/omarchy-lumon)** — a whole-system _Severance_ theme for Omarchy. This repo is one piece; the hub links the rest.

*Severance* / Lumon Industries wallpapers for [Omarchy](https://omarchy.org),
plus an hourly cycler.

- **`wallpapers/40`–`45`** — the severed-floor crew as ASCII line portraits
  (Milchick, Mark, Helly, Dylan, Irving, Kier): "LUMON" up top, a big centred
  glyph face, the character's quote off to the left. Nothing else.
- **`wallpapers/10`–`13`** — clean vector-built Lumon brand wallpapers
  (void / quiet corner / wordmark / glow), 4K.
- **`quote/`** — ten eerie Severance quotes composited onto stills, Lumon-placard
  style.

## Install

```sh
git clone https://github.com/KaiCryan/omarchy-lumon-wallpapers
cd omarchy-lumon-wallpapers
./install.sh            # copies wallpapers + enables the hourly cycle
./install.sh --no-cycle # skip the timer
```

Then `omarchy theme bg next` cycles through them (they land in
`~/.config/omarchy/backgrounds/lumon/`).

### Hourly cycle

`install.sh` drops a `wallpaper-cycle.timer` systemd user unit that runs
`omarchy theme bg next` at the top of every hour.

```sh
systemctl --user disable --now wallpaper-cycle.timer   # stop it
# change the cadence: edit OnCalendar= in ~/.config/systemd/user/wallpaper-cycle.timer
```

## Regenerating the character set

Everything is built from `characters/`:

```sh
cd characters
./build.sh
```

Reads `characters.tsv` (`id / src / crop / name / role / dept / quote / sketch`)
and the headshots in `src/`. Add a row + a headshot to add a character; the
`sketch` column (`blur,blackpt,whitept`) tunes the pencil-sketch pass per photo.
Writes the wallpapers to `characters/wallpapers/` and, if
[omarchy-lumon-greeting](https://github.com/KaiCryan/omarchy-lumon-greeting)
is installed, refreshes its `badge` portraits too.

`characters/_portrait.py` (image → ASCII, ImageMagick only) is shared with the
greeting repo. `characters/SOURCES.md` lists every headshot's Wikimedia origin —
used for a personal, non-commercial desktop theme.

## Login theme (optional)

[`login-theme/`](login-theme/) plays the *Severance* main-title theme at login
and lets it ride into the session, with a pause control in the bar. The audio
is copyrighted and not included — you supply your own. See
[`login-theme/README.md`](login-theme/README.md).

```sh
cd login-theme && ./install.sh
lumon-login-theme set-audio ~/Music/severance-main-titles.mp3
```

## Uninstall

```sh
./uninstall.sh
```

## Requires

ImageMagick, and the fonts Michroma / IBM Plex Sans / a mono Nerd Font
(resolved through `fontconfig`; falls back to generic families).
