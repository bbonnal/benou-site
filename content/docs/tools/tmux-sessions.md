---
title: "tmux sessions"
date: 2026-07-25
tags: ["tools", "tmux", "sessions"]
source: doc/pages/tools/tmux-sessions.md
source_sha: d53e0ede7ed4
---

> Living in tmux full-time: Ghostty starts it for you, sessions survive reboots, and how
> saving actually works. Keybinding reference lives in `tmux.md`; this page is the workflow.

Prefix is `Ctrl+S` throughout, written `Prefix`.

## The five keys that cover almost everything

```
Prefix d        detach — leave the session running, close the terminal
Prefix C-j      switch session (fzf picker)
Prefix C-s      save a snapshot of every session      <- the one you must remember
Prefix R        rename the current session
Prefix X        kill the current session (asks first)
```

---

## A day in the life

```
DAY 1
  open ghostty      no server, no snapshot
                    -> "Session name (Enter for 'main'):"  you type: work
                    -> split panes, start nvim
  Prefix C-s        -> snapshot: [work]
  open ghostty      "work" is busy
                    -> "Session name (Enter for 'main'):"  you type: notes
                    -> a different layout
  Prefix C-s        -> snapshot: [work, notes]     supersedes the first snapshot
  shut down         panes die, the snapshot on disk does not

DAY 2
  open ghostty      no server, snapshot exists
                    -> "restoring layout saved 2026-07-24 18:42 (14h ago)..."
                    -> work (3 panes) and notes (2 panes) rebuilt, cwds and nvim included
                    -> attaches to whichever you used last
  open ghostty      "notes" is free -> attaches straight to it, no prompt
  Prefix C-j        -> fzf between them
  status bar        -> "saved 14h" in yellow: your layout has drifted, press Prefix C-s
```

The only habit to build is `Prefix C-s` before you finish. Everything else is automatic.

---

## Mental model

```
tmux server ....................... one background process, outlives every terminal window
  |
  +-- session "work" .............. a workspace; this is what gets saved and restored
  |     +-- window 1 .............. like a tab
  |     |     +-- pane ............ a shell
  |     |     +-- pane
  |     +-- window 2
  |
  +-- session "notes"
```

**The one rule:** the server is not your terminal. Closing a Ghostty window kills only the
*view*. The session, its panes, and everything running in them keep going. That is why
`Prefix d` and clicking the X are the same thing here, and why nothing is ever lost by
closing a window.

Only two things actually destroy a session: `Prefix X`, and exiting every pane in it.

---

## What happens when you open a Ghostty window

`~/.local/bin/tmux-attach` decides, in this order:

```
already inside tmux ................... plain shell, no nesting (matters over ssh)
TMUX_AUTOSTART=0 ...................... plain shell
no server running + snapshot exists ... restore everything, then attach
a session with no window attached ..... attach to the most recently active one
otherwise ............................. ask for a name, create it
```

Why "no window attached" and not just "any session": two windows attached to one session
mirror each other keystroke for keystroke and both shrink to the smaller one's size. So
each window gets its own session, and a session you closed is reused rather than piling up.

### The name prompt

```
Session name (Enter for 'main-2'):
```

```
Enter (empty) ............. uses the offered name: main, main-2, main-3, ...
a name that exists, free .. attaches to it — typing a name is also how you jump to it
a name that exists, busy .. says so and asks again
anything else ............. creates it
Ctrl+D .................... plain shell, no tmux
```

