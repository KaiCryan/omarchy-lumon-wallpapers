# Lumon login theme

Play the *Severance* "Main Titles" the moment you log in — the Lumon lock
screen drops over the session, the theme swells, and it keeps playing after
you unlock. Pause it from the bar or `SUPER+CTRL+P`.

## The honest caveat

This does **not** play at the real pre-login greeter. Omarchy boots into
`greetd`, which runs as a separate `greeter` user with its own audio session
that is destroyed at login — there's no way to hand a playing track across
that boundary. So the theme starts the instant your Hyprland **session**
starts, ~1–2 s after your password goes in. With `LOCK_ON_LOGIN=1` (default)
the screen locks immediately, so what you *see* is: unlock prompt → theme
playing → you unlock → theme continues. Close enough to a scored login.

## The audio is yours to supply

The Severance main-title theme (Theodore Shapiro, Apple TV+) is copyrighted.
It is **not** in this repo and never will be. Provide your own copy:

```sh
lumon-login-theme set-audio ~/Music/severance-main-titles.mp3
# or drop it at ~/.config/omarchy/lumon/main-titles.mp3 yourself
```

Accepted: `.mp3 .opus .m4a .ogg .flac .wav`. Until a file is present the whole
thing stays dormant — no music, and no lock-on-login either.

## Install

```sh
cd login-theme
./install.sh
```

Symlinks `lumon-login-theme` into `~/.local/bin`, copies the config, and
injects marked blocks into `~/.config/hypr/autostart.lua` and `bindings.lua`.
Idempotent. `./uninstall.sh` reverses it (keeps your config + audio).

## Controls

| | |
|---|---|
| bar media widget | pause / resume / scrub — mpv exposes MPRIS, so it just appears there |
| `XF86AudioPlay` / play-pause key | toggles it like any MPRIS player |
| `lumon-login-theme toggle \| stop \| status` | from a terminal |
| `lumon-login-theme disable` | stop it auto-playing at login (re-enable with `enable`) |

No dedicated hotkey is installed (every sensible chord was already taken by
Omarchy). To add one, put this in `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + ALT + P", "Pause/resume login theme", "lumon-login-theme toggle")
```

## Config — `~/.config/omarchy/lumon-login-theme.conf`

| Key | Default | |
|---|---|---|
| `VOLUME` | `65` | mpv volume, 100 = unity |
| `LOOP` | `0` | `1` = repeat until stopped |
| `LOCK_ON_LOGIN` | `1` | drop the Lumon lock screen at session start |
| `LOGIN_DELAY` | `1.5` | seconds to wait for the shell before locking — lower if you see a desktop flash |
| `TITLE` | `Severance — Main Titles` | shown in the bar |
| `AUDIO` | — | explicit path; overrides the `~/.config/omarchy/lumon/` lookup |

## How it works

`o.exec_on_start("lumon-login-theme login")` fires on `hyprland.start`. That
re-execs itself detached, waits `LOGIN_DELAY`, runs `omarchy-system-lock`,
then starts `mpv --no-video --input-ipc-server=…`. Playback is a normal
session process, so it survives the unlock. `toggle`/`pause`/`stop` talk to
mpv over its IPC socket via `socat`; the bar sees it over MPRIS
(`/etc/mpv/scripts/mpris.so`).
