---
title: "Lazygit"
date: 2026-03-11
tags: ["tools", "lazygit", "git"]
source: doc/pages/tools/lazygit.md
source_sha: bb5707f3e8ca
---

> Lazygit keybindings. Open from tmux with Prefix+Ctrl+k.

## Navigation

- Move between panels: `Tab` / `Shift+Tab`
- Move up/down in list: `k` / `j`
- Scroll panel up/down: `Ctrl+u` / `Ctrl+d`
- Go to next/previous hunk: `]` / `[`

## Staging

- Stage / unstage file: `Space`
- Stage all files: `a`
- Stage hunk: `Space` (in diff view)
- Discard changes: `d`
- Discard all: `D`

## Commits

- Commit: `c`
- Amend last commit: `A`
- Reword last commit message: `r`
- Undo last commit: `g` then confirm

## Branches

- Checkout branch: `Space` (in branches panel)
- New branch: `n`
- Delete branch: `d`
- Merge branch into current: `M`
- Rebase onto branch: `r`

## Stash

- Stash changes: `s`
- Pop stash: `Space` (in stash panel)

## Remotes

- Push: `P`
- Pull: `p`
- Fetch: `f`

## Misc

- Quit: `q`
- Open help: `?`
- Open file in editor: `e`
- Copy commit hash: `Ctrl+y`
- Filter/search: `/`

## IdeaVim-style mappings (if configured)

The LSP-style mappings (`grn`, `gra`, etc.) from IdeaVim carry over conceptually — see `tools/ideavim` page for details.
