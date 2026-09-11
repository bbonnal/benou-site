---
title: "Ghostty"
date: 2026-08-23
tags: ["tools", "ghostty", "terminal"]
source: doc/pages/tools/ghostty.md
source_sha: 61e939b94b3a
---

> Ghostty terminal emulator config. Lives at `~/.config/ghostty/config`.

## Shell

- Every window opens inside tmux:
  `command = /usr/bin/zsh -l -c "exec tmux-attach"`
  - `zsh -l` sources `.zprofile`, so the XDG vars and `PATH` are set before tmux starts
  - `tmux-attach` restores the saved layout on the first window after a boot, otherwise
    reuses a session no other window is on — see `tmux-sessions.md`
  - Panes inside tmux get their own interactive zsh, so `.zshrc` is sourced there
  - Escape hatch: `TMUX_AUTOSTART=0 ghostty`, or `ghostty -e zsh`

- Pin the integration scheme, since `command` is no longer a bare shell name for
  `detect` to recognise:
  `shell-integration = zsh`

## Keyboard input

- Ghostty does not compose dead keys itself — it hands keys to GTK's input
  method, and since GTK 4.20 that needs `export GTK_IM_MODULE=simple` in
  `.zprofile` or `^`+`e` produces nothing. See `system/keyboard.md`.

## Font / appearance

- Font: `font-family = JetBrains Mono`, size 12
- Disable ligatures: `font-feature = "-calt, -liga, -dlig"`
- Theme: `theme = GitLab Dark Grey`
- Cursor: `cursor-style = block`
- Extra row spacing: `adjust-cell-height = 35%`

## Shell integration

- Keep cursor shaping and cwd reporting, drop the rest:
  `shell-integration-features = cursor,no-sudo,no-title,no-ssh-env,no-ssh-terminfo,path`

## Window

- No decorations: `window-decoration = none`
- Close without confirming: `confirm-close-surface = false`
  (safe here — closing a window only detaches from the tmux session, see `tmux-sessions.md`)
- Save size/position across sessions: `window-save-state = always`
- Display-P3 colorspace: `window-colorspace = "display-p3"`
- Padding 8px each side, balanced: `window-padding-x/y = 8`, `window-padding-balance = true`
- No cgroup isolation: `linux-cgroup = never`

## Mouse

- Auto-hide while typing: `mouse-hide-while-typing = true`
- Slower scroll: `mouse-scroll-multiplier = 0.5`

## Reload

- Ghostty auto-reloads on config save. If a change doesn't apply, restart the terminal.
