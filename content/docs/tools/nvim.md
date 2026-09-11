---
title: "Neovim"
date: 2026-08-02
tags: ["tools", "neovim", "editor"]
source: doc/pages/tools/nvim.md
source_sha: f84c18863d90
---

> Neovim keybindings. Leader is Space. Config: one file per concern in
> `.config/nvim/lua/{config,plugins}/` — see `doc/nvim/README.md`.

## General

- Save file:
  `<leader>w`

- Clear search highlight:
  `Escape`

- Format buffer (conform.nvim; python = ruff):
  `<leader>f`

- Open diagnostic quickfix list:
  `<leader>q`

- Toggle file explorer (neo-tree):
  `\`

## Telescope / Fuzzy Finder

- Search help tags: `<leader>sh`
- Search keymaps: `<leader>sk`
- Search files: `<leader>sf`
- Search current word: `<leader>sw`
- Live grep: `<leader>sg`
- Search diagnostics: `<leader>sd`
- Resume previous search: `<leader>sr`
- Search recent files: `<leader>s.`
- Find existing buffers: `<leader><leader>`
- Fuzzy search in current buffer: `<leader>/`
- Live grep in open files: `<leader>s/`
- Find Neovim config files: `<leader>sn`
- Search Telescope pickers: `<leader>ss`

## LSP

Servers: basedpyright + ruff (python), clangd (C/C++), roslyn (C#), lua_ls.

- Rename symbol: `grn`
- Code action (ruff autofix, organize imports, ...): `gra`
- Find references: `grr`
- Go to implementation: `gri`
- Go to definition: `grd`
- Go to declaration: `grD`
- Go to type definition: `grt`
- Document symbols: `gO`
- Workspace symbols: `gW`
- Toggle inlay hints: `<leader>th`

## Debug / DAP

Workflow, docker attach, launch.json: see `nvim-debugging`.

- Toggle breakpoint: `<leader>db`
- Conditional breakpoint: `<leader>dB`
- Start / continue (opens config picker): `<leader>dc`
- Run to cursor: `<leader>dC`
- Step into / over / out: `<leader>di` / `<leader>dO` / `<leader>do`
- Terminate: `<leader>dt`
- Toggle debug UI: `<leader>du`
- Eval expression under cursor: `<leader>de`
- Run last config again: `<leader>dl`
- Toggle REPL: `<leader>dr`
- Debug python test method / class: `<leader>dm` / `<leader>dM`
- VS Code style: `F5` continue, `F10` over, `F11` into, `F12` out

## Autocompletion (blink.cmp)

- Next item: `Ctrl+n`
- Previous item: `Ctrl+p`
- Scroll docs up: `Ctrl+b`
- Scroll docs down: `Ctrl+f`
- Confirm completion: `Ctrl+Space` (or `Ctrl+y`)
- Cancel: `Ctrl+e`
- Next / previous snippet placeholder: `Tab` / `Shift+Tab`

## Tmux Navigation (vim-tmux-navigator)

- Navigate left: `Ctrl+h`
- Navigate down: `Ctrl+j`
- Navigate up: `Ctrl+k`
- Navigate right: `Ctrl+l`
- Navigate previous: `Ctrl+\`

## Mini.nvim Text Objects / Surrounds

- Visual select around parenthesis: `va)`
- Yank inside next quote: `yinq`
- Change inside single quotes: `ci'`
- Surround add inner word with parenthesis: `saiw)`
- Surround delete quotes: `sd'`
- Surround replace parenthesis with quotes: `sr)'`

## Maintenance

- Update plugins (review diff, `:w` applies, `:q` discards): `:PackUpdate`
- What is installed, without fetching: `:PackStatus`
- Roll everything back to the lockfile: `:PackRestore`
- Delete plugins nothing references any more: `:PackClean`
- LSP / formatter / debugger installer: `:Mason`
- Attached servers for this buffer: `:LspInfo`
- Which formatter ran: `:ConformInfo`
- Diagnose problems: `:checkhealth`
