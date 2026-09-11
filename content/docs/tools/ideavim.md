---
title: "IdeaVim"
date: 2026-03-11
tags: ["tools", "ideavim", "jetbrains"]
source: doc/pages/tools/ideavim.md
source_sha: 257f0de486c1
---

> IdeaVim keybindings for JetBrains IDEs. Leader is Space.

## Navigation

- End of line: `L` → `$`
- Start of line: `H` → `^`

## Project Explorer (NERDTree)

- Toggle NERDTree: `<leader>e`
- Focus NERDTree: `<leader>o`
- Find current file in tree: `<leader>pv`

## Comments

- Toggle line comment: `<leader>kc` or `gcc`
- Toggle block comment: `<leader>kb`
- Toggle comment (visual): `gc`

## Tab navigation

- Previous tab: `gh`
- Next tab: `gl`
- Close editor: `<leader>ct`

## Method navigation

- Move method down: `gj`
- Move method up: `gk`

## Navigation / History

- Jump to last change: `g,`
- Jump to next change: `g.`
- Navigate back: `gb`

## LSP-style mappings

- Rename element: `grn`
- Code action / intentions: `gra`
- Find references: `grr`
- Go to implementation: `gri`
- Go to definition: `grd`
- Go to declaration: `grD`
- Go to type definition: `grt`
- File structure popup: `gO`
- Workspace symbol: `gW`
- Go to super method: `gs`
- Show documentation: `K`
- Show parameter info: `<leader>k`
- Reformat code: `<leader>f`

## Telescope-style search

- Search help: `<leader>sh`
- Lookup element: `<leader>sk`
- Search files: `<leader>sf`
- Search current word: `<leader>sw`
- Find in path (grep): `<leader>sg`
- Problems view: `<leader>sd`
- Recent files: `<leader>sr` or `<leader>s.` or `<leader><leader>`
- Search in current buffer: `<leader>/`
- Search in open files: `<leader>s/`

## Additional

- Replace in path: `<leader>rf`
- Generate menu: `<leader>ge`
- Expand all regions: `<leader>er`
- Collapse all regions: `<leader>cr`
- AceJump word: `<leader>fw`
- AceJump target: `<leader>fp`

## Window / Split navigation

- Move to split left/down/up/right: `Ctrl+h/j/k/l`
- Previous split: `Ctrl+\`

## Window management

- Split vertically: `<leader>vs`
- Split horizontally: `<leader>hs`
- Unsplit: `<leader>wu`
- Unsplit all: `<leader>wo`
