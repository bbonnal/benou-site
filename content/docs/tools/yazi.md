---
title: "Yazi"
date: 2026-03-11
tags: ["tools", "yazi", "files"]
source: doc/pages/tools/yazi.md
source_sha: ca0a38662013
---

> Yazi file manager keybindings. Open with `f` alias or `yazi`.

## Navigation

- Move down/up: `j` / `k`
- Enter directory / open file: `l` or `Enter`
- Go to parent directory: `h`
- Go to home directory: `~`
- Go to root: `/`
- Jump to top: `gg`
- Jump to bottom: `G`

## Opening files

- Open with default app: `Enter` or `l`
- Open with picker: `o`
- Open in editor ($EDITOR): `e`
- Open in pager: `i`

## Selection

- Toggle selection: `Space`
- Select all: `Ctrl+a`
- Invert selection: `Ctrl+r`

## File operations

- Yank (copy) selected: `y`
- Cut selected: `x`
- Paste: `p`
- Paste (overwrite): `P`
- Delete (trash): `d`
- Delete permanently: `D`
- Create file: `a`
- Create directory: `A` (or `a` with trailing `/`)
- Rename: `r`

## Search / Filter

- Filter files in current dir: `f`
- Search with fd: `s`
- Search with ripgrep: `S`

## Tabs

- Open new tab: `t`
- Switch to tab 1–9: `1`–`9`
- Close tab: `q`

## Misc

- Quit: `q` (or `Q` to quit without cd)
- Show hidden files toggle: `.`
- Sort by name/modified/size: `,n` / `,m` / `,s`
- Copy path to clipboard: `c` then `c` (yank path), `c` then `d` (yank dir)
- Shell command: `!`
- Interactive shell: `s` (custom, depends on config)
