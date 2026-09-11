---
title: "tmux"
date: 2026-07-25
tags: ["tools", "tmux", "terminal"]
source: doc/pages/tools/tmux.md
source_sha: f4a94940e7ff
---

> Tmux keybindings. Prefix is Ctrl+S.

Ghostty starts tmux for every window, and sessions survive reboots — see `tmux-sessions.md`
for how that works, session naming, and saving/restoring.

## Custom bindings

- Reload config:
  `Prefix r`

- Split pane horizontally (side by side):
  `Prefix $`

- Split pane vertically (top/bottom):
  `Prefix -`

## Popup windows

- Open lazygit in a popup (80%x80%):
  `Prefix Ctrl+k`

- Create a new tmux session interactively:
  `Prefix Ctrl+n`

- Switch session via fzf picker:
  `Prefix Ctrl+j`

- Open a shell popup in current directory (75%x75%):
  `Prefix Ctrl+h`

## Windows

- New window: `Prefix c`
- Kill window: `Prefix &`
- Rename window: `Prefix ,`
- Next window: `Prefix n`
- Previous window: `Prefix p`
- Last window: `Prefix l`
- Select window 0–9: `Prefix 0`–`Prefix 9`
- Choose window from list: `Prefix w`
- Move window: `Prefix .`
- Break pane to new window: `Prefix !`

## Panes

- Kill active pane: `Prefix x`
- Zoom active pane: `Prefix z`
- Select next pane: `Prefix o`
- Show pane numbers: `Prefix q`
- Move pane to previous: `Prefix ;`
- Swap pane up: `Prefix {`
- Swap pane down: `Prefix }`
- Select pane: `Prefix Up/Down/Left/Right`
- Mark pane: `Prefix m`
- Clear mark: `Prefix M`
- Search for pane: `Prefix f`

## Sessions

- Detach client: `Prefix d`
- Rename current session: `Prefix R`
- Kill current session (confirms first): `Prefix X`
- Choose session from list: `Prefix s`
- Switch to next client: `Prefix )`
- Switch to previous client: `Prefix (`
- Switch to last client: `Prefix L`

Note: `Prefix R` exists because tmux's default rename-session key is `Prefix $`, which is
rebound here to split-window.

## Save & restore (tmux-resurrect)

- Save a snapshot of **all** sessions: `Prefix C-s`
- Restore the newest snapshot: `Prefix C-r`

`Prefix C-s` is resurrect's save, not `send-prefix` — tpm loads last and rebinds it, so a
`bind-key C-s send-prefix` line in `tmux.conf` would be dead code. Details and the rollback
procedure are in `tmux-sessions.md`.

## Copy mode

- Enter copy mode: `Prefix [`
- Paste most recent buffer: `Prefix ]`
- Enter copy mode + scroll up: `Prefix PPage`
- List paste buffers: `Prefix #`
- Choose paste buffer: `Prefix =`

## Layouts

- Next layout: `Prefix Space`
- Even horizontal: `Prefix M-1`
- Even vertical: `Prefix M-2`
- Main horizontal: `Prefix M-3`
- Main vertical: `Prefix M-4`
- Tiled: `Prefix M-5`
- Spread evenly: `Prefix E`

## Misc

- Describe key binding: `Prefix /`
- List key bindings: `Prefix ?`
- Prompt for command: `Prefix :`
- Show messages: `Prefix ~`
- Show clock: `Prefix t`
- Display window info: `Prefix i`

## Vim-tmux navigation (cross pane/split)

- `Ctrl+h/j/k/l` — navigate between tmux panes and nvim splits seamlessly
- `Ctrl+\` — navigate to previous pane/split

## Modified keys (Shift+Enter, Ctrl+Enter)

A terminal only reports modified keys when the program asks for them, and inside tmux that
request has to survive two hops. Miss either hop and tmux forwards a bare `Enter` — which is
why Claude Code used to submit the prompt instead of inserting a newline:

    set -ag terminal-features ",${TERM}:extkeys"   # Ghostty can report modified keys
    set -s extended-keys on                        # pass the pane's request through

Nothing was ever bound to `Shift+Enter`; tmux simply could not see the Shift.

To check it is live: `tmux display -p '#{pane_key_mode}'` prints `VT10x` when off, `Ext 1` or
`Ext 2` once the program in the pane has negotiated. Programs negotiate at startup, so after
changing this restart the program — `Prefix r` alone is not enough.

## Plugins

- tpm — plugin manager (`Prefix I` install, `Prefix U` update)
- tmux-sensible — sensible defaults
- tmux-resurrect — session persistence
- vim-tmux-navigator — seamless nvim+tmux navigation

## Status bar

- Top bar: windows left, snapshot age + session + time right
- Window format: `index:name`; active window has bold white background
- Snapshot age comes from `~/.local/bin/tmux-save-age`: grey under an hour, yellow under a
  day, red beyond — a reminder to press `Prefix C-s`