`.` and `:` are replaced with `-` (tmux won't accept them in a session name).

Names are worth typing: they are what restore brings sessions back *as*. `main-2` tells
you nothing tomorrow morning. Renamed later with `Prefix R` — the new name is picked up by
the next `Prefix C-s`.

---

## Saving and restoring, honestly

This is tmux-resurrect, and it does not work the way you would guess.

### A save is a snapshot of the whole server

`Prefix C-s` writes **every session at once** into one file. There is no per-session save.
Two consequences:

- **Saves are not additive.** Kill `notes`, then press `Prefix C-s`, and `notes` is gone
  from the new snapshot. The snapshot always describes exactly what was running when you
  pressed the key.
- **You never save "just this session".** Saving from inside `work` also captures `notes`.

### Where it lives

```
~/.local/share/tmux/resurrect/
  last -> tmux_resurrect_20260724T184200.txt      symlink to the newest
  tmux_resurrect_20260724T184200.txt
  tmux_resurrect_20260723T091500.txt              older snapshots are kept
```

`Prefix C-r` (and the automatic restore on a cold start) always reads `last`. Old snapshots
are pruned after 30 days.

**Rolling back to an earlier snapshot** — repoint `last` and restore:

```sh
cd ~/.local/share/tmux/resurrect
ls -t                                          # newest first
ln -sf tmux_resurrect_20260723T091500.txt last
```

Then `Prefix C-r`. Nothing is overwritten until your next `Prefix C-s`.

### What survives and what does not

```
layout, splits, sizes ......... yes
window and session names ...... yes
working directory per pane .... yes
nvim, less, man, top, htop .... yes    restarted from an allowlist
any other program .............. no    comes back as a plain shell
pane scrollback ................ no    deliberately off here
shell variables, background jobs  no
```

The allowlist is `@resurrect-default-processes`:
`vi vim view nvim emacs man less more tail top htop irssi weechat mutt`.

Concretely: a snapshot holding `nvim report.typ` and `typst watch report.typ` restores the
nvim pane running nvim, and the typst pane as a bare shell in the right directory. To have
`typst watch` restart too, add to `tmux.conf`:

```
set -g @resurrect-processes 'typst'
```

### The staleness trap

Restore is automatic; saving is not. So this can happen:

```
day 2   restore yesterday's snapshot, work all day, forget Prefix C-s
day 3   restore ... yesterday's snapshot again — the same one
day 4   still that same snapshot
```

Nothing is broken, and nothing warns you. That is what the status-bar segment is for:

```
saved 12m     grey     fresh, ignore it
saved 5h      yellow   drifted today, worth a Prefix C-s
saved 7mo     red      this is what tomorrow morning would restore
never saved   red      no snapshot at all
```

It reads the mtime of `last`, so it turns grey within five seconds of a save.

---

## Is history shared between sessions?

Two different histories, two different answers.

**Shell history — yes, completely shared, and always has been.** `.zshrc` sets
`share_history` and `inc_append_history` against a single `HISTFILE`
(`$XDG_CACHE_HOME/zsh_history`). A command run in one pane is immediately available to
`Ctrl+R` in every other pane, every window, every session — and it outlives reboots. This
is zsh, not tmux; sessions have no effect on it either way.

**Scrollback — no.** Each pane has its own buffer (50 000 lines, from tmux-sensible). It is
never shared between panes and is not saved across reboots. Restored panes start blank.

---

## Detach vs close vs kill

```
action                  keys              session lives on?   panes keep running?
detach                  Prefix d          yes                 yes
close the ghostty win   window close      yes                 yes
kill the session        Prefix X          no                  no
exit every pane         exit / Ctrl+D     no                  no
```

The first two are identical in effect. Use whichever is nearer to hand.

---

## Session cheat-sheet

From inside tmux:

```
Prefix C-j      switch session (fzf)
Prefix s        switch session (tmux's own list, shows windows as a tree)
Prefix C-n      create a session by name, in a popup
Prefix R        rename this session
Prefix X        kill this session
Prefix d        detach
```

From any shell:

```sh
tmux ls                             # list sessions
tmux attach -t '=work'              # attach to one by name
tmux new-session -s notes           # create one
tmux kill-session -t '=notes'       # kill one
tmux kill-server                    # kill everything (the snapshot on disk survives)
```

### Two quoting traps worth knowing

**Always write `'=name'`, quoted.** The `=` tells tmux to match the name *exactly*; without
it `-t work` also matches `workshop`, and tmux picks one for you. And the quotes matter in
zsh specifically — a bare word starting with `=` is a command-path expansion:

```sh
tmux kill-session -t =notes      # zsh: notes not found
tmux kill-session -t '=notes'    # correct
```

---

## Getting out of tmux

```sh
TMUX_AUTOSTART=0 ghostty     # one window with a plain shell
ghostty -e zsh               # same thing via ghostty's own flag
```

`Ctrl+D` at the name prompt also drops you into a plain shell for that window. Inside an
existing tmux session (over ssh, say) `tmux-attach` is a no-op and starts a plain shell, so
sessions never nest by accident.

To stop the whole thing permanently, remove the `command = ` line from
`~/.config/ghostty/config`.

---

## Troubleshooting

```
Ghostty opens and closes instantly
    tmux-attach is missing from PATH -> run `stow -v .` in ~/Dotfiles.
    To get a terminal meanwhile: `ghostty -e zsh`, or a TTY with Ctrl+Alt+F2.

The same old layout gets restored every morning
    You are not saving. Check the status bar colour; press Prefix C-s before you finish.

I am in a session called "0"
    A snapshot taken before this setup existed, from a plain `tmux` with no -s.
    Prefix R to rename it, then Prefix C-s so the name sticks.

Two windows showing the same panes
    Two clients on one session. Prefix d in one, then reopen — it will pick a free
    session or offer to make one.

Sessions piling up
    `tmux ls` to see them, Prefix X to kill the one you are in. Remember the next
    Prefix C-s is what removes them from the snapshot too.

A restored pane is a plain shell instead of my program
    Not on the resurrect allowlist. See "What survives and what does not".

Config edits are not taking effect
    tmux.conf: Prefix r. ghostty: reloads on save, restart the window if not.
```

---

## Learning path

**Week 1 — stop losing work.** Only three keys: `Prefix d` to leave, `Prefix C-j` to move
between sessions, and a name at the prompt that means something. Close windows freely and
notice that nothing dies.

**Week 2 — make it persist.** `Prefix C-s` before you shut down; watch the status segment
go grey. Reboot, and see the layout come back. Once that is habit, learn the rollback so a
bad save is never final.

See also: `tmux.md` (all keybindings), `ghostty.md` (terminal config).
