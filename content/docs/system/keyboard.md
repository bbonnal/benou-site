---
title: "Keyboard"
date: 2026-08-23
tags: ["system", "keyboard", "xkb"]
source: doc/pages/system/keyboard.md
source_sha: b7ed0241e37b
---

> Custom Swiss keyboard layout variants and unicode input.

## Layout overview

- Base layout: `ch_benou_full` (custom, defined in xkb)
- Two variants loaded simultaneously:
  - `fr_code` — optimized for coding (symbols accessible via AltGr)
  - `fr_typing` — optimized for typing French (accents easier)
- Toggle between variants: `Alt+Shift` (xkb option: `grp:alt_shift_toggle`)
- Caps Lock → Ctrl: `ctrl:nocaps`

## Dead keys on Wayland

`fr_typing` maps `<AE12>` to `dead_circumflex`, but a dead key only becomes `ê`
if something downstream composes it. GTK 4.20 dropped its built-in compose
fallback on Wayland when no input method is running — it now defers to the
compositor's `text-input-v3`, and sway has no IME behind that protocol. So GTK4
apps (ghostty, and with it nvim/tmux; also zathura, pavucontrol) silently
swallowed `^`+`e`. Fix, in `.zprofile`:

`export GTK_IM_MODULE=simple`

This restores GTK's own compose table — no daemon, no IME package. It must be in
the environment of the *GTK process*: `.zprofile` works because the tty login
shell that starts sway exports it down to every client. The `zsh -l` that ghostty
runs as its shell is inside the process, too late to count.

Two things that made this confusing:

- Firefox kept working. It links libgtk-**3**, which still has the fallback.
  A toolkit difference, not a layout one.
- `é è à ç` kept working. They are direct keysyms in this layout
  (`<AC10>`, `<AD11>`, `<AC11>`, `<AE04>`) and never touch the compose path.
  Only `ê â î ô û`, `¨` and `~` accents broke.

## Unicode character input

Works in any GTK app (terminal, browser, etc.):

- Short codepoints (4 hex digits):
  `Ctrl+Shift+u` → type hex code → `Enter`
  Example: `Ctrl+Shift+u` → `f488` → `Enter`

- Long codepoints (via nerf font / special):
  In nvim insert mode: `Ctrl+v` `u` then 4-digit hex
  Or: `Ctrl+v` `U` then 8-digit hex

## Key repeat

- Delay: 300ms (before repeat starts)
- Rate: 100 keys/second

## Useful xkb commands

- Check current layout/variant:
  `swaymsg -t get_inputs | grep -A5 keyboard`

- Reload input config (after sway reload):
  `$mod+Shift+c`

## xkb custom layout location

`~/.config/xkb/symbols/ch_benou_full`

libxkbcommon searches `$XDG_CONFIG_HOME/xkb` on its own, so no symlink into
`/usr/share/X11/xkb/symbols/` and no `evdev.xml` edit is needed — the
`sudo ln -s` instructions in that directory's `README.md` are obsolete.
