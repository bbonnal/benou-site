---
title: "Neovim"
date: 2026-09-12
tags: ["tools", "neovim", "editor"]
source: doc/pages/tools/nvim.md
source_sha: 9d15e6fc32db
---

> Neovim keybindings and recipes. Leader is Space. Config: one file per concern in
> `.config/nvim/lua/{config,plugins}/` — see `doc/nvim/README.md`.

## Vim basics

Vim's own motions and operators, not this config's — they work anywhere vim
bindings do.

### Motion

- Left / down / up / right: `h` `j` `k` `l`
- Start of next / previous word: `w` / `b`
- Start / end of line: `0` / `$`
- Start / end of file: `gg` / `G`

### Editing

- Insert before / after the cursor: `i` / `a`
- Delete line: `dd`
- Yank line: `yy`
- Paste after the cursor: `p`
- Undo / redo: `u` / `Ctrl+r`

### Files

- Save: `:w` (this config also maps `<leader>w`)
- Quit: `:q`
- Save and quit: `:wq`
- Quit without saving: `:q!`

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

## Recipes

Filtering through shell commands: `:read !cmd` inserts a command's output below the
cursor, and `:'<,'>!cmd` replaces the selected lines with whatever the command makes
of them.

### Insert the date

- Full: `:read !date` → `Sun Dec 21 01:24:39 PM CET 2025`
- Date only: `:read !date +\%F` → `2025-12-21`
- Date and time: `:read !date +\%F\ \%T` → `2025-12-21 13:35:47`

`%` means "the current filename" inside `:!`, so every `%` in the format string has
to be escaped as `\%`.

### Number a list

Select the lines, then filter them through `nl`:

```
:'<,'>!nl -w1 -s.

 First item           1. First item
 Second item    →    2. Second item
 Third item           3. Third item
```

`-w1` is the number width, `-s.` the separator after it. The leading space on each
input line is what puts a space after the dot.

### Count lines, words and characters across files

```
:read !wc -l -w -m ~/Repos/benou-site/content/docs/tools/* | sort -n
```

`sort -n` puts the biggest last; `wc` prints a warning line for any directory in the
glob, which you delete along with the rest once you are done reading it.

### Find and replace in a selection

```
:'<,'>s/kangaroo/koala/gIc
```

- `g` — every match on a line, not just the first
- `I` — case-sensitive, whatever `ignorecase` is set to
- `c` — confirm each replacement

Because of `I`, a capitalised `Kangaroo` is left alone and needs a second pass.

Manual alternative, good when the matches want different treatment: `ciw` the first
one, then move to the next match and repeat with `.`.

### Search for the text you just yanked

Yank it, press `/`, then `Ctrl+r` `"` to paste the unnamed register into the search
prompt. Walk the matches with `n` and `N`.

## Maintenance

- Update plugins (review diff, `:w` applies, `:q` discards): `:PackUpdate`
- What is installed, without fetching: `:PackStatus`
- Roll everything back to the lockfile: `:PackRestore`
- Delete plugins nothing references any more: `:PackClean`
- LSP / formatter / debugger installer: `:Mason`
- Attached servers for this buffer: `:LspInfo`
- Which formatter ran: `:ConformInfo`
- Diagnose problems: `:checkhealth`
