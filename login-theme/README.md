# Lumon login theme

Play the *Severance* "Main Titles" **every time you unlock the screen** — a
cold login included. The theme swells over the Lumon lock screen and keeps
playing into the session. Pause it from the bar media widget.

## The honest caveat

This does **not** play at the real pre-login greeter. Omarchy boots into
`greetd`, which runs as a separate `greeter` user with its own audio session
that is destroyed at login — there's no way to hand a playing track across
that boundary. Instead, a small watcher inside your session notices the
lock→unlock transition and starts the theme then. With `LOCK_ON_LOGIN=1`
(default) the session also locks itself at boot, so a cold login gets the
theme on that first unlock too.

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
injects a marked block into `~/.config/hypr/autostart.lua`. Idempotent.
`./uninstall.sh` reverses it (keeps your config + audio).

**It only takes effect at your next login** — the watcher and the boot lock
are started by `autostart.lua`, which runs when the Hyprland session starts.

## Controls

| | |
|---|---|
| bar media widget | pause / resume / scrub — mpv exposes MPRIS, so it just appears there |
| `XF86AudioPlay` / play-pause key | toggles it like any MPRIS player |
| `lumon-login-theme toggle \| stop \| status` | from a terminal |
| `lumon-login-theme disable` | stop it auto-playing on unlock (re-enable with `enable`) |

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
| `LOCK_ON_LOGIN` | `1` | also lock at boot, so a cold login gets the theme |
| `LOGIN_DELAY` | `1.5` | seconds to wait for the shell before the boot lock |
| `RETRIGGER_DEBOUNCE` | `8` | ignore an unlock within N s of the last play |
| `TITLE` | `Severance — Main Titles` | shown in the bar |
| `AUDIO` | — | explicit path; overrides the `~/.config/omarchy/lumon/` lookup |

## How it works

`o.exec_on_start("lumon-login-theme login")` fires on `hyprland.start`. It
launches `lumon-login-theme watch` (an flock-guarded loop that polls
`omarchy-hyprland-session-locked` every 2 s and, on a lock→unlock edge, starts
the theme), and — if `LOCK_ON_LOGIN` — locks the screen once the shell is up.

Playback is `mpv --no-video --input-ipc-server=…` run detached, so it's a
normal session process that survives the unlock and rides into the session.
`toggle`/`pause`/`stop` talk to mpv over its IPC socket via `socat`; the bar
sees it over MPRIS (`/etc/mpv/scripts/mpris.so`).
